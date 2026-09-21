#!/usr/bin/env python3
"""Focused validation tests for the optional local boot animation."""

from __future__ import annotations

import hashlib
import stat
import sys
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from boot_animation import (  # noqa: E402
    MAX_MEMBER_COUNT,
    BootAnimationError,
    validate_payload,
)


def write_valid(path: Path, frame: bytes = b"frame") -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
        archive.writestr("part0/frame.png", frame)


def assert_rejected(path: Path, context: str) -> None:
    try:
        validate_payload(path)
    except BootAnimationError:
        return
    raise AssertionError(f"{context}: invalid archive was accepted")


def main() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        valid = root / "bootanimation.zip"
        write_valid(valid)
        expected = hashlib.sha256(valid.read_bytes()).hexdigest()
        assert validate_payload(valid) == expected

        repository_payload = Path("custom/boot-animation/bootanimation.zip")
        assert repository_payload.is_file()
        assert validate_payload(repository_payload) == hashlib.sha256(
            repository_payload.read_bytes()
        ).hexdigest()

        desc_only = root / "desc-only.zip"
        with zipfile.ZipFile(desc_only, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\n")
        assert_rejected(desc_only, "desc-only archive")

        missing_desc = root / "missing-desc.zip"
        with zipfile.ZipFile(missing_desc, "w") as archive:
            archive.writestr("part0/frame.png", b"frame")
        assert_rejected(missing_desc, "missing desc")

        malformed = root / "malformed.zip"
        malformed.write_bytes(b"not a zip")
        assert_rejected(malformed, "malformed archive")

        traversal = root / "traversal.zip"
        with zipfile.ZipFile(traversal, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            archive.writestr("../outside", b"escape")
        assert_rejected(traversal, "path traversal")

        duplicate = root / "duplicate.zip"
        with zipfile.ZipFile(duplicate, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            archive.writestr("part0/frame.png", b"frame")
        assert_rejected(duplicate, "duplicate member")

        encrypted = root / "encrypted.zip"
        with zipfile.ZipFile(encrypted, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            archive.writestr("part0/frame.png", b"frame")
        encrypted_data = bytearray(encrypted.read_bytes())
        for marker, offset in ((b"PK\x03\x04", 6), (b"PK\x01\x02", 8)):
            cursor = 0
            while True:
                cursor = encrypted_data.find(marker, cursor)
                if cursor < 0:
                    break
                flags = int.from_bytes(
                    encrypted_data[cursor + offset : cursor + offset + 2], "little"
                ) | 0x1
                encrypted_data[cursor + offset : cursor + offset + 2] = flags.to_bytes(2, "little")
                cursor += len(marker)
        encrypted.write_bytes(encrypted_data)
        assert_rejected(encrypted, "encrypted member")

        symlink_member = root / "symlink-member.zip"
        with zipfile.ZipFile(symlink_member, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            info = zipfile.ZipInfo("part0/frame.png")
            info.external_attr = (stat.S_IFLNK | 0o777) << 16
            archive.writestr(info, b"frame")
        assert_rejected(symlink_member, "symlink member")

        excessive = root / "excessive.zip"
        with zipfile.ZipFile(excessive, "w") as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            for index in range(MAX_MEMBER_COUNT):
                archive.writestr(f"part0/frame-{index}.png", b"x")
        assert_rejected(excessive, "member count")

        invalid_description = root / "invalid-description.zip"
        with zipfile.ZipFile(invalid_description, "w") as archive:
            archive.writestr("desc.txt", "not a boot animation\n")
            archive.writestr("part0/frame.png", b"frame")
        assert_rejected(invalid_description, "invalid description")

        compressed_bomb = root / "compression-ratio.zip"
        with zipfile.ZipFile(compressed_bomb, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("desc.txt", "1 1 1\np 1 0 part0\n")
            archive.writestr("part0/frame.png", b"0" * (2 * 1024 * 1024))
        assert_rejected(compressed_bomb, "compression ratio")

        symlink = root / "symlink.zip"
        symlink.symlink_to(valid)
        assert_rejected(symlink, "payload symlink")

    print("boot animation validation tests passed")


if __name__ == "__main__":
    main()
