#!/usr/bin/env python3
"""Hostile-ZIP validation and exact extraction for executable bootstraps."""

from __future__ import annotations

from contextlib import contextmanager
import fcntl
import hashlib
import os
from pathlib import Path, PurePosixPath
import posixpath
import stat
import struct
from typing import Any, BinaryIO, Iterator
import zipfile


READ_CHUNK = 1024 * 1024
MAX_COMPRESSION_RATIO = 200
SUPPORTED_COMPRESSION = frozenset((zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED))
COMMON_FLAGS = 0x0008 | 0x0800
DEFLATE_FLAGS = COMMON_FLAGS | 0x0006


class BootstrapError(Exception):
    """Raised when executable bootstrap data fails closed."""


def _fail(message: str) -> None:
    raise BootstrapError(message)


@contextmanager
def open_regular(path: Path, maximum: int, context: str) -> Iterator[BinaryIO]:
    """Open one bounded regular inode without following its final link."""
    if not hasattr(os, "O_NOFOLLOW"):
        _fail("no-follow file access is unavailable")
    try:
        before = path.lstat()
    except OSError as exc:
        _fail(f"cannot stat {context}: {exc.strerror or exc}")
    if not stat.S_ISREG(before.st_mode) or before.st_size > maximum:
        _fail(f"{context} is not a bounded regular file")

    flags = os.O_RDONLY | os.O_NOFOLLOW
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        _fail(f"cannot safely open {context}: {exc.strerror or exc}")
    stream = os.fdopen(descriptor, "rb", closefd=True)
    try:
        opened = os.fstat(stream.fileno())
        if not stat.S_ISREG(opened.st_mode):
            _fail(f"{context} changed type")
        if (opened.st_dev, opened.st_ino) != (before.st_dev, before.st_ino):
            _fail(f"{context} changed before open")
        if opened.st_size != before.st_size or opened.st_size > maximum:
            _fail(f"{context} changed size before open")
        yield stream
        after = os.fstat(stream.fileno())
        if (after.st_dev, after.st_ino, after.st_size) != (
            opened.st_dev,
            opened.st_ino,
            opened.st_size,
        ):
            _fail(f"{context} changed while open")
    finally:
        stream.close()


def hash_open_file(stream: BinaryIO, maximum: int) -> tuple[int, str]:
    stream.seek(0)
    digest = hashlib.sha256()
    size = 0
    while True:
        chunk = stream.read(READ_CHUNK)
        if not chunk:
            break
        size += len(chunk)
        if size > maximum:
            _fail("file exceeds its byte limit")
        digest.update(chunk)
    stream.seek(0)
    return size, digest.hexdigest()


def verify_artifact(stream: BinaryIO, expected_size: int, expected_sha256: str) -> None:
    size, digest = hash_open_file(stream, expected_size)
    if size != expected_size or digest != expected_sha256:
        _fail("archive size or SHA-256 mismatch")


def _normalized_member(info: zipfile.ZipInfo) -> str:
    name = info.orig_filename
    if not name or "\x00" in name or "\\" in name:
        _fail("archive member has an unsafe name")
    pure = PurePosixPath(name)
    normalized = posixpath.normpath(name)
    if (
        name.startswith("/")
        or pure.is_absolute()
        or normalized != name
        or any(part in ("", ".", "..") for part in pure.parts)
        or len(pure.parts) != 1
    ):
        _fail("archive member is not one normalized top-level POSIX name")
    return normalized


def _member_mode(info: zipfile.ZipInfo) -> int:
    if info.create_system != 3:
        _fail("archive member lacks authenticated Unix file metadata")
    mode = (info.external_attr >> 16) & 0xFFFF
    if not stat.S_ISREG(mode):
        _fail("archive contains a link, directory, or special file")
    return stat.S_IMODE(mode)


