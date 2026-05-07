# Upstream PR + clean history reorientation

The current working tree contains several completed local tickets mixed together. Do not push or open a PR from this mixed tree as-is.

## Goal

Prioritize clean, focused branches that can plausibly be opened as upstream pull requests. Keep fork-local or legally sensitive work separate.

## Current likely upstream PR candidates

### 1. Configurable release owner/repository

Best candidate.

Candidate scope:

- `src/declarations.sh`
- `src/util_functions.sh`
- optionally release workflow git author-name lines in:
  - `.github/workflows/release.yml`
  - `.github/workflows/release-lineage.yml`

Upstream PR rules:

- Preserve upstream defaults, not fork-specific defaults, once the actual upstream base is known.
- Do not include SPDX/license header churn.
- Do not include debug-ADB guardrails.
- Do not include key-generation/secrets-scanning changes.
- Pitch: avoid generic shell `USER` for release URL ownership; add explicit release owner/repository variables and use GitHub Actions context when available.

### 2. Renovate config compatibility

Small candidate.

Candidate scope:

- `.github/renovate.json5`

Change:

- `fileMatch` → `managerFilePatterns` for Renovate custom regex managers.

This should be a tiny standalone PR if upstream uses the same Renovate config and the change is still relevant against upstream HEAD.

### 3. Ignore Python/local tooling artifacts

Maybe candidate.

Candidate scope should probably be limited to:

- `.ruff_cache/`
- `__pycache__/`
- `*.py[cod]`

Do not include key filename ignores in this generic housekeeping PR unless the PR is explicitly about signing-material hygiene.

## Keep separate / likely not upstream as-is

- `LICENSE` and broad license wording changes.
- SPDX/copyright header rollout.
- HYGIENE-13 secrets scanner and key path changes, unless intentionally proposed as a separate security PR.
- ADBDEBUG-3 debug artifact guardrails, unless upstream has the same debug-ADB workflow need and agrees with the behavior.
- Local planning docs under `docs/planning/` and local ticket docs under `docs/tickets/` unless the maintainer requests publishing them.

## UPSTREAM-1 branch split output

Detailed branch/hunk buckets are recorded in [`upstream-pr-branch-split.md`](upstream-pr-branch-split.md).

Identified upstream base:

- `upstream=https://github.com/pixincreate/PixeneOS.git`
- `upstream/main` at `a2c41733b042f786c387320171c4b164b3ad89e5` when verified on 2026-05-07

Fetch and re-check this base before cutting each PR branch.

## Clean-history procedure

1. Fetch and verify the real upstream remote/base before making PR branches.
2. Do not commit the whole dirty tree as one commit.
3. For each upstream PR candidate, create a fresh branch from the upstream base.
4. Cherry-pick or reapply only the minimal relevant hunks.
5. Validate each branch independently.
6. Use focused commit messages and PR descriptions with rationale, compatibility notes, and validation commands.
7. Keep fork-local completed work on a separate local integration branch after upstream PR branches are cut.

## Suggested order

1. Resolve upstream remote/base and write down the branch split.
2. Prepare `configurable-release-repository` branch first.
3. Prepare `renovate-manager-file-patterns` branch second if still applicable.
4. Prepare `ignore-python-local-artifacts` branch third if desired.
5. Only then return to `RELEASE-1`, ROM compatibility, or matrix work.
