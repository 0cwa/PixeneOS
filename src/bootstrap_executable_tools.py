#!/usr/bin/env python3
"""Acquire and publish authenticated executable tools from the immutable lock."""

from __future__ import annotations

import argparse
from collections.abc import Mapping
from contextlib import ExitStack
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import sys
import tempfile
from typing import Any, BinaryIO, Callable

from bootstrap_archive import (
    BootstrapError,
    extract_archive,
    hash_open_file,
    inspect_archive,
    open_regular,
    open_sealed_executable,
    open_validated_executable,
    validate_install,
    verify_artifact,
)
from bootstrap_io import (
    DOWNLOAD_CHUNK,
    MAX_SIGNATURE_BYTES,
    atomic_write,
    committed_bytes,
    download_https,
    ensure_private_directory,
    fsync_directory,
    verify_ssh_signature,
    write_exclusive,
)
from validate_executable_tool_lock import (
    DEFAULT_LOCK,
    DEFAULT_TRUST,
    ValidationError,
    load_validated_trust,
    validate_lock,
)


MAX_RECEIPT_BYTES = 4096
REPORT_SCHEMA = 1
LOWER_SHA256 = re.compile(r"[0-9a-f]{64}\Z")
UNSAFE_ENVIRONMENT_NAMES = frozenset(
    ("BASH_ENV", "ENV", "GLIBC_TUNABLES", "RUST_BACKTRACE", "RUST_LOG")
)
UNSAFE_ENVIRONMENT_PREFIXES = ("LD_", "DYLD_")


def fail(message: str) -> None:
    raise BootstrapError(message)


def fd_exec_supported() -> bool:
    return os.execve in os.supports_fd


def sanitized_environment(source: Mapping[str, str]) -> dict[str, str]:
    result: dict[str, str] = {}
    for name, value in source.items():
        if not isinstance(name, str) or not isinstance(value, str):
            fail("executable environment must contain only text")
        if name in UNSAFE_ENVIRONMENT_NAMES or name.startswith(
            UNSAFE_ENVIRONMENT_PREFIXES
        ):
            continue
        if not name or "=" in name or "\x00" in name or "\x00" in value:
            fail("executable environment contains an unsafe entry")
        result[name] = value
    return result