def _compressed_range(
    stream: BinaryIO, info: zipfile.ZipInfo, start_dir: int
) -> tuple[int, int]:
    stream.seek(info.header_offset)
    header = stream.read(30)
    if len(header) != 30 or header[:4] != b"PK\x03\x04":
        _fail("archive has an invalid local member header")
    local_flags, local_compression = struct.unpack("<HH", header[6:10])
    if local_flags != info.flag_bits or local_compression != info.compress_type:
        _fail("archive local member metadata contradicts the central directory")
    name_length, extra_length = struct.unpack("<HH", header[26:30])
    start = info.header_offset + 30 + name_length + extra_length
    end = start + info.compress_size
    if start < 0 or end < start or end > start_dir:
        _fail("archive member data is outside the valid ZIP data range")
    return start, end


def inspect_archive(stream: BinaryIO, layout: list[dict[str, Any]]) -> None:
    """Authenticate the full ZIP structure and every uncompressed member byte."""
    expected = {entry["path"]: entry for entry in layout}
    seen: set[str] = set()
    stream.seek(0)
    try:
        with zipfile.ZipFile(stream) as archive:
            infos = archive.infolist()
            if len(infos) != len(expected):
                _fail("archive member count does not match the exact layout")
            ranges: list[tuple[int, int]] = []
            for info in infos:
                name = _normalized_member(info)
                if name in seen:
                    _fail("archive has duplicate normalized member names")
                seen.add(name)
                entry = expected.get(name)
                if entry is None:
                    _fail("archive contains a member outside the exact layout")
                if info.flag_bits & 0x1:
                    _fail("encrypted archive members are forbidden")
                if info.compress_type not in SUPPORTED_COMPRESSION:
                    _fail("archive uses unsupported compression")
                allowed_flags = (
                    DEFLATE_FLAGS
                    if info.compress_type == zipfile.ZIP_DEFLATED
                    else COMMON_FLAGS
                )
                if info.flag_bits & ~allowed_flags:
                    _fail("archive member uses unsupported ZIP flags")
                ranges.append(_compressed_range(stream, info, archive.start_dir))
                if _member_mode(info) != int(entry["mode"], 8):
                    _fail("archive member mode does not match the lock")
                if info.file_size != entry["size"]:
                    _fail("archive member size does not match the lock")
                if info.file_size and (
                    info.compress_size == 0
                    or info.file_size > info.compress_size * MAX_COMPRESSION_RATIO
                ):
                    _fail("archive member exceeds the compression-ratio limit")

                digest = hashlib.sha256()
                count = 0
                with archive.open(info, "r") as source:
                    while True:
                        chunk = source.read(READ_CHUNK)
                        if not chunk:
                            break
                        count += len(chunk)
                        if count > entry["size"]:
                            _fail("archive member expands beyond its locked size")
                        digest.update(chunk)
                if count != entry["size"] or digest.hexdigest() != entry["sha256"]:
                    _fail("archive member bytes do not match the lock")
            ordered_ranges = sorted(ranges)
            for previous, current in zip(ordered_ranges, ordered_ranges[1:]):
                if current[0] < previous[1]:
                    _fail("archive member compressed ranges overlap")
    except (OSError, zipfile.BadZipFile, RuntimeError, NotImplementedError) as exc:
        _fail(f"invalid executable archive: {type(exc).__name__}")
    finally:
        stream.seek(0)
    if seen != set(expected):
        _fail("archive is missing locked members")


