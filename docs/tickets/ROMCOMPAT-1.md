# ROMCOMPAT-1 — Per-hunk disposition for `my-avbroot-setup@91e49bc`

## Goal

The `0cwa/my-avbroot-setup` fork carries LineageOS-compat work whose cumulative delta against upstream master is +594 / -175 (21 commits ahead of merge-base, ending at `91e49bc`; the ticket's original "single commit" framing was inaccurate — see the fork's [`docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md)). Split that delta into logical hunks and decide for each: **(U) submit upstream PR**, **(F) keep fork-only**, or **(D) drop entirely**.

This analysis is allowed to run before any META ratification. The output is what lets the maintainer make the upstream-vs-fork decision without guessing.

## Acceptance

- The disposition lives in the fork repo at `0cwa/my-avbroot-setup:docs/upstream-disposition.md` on `master`. The PixeneOS side keeps only this ticket and the cross-repo pointers.
- The disposition contains a table with one row per logical hunk:
  | Hunk | Files touched | Lines | Summary | Disposition (U/F/D) | Rationale | Upstream PR-readiness |
- Every line of the +594/-175 diff is accounted for at a logical level; avoid orphan changes.
- Logical hunks include at least:
  - `--compatible-sepolicy` flag handling;
  - ODM partition handling;
  - partition-specific `file_contexts` lookup;
  - CIL fallback path;
  - `cil_rules.py`.
- Each `U` row has a short draft upstream-PR description.
- Each `F` row explains why upstream may reject or why it is PixeneOS-specific.
- Each `D` row points to what supersedes it.
- A summary recommends the smallest safe first integration/upstreaming step.
- End-of-ticket docs record validation sources and any uncertainty.

## Depends

—

## Notes

- A working clone of the fork lives at `../my-avbroot-setup/` (sibling to this repo). The frozen analysis snapshots `.pi/research/my-avbroot-fork/` (shallow) and `.pi/research/my-avbroot-upstream/` are kept for historical reference but should not be used for new commit-history claims.
- The ticket originally noted that `cil_rules.py` may be easy to upstream as a self-contained PR. The completed disposition shows that is **not** correct: without the CIL fallback path (hunk 8) it has no caller and would be dead code. See the fork's [`docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md) hunk 9.
- `--compatible-sepolicy` is the most opinionated change; the disposition keeps it fork-only and defers any upstream design discussion.
- ODM and partition-specific `file_contexts` are device-coupled; upstream may want a generic abstraction.
- Do **not** open upstream PRs in this ticket.

## Out of scope

- Opening upstream PRs.
- Editing the fork.
- Designing the full per-ROM manifest.

## Implementation sketch

1. Inspect the fork and upstream diff for commit `91e49bc`.
2. Identify logical hunks rather than merely copying raw diff hunks.
3. For each hunk, read upstream surrounding code and estimate upstreamability.
4. Draft per-`U` PR summaries.
5. Sort recommended work from smallest/least-opinionated to largest/most-opinionated.