class Bootstrapper:
    def __init__(
        self,
        document: dict[str, Any],
        trust_bytes: bytes,
        workdir: Path,
        verifier: Callable[
            [BinaryIO, BinaryIO, BinaryIO, dict[str, Any]], None
        ] = verify_ssh_signature,
        downloader: Callable[[str, Path, int], tuple[int, str]] = download_https,
    ) -> None:
        self.tools = {tool["id"]: tool for tool in document["tools"]}
        self.trust_bytes = trust_bytes
        self.workdir = workdir.absolute()
        self.cache = self.workdir / "bootstrap-cache"
        self.store = self.workdir / "tools" / "by-sha256"
        self.verifier = verifier
        self.downloader = downloader

    def _object_path(self, kind: str, digest: str) -> Path:
        return self.cache / "objects" / kind / digest

    def _install_path(self, tool: dict[str, Any]) -> Path:
        return self.store / tool["sha256"]

    def _publish_object(
        self, source: Path, kind: str, digest: str, maximum: int
    ) -> Path:
        target = self._object_path(kind, digest)
        ensure_private_directory(target.parent)
        temporary = target.parent / f".new-{secrets.token_hex(16)}"
        try:
            with open_regular(
                source, maximum, "verified bootstrap object"
            ) as input_stream:
                size, actual = hash_open_file(input_stream, maximum)
                if actual != digest:
                    fail("verified bootstrap object changed before publication")
                descriptor = os.open(
                    temporary,
                    os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                    0o600,
                )
                try:
                    input_stream.seek(0)
                    copied = 0
                    while True:
                        chunk = input_stream.read(DOWNLOAD_CHUNK)
                        if not chunk:
                            break
                        copied += len(chunk)
                        view = memoryview(chunk)
                        while view:
                            written = os.write(descriptor, view)
                            if written <= 0:
                                fail("short content-addressed object write")
                            view = view[written:]
                    if copied != size:
                        fail("verified bootstrap object changed during publication")
                    os.fsync(descriptor)
                finally:
                    os.close(descriptor)
            os.link(temporary, target, follow_symlinks=False)
            fsync_directory(target.parent)
        except FileExistsError:
            with open_regular(target, maximum, "cached bootstrap object") as stream:
                size, actual = hash_open_file(stream, maximum)
            if actual != digest or size > maximum:
                fail("content-addressed cache collision or corruption")
        finally:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
        return target

    def _receipt(self, tool: dict[str, Any]) -> dict[str, str] | None:
        path = self.cache / "receipts" / f"{tool['sha256']}.json"
        if path.is_symlink():
            fail("bootstrap cache receipt must not be a symlink")
        if not path.exists():
            return None
        with open_regular(path, MAX_RECEIPT_BYTES, "bootstrap cache receipt") as stream:
            raw = stream.read(MAX_RECEIPT_BYTES + 1)
        try:
            receipt = json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError):
            fail("bootstrap cache receipt is invalid")
        expected_fields = {"archive_sha256", "signature_sha256", "tool"}
        if type(receipt) is not dict or set(receipt) != expected_fields:
            fail("bootstrap cache receipt has invalid fields")
        if receipt["archive_sha256"] != tool["sha256"] or receipt["tool"] != tool["id"]:
            fail("bootstrap cache receipt does not match the lock")
        signature_digest = receipt["signature_sha256"]
        if (
            not isinstance(signature_digest, str)
            or LOWER_SHA256.fullmatch(signature_digest) is None
        ):
            fail("bootstrap cache receipt has an invalid signature digest")
        canonical = json.dumps(receipt, indent=2, sort_keys=True).encode() + b"\n"
        if raw != canonical:
            fail("bootstrap cache receipt is not canonical")
        return receipt

    def _verify_pair(
        self,
        tool: dict[str, Any],
        archive_path: Path,
        signature_path: Path,
        trust_path: Path,
    ) -> None:
        with ExitStack() as stack:
            archive = stack.enter_context(
                open_regular(archive_path, tool["size"], "executable archive")
            )
            signature = stack.enter_context(
                open_regular(signature_path, MAX_SIGNATURE_BYTES, "OpenSSH signature")
            )
            trust = stack.enter_context(
                open_regular(trust_path, len(self.trust_bytes), "allowed signers")
            )
            verify_artifact(archive, tool["size"], tool["sha256"])
            self.verifier(archive, signature, trust, tool)
            inspect_archive(archive, tool["layout"])

    def _ensure_artifact(
        self, tool: dict[str, Any], stage: Path, trust_path: Path
    ) -> tuple[Path, Path, str]:
        receipt = self._receipt(tool)
        if receipt is not None:
            archive_path = self._object_path("archives", receipt["archive_sha256"])
            signature_path = self._object_path(
                "signatures", receipt["signature_sha256"]
            )
            self._verify_pair(tool, archive_path, signature_path, trust_path)
            return archive_path, signature_path, receipt["signature_sha256"]

        archive_stage = stage / f"{tool['id']}.archive"
        signature_stage = stage / f"{tool['id']}.signature"
        size, digest = self.downloader(tool["url"], archive_stage, tool["size"])
        if size != tool["size"] or digest != tool["sha256"]:
            fail("downloaded archive size or SHA-256 mismatch")
        _, signature_digest = self.downloader(
            tool["signature"]["url"], signature_stage, MAX_SIGNATURE_BYTES
        )
        self._verify_pair(tool, archive_stage, signature_stage, trust_path)
        archive_path = self._publish_object(
            archive_stage, "archives", tool["sha256"], tool["size"]
        )
        signature_path = self._publish_object(
            signature_stage, "signatures", signature_digest, MAX_SIGNATURE_BYTES
        )
        receipt_data = {
            "archive_sha256": tool["sha256"],
            "signature_sha256": signature_digest,
            "tool": tool["id"],
        }
        receipt_path = self.cache / "receipts" / f"{tool['sha256']}.json"
        atomic_write(
            receipt_path,
            json.dumps(receipt_data, indent=2, sort_keys=True).encode() + b"\n",
        )
        return archive_path, signature_path, signature_digest

    def _check_legacy_directory(self, tool: dict[str, Any]) -> None:
        legacy = self.workdir / "tools" / tool["id"]
        if legacy.exists() or legacy.is_symlink():
            validate_install(legacy, tool["layout"])
            fail("legacy executable directory is not digest-bound")

    def install(self, selected: list[str], report_path: Path) -> None:
        if not selected or len(selected) != len(set(selected)):
            fail("selected executable tool IDs must be unique and nonempty")
        try:
            tools = [self.tools[tool_id] for tool_id in sorted(selected)]
        except KeyError:
            fail("selected executable tool is absent from the lock")
        ensure_private_directory(self.workdir)
        ensure_private_directory(self.cache)
        ensure_private_directory(self.store)
        try:
            report_destination = report_path.resolve(strict=False)
            report_destination.relative_to(self.workdir.resolve(strict=True))
        except ValueError:
            fail("bootstrap report must remain inside the work directory")
        stage_root = self.cache / "staging"
        ensure_private_directory(stage_root)
        stage = Path(tempfile.mkdtemp(prefix="txn-", dir=stage_root))
        os.chmod(stage, 0o700)
        try:
            trust_path = stage / "allowed_signers"
            write_exclusive(trust_path, self.trust_bytes)

            verified: dict[str, tuple[Path, str]] = {}
            for tool in tools:
                archive, _, signature_digest = self._ensure_artifact(
                    tool, stage, trust_path
                )
                verified[tool["id"]] = (archive, signature_digest)

            for tool in tools:
                self._check_legacy_directory(tool)
                installed = self._install_path(tool)
                if installed.exists() or installed.is_symlink():
                    validate_install(installed, tool["layout"])

            extracted: dict[str, Path] = {}
            for tool in tools:
                installed = self._install_path(tool)
                if installed.exists():
                    continue
                destination = stage / f"install-{tool['id']}"
                destination.mkdir(mode=0o700)
                archive_path = verified[tool["id"]][0]
                with open_regular(
                    archive_path, tool["size"], "verified executable archive"
                ) as archive:
                    verify_artifact(archive, tool["size"], tool["sha256"])
                    inspect_archive(archive, tool["layout"])
                    extract_archive(archive, destination, tool["layout"])
                validate_install(destination, tool["layout"])
                extracted[tool["id"]] = destination

            for tool in tools:
                destination = extracted.get(tool["id"])
                if destination is None:
                    continue
                installed = self._install_path(tool)
                try:
                    os.rename(destination, installed)
                    fsync_directory(installed.parent)
                except FileExistsError:
                    validate_install(installed, tool["layout"])

            report = self._report(tools, verified)
            atomic_write(
                report_destination,
                json.dumps(report, indent=2, sort_keys=True).encode() + b"\n",
            )
        finally:
            shutil.rmtree(stage, ignore_errors=True)

    def _report(
        self, tools: list[dict[str, Any]], verified: dict[str, tuple[Path, str]]
    ) -> dict[str, Any]:
        return {
            "schema_version": REPORT_SCHEMA,
            "tools": [
                {
                    "archive_sha256": tool["sha256"],
                    "archive_size": tool["size"],
                    "arch": tool["arch"],
                    "id": tool["id"],
                    "layout": tool["layout"],
                    "signature": {
                        "identity": tool["signature"]["identity"],
                        "namespace": tool["signature"]["namespace"],
                        "sha256": verified[tool["id"]][1],
                        "signer_fingerprint": tool["signature"]["signer_fingerprint"],
                        "type": "ssh",
                        "verified": True,
                    },
                    "version": tool["version"],
                }
                for tool in tools
            ],
        }

    def resolve(self, tool_id: str) -> Path:
        tool = self.tools.get(tool_id)
        if tool is None:
            fail("unknown executable tool")
        self._check_legacy_directory(tool)
        installed = self._install_path(tool)
        validate_install(installed, tool["layout"])
        executable = (installed / tool_id).absolute()
        if not executable.is_absolute() or tool["sha256"] not in executable.parts:
            fail("executable path is not absolute and digest-bound")
        return executable

    def run(
        self,
        tool_id: str,
        arguments: list[str],
        environment: Mapping[str, str] | None = None,
    ) -> None:
        if any(
            not isinstance(argument, str) or "\x00" in argument
            for argument in arguments
        ):
            fail("executable arguments must be NUL-free text")
        if not fd_exec_supported():
            fail("file-descriptor execution is unavailable")
        tool = self.tools.get(tool_id)
        if tool is None:
            fail("unknown executable tool")
        executable_entry = next(
            (entry for entry in tool["layout"] if entry["path"] == tool_id), None
        )
        if executable_entry is None:
            fail("locked executable member is absent from the install layout")
        self._check_legacy_directory(tool)
        installed = self._install_path(tool)
        executable_environment = sanitized_environment(
            os.environ if environment is None else environment
        )
        with open_validated_executable(
            installed, tool["layout"], tool_id
        ) as source_descriptor:
            with open_sealed_executable(
                source_descriptor, executable_entry
            ) as descriptor:
                os.execve(descriptor, [tool_id, *arguments], executable_environment)
        fail("file-descriptor execution unexpectedly returned")


