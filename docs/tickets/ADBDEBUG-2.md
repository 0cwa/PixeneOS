# ADBDEBUG-2 — Plan SPDX/license headers for `debugmod.py`, `debug_module_setup.sh`

## Goal

Once META-1 lands a license-header policy, plan the addition of SPDX headers + a brief copyright/credit notice to `src/debugmod.py` and `src/debug_module_setup.sh`. Plan only — no source edits in this ticket.

## Acceptance

- `docs/planning/adbdebug-headers-plan.md` (local-only) contains:
  - The exact header text for each file (Python style for `.py`, shell style for `.sh`).
  - A line attributing prior work, if any (check `git log -p` for the introducing commit; preserve any author intent).
  - A note on whether either file derives from third-party code (e.g. an existing Magisk debug module template). If derivative, cite the upstream + license, do not re-license.
  - The PR strategy: single PR for both files, scoped to ADB-debug only, separate from the broader HYGIENE-3 rollout so this lands fast as a small change.
- The plan is reviewable in <5 minutes. One-page max.

## Depends

- META-1 (license-header policy)
- ADBDEBUG-1 (so we know the module's design before stamping a license on it)

## Notes

- These two files were called out in the planning session as missing SPDX. Treat them as the canary for the broader HYGIENE-3 rollout; a successful small PR here de-risks the project-wide effort.
- If either file turns out to be derived from a Magisk module template, that finding is *important* — capture it before stamping a header, even if it delays the ticket.
- This ticket is intentionally narrower than HYGIENE-3 so it can land independently.

## Out of scope

- Editing the source files.
- Project-wide rollout (HYGIENE-3).
- Resolving META-1.

## Implementation sketch

1. Wait for META-1 + ADBDEBUG-1 to close.
2. `git log --follow src/debugmod.py src/debug_module_setup.sh` → first commits, authors, original sources cited in messages.
3. Confirm derivative-or-original status.
4. Draft the per-file headers in the plan doc. Note PR scope.
