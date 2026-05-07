# HYGIENE-11 — Pre-commit secrets hook scope audit

Scope: planning/audit only. No hook code, install flow, CI configuration, or contributor workflow was changed by this ticket.

Reviewed files:

- `src/hooks/pre-commit`
- `src/setup_hooks.sh`
- `src/declarations.sh`
- `src/exchange.sh`
- `src/util_functions.sh`
- `.gitignore`
- `.github/workflows/release.yml`
- `.github/workflows/release-lineage.yml`
- README setup/secret sections

## Current behavior and install path

`src/setup_hooks.sh` installs the hook by copying the tracked script into Git's local hook directory:

```bash
cp "src/hooks/pre-commit" ".git/hooks/"
chmod +x .git/hooks/pre-commit
```

That means the effective runtime path is `.git/hooks/pre-commit` in each local clone/worktree. Git hooks are not versioned by Git itself, so contributors are protected only after they manually run the installer for that specific clone. The hook can also be bypassed with `git commit --no-verify`.

The hook itself is currently:

```bash
if git diff --cached --name-only | grep -q '^\.keys/'; then
  echo -e "Error: The \`.keys\` directory should not be committed as it contains your AVB keys!"
  exit 1
fi
```

On commit, it looks only at staged path names. If any staged path starts with the repository-root prefix `.keys/`, it exits non-zero and blocks the commit. Otherwise it exits successfully.

Quick local behavior check performed during this audit:

- forced-staged `.keys/avb.key` was blocked;
- staged `avb.key` at repository root was allowed;
- staged workflow text containing a base64-looking key variable was allowed.

## Scanned file types and patterns

The current hook is a path guard, not a content scanner.

It scans:

- all staged paths returned by `git diff --cached --name-only`;
- every staged file type equally, but only by filename/path;
- the literal root-relative prefix `.keys/`.

It does not scan:

- file contents;
- PEM/private-key markers;
- high-entropy strings;
- base64 payloads;
- passphrase variables;
- GitHub Actions secrets references;
- key-like filenames outside root `.keys/`;
- nested directories such as `some/subdir/.keys/`;
- an exact file/symlink path named `.keys` without a trailing slash.

## Project key coverage

| Secret/key material | Current protection | Notes |
| --- | --- | --- |
| Root `.keys/` directory | Partial / good when installed | `.gitignore` ignores `.keys`, and the hook blocks forced-staged files below `.keys/`. This protects the documented root `.keys/` directory only if the local hook has been installed. |
| Local AVB key (`avb.key`) | Not reliably protected | `src/declarations.sh` defaults `KEYS[AVB]` to `avb.key`, and `generate_keys` writes to `${KEYS[AVB]}`. Unless the user overrides that path into `.keys/`, the current hook does not catch it. |
| Local OTA key (`ota.key`) | Not reliably protected | Same issue as `avb.key`; default path is repository root, not `.keys/`. |
| Local OTA certificate (`ota.crt`) | Not protected by hook | The certificate may be less sensitive than private keys, but it is part of the signing material set and is not matched unless stored under `.keys/`. |
| AVB public key metadata (`avb_pkmd.bin`) | Not protected by hook | Public metadata is not equivalent to a private key, but it is still key-related output and is outside the current `.keys/` match by default. |
| CI base64 key variables (`KEYS_AVB_BASE64`, `KEYS_CERT_OTA_BASE64`, `KEYS_OTA_BASE64`; README names `AVB_KEY`, `CERT_OTA`, `OTA_KEY`) | Not protected by hook | The hook does not inspect content, so a pasted base64 secret in YAML, TOML, shell, Markdown, or another file would be allowed. |
| Passphrases (`PASSPHRASE_AVB`, `PASSPHRASE_OTA`) | Not protected by hook | These are referenced as GitHub secrets in workflows, but literal committed values would not be detected. |
| CI-decoded `.tmp/.keys/*` files | Mostly protected by `.tmp` ignore, not this hook | `base64_decode` writes under `${WORKDIR}/.keys/`, with `WORKDIR=.tmp`. `.tmp` is ignored, but the hook only matches root `.keys/`, not `.tmp/.keys/`. |

Important discrepancy: README says generated AVB keys are stored in `.keys`, while the current `generate_keys` implementation appears to use the default key filenames from `src/declarations.sh` (`avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`) unless a caller overrides them. Treat this as a follow-up implementation/documentation alignment issue rather than changing it in this audit ticket.

## False-positive risks

- Any intentionally staged non-secret fixture under root `.keys/` is blocked.
- If a historical `.keys/...` file ever became tracked, staging its deletion or rename could also be blocked because the hook checks staged names without filtering by change type.
- Contributors who keep harmless documentation or examples under `.keys/` cannot commit them without moving the files or bypassing the hook.

These false positives are acceptable for the current narrow guard because `.keys/` is intended to be private local signing-key storage.

## False-negative risks

- Hook not installed in a clone/worktree.
- Hook bypassed with `--no-verify`.
- Secret files created at default root filenames (`avb.key`, `ota.key`, `ota.crt`) are not matched.
- Secrets placed in `env.toml`, Markdown, shell scripts, YAML workflows, release notes, or test fixtures are not matched.
- Base64-encoded CI secrets are not detected by entropy/content checks.
- Passphrases are not detected.
- Nested `.keys/` paths and exact `.keys` file/symlink paths are not detected.
- The guard is local-only; it does not enforce anything in CI or on the server side.

## Portability

The hook is small and uses common Unix tools (`bash`, `git`, `grep`). It should work for Linux and typical macOS developer environments. It is less portable for native Windows users unless they commit through Git Bash, WSL, or another environment that provides `/bin/bash` and `grep`.

Because installation is a manual copy into `.git/hooks/`, it can also overwrite an existing local pre-commit hook and does not compose with standard hook managers unless contributors wire it in themselves.

## Recommendation

Keep the current `.keys/` guard as a cheap defense-in-depth check, but supplement it rather than treating it as a complete secrets scanner.

Recommended follow-up implementation direction:

1. Add a standard secrets scanner to local pre-commit and CI, such as `gitleaks`, `detect-secrets`, or a `pre-commit` framework hook.
2. Extend coverage to project-specific filenames and variables: `avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`, `KEYS_*_BASE64`, `AVB_KEY`, `CERT_OTA`, `OTA_KEY`, `PASSPHRASE_AVB`, and `PASSPHRASE_OTA`.
3. Decide whether generated local keys should actually live under root `.keys/`, or update README/code so the documented and implemented paths match.
4. Add CI enforcement so missed local hook installation does not become the only line of defense.

Created follow-up ticket: `docs/tickets/HYGIENE-13.md`.

## Acceptance check

- Current hook behavior and install path documented: done.
- Scanned file types/patterns documented: done.
- False-positive and false-negative risks documented: done.
- `.keys`, AVB/OTA secrets, and base64 CI secret protection assessed: done.
- Recommendation recorded as keep-and-supplement: done.
- Code/config changes not bundled into this ticket: done.
