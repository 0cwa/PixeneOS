# Executable tool trust lock

`locks/executable-tools-v1.json` records the immutable release archives and
authenticated layouts for the three executable tools currently pinned by
PixeneOS on `x86_64-unknown-linux-gnu`. The lock is repository data only. It is
validated offline by `src/validate_executable_tool_lock.py`.

## Trust root

The sole allowed signer is the Ed25519 key published in chenxiaolong's
[SSH signature verification guide][signing-guide]:

```text
identity: chenxiaolong
namespace: file
key type: ssh-ed25519
fingerprint: SHA256:Ct0HoRyrFLrnF9W+A/BKEiJmwx7yWkgaW/JvghKrboA
```

The exact allowed-signers binding is checked in at
`trust/chenxiaolong.allowed_signers`. The validator parses the OpenSSH key blob,
requires an Ed25519 key with exactly 32 public-key bytes, recomputes the OpenSSH
SHA-256 fingerprint with Python's standard library, and requires every lock
entry to name that fingerprint, identity, and namespace.

## Recorded release artifacts

The following archive sizes and SHA-256 digests were independently recomputed
from downloads made on 2026-07-20. They matched the sizes and SHA-256 asset
digests exposed by GitHub's release API. Each detached signature was exactly 294
bytes and was accepted by `ssh-keygen -Y verify` using identity `chenxiaolong`
and namespace `file` only after the archive digest and size had been checked.

| Tool | Release archive | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| afsr 1.0.4 | `afsr-1.0.4-x86_64-unknown-linux-gnu.zip` | 1,548,868 | `8fdbc9aa6c31b4e6530388ffc5adc42652ec6bbd753aef0815d27d8c3a4b9687` |
| avbroot 3.31.0 | `avbroot-3.31.0-x86_64-unknown-linux-gnu.zip` | 3,979,155 | `59e7992c2a6379d8ee351e423a851ef360a97cd14a37e6b2e57608eb477c3210` |
| custota-tool 6.2 | `custota-tool-6.2-x86_64-unknown-linux-gnu.zip` | 2,153,916 | `e682c558f8111287b9668f647bc9fded3fa095714957fd8090bc386bae02917d` |

Detached-signature SHA-256 digests observed during that verification were:

| Signature | SHA-256 |
| --- | --- |
| `afsr-1.0.4-x86_64-unknown-linux-gnu.zip.sig` | `354bd28d0c1cf20a9ca76dfb958451ad17fa1f34f125fec1ddae58fffc315616` |
| `avbroot-3.31.0-x86_64-unknown-linux-gnu.zip.sig` | `2fb0067d577310b138f542161cc04e0901249c5b661c7f15784822141b8a3437` |
| `custota-tool-6.2-x86_64-unknown-linux-gnu.zip.sig` | `ca28ad6130108240fa67418059426b94e001d905e1a51f24eff4bb692f4570ee` |

GitHub does not publish separate publisher-signed checksum files for these
releases. GitHub's asset digest is discovery metadata, not a replacement for the
publisher's detached SSH signature. Builds must consume the reviewed digest in
the checked-in lock and must not obtain mutable digest policy from the API.

Official releases:

- [afsr v1.0.4][afsr-release]
- [avbroot v3.31.0][avbroot-release]
- [Custota v6.2][custota-release]

## Verification and archive inspection

The release archives were downloaded to a private temporary directory. Before
any extraction, each archive was checked for its exact byte size and SHA-256,
verified with the detached OpenSSH signature, and inspected through Python's ZIP
central-directory parser. Inspection rejected duplicate names, absolute paths,
backslashes, empty or dot components, non-normalized paths, encrypted members,
and non-file/non-directory Unix entry types. The reviewed archives contained:

| Tool | Member | Type | Mode | Bytes | SHA-256 |
| --- | --- | --- | --- | ---: | --- |
| afsr | `afsr` | file | `0755` | 3,469,744 | `923fa7caaac8b5e3b15b3f0f2e9a08ca34b226cbbcee3f80f40ee5afc735c6d7` |
| avbroot | `LICENSE` | file | `0644` | 35,149 | `3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986` |
| avbroot | `README.md` | file | `0644` | 31,744 | `29c520ac9a61f71cd2db30e091ef638a523dc2e87a16f5340763396a20c3c97e` |
| avbroot | `avbroot` | file | `0755` | 10,139,408 | `7fdfa4a6c8a3145c846faeea1aa49aa407c296710d72744a88e8a8c441e05ea0` |
| custota-tool | `custota-tool` | file | `0755` | 5,056,240 | `3245641f1f7cfef3b6fd0257d6bdda83fa9c65c533e289e4c8f12e1e8c50b41a` |

Only after those checks passed were the archives extracted into separate private
temporary directories. The extracted member types, modes, sizes, and SHA-256
digests matched the central-directory inspection and the committed lock.

The verification environment was:

- curl 8.18.0 with OpenSSL 3.5.5
- OpenSSH 10.2p1 with OpenSSL 3.5.5
- Python 3.14.5 standard-library `zipfile`
- GNU coreutils `sha256sum` 9.10
- Info-ZIP `unzip` 6.00, used only after authentication and inspection

## Offline validation policy

Run:

```sh
python3 src/validate_executable_tool_lock.py
```

For fixtures or independent copies, use `--lock PATH --trust PATH`. Validation
does not access the network. It fails closed on duplicate or unknown JSON fields,
duplicate tools or members, noncanonical JSON, uppercase or malformed hashes,
unbounded sizes, unsafe or unsorted layout paths, unknown members or modes,
unreviewed tool IDs, versions, architectures, URLs, signature parameters, trust
keys, and fingerprints. Both input paths must resolve directly to bounded regular
files; symlinks are not followed.

The current schema deliberately recognizes only these three releases on
`x86_64-unknown-linux-gnu`. Adding another version, platform, tool, member, or
mode requires a reviewed validator-policy update and regenerated canonical lock.

## Trust rotation

Never fetch or replace signing keys automatically. A signer rotation requires an
authoritative publisher statement binding the replacement key, independent
review of that provenance, and a single-purpose change that updates the trust
file, validator binding, and affected lock entries together. Rotation tests must
demonstrate acceptance of the new key and rejection of the retired key, wrong
identities, and wrong namespaces. Re-verify all retained release artifacts after
rotation; do not infer that a new key authenticates old assets without valid new
signatures or an authoritative cross-binding.

## Explicit non-authorization

This tranche does **not** integrate the lock into PixeneOS acquisition, cache
reuse, extraction, permission changes, or execution. The presence of a lock
entry, valid repository data, successful fixture validation, or prior manual
inspection does not authorize executing an archive member. Until a later,
independently reviewed integration enforces digest and signature verification on
the actual downloaded inode before any extraction, `chmod`, or execution, the
existing executable-tool acquisition path remains untrusted.

[signing-guide]: https://github.com/chenxiaolong/chenxiaolong/blob/master/VERIFY_SSH_SIGNATURES.md
[afsr-release]: https://github.com/chenxiaolong/afsr/releases/tag/v1.0.4
[avbroot-release]: https://github.com/chenxiaolong/avbroot/releases/tag/v3.31.0
[custota-release]: https://github.com/chenxiaolong/Custota/releases/tag/v6.2
