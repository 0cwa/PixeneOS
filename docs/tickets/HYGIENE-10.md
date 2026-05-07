# HYGIENE-10 — Archive/delete stale remote branches after maintainer approval

## Goal

Execute the stale-branch disposition plan from HYGIENE-1 once the maintainer explicitly approves remote branch operations.

## Acceptance

- Re-verify the branch inventory before acting:
  - no open PRs target the stale branches;
  - ahead/behind counts are still consistent enough with `docs/planning/branch-inventory.md`;
  - the maintainer has explicitly approved the archive/delete action.
- Create archive tags before deleting branches marked `archive-as-tag`:
  - `archive/staging`
  - `archive/revert-44-fix-magisk-and-fail-fast`
  - `archive/fix-magisk-and-fail-fast`
  - `archive/fix-magisk-dl-and-fail-fast`
  - `archive/patch-1`
  - `archive/patch-2`
  - `archive/revert-24-add-decode-check`
- Delete `recovery-option` from origin only after maintainer approval.
- Leave `renovate/renovatebot-github-action-41.x` for Renovate to refresh unless a later Renovate ticket says otherwise.
- Do not touch `main`, `gh-pages`, or `lineage`.

## Depends

- HYGIENE-1
- maintainer approval

## Notes

This is intentionally blocked until the maintainer authorizes remote branch/tag operations.

## Out of scope

- Rewriting branch history.
- Archiving `lineage`; HYGIENE-5/ROMCOMPAT own that later trigger.
- Fixing Renovate config drift.
