# HYGIENE-1 — Inventory + flag stale branches

## Goal

Produce a single document listing every branch on `origin/0cwa/PixeneOS` with a recommended disposition (keep / archive / delete). Do **not** delete or rename anything in this ticket — output is decision input only.

## Acceptance

- A new file `docs/planning/branch-inventory.md` (local-only, gitignored) lists every remote branch with: name, last-commit date, last-commit author, ahead/behind vs `main`, has-open-PR (yes/no), recommendation.
- The following stale candidates are explicitly addressed: `staging`, `recovery-option`, `revert-44-fix-magisk-and-fail-fast`, `fix-magisk-and-fail-fast`, `fix-magisk-dl-and-fail-fast`, `patch-1`, `patch-2`, `revert-24-add-decode-check`, `renovate/renovatebot-github-action-41.x`.
- Recommendation column uses one of: `keep-active`, `archive-as-tag`, `delete-from-origin`, `let-renovate-refresh`, `needs-maintainer-input`.
- File ends with a "Next actions" section grouping branches by recommendation.

## Depends

— (runnable now)

## Notes

- The 90-day staleness rule from `docs/planning/branching-model.md` is the default, but maintainer override is fine; capture the override reason in the recommendation column.
- Renovate branches: prefer `let-renovate-refresh` over delete; deleting a Renovate branch can confuse the bot.
- Output file is excluded from git via the `docs/**` rule. Future "publish branch inventory" is a separate decision (META-12).

## Out of scope

- Actually deleting or renaming branches.
- Touching local branches that aren't on `origin`.
- Renaming `main`.

## Implementation sketch

1. `git ls-remote --heads origin` → branch list.
2. For each: `git log -1 --format='%cI %an' origin/<branch>` and `git rev-list --left-right --count origin/main...origin/<branch>`.
3. Cross-reference open PRs via `gh pr list --state open --json headRefName` (if `gh` available; else mark "PR-status unknown").
4. Apply staleness rule + maintainer overrides. Write `docs/planning/branch-inventory.md`.
