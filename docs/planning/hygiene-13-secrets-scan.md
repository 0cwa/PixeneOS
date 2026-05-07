# HYGIENE-13 — secrets scanner implementation note

Implemented a keep-and-supplement approach for PixeneOS signing secret protection.

## Selected scanner

- Selected `gitleaks` as the standard secrets scanner.
- Added `.gitleaks.toml` with project-specific rules for:
  - PixeneOS signing material paths: `.keys/`, `avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`;
  - CI/base64 signing variables: `KEYS_AVB_BASE64`, `KEYS_CERT_OTA_BASE64`, `KEYS_OTA_BASE64`, `AVB_KEY`, `CERT_OTA`, `OTA_KEY`;
  - signing passphrase variables: `PASSPHRASE_AVB`, `PASSPHRASE_OTA`;
  - generic private-key PEM markers.
- Added `.github/workflows/secrets-scan.yml` so CI runs the gitleaks action and the PixeneOS fallback scanner.

## Local hook behavior

- Kept the existing root `.keys/` path guard in `src/hooks/pre-commit`.
- Added `src/scan_secrets.sh --staged` to the pre-commit hook.
- The scanner runs gitleaks when installed and always runs a small PixeneOS-specific fallback so contributors without gitleaks still get coverage for project signing filenames and variable assignments.
- `src/setup_hooks.sh` now tells contributors to install gitleaks for full standard scanner coverage.

## Generated key path alignment

`generate_keys` now redirects the default local signing outputs into `.keys/`:

- `.keys/avb.key`
- `.keys/ota.key`
- `.keys/ota.crt`
- `.keys/avb_pkmd.bin`

Callers that explicitly set custom `KEYS[...]` paths before sourcing the scripts are preserved. README wording now matches the default local generation behavior and warns users to keep these files private.

## Validation

Commands run:

```sh
bash -n src/scan_secrets.sh src/hooks/pre-commit src/setup_hooks.sh src/util_functions.sh src/declarations.sh src/exchange.sh
python3 - <<'PY'
import tomllib
with open('.gitleaks.toml','rb') as f:
    tomllib.load(f)
print('.gitleaks.toml parses as TOML')
PY
src/scan_secrets.sh --all
```

Positive fake-secret check using an isolated temporary git index:

```sh
KEYS_AVB_BASE64=<base64 signing key from GitHub Secrets>
```

Result: blocked with `contains a PixeneOS base64 signing secret assignment`.

Negative normal-source check using an isolated temporary git index:

```sh
normal documentation change
```

Result: passed.

Note: `gitleaks` was not installed in this local environment, so local command output used the PixeneOS fallback scanner. CI is wired to the gitleaks GitHub Action.
