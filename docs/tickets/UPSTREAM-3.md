# UPSTREAM-3 — Prepare upstream PR: Renovate managerFilePatterns

## Goal

Create a tiny upstream PR branch for Renovate custom-manager compatibility if the upstream config still uses deprecated/old `fileMatch` fields.

## Acceptance

- Branch is based on the verified upstream base.
- Check upstream `.github/renovate.json5` before applying anything.
- Include only the Renovate config change:
  - `fileMatch` → `managerFilePatterns` for the existing custom regex managers.
- Do not include `.gitignore`, release config, SPDX/license, or local planning changes.
- Validate that the JSON5 remains syntactically valid, or record why local validation tooling is unavailable.
- Commit/PR message explains this as a Renovate config compatibility/maintenance update.

## Depends

- UPSTREAM-1

## Output

Prepared clean upstream PR branch `upstream/renovate-manager-file-patterns` in worktree `../PixeneOS-upstream-3` from verified `upstream/main` (`a2c41733b042f786c387320171c4b164b3ad89e5`).

Commit: `17ff784` — `Use Renovate managerFilePatterns`.

Included only `.github/renovate.json5`, replacing the 8 existing custom regex manager `fileMatch` keys with `managerFilePatterns`.

Validation performed:

- inspected `upstream/main:.github/renovate.json5` and confirmed custom regex managers still used `fileMatch`;
- `npx --yes json5 .github/renovate.json5 >/dev/null`;
- `git diff upstream/main -- .github/renovate.json5` showed only `fileMatch` → `managerFilePatterns` replacements;
- `git diff --name-status upstream/main..HEAD` shows only `.github/renovate.json5`.

## Out of scope

- Updating dependency versions.
- Reworking Renovate policy.
- Any code changes.
