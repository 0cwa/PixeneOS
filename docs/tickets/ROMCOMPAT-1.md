# ROMCOMPAT-1 — Per-hunk disposition for `my-avbroot-setup@91e49bc`

## Goal

The `0cwa/my-avbroot-setup` fork carries a single LineageOS-compat commit (`91e49bc`, +594/-175). Split it into logical hunks and decide for each: **(U) submit upstream PR**, **(F) keep fork-only**, or **(D) drop entirely**.

This analysis is allowed to run before any META ratification. The output is what lets the maintainer make the upstream-vs-fork decision without guessing.

## Acceptance

- `docs/planning/91e49bc-disposition.md` contains a table with one row per logical hunk:
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

- Research clones may exist at `.pi/research/my-avbroot-fork/` and `.pi/research/my-avbroot-upstream/`. Use existing clones if present; do not create new project-root clones.
- `cil_rules.py` may be easiest to upstream as a self-contained PR if upstream is amenable.
- `--compatible-sepolicy` is the most opinionated change; expect upstream to discuss flag naming/defaults.
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
