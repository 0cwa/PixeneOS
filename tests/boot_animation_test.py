#!/usr/bin/env python3
"""Focused validation tests for the optional local boot animation."""

from __future__ import annotations

import hashlib
import io
import stat
import sys
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from boot_animation import (  # noqa: E402
    APEX_BOOT_ANIMATION_PATH,
    DISABLED_APEX_BOOT_ANIMATION_PATH,
    MAX_MEMBER_COUNT,
    BootAnimationError,
    build_runtime_payload,
    disable_apex_boot_animation_precedence,
    install_runtime_payload,
    validate_payload,
    verify_runtime_installation,
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


class FakeExtFs:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.mkdir_calls: list[tuple[str, int, bool, bool]] = []
        self.open_calls: list[tuple[str, str, int]] = []

    @property
    def tree(self) -> Path:
        raise AssertionError("boot animation injection bypassed ExtFs metadata APIs")

    def mkdir(
        self,
        path: str,
        mode: int = 0o755,
        parents: bool = False,
        exist_ok: bool = False,
    ) -> None:
        self.mkdir_calls.append((path, mode, parents, exist_ok))
        (self.root / path.lstrip("/")).mkdir(
            mode=mode,
            parents=parents,
            exist_ok=exist_ok,
        )

    def open(self, path: str, open_mode: str, mode: int = 0o644):
        self.open_calls.append((path, open_mode, mode))
        target = self.root / path.lstrip("/")
        target.parent.mkdir(parents=True, exist_ok=True)
        return target.open(open_mode)


def test_runtime_payload_installation() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        source = root / "source.zip"
        write_valid(source)

        runtime = build_runtime_payload(source)
        with zipfile.ZipFile(io.BytesIO(runtime), "r") as archive:
            files = [info for info in archive.infolist() if not info.is_dir()]
            assert files
            assert all(info.compress_type == zipfile.ZIP_STORED for info in files)

        product = FakeExtFs(root / "product-fs")
        install_runtime_payload({"product": product}, runtime)

        expected_targets = [
            "/product/media/bootanimation.zip",
            "/product/media/bootanimation-dark.zip",
        ]
        assert [call[0] for call in product.open_calls] == expected_targets
        assert all(call[1:] == ("wb", 0o644) for call in product.open_calls)
        assert all(call[0] == "/product/media" for call in product.mkdir_calls)
        for target in expected_targets:
            assert (product.root / target.lstrip("/")).read_bytes() == runtime

        system = FakeExtFs(root / "system-fs")
        bootanimation = system.root / "system/bin/bootanimation"
        bootanimation.parent.mkdir(parents=True, exist_ok=True)
        bootanimation.write_bytes(
            b"ELF-prefix" + APEX_BOOT_ANIMATION_PATH + b"ELF-suffix"
        )
        original_size = bootanimation.stat().st_size
        disable_apex_boot_animation_precedence({"system": system})
        patched_binary = bootanimation.read_bytes()
        assert bootanimation.stat().st_size == original_size
        assert APEX_BOOT_ANIMATION_PATH not in patched_binary
        assert patched_binary.count(DISABLED_APEX_BOOT_ANIMATION_PATH) == 1

        verify_runtime_installation(
            source,
            bootanimation,
            product.root / "product/media/bootanimation.zip",
            product.root / "product/media/bootanimation-dark.zip",
        )

        unsupported = FakeExtFs(root / "unsupported-system")
        unsupported_binary = unsupported.root / "system/bin/bootanimation"
        unsupported_binary.parent.mkdir(parents=True, exist_ok=True)
        unsupported_binary.write_bytes(b"ELF-without-apex-path")
        try:
            disable_apex_boot_animation_precedence({"system": unsupported})
        except RuntimeError:
            pass
        else:
            raise AssertionError("unsupported bootanimation binary was accepted")

        duplicate = FakeExtFs(root / "duplicate-system")
        duplicate_binary = duplicate.root / "system/bin/bootanimation"
        duplicate_binary.parent.mkdir(parents=True, exist_ok=True)
        duplicate_binary.write_bytes(APEX_BOOT_ANIMATION_PATH * 2)
        try:
            disable_apex_boot_animation_precedence({"system": duplicate})
        except RuntimeError:
            pass
        else:
            raise AssertionError("ambiguous bootanimation binary was accepted")

        try:
            install_runtime_payload({}, runtime)
        except RuntimeError:
            pass
        else:
            raise AssertionError("missing product partition was accepted")


def main() -> None:
    test_runtime_payload_installation()
    checked_in = Path("custom/boot-animation/bootanimation.zip")
    expected = hashlib.sha256(checked_in.read_bytes()).hexdigest()
    assert validate_payload(checked_in) == expected

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        valid = root / "bootanimation.zip"
        write_valid(valid)
        expected = hashlib.sha256(valid.read_bytes()).hexdigest()
        assert validate_payload(valid) == expected

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
            for index in range(MAX_MEMBER_COUNT + 1):
                archive.writestr(f"part0/frame-{index}.png", b"x")
        assert_rejected(excessive, "member count")

        extended_description = root / "extended-description.zip"
        with zipfile.ZipFile(extended_description, "w") as archive:
            archive.writestr(
                "desc.txt",
                "1440 1440 30\np 0 0 part0 #000000 -1\n",
            )
            archive.writestr("part0/frame.png", b"frame")
        validate_payload(extended_description)

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
