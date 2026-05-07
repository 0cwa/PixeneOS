# Branching Model

## Current state (observed)

| Branch                                          | Where     | Status vs origin                                       | Action                       |
|-------------------------------------------------|-----------|--------------------------------------------------------|------------------------------|
| `main`                                          | local + origin | active; downstream uses it                       | keep, never rewrite          |
| upstream `pixincreate/PixeneOS:main`            | upstream  | 103 ahead / 0 behind, 8 files diff                     | track, selectively merge     |
| `lineage`                                       | local + origin | 44 ahead / 144 behind upstream; divergent         | document; rebuild not rebase |
| `staging`                                       | origin    | stale                                                  | flag in HYGIENE-1            |
| `recovery-option`                               | origin    | stale                                                  | flag                         |
| `revert-44-fix-magisk-and-fail-fast`            | origin    | stale                                                  | flag                         |
| `fix-magisk-and-fail-fast`                      | origin    | stale                                                  | flag                         |
| `fix-magisk-dl-and-fail-fast`                   | origin    | stale                                                  | flag                         |
| `patch-1`, `patch-2`                            | origin    | stale                                                  | flag                         |
| `revert-24-add-decode-check`                    | origin    | stale                                                  | flag                         |
| `renovate/renovatebot-github-action-41.x`       | origin    | renovate stale                                         | flag (let Renovate refresh)  |

## Target topology

```
main  ────────────────────────────────────────────►  (active, never rewritten)
        │
        ├──► topic/hygiene-*       (short-lived, squash-merged)
        ├──► topic/adbdebug-*
        ├──► topic/rom-lineage-*   (rebases against main; do not target lineage branch)
        ├──► topic/matrix-*
        ├──► topic/buildopt-*
        ├──► topic/cli-*
        ├──► topic/modconv-*
        └──► topic/infra-*

lineage  (deprecated)  ──── archive after ROMCOMPAT-2 lands on main ────►  tag/archive/lineage-pre-romcompat
```

### Rules

1. **Never rewrite `main`.** No force-push, no rebase-onto, no history surgery.
2. **Topic branches** are the unit of work. Squash-merge into `main` once review + matrix passes.
3. **`lineage` is dead-end.** Once ROMCOMPAT-2 lands a generic per-ROM path on `main`, archive `lineage` as a tag (`archive/lineage-pre-romcompat`) and delete the branch from origin. Do **not** rebase or merge `lineage` back — its 144-behind drift makes that a footgun. (See ADR-0001 + HYGIENE-5.)
4. **Upstream `pixincreate/PixeneOS:main`** is treated as a reference, not a default merge target. The 103-ahead delta is selectively cherry-picked through ROMCOMPAT and HYGIENE tickets.
5. **`my-avbroot-setup` fork** (separate repo) follows the same model. See ADR-0002.

## Stale-branch policy

- A branch is "stale" if: no commits in 90 days, AND not part of an open PR, AND no ticket links to it.
- Action: flag in HYGIENE-1, push a rename `archive/<original-name>` for anything the maintainer wants to keep, then delete from origin. Local copies are the maintainer's call.

## Tag conventions

- `v<rom>-<device>-<date>` for shipped artifacts (e.g. `v-graphene-shiba-2025-05-01`).
- `archive/<branch-name>` for sealed branches.
- `adr/<NNNN>` for ADR-anchoring tags (optional, only if an ADR pins a commit).

## Why not GitFlow / trunk-based / release branches?

- GitFlow's `develop` branch adds churn for a single-maintainer project; rejected.
- Pure trunk-based works, and that *is* what `main` + topic branches gives us. We're trunk-based with topic branches; that's the model.
- Release branches are unnecessary: artifacts are tagged, not branched. If a hot-fix is needed for a shipped tag, branch from the tag and PR back to `main`.
