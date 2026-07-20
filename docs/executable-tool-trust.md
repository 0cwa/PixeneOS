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

## Runtime bootstrap enforcement

`src/bootstrap_executable_tools.py` consumes this lock directly. The shell
runtime does not reconstruct executable release versions, asset URLs, or
layouts. It selects enabled tool IDs and submits the entire set in one batch.
Every selected archive must pass its locked byte size, SHA-256, detached
OpenSSH signature, exact hostile-archive inspection, and full member digest
check before extraction of any selected archive begins.

Downloads use bounded streaming into exclusive, no-follow files in a private
mode-`0700` transaction directory. Verified bytes are fsynced and atomically
published under `bootstrap-cache/objects`; a canonical receipt binds the
archive digest to its verified signature digest. Cache hits repeat size,
digest, signature, and archive inspection. A missing, corrupt, linked, or
noncanonical cache entry fails closed.

Members are extracted without `unzip` into private transaction directories.
The extractor accepts only the exact locked top-level regular-file layout and
rejects traversal, absolute paths, backslashes, aliases, duplicates, links,
special files, directories, extras, encryption, unsupported ZIP flags or
compression, overlapping compressed ranges, and excessive expansion. It
rechecks extracted types, modes, sizes, and digests before atomically publishing
the directory at `tools/by-sha256/<archive-sha256>`.

Existing digest-addressed installations are fully revalidated. Legacy
`tools/<id>` directories are never trusted as an installation bypass. Direct
PixeneOS invocations use the runtime `run` command, which opens the exact
digest-addressed installation through a held directory descriptor, revalidates
the complete locked layout, copies the verified executable bytes into an
anonymous file descriptor, sets the locked mode, seals the snapshot against
content changes, and rechecks its digest and mode after sealing. It executes
that sealed descriptor without resolving the executable pathname again.

The `resolve` command and digest-addressed executable paths exist only for
compatibility with the pinned helper. A successful resolution does not itself
authorize execution. The helper still resolves `avbroot`, `afsr`, and
`custota-tool` through `PATH`; PixeneOS places only enabled digest-addressed
directories at the front of that path, but the helper's later pathname lookup
remains an open execution boundary. Close it with the planned trusted-prefix
`ToolRunner` integration before treating helper execution as inode-bound.

The canonical JSON report contains stable tool identity, version, architecture,
archive and member sizes/digests, and signer verification results. It omits
URLs, timestamps, cache-hit state, temporary names, and all cache/report paths.
The report is written atomically only after the complete selected transaction
succeeds.

The offline lock validator by itself still does **not** authorize extraction,
permission changes, or execution. A successful runtime transaction authorizes
authenticated installation, and the `run` command authorizes direct PixeneOS
execution only through its post-seal-verified anonymous file descriptor. It
does not authorize the helper's compatibility PATH execution. Run acquisition
through `check_and_download_dependencies`; do not call the legacy downloader
for these three executable tools. Real OTA integration remains blocked until
the helper uses the trusted runner and the other documented host-code
supply-chain gates are closed.

[signing-guide]: https://github.com/chenxiaolong/chenxiaolong/blob/master/VERIFY_SSH_SIGNATURES.md
[afsr-release]: https://github.com/chenxiaolong/afsr/releases/tag/v1.0.4
[avbroot-release]: https://github.com/chenxiaolong/avbroot/releases/tag/v3.31.0
[custota-release]: https://github.com/chenxiaolong/Custota/releases/tag/v6.2
