# ADR-0001 — Keep `main` active and never rewrite it

- **Status:** accepted
- **Date:** 2025-05-06
- **Deciders:** maintainer
- **Related tickets:** HYGIENE-1, HYGIENE-5, META-2

## Context

`0cwa/PixeneOS:main` is actively used by the maintainer and downstream consumers. It is 103 commits ahead of upstream `pixincreate/PixeneOS:main` (with only 8 files actually different in net effect). A separate `lineage` branch is 44 ahead / 144 behind upstream and divergent.

Three options were on the table:

1. Rebase `main` onto upstream and force-push.
2. Start a fresh repo under a new name and migrate users.
3. Keep `main` exactly as-is and evolve forward via topic branches.

Downstream users have Custota update flows pinned to today's `0cwa/PixeneOS` artifact paths. A force-push or rename would break update delivery without warning. The 103-commit delta against upstream is not all useful churn — much of it is operational glue this fork needs.

## Decision

`main` is **never rewritten**. No force-push, no rebase-onto-upstream, no history surgery. All changes land via squash-merged topic branches. The `lineage` branch is treated as a dead-end and will be archived (not rebased) once ROMCOMPAT-2 lands a per-ROM path on `main`.

## Consequences

- **Easier:** downstream Custota flows keep working; topic-branch model is simple.
- **Harder:** harder to selectively pull from upstream — we cherry-pick or recreate, never rebase. The 103-commit delta will not shrink mechanically; it shrinks only as ROMCOMPAT / MATRIX work lands generic versions of fork-only patches.
- **Risk:** upstream and fork drift may grow. Mitigated by the ROMCOMPAT phase, which surfaces upstreamable hunks as PRs (META-3).

## Alternatives considered

- **Rebase-and-force-push.** Rejected — breaks downstream update flow. Even with notice, Custota pinning makes this a real user-visible regression.
- **Fresh repo + migration.** Deferred to META-2; not rejected forever but not done now. If the rebrand at META-7 demands a new repo, that is a separate, signposted migration with redirect tags.

## Notes

- The 103-ahead / 0-behind / 8-file-diff observation came from this planning session's upstream comparison.
- See `docs/planning/branching-model.md` for the topic-branch policy and the `lineage` archive plan.
