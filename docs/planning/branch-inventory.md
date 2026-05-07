# Branch Inventory — origin/0cwa/PixeneOS

Generated: 2026-05-06 from `git fetch --prune origin`, `git ls-remote --heads origin`, local `origin/*` refs, and `gh pr list --repo 0cwa/PixeneOS --state open --json headRefName`.

Open PR cross-reference: `gh pr list` returned `[]`; all branches below have `has-open-PR = no`.

Staleness rule: per `docs/planning/branching-model.md`, stale means no commits in 90 days, no open PR, and no ticket link. With today = 2026-05-06, last commit before 2026-02-05 is stale unless overridden.

| Branch | Last commit date | Last author | Ahead / behind vs `origin/main` | Has open PR | Recommendation | Reason |
|---|---:|---|---:|---|---|---|
| `main` | 2026-05-06 | 0cwa | +0 / -0 | no | `keep-active` | Primary active branch; branching model says never rewrite. |
| `gh-pages` | 2026-05-01 | 0cwa | +116 / -487 | no | `keep-active` | Active Custota/public update server branch; do not archive while current devices poll it. |
| `lineage` | 2026-05-06 | Kaia Nau | +56 / -14 | no | `keep-active` | Active/deprecated compatibility branch; keep until HYGIENE-5/ROMCOMPAT migration archives it as planned. |
| `staging` | 2026-01-22 | Kaia Nau | +47 / -58 | no | `archive-as-tag` | Explicit stale candidate. It still has 47 unique commits, so preserve as `archive/staging` before deleting branch. |
| `recovery-option` | 2025-08-29 | 0cwa | +0 / -174 | no | `delete-from-origin` | Explicit stale candidate and has no commits ahead of `main`; no archival value visible from branch tip. |
| `revert-44-fix-magisk-and-fail-fast` | 2025-12-17 | 0cwa | +31 / -124 | no | `archive-as-tag` | Explicit stale candidate with unique revert work; archive before deleting. |
| `fix-magisk-and-fail-fast` | 2025-12-17 | 0cwa | +29 / -124 | no | `archive-as-tag` | Explicit stale candidate with unique Magisk/fail-fast work; archive before deleting. |
| `fix-magisk-dl-and-fail-fast` | 2025-12-20 | 0cwa | +8 / -161 | no | `archive-as-tag` | Explicit stale candidate with unique follow-up work; archive before deleting. |
| `patch-1` | 2024-08-22 | 0cwa | +2 / -487 | no | `archive-as-tag` | Explicit stale candidate with unique commits; small enough to inspect later, but archive before deleting. |
| `patch-2` | 2025-12-25 | 0cwa | +5 / -159 | no | `archive-as-tag` | Explicit stale candidate with unique fail-fast commits; archive before deleting. |
| `revert-24-add-decode-check` | 2024-09-08 | 0cwa | +1 / -342 | no | `archive-as-tag` | Explicit stale candidate with a unique revert; archive before deleting. |
| `renovate/renovatebot-github-action-41.x` | 2025-03-18 | Renovate Bot | +41 / -273 | no | `let-renovate-refresh` | Renovate branch is stale, but deleting can confuse the bot. Let a new Renovate run replace it. |

## Stale candidates explicitly addressed

- `staging` — `archive-as-tag`
- `recovery-option` — `delete-from-origin`
- `revert-44-fix-magisk-and-fail-fast` — `archive-as-tag`
- `fix-magisk-and-fail-fast` — `archive-as-tag`
- `fix-magisk-dl-and-fail-fast` — `archive-as-tag`
- `patch-1` — `archive-as-tag`
- `patch-2` — `archive-as-tag`
- `revert-24-add-decode-check` — `archive-as-tag`
- `renovate/renovatebot-github-action-41.x` — `let-renovate-refresh`

## Next actions

### keep-active

- Keep `main`, `gh-pages`, and `lineage` for now.
- Revisit `lineage` only through HYGIENE-5/ROMCOMPAT; do not merge/rebase it opportunistically.

### archive-as-tag

Create archive tags first, then delete the corresponding remote branches after maintainer confirmation:

- `archive/staging` from `origin/staging`
- `archive/revert-44-fix-magisk-and-fail-fast` from `origin/revert-44-fix-magisk-and-fail-fast`
- `archive/fix-magisk-and-fail-fast` from `origin/fix-magisk-and-fail-fast`
- `archive/fix-magisk-dl-and-fail-fast` from `origin/fix-magisk-dl-and-fail-fast`
- `archive/patch-1` from `origin/patch-1`
- `archive/patch-2` from `origin/patch-2`
- `archive/revert-24-add-decode-check` from `origin/revert-24-add-decode-check`

### delete-from-origin

- Delete `recovery-option` from origin after maintainer ack; it has `+0` unique commits vs `origin/main`.

### let-renovate-refresh

- Leave `renovate/renovatebot-github-action-41.x` alone until Renovate runs. If it remains stuck after Renovate is confirmed healthy, ask Renovate to recreate/update rather than manually force-pushing.

### needs-maintainer-input

- None from this inventory. The archive/delete actions above still need human approval because this ticket is decision input only.