def extract_archive(
    stream: BinaryIO, destination: Path, layout: list[dict[str, Any]]
) -> None:
    """Extract an already inspected archive into a new private directory."""
    expected = {entry["path"]: entry for entry in layout}
    stream.seek(0)
    before = destination.lstat()
    if not stat.S_ISDIR(before.st_mode):
        _fail("extraction destination is not a real directory")
    directory_fd = os.open(destination, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        opened = os.fstat(directory_fd)
        if (opened.st_dev, opened.st_ino) != (before.st_dev, before.st_ino):
            _fail("extraction destination changed before open")
        with zipfile.ZipFile(stream) as archive:
            for info in archive.infolist():
                name = _normalized_member(info)
                entry = expected[name]
                flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
                descriptor = os.open(name, flags, 0o600, dir_fd=directory_fd)
                try:
                    digest = hashlib.sha256()
                    count = 0
                    with os.fdopen(descriptor, "wb", closefd=False) as target:
                        with archive.open(info, "r") as source:
                            while True:
                                chunk = source.read(READ_CHUNK)
                                if not chunk:
                                    break
                                count += len(chunk)
                                if count > entry["size"]:
                                    _fail("member changed during extraction")
                                target.write(chunk)
                                digest.update(chunk)
                        target.flush()
                        os.fsync(target.fileno())
                    if count != entry["size"] or digest.hexdigest() != entry["sha256"]:
                        _fail("extracted member bytes do not match the lock")
                    os.fchmod(descriptor, int(entry["mode"], 8))
                    os.fsync(descriptor)
                finally:
                    os.close(descriptor)
        os.fsync(directory_fd)
        after = os.fstat(directory_fd)
        if (after.st_dev, after.st_ino) != (opened.st_dev, opened.st_ino):
            _fail("extraction destination changed while open")
    finally:
        os.close(directory_fd)
        stream.seek(0)


def _stable_identity(info: os.stat_result) -> tuple[int, ...]:
    return (
        info.st_dev,
        info.st_ino,
        info.st_mode,
        info.st_size,
        info.st_mtime_ns,
        info.st_ctime_ns,
    )


def _validate_open_member(directory_fd: int, name: str, entry: dict[str, Any]) -> int:
    try:
        before = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
    except OSError:
        _fail("cannot stat installed executable member")
    if not stat.S_ISREG(before.st_mode):
        _fail("installed executable member is not a regular file")
    if stat.S_IMODE(before.st_mode) != int(entry["mode"], 8):
        _fail("installed executable member has the wrong mode")

    flags = os.O_RDONLY | os.O_NOFOLLOW
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    try:
        descriptor = os.open(name, flags, dir_fd=directory_fd)
    except OSError:
        _fail("cannot safely open installed executable member")
    try:
        opened = os.fstat(descriptor)
        if _stable_identity(opened) != _stable_identity(before):
            _fail("installed executable member changed before open")
        with os.fdopen(descriptor, "rb", closefd=False) as stream:
            size, digest = hash_open_file(stream, entry["size"])
        after = os.fstat(descriptor)
        if _stable_identity(after) != _stable_identity(opened):
            _fail("installed executable member changed while being read")
        if size != entry["size"] or digest != entry["sha256"]:
            _fail("installed executable member does not match the lock")
        return descriptor
    except Exception:
        os.close(descriptor)
        raise


@contextmanager
def _open_validated_install(
    directory: Path,
    layout: list[dict[str, Any]],
    executable_name: str | None,
) -> Iterator[int | None]:
    try:
        directory_stat = directory.lstat()
    except OSError as exc:
        _fail(f"cannot stat installed executable directory: {exc.strerror or exc}")
    if not stat.S_ISDIR(directory_stat.st_mode):
        _fail("installed executable path is not a real directory")

    directory_fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    executable_fd: int | None = None
    try:
        opened = os.fstat(directory_fd)
        if (opened.st_dev, opened.st_ino) != (
            directory_stat.st_dev,
            directory_stat.st_ino,
        ):
            _fail("installed executable directory changed before open")
        expected = {entry["path"]: entry for entry in layout}
        if set(os.listdir(directory_fd)) != set(expected):
            _fail("installed executable directory does not match the exact layout")
        for name, entry in expected.items():
            descriptor = _validate_open_member(directory_fd, name, entry)
            if name == executable_name:
                executable_fd = descriptor
            else:
                os.close(descriptor)
        if executable_name is not None and executable_fd is None:
            _fail("locked executable member is absent from the install layout")
        after = os.fstat(directory_fd)
        if _stable_identity(after) != _stable_identity(opened):
            _fail("installed executable directory changed during validation")
        yield executable_fd
    finally:
        if executable_fd is not None:
            os.close(executable_fd)
        os.close(directory_fd)


@contextmanager
def open_validated_executable(
    directory: Path, layout: list[dict[str, Any]], executable_name: str
) -> Iterator[int]:
    """Yield the exact locked executable inode while its directory FD is held."""
    entries = {entry["path"]: entry for entry in layout}
    executable_entry = entries.get(executable_name)
    if executable_entry is None:
        _fail("locked executable member is absent from the install layout")
    if int(executable_entry["mode"], 8) & 0o111 == 0:
        _fail("locked executable member is not executable")
    with _open_validated_install(directory, layout, executable_name) as descriptor:
        if descriptor is None:
            _fail("locked executable member descriptor is unavailable")
        yield descriptor


@contextmanager
def open_sealed_executable(source_fd: int, entry: dict[str, Any]) -> Iterator[int]:
    """Copy locked bytes into a write-sealed anonymous executable inode."""
    required_os = ("memfd_create", "MFD_ALLOW_SEALING", "MFD_CLOEXEC")
    required_fcntl = (
        "F_ADD_SEALS",
        "F_GET_SEALS",
        "F_SEAL_WRITE",
        "F_SEAL_GROW",
        "F_SEAL_SHRINK",
        "F_SEAL_SEAL",
    )
    if any(not hasattr(os, name) for name in required_os) or any(
        not hasattr(fcntl, name) for name in required_fcntl
    ):
        _fail("sealed file-descriptor execution is unavailable")

    flags = os.MFD_ALLOW_SEALING | os.MFD_CLOEXEC
    try:
        descriptor = os.memfd_create("pixene-executable", flags)
    except OSError:
        _fail("cannot create a sealed executable")
    try:
        os.lseek(source_fd, 0, os.SEEK_SET)
        digest = hashlib.sha256()
        count = 0
        while True:
            chunk = os.read(source_fd, READ_CHUNK)
            if not chunk:
                break
            count += len(chunk)
            if count > entry["size"]:
                _fail("executable copy exceeds its locked size")
            digest.update(chunk)
            view = memoryview(chunk)
            while view:
                written = os.write(descriptor, view)
                if written <= 0:
                    _fail("short sealed executable write")
                view = view[written:]
        if count != entry["size"] or digest.hexdigest() != entry["sha256"]:
            _fail("sealed executable source does not match the lock")

        os.fchmod(descriptor, int(entry["mode"], 8))
        os.fsync(descriptor)
        required_seals = (
            fcntl.F_SEAL_WRITE
            | fcntl.F_SEAL_GROW
            | fcntl.F_SEAL_SHRINK
            | fcntl.F_SEAL_SEAL
        )
        optional_exec_seal = getattr(fcntl, "F_SEAL_EXEC", 0)
        requested_seals = required_seals | optional_exec_seal
        fcntl.fcntl(descriptor, fcntl.F_ADD_SEALS, requested_seals)
        applied_seals = fcntl.fcntl(descriptor, fcntl.F_GET_SEALS)
        if applied_seals & requested_seals != requested_seals:
            _fail("sealed executable is missing required seals")

        with os.fdopen(descriptor, "rb", closefd=False) as stream:
            sealed_size, sealed_digest = hash_open_file(stream, entry["size"])
        sealed_stat = os.fstat(descriptor)
        if (
            sealed_size != entry["size"]
            or sealed_digest != entry["sha256"]
            or not stat.S_ISREG(sealed_stat.st_mode)
            or stat.S_IMODE(sealed_stat.st_mode) != int(entry["mode"], 8)
        ):
            _fail("sealed executable does not match the locked bytes and mode")
        yield descriptor
    except OSError:
        _fail("sealed executable preparation failed")
    finally:
        os.close(descriptor)


def validate_install(directory: Path, layout: list[dict[str, Any]]) -> None:
    with _open_validated_install(directory, layout, None):
        pass
