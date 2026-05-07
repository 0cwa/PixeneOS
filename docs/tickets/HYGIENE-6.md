# HYGIENE-6 — Refresh stale `lineage` divergence assumptions

## Goal

`HYGIENE-5.md` recorded historical divergence as `44 / 144`, but the HYGIENE-5 audit observed the current actionable fork-vs-fork count as `14 / 56` for `origin/main...origin/lineage`. Update the ticket/planning notes so future agents do not chase stale numbers.

## Acceptance

- `docs/tickets/HYGIENE-5.md` is updated to distinguish:
  - the historical ticket expectation (`44 / 144`), and
  - the current observed fork-vs-fork divergence (`14 / 56` on 2026-05-06).
- The note explains why `upstream/main...origin/lineage` can differ from `origin/main...origin/lineage`.
- `docs/planning/lineage-branch-disposition.md` is left intact unless the counts are re-verified and intentionally refreshed.
- No branch operations are performed: no tag/delete/cherry-pick/rebase/merge/fast-forward.

## Depends

- HYGIENE-5

## Notes

- This is documentation hygiene only.
- Use fresh local commands before editing if refs have changed:
  - `git rev-list --left-right --count origin/main...origin/lineage`
  - `git rev-list --left-right --count upstream/main...origin/lineage`

## Out of scope

- Reclassifying the Lineage commits.
- Archiving the branch.
- Doing ROMCOMPAT design work.

## Implementation sketch

1. Re-run the divergence commands.
2. Patch the stale count language in `docs/tickets/HYGIENE-5.md`.
3. Mark HYGIENE-6 done in `docs/tickets/INDEX.md` only if the stale-count ambiguity is resolved.
