# HYGIENE-13 — Supplement secrets scanning beyond `.keys/`

## Goal

HYGIENE-11 found that the current pre-commit hook is a narrow root `.keys/` path guard. Supplement it with broader, portable secrets scanning and align documented/generated signing-key paths.

## Acceptance

- A standard secrets-scanning approach is selected and wired into contributor and CI workflows, or a documented reason is recorded for choosing a different approach.
- Coverage includes PixeneOS-specific signing material and variables, at minimum:
  - `avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`;
  - `KEYS_AVB_BASE64`, `KEYS_CERT_OTA_BASE64`, `KEYS_OTA_BASE64`;
  - README/GitHub secret names `AVB_KEY`, `CERT_OTA`, `OTA_KEY`;
  - `PASSPHRASE_AVB`, `PASSPHRASE_OTA`.
- The existing `.keys/` guard is not weakened unless the replacement provides equivalent or stronger protection.
- README/code behavior for generated local key paths is reconciled: either keys are generated under `.keys/`, or documentation is updated to match the implemented paths with clear safety guidance.
- Validation steps are documented, including at least one positive test that a fake key/secret is blocked and one negative test that normal source changes still pass.

## Depends

HYGIENE-11

## Notes

Planning source: `docs/planning/precommit-secrets-audit.md`.

Keep licensing/provenance wording conservative if touching docs; do not introduce new license claims in third-party-derived files.

## Output

Implemented in this slice:

- selected `gitleaks` as the standard scanner and added `.gitleaks.toml` project rules;
- added `.github/workflows/secrets-scan.yml` for CI enforcement;
- added `src/scan_secrets.sh` and wired it into `src/hooks/pre-commit` while preserving the existing `.keys/` guard;
- updated `.gitignore` for common generated signing filenames;
- changed `generate_keys` defaults so local generated signing files go under `.keys/`;
- updated README safety guidance and `src/setup_hooks.sh` contributor messaging.

Validation recorded in `docs/planning/hygiene-13-secrets-scan.md`:

- shell syntax check passed for touched shell scripts;
- `.gitleaks.toml` parsed as TOML;
- `src/scan_secrets.sh --all` passed locally;
- isolated-index positive fake `KEYS_AVB_BASE64=...` check was blocked;
- isolated-index normal-source negative check passed.

Local note: `gitleaks` was not installed in this environment, so local validation exercised the PixeneOS fallback scanner. CI is wired to the gitleaks action.

## Out of scope

- Auditing real CI secret storage or rotating existing secrets.
- Rewriting release workflows beyond the minimum needed to enforce scanner checks.
