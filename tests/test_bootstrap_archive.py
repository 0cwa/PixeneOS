#!/usr/bin/env python3
"""Adversarial tests for executable-bootstrap ZIP validation and extraction."""

from __future__ import annotations

from contextlib import contextmanager
import fcntl
import hashlib
import io
import os
from pathlib import Path
import stat
import struct
import sys
import tempfile
import unittest
from unittest import mock
import warnings
import zipfile


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "src"))

from bootstrap_archive import (  # noqa: E402
    BootstrapError,
    extract_archive,
    inspect_archive,
    open_sealed_executable,
    open_validated_executable,
    validate_install,
)


TOOL_BYTES = b"#!/bin/sh\nprintf 'fixture tool\\n'\n"


def locked_member(
    name: str = "tool", data: bytes = TOOL_BYTES, mode: int = 0o755
) -> dict[str, object]:
    return {
        "mode": f"0{mode:o}",
        "path": name,
        "sha256": hashlib.sha256(data).hexdigest(),
        "size": len(data),
        "type": "file",
    }


def zip_info(
    name: str,
    mode: int = stat.S_IFREG | 0o755,
    compression: int = zipfile.ZIP_DEFLATED,
) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
    info.create_system = 3
    info.external_attr = mode << 16
    info.compress_type = compression
    return info


def make_archive(
    entries: list[tuple[str, bytes, int]],
    compression: int = zipfile.ZIP_DEFLATED,
) -> bytes:
    stream = io.BytesIO()
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", UserWarning)
        with zipfile.ZipFile(stream, "w") as archive:
            for name, data, mode in entries:
                archive.writestr(zip_info(name, mode, compression), data)
    return stream.getvalue()


def patch_single_member_headers(
    archive: bytes,
    *,
    flags: int | None = None,
    compression: int | None = None,
) -> bytes:
    """Patch matching local/central fields without rebuilding the ZIP."""
    result = bytearray(archive)
    local = result.find(b"PK\x03\x04")
    central = result.find(b"PK\x01\x02")
    if local < 0 or central < 0:
        raise AssertionError("fixture ZIP lacks expected headers")
    if flags is not None:
        struct.pack_into("<H", result, local + 6, flags)
        struct.pack_into("<H", result, central + 8, flags)
    if compression is not None:
        struct.pack_into("<H", result, local + 8, compression)
        struct.pack_into("<H", result, central + 10, compression)
    return bytes(result)


def patch_single_member_local_header(
    archive: bytes,
    *,
    flags: int | None = None,
    compression: int | None = None,
) -> bytes:
    """Patch only local-header fields to create central/local contradictions."""
    result = bytearray(archive)
    local = result.find(b"PK\x03\x04")
    if local < 0:
        raise AssertionError("fixture ZIP lacks a local member header")
    if flags is not None:
        struct.pack_into("<H", result, local + 6, flags)
    if compression is not None:
        struct.pack_into("<H", result, local + 8, compression)
    return bytes(result)


