# HYGIENE-3 — SPDX header policy rollout plan

## Goal

Once META-1 lands a license-header policy decision, produce a *plan* (not a code change) for rolling SPDX headers out across the existing source tree without churning `main` or breaking attribution.

## Acceptance

- A document `docs/planning/spdx-rollout.md` (local-only) describing:
  - the header text exactly as agreed in META-1 (e.g. `# SPDX-License-Identifier: GPL-3.0-or-later`);
  - which file types get the header (`*.py`, `*.sh`, `*.toml`?, workflows?);
  - the rollout order (new files first, then `src/**`, then workflows, then root configs);
  - the per-file PR-or-batch decision (single PR vs per-directory PR);
  - exception list (e.g. `LICENSE`, vendored files) with rationale.
- A checklist of files currently lacking headers, taken from a `grep -L 'SPDX-License-Identifier'` sweep.
- An explicit note on third-party-derived files (e.g. anything copied from `chenxiaolong/my-avbroot-setup`) — those keep the original header, never get re-licensed.

## Depends

- META-1 (license-header policy decision)

## Notes

- This ticket is **planning only**, even after META-1 unblocks it. Actual header insertion is a follow-up ticket per directory (e.g. `HYGIENE-3a-headers-src-py`, etc.) so each PR stays small.
- `src/debugmod.py` and `src/debug_module_setup.sh` are already flagged for ADBDEBUG-2; do not double-track them here.
- Check for files with non-SPDX legacy notices first; those need a decision: replace, supplement, or leave.

## Out of scope

- Adding any actual SPDX header to any file.
- Touching `main`.
- Resolving the META-1 decision itself.

## Implementation sketch

1. Wait for META-1 to close.
2. Run `git ls-files src/ .github/` and grep for `SPDX-License-Identifier`.
3. Categorise: missing / present / non-SPDX-legacy / third-party-derived.
4. Write `docs/planning/spdx-rollout.md`. Surface counts, per-directory order, batch-vs-PR plan.
