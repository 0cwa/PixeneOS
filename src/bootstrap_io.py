#!/usr/bin/env python3
"""Private I/O, committed-policy, download, and OpenSSH bootstrap helpers."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import secrets
import stat
import subprocess
from typing import Any, BinaryIO
import urllib.parse
import urllib.request

from bootstrap_archive import BootstrapError


MAX_SIGNATURE_BYTES = 64 * 1024
DOWNLOAD_CHUNK = 1024 * 1024
SYSTEM_GIT = Path("/usr/bin/git")
SYSTEM_SSH_KEYGEN = Path("/usr/bin/ssh-keygen")


def fail(message: str) -> None:
    raise BootstrapError(message)


def ensure_private_directory(path: Path) -> None:
    try:
        path.mkdir(mode=0o700, parents=True, exist_ok=True)
        info = path.lstat()
    except OSError as exc:
        fail(f"cannot create private bootstrap directory: {exc.strerror or exc}")
    if not stat.S_ISDIR(info.st_mode) or stat.S_IMODE(info.st_mode) & 0o077:
        fail("bootstrap directory is not a private real directory")


def fsync_directory(path: Path) -> None:
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def write_exclusive(path: Path, data: bytes, mode: int = 0o600) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    descriptor = os.open(path, flags, mode)
    try:
        view = memoryview(data)
        while view:
            written = os.write(descriptor, view)
            if written <= 0:
                fail("short bootstrap metadata write")
            view = view[written:]
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def atomic_write(path: Path, data: bytes, mode: int = 0o600) -> None:
    ensure_private_directory(path.parent)
    temporary = path.parent / f".new-{secrets.token_hex(16)}"
    try:
        write_exclusive(temporary, data, mode)
        os.replace(temporary, path)
        fsync_directory(path.parent)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def committed_bytes(path: Path, captured: bytes) -> None:
    """Require captured policy bytes to equal the clean HEAD blob."""
    if not SYSTEM_GIT.is_file() or SYSTEM_GIT.is_symlink():
        fail("the system Git verifier is unavailable")
    repository = subprocess.run(
        [str(SYSTEM_GIT), "-C", str(path.parent), "rev-parse", "--show-toplevel"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if repository.returncode != 0:
        fail("bootstrap policy is not inside a Git checkout")
    root = Path(repository.stdout.strip()).resolve()
    resolved = path.resolve()
    try:
        relative = resolved.relative_to(root).as_posix()
    except ValueError:
        fail("bootstrap policy is outside the repository")
    blob = subprocess.run(
        [str(SYSTEM_GIT), "-C", str(root), "show", f"HEAD:{relative}"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if blob.returncode != 0 or blob.stdout != captured:
        fail("bootstrap policy must exactly match its committed HEAD blob")


def download_https(url: str, destination: Path, maximum: int) -> tuple[int, str]:
    parsed = urllib.parse.urlsplit(url)
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username
        or parsed.password
    ):
        fail("bootstrap download URL is not strict HTTPS")
    request = urllib.request.Request(
        url, headers={"User-Agent": "PixeneOS-bootstrap/1"}
    )
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
    descriptor = os.open(destination, flags, 0o600)
    digest = hashlib.sha256()
    total = 0
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            final = urllib.parse.urlsplit(response.geturl())
            if final.scheme != "https" or not final.hostname:
                fail("bootstrap redirect left HTTPS")
            if response.headers.get("Content-Encoding", "identity") not in (
                "",
                "identity",
            ):
                fail("encoded bootstrap responses are forbidden")
            declared = response.headers.get("Content-Length")
            if declared is not None:
                try:
                    if int(declared) < 0 or int(declared) > maximum:
                        fail("bootstrap response exceeds its byte limit")
                except ValueError:
                    fail("bootstrap response has an invalid length")
            while True:
                chunk = response.read(DOWNLOAD_CHUNK)
                if not chunk:
                    break
                total += len(chunk)
                if total > maximum:
                    fail("bootstrap response exceeds its byte limit")
                view = memoryview(chunk)
                while view:
                    written = os.write(descriptor, view)
                    if written <= 0:
                        fail("short bootstrap download write")
                    view = view[written:]
                digest.update(chunk)
        os.fsync(descriptor)
    except BootstrapError:
        try:
            destination.unlink()
        except FileNotFoundError:
            pass
        raise
    except Exception:
        try:
            destination.unlink()
        except FileNotFoundError:
            pass
        fail("bootstrap HTTPS acquisition failed")
    finally:
        os.close(descriptor)
    return total, digest.hexdigest()


def verify_ssh_signature(
    archive: BinaryIO, signature: BinaryIO, trust: BinaryIO, tool: dict[str, Any]
) -> None:
    if (
        not SYSTEM_SSH_KEYGEN.is_file()
        or SYSTEM_SSH_KEYGEN.is_symlink()
        or not Path("/proc/self/fd").is_dir()
    ):
        fail("OpenSSH signature verification is unavailable")
    archive.seek(0)
    signature.seek(0)
    trust.seek(0)
    command = [
        str(SYSTEM_SSH_KEYGEN),
        "-Y",
        "verify",
        "-f",
        f"/proc/self/fd/{trust.fileno()}",
        "-I",
        tool["signature"]["identity"],
        "-n",
        tool["signature"]["namespace"],
        "-s",
        f"/proc/self/fd/{signature.fileno()}",
    ]
    result = subprocess.run(
        command,
        stdin=archive,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        close_fds=True,
        pass_fds=(signature.fileno(), trust.fileno()),
        check=False,
    )
    archive.seek(0)
    signature.seek(0)
    trust.seek(0)
    if result.returncode != 0:
        fail("OpenSSH signature verification failed")