class BootstrapArchiveTest(unittest.TestCase):
    def assert_rejected(
        self, archive: bytes, layout: list[dict[str, object]] | None = None
    ) -> None:
        with self.assertRaises(BootstrapError):
            inspect_archive(io.BytesIO(archive), layout or [locked_member()])

    def test_safe_exact_layout_inspects_extracts_and_validates(self) -> None:
        readme = b"reviewed fixture\n"
        layout = [
            locked_member("README.md", readme, 0o644),
            locked_member(),
        ]
        archive = make_archive(
            [
                ("README.md", readme, stat.S_IFREG | 0o644),
                ("tool", TOOL_BYTES, stat.S_IFREG | 0o755),
            ]
        )
        stream = io.BytesIO(archive)

        inspect_archive(stream, layout)
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "installed"
            destination.mkdir(mode=0o700)
            extract_archive(stream, destination, layout)
            validate_install(destination, layout)

            self.assertEqual((destination / "tool").read_bytes(), TOOL_BYTES)
            self.assertEqual((destination / "README.md").read_bytes(), readme)
            self.assertEqual(stat.S_IMODE((destination / "tool").stat().st_mode), 0o755)
            self.assertEqual(
                stat.S_IMODE((destination / "README.md").stat().st_mode), 0o644
            )

    def test_unsafe_member_names_are_rejected(self) -> None:
        for name in ("../tool", "/tool", "dir/tool", "tool\\alias", "./tool"):
            with self.subTest(name=name):
                archive = make_archive([(name, TOOL_BYTES, stat.S_IFREG | 0o755)])
                self.assert_rejected(archive)

    def test_duplicate_exact_and_normalized_names_are_rejected(self) -> None:
        layout = [locked_member(), locked_member("placeholder", b"x", 0o644)]
        exact = make_archive(
            [
                ("tool", TOOL_BYTES, stat.S_IFREG | 0o755),
                ("tool", TOOL_BYTES, stat.S_IFREG | 0o755),
            ]
        )
        normalized_alias = make_archive(
            [
                ("tool", TOOL_BYTES, stat.S_IFREG | 0o755),
                ("./tool", TOOL_BYTES, stat.S_IFREG | 0o755),
            ]
        )
        self.assert_rejected(exact, layout)
        self.assert_rejected(normalized_alias, layout)

    def test_links_special_files_and_directories_are_rejected(self) -> None:
        hostile = {
            "symlink": ("tool", b"target", stat.S_IFLNK | 0o777),
            "fifo": ("tool", b"", stat.S_IFIFO | 0o644),
            "directory": ("tool/", b"", stat.S_IFDIR | 0o755),
        }
        for case_name, entry in hostile.items():
            with self.subTest(case=case_name):
                self.assert_rejected(make_archive([entry]))

    def test_extra_and_missing_members_are_rejected(self) -> None:
        extra = make_archive(
            [
                ("tool", TOOL_BYTES, stat.S_IFREG | 0o755),
                ("surprise", b"extra", stat.S_IFREG | 0o644),
            ]
        )
        self.assert_rejected(extra)

        missing_layout = [locked_member(), locked_member("README.md", b"readme", 0o644)]
        ordinary = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        self.assert_rejected(ordinary, missing_layout)

    def test_encrypted_flag_is_rejected(self) -> None:
        ordinary = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        self.assert_rejected(patch_single_member_headers(ordinary, flags=0x0001))

    def test_unsupported_compression_and_flags_are_rejected(self) -> None:
        bzip2_archive = make_archive(
            [("tool", TOOL_BYTES, stat.S_IFREG | 0o755)],
            compression=zipfile.ZIP_BZIP2,
        )
        self.assert_rejected(bzip2_archive)

        ordinary = make_archive(
            [("tool", TOOL_BYTES, stat.S_IFREG | 0o755)],
            compression=zipfile.ZIP_STORED,
        )
        self.assert_rejected(patch_single_member_headers(ordinary, flags=0x0010))

    def test_local_header_flags_and_compression_must_match_central_entry(self) -> None:
        ordinary = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        contradictory = {
            "local-encryption": patch_single_member_local_header(
                ordinary, flags=0x0001
            ),
            "local-unsupported-flag": patch_single_member_local_header(
                ordinary, flags=0x0010
            ),
            "local-compression": patch_single_member_local_header(
                ordinary, compression=zipfile.ZIP_BZIP2
            ),
        }
        for case_name, archive in contradictory.items():
            with self.subTest(case=case_name):
                self.assert_rejected(archive)

    def test_compression_bomb_is_rejected(self) -> None:
        expanded = b"A" * (1024 * 1024)
        archive = make_archive(
            [("tool", expanded, stat.S_IFREG | 0o755)],
            compression=zipfile.ZIP_DEFLATED,
        )
        self.assert_rejected(archive, [locked_member(data=expanded)])

    def test_locked_member_size_hash_and_mode_must_all_match(self) -> None:
        archive = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        wrong_size = locked_member()
        wrong_size["size"] = len(TOOL_BYTES) + 1
        wrong_hash = locked_member()
        wrong_hash["sha256"] = "0" * 64
        wrong_mode = locked_member()
        wrong_mode["mode"] = "0644"

        for case_name, layout in (
            ("size", [wrong_size]),
            ("hash", [wrong_hash]),
            ("mode", [wrong_mode]),
        ):
            with self.subTest(case=case_name):
                self.assert_rejected(archive, layout)

    def test_corrupt_and_truncated_archives_are_rejected(self) -> None:
        ordinary = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        for case_name, archive in (
            ("garbage", b"not a ZIP"),
            ("truncated", ordinary[:-12]),
        ):
            with self.subTest(case=case_name):
                self.assert_rejected(archive)

    @contextmanager
    def installed_fixture(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "installed"
            directory.mkdir(mode=0o700)
            tool = directory / "tool"
            tool.write_bytes(TOOL_BYTES)
            tool.chmod(0o755)
            yield directory, tool

    def test_install_validation_rejects_content_mode_and_extra_member(self) -> None:
        for case_name in ("content", "mode", "extra"):
            with self.subTest(case=case_name), self.installed_fixture() as fixture:
                directory, tool = fixture
                if case_name == "content":
                    tool.write_bytes(b"X" * len(TOOL_BYTES))
                elif case_name == "mode":
                    tool.chmod(0o775)
                else:
                    (directory / "extra").write_bytes(b"unexpected")
                with self.assertRaises(BootstrapError):
                    validate_install(directory, [locked_member()])

    def test_install_validation_rejects_member_and_directory_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = root / "target"
            target.mkdir()
            real_tool = target / "real-tool"
            real_tool.write_bytes(TOOL_BYTES)
            real_tool.chmod(0o755)
            (target / "tool").symlink_to(real_tool)
            with self.assertRaises(BootstrapError):
                validate_install(target, [locked_member()])

            alias = root / "installed-alias"
            alias.symlink_to(target, target_is_directory=True)
            with self.assertRaises(BootstrapError):
                validate_install(alias, [locked_member()])

    def test_extraction_refuses_preexisting_target(self) -> None:
        archive = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        stream = io.BytesIO(archive)
        layout = [locked_member()]
        inspect_archive(stream, layout)
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "installed"
            destination.mkdir(mode=0o700)
            existing = destination / "tool"
            existing.write_bytes(b"do not replace")

            with self.assertRaises(FileExistsError):
                extract_archive(stream, destination, layout)
            self.assertEqual(existing.read_bytes(), b"do not replace")

    def test_validated_executable_fd_survives_path_replacement(self) -> None:
        with self.installed_fixture() as fixture:
            directory, tool = fixture
            original = tool.stat()

            with open_validated_executable(
                directory, [locked_member()], "tool"
            ) as descriptor:
                replacement = directory / "replacement"
                replacement.write_bytes(b"malicious replacement")
                replacement.chmod(0o755)
                replacement.replace(tool)

                self.assertIsInstance(descriptor, int)
                self.assertEqual(os.fstat(descriptor).st_ino, original.st_ino)
                os.lseek(descriptor, 0, os.SEEK_SET)
                self.assertEqual(os.read(descriptor, len(TOOL_BYTES)), TOOL_BYTES)

    def test_validated_executable_requires_locked_executable_member(self) -> None:
        with self.installed_fixture() as fixture:
            directory, _ = fixture
            with self.assertRaises(BootstrapError):
                with open_validated_executable(directory, [locked_member()], "missing"):
                    self.fail("an absent executable must never yield a descriptor")

    def test_validated_executable_requires_locked_execute_bits(self) -> None:
        with self.installed_fixture() as fixture:
            directory, tool = fixture
            tool.chmod(0o644)
            with self.assertRaises(BootstrapError):
                with open_validated_executable(
                    directory, [locked_member(mode=0o644)], "tool"
                ):
                    self.fail("a nonexecutable locked member must never be yielded")

    def test_extraction_failure_never_grants_locked_executable_mode(self) -> None:
        archive = make_archive([("tool", TOOL_BYTES, stat.S_IFREG | 0o755)])
        layout = [locked_member()]
        inspect_archive(io.BytesIO(archive), layout)
        changed = make_archive([("tool", b"X" * len(TOOL_BYTES), stat.S_IFREG | 0o755)])

        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "installed"
            destination.mkdir(mode=0o700)
            with mock.patch("bootstrap_archive.os.fchmod", wraps=os.fchmod) as chmod:
                with self.assertRaises(BootstrapError):
                    extract_archive(io.BytesIO(changed), destination, layout)

            chmod.assert_not_called()
            self.assertEqual(
                stat.S_IMODE((destination / "tool").stat().st_mode) & 0o111,
                0,
            )

    def test_sealed_executable_survives_same_inode_source_overwrite(self) -> None:
        with self.installed_fixture() as (directory, tool):
            layout = [locked_member()]
            with open_validated_executable(directory, layout, "tool") as source:
                with open_sealed_executable(source, layout[0]) as executable:
                    tool.write_bytes(b"X" * len(TOOL_BYTES))
                    os.lseek(executable, 0, os.SEEK_SET)
                    self.assertEqual(os.read(executable, len(TOOL_BYTES)), TOOL_BYTES)
                    seals = fcntl.fcntl(executable, fcntl.F_GET_SEALS)
                    required = (
                        fcntl.F_SEAL_WRITE
                        | fcntl.F_SEAL_GROW
                        | fcntl.F_SEAL_SHRINK
                        | fcntl.F_SEAL_SEAL
                    )
                    self.assertEqual(seals & required, required)
                    with self.assertRaises(OSError):
                        os.write(executable, b"X")

    def test_sealed_executable_closes_memfd_when_sealing_fails(self) -> None:
        captured: list[int] = []
        original = os.memfd_create

        def capture_memfd(name: str, flags: int) -> int:
            descriptor = original(name, flags)
            captured.append(descriptor)
            return descriptor

        with self.installed_fixture() as (directory, _):
            layout = [locked_member()]
            with open_validated_executable(directory, layout, "tool") as source:
                with mock.patch("bootstrap_archive.os.memfd_create", capture_memfd):
                    with mock.patch(
                        "bootstrap_archive.fcntl.fcntl", side_effect=OSError("fail")
                    ):
                        with self.assertRaises(BootstrapError):
                            with open_sealed_executable(source, layout[0]):
                                self.fail("unsealed executable was yielded")
        self.assertEqual(len(captured), 1)
        with self.assertRaises(OSError):
            os.fstat(captured[0])

    def test_sealed_memfd_executes_a_real_native_binary(self) -> None:
        payload = Path("/usr/bin/true").read_bytes()
        layout = [locked_member("tool", payload)]
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "installed"
            directory.mkdir(mode=0o700)
            tool = directory / "tool"
            tool.write_bytes(payload)
            tool.chmod(0o755)
            child = os.fork()
            if child == 0:
                try:
                    with open_validated_executable(directory, layout, "tool") as source:
                        with open_sealed_executable(source, layout[0]) as executable:
                            os.execve(executable, ["tool"], {"PATH": "/usr/bin"})
                finally:
                    os._exit(127)
            _, status = os.waitpid(child, 0)
            self.assertEqual(os.waitstatus_to_exitcode(status), 0)


if __name__ == "__main__":
    unittest.main()
