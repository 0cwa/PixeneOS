#!/usr/bin/env python3
"""Runtime crypto, cache, batching, race, and reporting tests for Tranche B."""

from __future__ import annotations

import copy
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "src"))

from bootstrap_archive import BootstrapError  # noqa: E402
from bootstrap_executable_tools import (  # noqa: E402
    Bootstrapper,
    parse_args,
    verify_ssh_signature,
    write_exclusive,
)


def archive_bytes(name: str, payload: bytes, mode: int = 0o755) -> bytes:
    output = io.BytesIO()
    info = zipfile.ZipInfo(name, (2026, 7, 20, 0, 0, 0))
    info.create_system = 3
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = (stat.S_IFREG | mode) << 16
    with zipfile.ZipFile(output, "w") as archive:
        archive.writestr(info, payload)
    return output.getvalue()


def tool_entry(tool_id: str, archive: bytes, payload: bytes) -> dict[str, object]:
    return {
        "arch": "fixture-linux",
        "artifact_name": f"{tool_id}.zip",
        "id": tool_id,
        "layout": [
            {
                "mode": "0755",
                "path": tool_id,
                "sha256": hashlib.sha256(payload).hexdigest(),
                "size": len(payload),
                "type": "file",
            }
        ],
        "sha256": hashlib.sha256(archive).hexdigest(),
        "signature": {
            "identity": "tester",
            "namespace": "file",
            "signer_fingerprint": "fixture-fingerprint",
            "type": "ssh",
            "url": f"https://fixtures.invalid/{tool_id}.zip.sig",
        },
        "size": len(archive),
        "url": f"https://fixtures.invalid/{tool_id}.zip",
        "version": "1",
    }


class BootstrapRuntimeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.work = self.root / "work"
        self.key = self.root / "signing-key"
        self.other_key = self.root / "other-key"
        for key in (self.key, self.other_key):
            subprocess.run(
                ["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)],
                check=True,
            )
        key_parts = self.key.with_suffix(".pub").read_text().split()
        self.trust = f"tester {key_parts[0]} {key_parts[1]}\n".encode()

        self.payloads = {
            "fixture-a": b"alpha executable",
            "fixture-b": b"beta executable",
        }
        self.archives = {
            name: archive_bytes(name, payload)
            for name, payload in self.payloads.items()
        }
        self.tools = {
            name: tool_entry(name, self.archives[name], payload)
            for name, payload in self.payloads.items()
        }
        self.signatures = {
            name: self.sign(self.archives[name], self.key, name)
            for name in self.archives
        }
        self.mapping: dict[str, bytes] = {}
        for name, tool in self.tools.items():
            self.mapping[str(tool["url"])] = self.archives[name]
            signature = tool["signature"]
            assert isinstance(signature, dict)
            self.mapping[str(signature["url"])] = self.signatures[name]

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def sign(self, data: bytes, key: Path, label: str) -> bytes:
        source = self.root / f"{label}-{key.name}.bin"
        source.write_bytes(data)
        subprocess.run(
            ["ssh-keygen", "-Y", "sign", "-f", str(key), "-n", "file", str(source)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return Path(f"{source}.sig").read_bytes()

    def document(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "tools": [copy.deepcopy(self.tools[name]) for name in sorted(self.tools)],
        }

    def downloader(self, mapping: dict[str, bytes] | None = None):
        values = self.mapping if mapping is None else mapping

        def download(url: str, destination: Path, maximum: int) -> tuple[int, str]:
            if url not in values:
                raise BootstrapError("fixture download missing")
            data = values[url]
            write_exclusive(destination, data)
            return len(data), hashlib.sha256(data).hexdigest()

        return download

    def bootstrapper(self, **kwargs) -> Bootstrapper:
        return Bootstrapper(
            self.document(),
            self.trust,
            self.work,
            downloader=kwargs.pop("downloader", self.downloader()),
            verifier=kwargs.pop("verifier", verify_ssh_signature),
            **kwargs,
        )

    def report_path(self) -> Path:
        return self.work / "reports" / "bootstrap.json"

    def test_real_signatures_batch_install_resolve_and_report_are_deterministic(
        self,
    ) -> None:
        bootstrapper = self.bootstrapper()
        bootstrapper.install(sorted(self.tools), self.report_path())
        first_report = self.report_path().read_bytes()

        for name, tool in self.tools.items():
            executable = bootstrapper.resolve(name)
            self.assertTrue(executable.is_absolute())
            self.assertIn(str(tool["sha256"]), executable.parts)
            self.assertEqual(executable.read_bytes(), self.payloads[name])
            self.assertEqual(stat.S_IMODE(executable.stat().st_mode), 0o755)

        bootstrapper.install(sorted(self.tools), self.report_path())
        self.assertEqual(first_report, self.report_path().read_bytes())
        report = json.loads(first_report)
        encoded = first_report.decode()
        self.assertEqual([item["id"] for item in report["tools"]], sorted(self.tools))
        self.assertNotIn(str(self.work), encoded)
        self.assertNotIn("https://", encoded)

    def test_size_digest_and_signature_are_required_with_and_semantics(self) -> None:
        cases = []
        wrong_size = self.document()
        wrong_size["tools"][0]["size"] += 1  # type: ignore[index]
        cases.append(("wrong-size", wrong_size, self.mapping))
        wrong_digest = self.document()
        wrong_digest["tools"][0]["sha256"] = "0" * 64  # type: ignore[index]
        cases.append(("wrong-digest", wrong_digest, self.mapping))
        wrong_signature = dict(self.mapping)
        first = self.tools["fixture-a"]["signature"]
        assert isinstance(first, dict)
        wrong_signature[str(first["url"])] = self.signatures["fixture-b"]
        cases.append(("wrong-signature", self.document(), wrong_signature))
        wrong_namespace = self.document()
        wrong_namespace["tools"][0]["signature"]["namespace"] = "git"  # type: ignore[index]
        cases.append(("wrong-namespace", wrong_namespace, self.mapping))
        wrong_identity = self.document()
        wrong_identity["tools"][0]["signature"]["identity"] = "other"  # type: ignore[index]
        cases.append(("wrong-identity", wrong_identity, self.mapping))

        for label, document, mapping in cases:
            with self.subTest(label=label):
                work = self.root / label
                bootstrapper = Bootstrapper(
                    document,
                    self.trust,
                    work,
                    downloader=self.downloader(mapping),
                )
                with self.assertRaises(BootstrapError):
                    bootstrapper.install(sorted(self.tools), work / "report.json")
                self.assertFalse(
                    (work / "tools" / "by-sha256").exists()
                    and any((work / "tools" / "by-sha256").iterdir())
                )

    def test_validly_signed_wrong_artifact_is_rejected_before_extraction(self) -> None:
        wrong = archive_bytes("fixture-a", b"validly signed but wrong")
        mapping = dict(self.mapping)
        tool = self.tools["fixture-a"]
        signature = tool["signature"]
        assert isinstance(signature, dict)
        mapping[str(tool["url"])] = wrong
        mapping[str(signature["url"])] = self.sign(wrong, self.key, "wrong-artifact")
        bootstrapper = self.bootstrapper(downloader=self.downloader(mapping))
        with self.assertRaises(BootstrapError):
            bootstrapper.install(sorted(self.tools), self.report_path())
        store = self.work / "tools" / "by-sha256"
        self.assertFalse(store.exists() and any(store.iterdir()))

    def test_missing_and_wrong_key_signatures_fail_without_installation(self) -> None:
        for label, mapping in (
            ("missing", dict(self.mapping)),
            ("malformed", dict(self.mapping)),
            ("wrong-key", dict(self.mapping)),
        ):
            tool = self.tools["fixture-a"]
            signature = tool["signature"]
            assert isinstance(signature, dict)
            if label == "missing":
                del mapping[str(signature["url"])]
            elif label == "malformed":
                mapping[str(signature["url"])] = b"not an OpenSSH signature"
            else:
                mapping[str(signature["url"])] = self.sign(
                    self.archives["fixture-a"], self.other_key, "wrong-key-signature"
                )
            work = self.root / label
            bootstrapper = Bootstrapper(
                self.document(), self.trust, work, downloader=self.downloader(mapping)
            )
            with self.assertRaises(BootstrapError):
                bootstrapper.install(sorted(self.tools), work / "report.json")
            self.assertFalse(
                (work / "tools" / "by-sha256").exists()
                and any((work / "tools" / "by-sha256").iterdir())
            )

    def test_late_failure_prevents_all_extraction_chmod_publication_and_execution(
        self,
    ) -> None:
        sentinel = self.root / "executed"
        self.payloads["fixture-a"] = f"#!/bin/sh\ntouch {sentinel}\n".encode()
        self.archives["fixture-a"] = archive_bytes(
            "fixture-a", self.payloads["fixture-a"]
        )
        self.tools["fixture-a"] = tool_entry(
            "fixture-a", self.archives["fixture-a"], self.payloads["fixture-a"]
        )
        tool_a = self.tools["fixture-a"]
        signature_a = tool_a["signature"]
        assert isinstance(signature_a, dict)
        self.mapping[str(tool_a["url"])] = self.archives["fixture-a"]
        self.mapping[str(signature_a["url"])] = self.sign(
            self.archives["fixture-a"], self.key, "sentinel"
        )
        tool_b = self.tools["fixture-b"]
        signature_b = tool_b["signature"]
        assert isinstance(signature_b, dict)
        self.mapping[str(signature_b["url"])] = b"late invalid signature"

        bootstrapper = self.bootstrapper()
        with mock.patch("bootstrap_executable_tools.extract_archive") as extract:
            with mock.patch("bootstrap_archive.os.fchmod") as chmod:
                with self.assertRaises(BootstrapError):
                    bootstrapper.install(sorted(self.tools), self.report_path())
        extract.assert_not_called()
        chmod.assert_not_called()
        store = self.work / "tools" / "by-sha256"
        self.assertFalse(store.exists() and any(store.iterdir()))
        self.assertFalse(sentinel.exists())

    def test_corrupt_cache_and_installed_directory_cannot_bypass_revalidation(
        self,
    ) -> None:
        bootstrapper = self.bootstrapper()
        bootstrapper.install(sorted(self.tools), self.report_path())
        tool = self.tools["fixture-a"]
        archive_object = (
            self.work / "bootstrap-cache" / "objects" / "archives" / str(tool["sha256"])
        )
        archive_object.write_bytes(b"X" * int(tool["size"]))
        shutil.rmtree(self.work / "tools" / "by-sha256")
        with self.assertRaises(BootstrapError):
            bootstrapper.install(sorted(self.tools), self.report_path())
        store = self.work / "tools" / "by-sha256"
        self.assertFalse(store.exists() and any(store.iterdir()))

        clean_work = self.root / "installed-bypass"
        clean = Bootstrapper(
            self.document(), self.trust, clean_work, downloader=self.downloader()
        )
        clean.install(sorted(self.tools), clean_work / "report.json")
        executable = clean.resolve("fixture-a")
        executable.write_bytes(b"Z" * len(self.payloads["fixture-a"]))
        with self.assertRaises(BootstrapError):
            clean.install(sorted(self.tools), clean_work / "report.json")
        with self.assertRaises(BootstrapError):
            clean.resolve("fixture-a")

    def test_archive_replacement_race_never_publishes_or_extracts_replacement(
        self,
    ) -> None:
        replaced = False

        def racing_verifier(archive, signature, trust, tool) -> None:
            nonlocal replaced
            verify_ssh_signature(archive, signature, trust, tool)
            if not replaced:
                opened_path = Path(os.readlink(f"/proc/self/fd/{archive.fileno()}"))
                replacement = opened_path.with_name("replacement")
                replacement.write_bytes(b"malicious replacement")
                os.replace(replacement, opened_path)
                replaced = True

        bootstrapper = self.bootstrapper(verifier=racing_verifier)
        with self.assertRaises(BootstrapError):
            bootstrapper.install(sorted(self.tools), self.report_path())
        store = self.work / "tools" / "by-sha256"
        self.assertFalse(store.exists() and any(store.iterdir()))

    def test_legacy_preinstalled_directory_is_revalidated_and_rejected(self) -> None:
        legacy = self.work / "tools" / "fixture-a"
        legacy.mkdir(parents=True)
        executable = legacy / "fixture-a"
        executable.write_bytes(b"untrusted")
        executable.chmod(0o755)
        bootstrapper = self.bootstrapper()
        with self.assertRaises(BootstrapError):
            bootstrapper.install(sorted(self.tools), self.report_path())
        store = self.work / "tools" / "by-sha256"
        self.assertFalse(store.exists() and any(store.iterdir()))

    def test_run_executes_validated_fd_with_exact_argv_and_sanitized_env(self) -> None:
        bootstrapper = self.bootstrapper()
        bootstrapper.install(sorted(self.tools), self.report_path())
        source_environment = {
            "PATH": "/custom/bin",
            "SIGNING_PASSPHRASE": "preserved secret",
            "LD_PRELOAD": "/untrusted/inject.so",
            "DYLD_INSERT_LIBRARIES": "/untrusted/inject.dylib",
            "GLIBC_TUNABLES": "glibc.malloc.check=3",
            "RUST_LOG": "trace",
        }
        observed: dict[str, object] = {}

        def fake_execve(descriptor, arguments, environment) -> None:
            observed["descriptor"] = descriptor
            observed["arguments"] = arguments
            observed["environment"] = environment
            os.lseek(descriptor, 0, os.SEEK_SET)
            observed["payload"] = os.read(descriptor, 4096)

        with mock.patch(
            "bootstrap_executable_tools.fd_exec_supported", return_value=True
        ):
            with mock.patch("bootstrap_executable_tools.os.execve", fake_execve):
                with self.assertRaises(BootstrapError):
                    bootstrapper.run(
                        "fixture-a",
                        ["argument with spaces", "$(not-a-shell)", "--flag"],
                        source_environment,
                    )

        self.assertIsInstance(observed["descriptor"], int)
        self.assertEqual(
            observed["arguments"],
            ["fixture-a", "argument with spaces", "$(not-a-shell)", "--flag"],
        )
        self.assertEqual(observed["payload"], self.payloads["fixture-a"])
        environment = observed["environment"]
        assert isinstance(environment, dict)
        self.assertEqual(environment["PATH"], "/custom/bin")
        self.assertEqual(environment["SIGNING_PASSPHRASE"], "preserved secret")
        for forbidden in (
            "LD_PRELOAD",
            "DYLD_INSERT_LIBRARIES",
            "GLIBC_TUNABLES",
            "RUST_LOG",
        ):
            self.assertNotIn(forbidden, environment)

    def test_run_executes_sealed_bytes_after_same_inode_source_overwrite(self) -> None:
        bootstrapper = self.bootstrapper()
        bootstrapper.install(sorted(self.tools), self.report_path())
        executable = bootstrapper.resolve("fixture-a")
        original_inode = executable.stat().st_ino
        observed: dict[str, object] = {}

        def overwrite_then_exec(descriptor, arguments, environment) -> None:
            executable.write_bytes(b"Z" * len(self.payloads["fixture-a"]))
            os.lseek(descriptor, 0, os.SEEK_SET)
            observed["inode"] = os.fstat(descriptor).st_ino
            observed["payload"] = os.read(descriptor, 4096)

        with mock.patch(
            "bootstrap_executable_tools.fd_exec_supported", return_value=True
        ):
            with mock.patch(
                "bootstrap_executable_tools.os.execve", overwrite_then_exec
            ):
                with self.assertRaises(BootstrapError):
                    bootstrapper.run("fixture-a", [], {"PATH": "/usr/bin"})

        self.assertNotEqual(observed["inode"], original_inode)
        self.assertEqual(observed["payload"], self.payloads["fixture-a"])
        self.assertEqual(
            executable.read_bytes(), b"Z" * len(self.payloads["fixture-a"])
        )

    def test_run_failure_never_calls_execve(self) -> None:
        bootstrapper = self.bootstrapper()
        bootstrapper.install(sorted(self.tools), self.report_path())
        executable = bootstrapper.resolve("fixture-a")
        executable.write_bytes(b"X" * len(self.payloads["fixture-a"]))

        with mock.patch(
            "bootstrap_executable_tools.fd_exec_supported", return_value=True
        ):
            with mock.patch("bootstrap_executable_tools.os.execve") as execve:
                with self.assertRaises(BootstrapError):
                    bootstrapper.run("fixture-a", [], {})
        execve.assert_not_called()

    def test_run_rejects_unsupported_fd_exec_and_nul_arguments(self) -> None:
        bootstrapper = self.bootstrapper()
        with mock.patch(
            "bootstrap_executable_tools.fd_exec_supported", return_value=False
        ):
            with mock.patch("bootstrap_executable_tools.os.execve") as execve:
                with self.assertRaises(BootstrapError):
                    bootstrapper.run("fixture-a", [], {})
        execve.assert_not_called()

        with mock.patch("bootstrap_executable_tools.os.execve") as execve:
            with self.assertRaises(BootstrapError):
                bootstrapper.run("fixture-a", ["bad\x00argument"], {})
        execve.assert_not_called()

        with mock.patch(
            "bootstrap_executable_tools.open_sealed_executable",
            side_effect=BootstrapError("sealing failed"),
        ):
            with mock.patch("bootstrap_executable_tools.os.execve") as execve:
                with self.assertRaises(BootstrapError):
                    bootstrapper.run("fixture-a", [], {})
        execve.assert_not_called()

    def test_run_parser_strips_only_one_separator(self) -> None:
        args = parse_args(
            [
                "--workdir",
                str(self.work),
                "run",
                "fixture-a",
                "--",
                "--",
                "literal",
            ]
        )
        self.assertEqual(args.arguments, ["--", "literal"])


if __name__ == "__main__":
    unittest.main()
