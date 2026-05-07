# HYGIENE-12 — Refresh Renovate config drift

## Goal

HYGIENE-1 found a stale Renovate branch and `docs/planning/gaps.md` notes that Renovate config probably needs a refresh. Audit and update the Renovate setup so dependency automation can recreate stale branches cleanly.

## Acceptance

- `docs/planning/renovate-refresh.md` documents current Renovate config, stale branch state, and recommended changes.
- If safe, `.github/renovate.json5` / `.github/workflows/renovate.yml` are updated in a focused tracked-code change.
- The stale `renovate/renovatebot-github-action-41.x` branch is not force-pushed manually.
- If live Renovate access is required and unavailable, flag that as maintainer action.

## Depends

- HYGIENE-1

## Notes

Let Renovate refresh its own branch once config is healthy; avoid manual branch surgery.

## Out of scope

- General dependency upgrades outside Renovate config.
- Deleting Renovate's stale branch unless maintainer explicitly instructs it.
