# HYGIENE-11 — Audit pre-commit secrets hook scope

## Goal

`docs/planning/gaps.md` notes that a pre-commit hook exists at `src/hooks/pre-commit`, but its secrets-scanning scope is unverified. Audit what it catches, what it misses, and whether it is portable enough for contributors.

## Acceptance

- `docs/planning/precommit-secrets-audit.md` documents:
  - current hook behavior and install path;
  - what file types/patterns it scans;
  - false-positive and false-negative risks;
  - whether it protects keys used by this project (`.keys`, AVB/OTA secrets, base64 CI secrets);
  - recommended next step: keep, replace with a standard tool, or supplement.
- If code/config changes are recommended, create a follow-up implementation ticket instead of bundling them here.

## Depends

—

## Notes

Planning/audit first. Do not weaken existing hook behavior during this ticket.

## Out of scope

- Adding a new secrets scanner.
- Changing contributor install flow.
- Auditing CI secret storage; INFRA/META tickets own key custody.
