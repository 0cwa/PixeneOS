# HYGIENE-12 — Renovate config refresh

Scope: audit Renovate configuration drift, make only safe focused configuration changes, and document the stale Renovate branch disposition. No Renovate branch was force-pushed, deleted, or rewritten.

Reviewed files and refs:

- `.github/renovate.json5`
- `.github/workflows/renovate.yml`
- `src/declarations.sh`
- `docs/planning/branch-inventory.md`
- `origin/renovate/renovatebot-github-action-41.x`

## Current Renovate workflow

The repository runs self-hosted Renovate through GitHub Actions:

- Triggered nightly at `0 0 * * *`, by manual `workflow_dispatch`, and on pushes to `main`.
- Uses `actions/checkout@v6`.
- Uses `renovatebot/github-action@v46.1.13`.
- Passes `configurationFile: .github/renovate.json5`.
- Uses the `RENOVATE` GitHub secret as the token.
- Limits execution to the current repository through `RENOVATE_REPOSITORIES: ${{ github.repository }}`.
- Exposes a manual `logLevel` input, defaulting to `info`.

A tag check against `renovatebot/github-action` showed `v46.1.13` as the newest visible `v*` tag at audit time, so the workflow action pin does not need a manual bump in this ticket.

## Current Renovate config

The config currently sets:

- `$schema: https://docs.renovatebot.com/renovate-schema.json`
- `prHourlyLimit: 0`
- `gitAuthor: Renovate Bot <renovatebot@non-existent-email.com>`
- `assignees: ["pixincreate"]`
- `labels: ["dependencies"]`
- eight regex custom managers for dependency pins in `src/declarations.sh`:
  - `VERSION[AVBROOT]` from GitHub releases for `chenxiaolong/avbroot`
  - `VERSION[AVBROOT_SETUP]` from git refs for `chenxiaolong/my-avbroot-setup`
  - `VERSION[CUSTOTA]` from GitHub releases for `chenxiaolong/Custota`
  - `VERSION[ALTERINSTALLER]` from GitHub releases for `chenxiaolong/AlterInstaller`
  - `VERSION[MSD]` from GitHub releases for `chenxiaolong/MSD`
  - `VERSION[BCR]` from GitHub releases for `chenxiaolong/BCR`
  - `VERSION[OEMUNLOCKONBOOT]` from GitHub releases for `chenxiaolong/OEMUnlockOnBoot`
  - `VERSION[AFSR]` from GitHub releases for `chenxiaolong/afsr`

The regexes still match the current `src/declarations.sh` assignment style.

## Config drift found

`npx --yes --package renovate renovate-config-validator .github/renovate.json5` validated the config but reported a migration warning for the custom manager file selector:

- old key: `fileMatch: ["src/declarations.sh"]`
- current migrated key: `managerFilePatterns: ["/src/declarations.sh/"]`

This is a narrow schema/API drift in the Renovate config rather than a project dependency upgrade.

## Change made

Updated all eight custom managers in `.github/renovate.json5` from `fileMatch` to `managerFilePatterns`, using the validator-suggested pattern:

```json5
managerFilePatterns: ["/src/declarations.sh/"],
```

No `.github/workflows/renovate.yml` change was made because the action pin is already current at audit time.

## Stale Renovate branch state

`docs/planning/branch-inventory.md` identifies `renovate/renovatebot-github-action-41.x` as stale:

- Last commit: 2025-03-18
- Last author: Renovate Bot
- Local ref tip checked during this ticket: `655fdf6 chore(deps): update renovatebot/github-action action to v41.0.16`
- Ahead / behind in the inventory: `+41 / -273`
- Open PR in the inventory: no
- Recommendation in the inventory: `let-renovate-refresh`

The branch is obsolete relative to `main`, where `.github/workflows/renovate.yml` already uses `renovatebot/github-action@v46.1.13`. It should not be manually force-pushed, deleted, or rewritten as part of this ticket. Let Renovate recreate or refresh its own branch after configuration health is restored.

## Recommended next actions

1. Keep the `.github/renovate.json5` migration from `fileMatch` to `managerFilePatterns`.
2. Keep `.github/workflows/renovate.yml` unchanged for now; `renovatebot/github-action@v46.1.13` is current by tag check.
3. Let a scheduled or manually dispatched Renovate run refresh branch state. Do not manually force-push, delete, or rewrite `renovate/renovatebot-github-action-41.x`.
4. Maintainer action if needed: if Renovate does not run or cannot update branches after this config change, inspect the GitHub Actions Renovate run logs and the `RENOVATE` secret/token permissions. This checkout cannot prove GitHub Actions execution or token health locally.
5. If the stale branch remains after a confirmed healthy Renovate run, ask Renovate to recreate/update the branch rather than doing branch surgery by hand.

## Validation

- `npx --yes --package renovate renovate-config-validator .github/renovate.json5` after the change: `Config validated successfully` with no migration warning.
- `git ls-remote --tags https://github.com/renovatebot/github-action.git 'refs/tags/v*' | sed 's#.*refs/tags/##' | sed 's#\\^{}##' | sort -V | tail -1`: `v46.1.13`.
- No force-push, delete, or rewrite was performed against `renovate/renovatebot-github-action-41.x`.

## Acceptance check

- Current Renovate config documented: done.
- Stale branch state documented: done.
- Recommended changes documented: done.
- Safe focused config change made: done (`fileMatch` → `managerFilePatterns`).
- Workflow left unchanged because the action pin is current: done.
- Manual stale-branch surgery avoided: done.
- Maintainer action for live Renovate/GitHub Actions verification documented: done.
