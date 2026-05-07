# HYGIENE-5 — Document `lineage` branch divergence + archive plan

## Goal

The original HYGIENE-5 ticket expected `lineage` to be 44 ahead / 144 behind upstream `main`, and divergent. That was a historical planning expectation, not a standing invariant: on 2026-05-06, the current actionable fork-vs-fork comparison was re-verified as `origin/main...origin/lineage` = 14 left-only / 56 right-only. Capture the branch disposition (archive once ROMCOMPAT-2 lands a generic per-ROM path) without letting stale divergence numbers drive future work.

## Acceptance

- `docs/planning/lineage-branch-disposition.md` (local-only) documents:
  - the historical ticket expectation (`44 / 144`) separately from the current observed fork-vs-fork divergence (`14 / 56` on 2026-05-06 for `origin/main...origin/lineage`);
  - a categorised diff of the right-only Lineage commits: `(a) Lineage-only patcher logic that ROMCOMPAT-2 will subsume`, `(b) one-off device fixes`, `(c) experimental dead ends`, `(d) potentially upstreamable hunks`;
  - the archive plan: tag as `archive/lineage-pre-romcompat`, then delete from origin;
  - the trigger condition: ROMCOMPAT-2 marked `done` + at least one Lineage device green on the matrix.
- The ticket/doc explicitly state: do **not** rebase, merge, or fast-forward `lineage`. Drift is too large.
- The ticket/doc explain that `upstream/main...origin/lineage` can differ from `origin/main...origin/lineage` because `upstream/main` and `origin/main` are different remote refs: the fork's `origin/main` may contain fork-local commits or lag/lead upstream independently, and symmetric-diff counts depend on the left-hand baseline.

## Depends

— (runnable now)

## Notes

- Historical expectation: `44 / 144`.
- Current observed counts on 2026-05-06:
  - `git rev-list --left-right --count origin/main...origin/lineage` → `14 56` (fork-vs-fork, current actionable divergence).
  - `git rev-list --left-right --count upstream/main...origin/lineage` → `0 145` (different baseline; do not compare directly to the fork-vs-fork count).
- Any merge still carries unnecessary conflict/context-loss risk. Cherry-picking the genuinely-useful commits via ROMCOMPAT-2 is cleaner.
- The "potentially upstreamable hunks" category overlaps with ROMCOMPAT-1's analysis of `91e49bc`; cross-reference but do not duplicate.
- This is a one-shot doc — the branch goes away eventually.

## Out of scope

- Tagging or deleting anything.
- Cherry-picking commits onto `main`.
- Doing ROMCOMPAT-2's design work.

## Implementation sketch

1. Re-verify both baselines before relying on counts:
   - `git rev-list --left-right --count origin/main...origin/lineage`
   - `git rev-list --left-right --count upstream/main...origin/lineage`
2. Treat `origin/main...origin/lineage` as the actionable fork-vs-fork divergence unless the maintainer explicitly asks for an upstream-baseline audit.
3. Classify the right-only Lineage commits (a/b/c/d). Use commit titles + brief inspection.
4. Write the doc; close with the trigger-condition statement.