def load_policy(lock: Path, trust: Path) -> tuple[dict[str, Any], bytes]:
    fingerprint, trust_bytes = load_validated_trust(trust)
    document = validate_lock(lock, fingerprint)
    lock_bytes = (
        json.dumps(document, ensure_ascii=True, indent=2, sort_keys=True).encode()
        + b"\n"
    )
    committed_bytes(lock, lock_bytes)
    committed_bytes(trust, trust_bytes)
    return document, trust_bytes


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Authenticate executable bootstrap tools."
    )
    parser.add_argument("--lock", type=Path, default=DEFAULT_LOCK)
    parser.add_argument("--trust", type=Path, default=DEFAULT_TRUST)
    parser.add_argument("--workdir", type=Path, required=True)
    subparsers = parser.add_subparsers(dest="command", required=True)
    install = subparsers.add_parser("install")
    install.add_argument("--report", type=Path, required=True)
    install.add_argument("tools", nargs="+")
    resolve = subparsers.add_parser("resolve")
    resolve.add_argument("tool")
    run = subparsers.add_parser("run")
    run.add_argument("tool")
    run.add_argument("arguments", nargs=argparse.REMAINDER)
    # argparse consumes the one CLI `--`; any subsequent `--` is tool data.
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        document, trust_bytes = load_policy(args.lock, args.trust)
        bootstrapper = Bootstrapper(document, trust_bytes, args.workdir)
        if args.command == "install":
            bootstrapper.install(args.tools, args.report)
            print("Executable bootstrap verification succeeded.")
        elif args.command == "resolve":
            print(bootstrapper.resolve(args.tool))
        else:
            bootstrapper.run(args.tool, args.arguments)
    except (BootstrapError, ValidationError) as exc:
        print(f"executable bootstrap failed: {exc}", file=sys.stderr)
        return 1
    except Exception:
        print("executable bootstrap failed: internal operation failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
