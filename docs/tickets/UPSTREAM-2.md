# UPSTREAM-2 — Prepare upstream PR: configurable release owner/repository

## Goal

Create a clean, focused upstream PR branch for the release owner/repository configurability idea from REBRAND-1.

## Acceptance

- Branch is based on the verified upstream base, not on the current mixed working tree.
- Only minimal relevant hunks are included, likely from:
  - `src/declarations.sh`;
  - `src/util_functions.sh`;
  - optionally release workflow git author-name lines if they apply cleanly upstream.
- Upstream defaults are preserved. Do not bake in fork-specific `0cwa/PixeneOS` if upstream's current default differs.
- Generic shell `USER` is not used as the project/release owner override.
- `MAGISK[REPOSITORY]` behavior is not changed unless upstream already couples it to the release owner and the PR explicitly addresses that.
- No unrelated changes are included:
  - no SPDX/license headers;
  - no root `LICENSE` changes;
  - no debug-ADB guardrails;
  - no secrets-scanner/key-path changes;
  - no local planning docs.
- Validation commands are recorded in the commit/PR notes.

## Depends

- UPSTREAM-1

## Notes

Suggested PR pitch: avoid relying on generic shell `USER` for release URL ownership; add explicit release owner/repository variables and use GitHub Actions context where available while preserving existing generated URL behavior.

## Output

Prepared clean upstream PR branch `upstream/configurable-release-repository` in worktree `../PixeneOS-upstream-2` from verified `upstream/main` (`a2c41733b042f786c387320171c4b164b3ad89e5`).

Commit: `2260aa3` — `Make release repository configurable`.

Included only:

- `src/declarations.sh`: explicit `PIXENEOS_RELEASE_OWNER` / `PIXENEOS_RELEASE_REPOSITORY` knobs.
- `src/util_functions.sh`: resolver using explicit overrides, then `GITHUB_REPOSITORY`, then upstream defaults `pixincreate/PixeneOS`; generated update URL uses the resolved release owner/repository.

Excluded workflow author-name changes to keep the PR minimal. `MAGISK[REPOSITORY]` behavior remains unchanged.

Validation performed:

- `git fetch upstream main --prune`
- `git rev-parse upstream/main` → `a2c41733b042f786c387320171c4b164b3ad89e5`
- `git ls-remote --heads https://github.com/pixincreate/PixeneOS.git main` → `a2c41733b042f786c387320171c4b164b3ad89e5 refs/heads/main`
- `bash -n src/declarations.sh src/util_functions.sh`
- `git diff upstream/main -- src/declarations.sh src/util_functions.sh .github/workflows/release.yml .github/workflows/release-lineage.yml`
- Manual shell checks: default resolves to `pixincreate/PixeneOS`; `GITHUB_REPOSITORY=example/Fork` resolves to `example/Fork`; explicit `PIXENEOS_RELEASE_OWNER=custom-owner PIXENEOS_RELEASE_REPOSITORY=custom-repo` resolves to `custom-owner/custom-repo`.
- `git diff --name-status upstream/main..HEAD` shows only `src/declarations.sh` and `src/util_functions.sh`.

## Out of scope

- Final project/tool name.
- Repository migration.
- Release asset or `gh-pages` rewrites.
- Full release URL hosting abstraction; RELEASE-1 owns that planning.
