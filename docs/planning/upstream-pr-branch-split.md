# UPSTREAM-1 branch split plan

Date: 2026-05-07

## Upstream base

Real upstream is identified as:

- Remote name: `upstream`
- URL: `https://github.com/pixincreate/PixeneOS.git`
- Base branch: `upstream/main`
- Verified base commit: `a2c41733b042f786c387320171c4b164b3ad89e5` (`chore(deps): update dependency chenxiaolong/bcr to v2.10 (#288)`)

Evidence/commands:

- `git ls-remote --heads https://github.com/pixincreate/PixeneOS.git main` returned `a2c41733b042f786c387320171c4b164b3ad89e5 refs/heads/main`.
- `origin/main` is merge commit `ef5641a3...` with message `Merge branch 'pixincreate:main' into main` and second parent `a2c41733b...`.
- Local remote config now includes fetch remote `upstream=https://github.com/pixincreate/PixeneOS.git` after `git remote add upstream ... && git fetch upstream main --prune`; its push URL is set to `DISABLED` to avoid accidental direct pushes upstream.

Before cutting PR branches, fetch again and confirm `git rev-parse upstream/main` still matches the intended base.

## Current dirty-tree buckets

Do **not** commit the current working tree as one mixed change. Split by minimal hunks, not just by file, because several files contain unrelated ticket work.

### Upstream PR candidate 1 — configurable release owner/repository

Purpose: avoid hard-coded release URL ownership while preserving upstream behavior by default.

Branch from `upstream/main`, suggested branch name: `upstream/configurable-release-repository`.

Include only these hunks:

- `src/declarations.sh`
  - replace hard-coded `USER`/`REPOSITORY` release URL ownership with explicit release owner/repository variables;
  - preserve upstream defaults: `pixincreate` / `PixeneOS` unless GitHub Actions context or caller-provided variables override them;
  - do **not** include SPDX/copyright header churn.
- `src/util_functions.sh`
  - add the release repository resolver;
  - use the resolved owner/repository in `location_path` inside `my_avbroot_setup`;
  - do **not** include key-generation path changes, debug-ADB filename suffixes, or SPDX/copyright header churn.
- Optional workflow hunk only if wanted for the same PR:
  - `.github/workflows/release.yml`
  - `.github/workflows/release-lineage.yml`
  - include only `git config --global user.name "${{ github.repository_owner }}"` (or another upstream-neutral dynamic value);
  - do **not** include debug-ADB release blocking/publishing guardrails.

Exclude from this PR:

- root `LICENSE` / license wording;
- `README.md` license wording and secrets-scanner/key-path documentation;
- `.gitignore` key filename ignores;
- secrets scanner files;
- debug-ADB guardrails;
- local planning/ticket docs.

Suggested validation on the branch:

- `bash -n src/declarations.sh src/util_functions.sh`
- `git diff upstream/main -- src/declarations.sh src/util_functions.sh .github/workflows/release.yml .github/workflows/release-lineage.yml`
- Manual check that generated release URLs still default to `https://github.com/pixincreate/PixeneOS/...` on upstream.

### Upstream PR candidate 2 — Renovate `managerFilePatterns`

Branch from fresh `upstream/main`, suggested branch name: `upstream/renovate-manager-file-patterns`.

Include only:

- `.github/renovate.json5`
  - `fileMatch` -> `managerFilePatterns` for each custom regex manager;
  - keep the PR tiny and standalone.

Validation:

- Confirm upstream still has `.github/renovate.json5` with custom regex managers using `fileMatch` before preparing the branch.
- `git diff upstream/main -- .github/renovate.json5` should show only the Renovate key migration.

### Upstream PR candidate 3 — Python/local artifact `.gitignore` housekeeping

Optional branch from fresh `upstream/main`, suggested branch name: `upstream/ignore-python-local-artifacts`.

Include only these `.gitignore` entries:

- `.ruff_cache/`
- `__pycache__/`
- `*.py[cod]`

Exclude `avb.key`, `ota.key`, `ota.crt`, `avb_pkmd.bin`, and `.keys/` policy changes from this generic housekeeping PR unless maintainer separately approves a signing-material hygiene PR.

Validation:

- `git diff upstream/main -- .gitignore` should show only the three Python/local artifact patterns.

## Fork-local / local-only bucket

Keep these out of upstream PR branches unless maintainer explicitly approves a separate proposal:

- `docs/planning/**` and `docs/tickets/**`: local planning/ticket system; ignored in this checkout.
- `.pi/**` and `.ruff_cache/**`: local agent/cache state.
- ADB debug release guardrails:
  - `.github/workflows/release.yml` debug-ADB block and release/publish `if:` guards;
  - `.github/workflows/release-lineage.yml` debug-ADB block and release/publish `if:` guards;
  - `src/util_functions.sh` debug-ADB output filename suffix hunk.
- Secrets/key-hygiene implementation unless intentionally proposed later as a dedicated security PR:
  - `.github/workflows/secrets-scan.yml`
  - `.gitleaks.toml`
  - `src/scan_secrets.sh`
  - `src/hooks/pre-commit` fallback scanner invocation;
  - `src/setup_hooks.sh` hook-installation tip;
  - `src/util_functions.sh` `.keys/` key-generation path changes;
  - `README.md` generated signing-file / scanner instructions;
  - `.gitignore` signing filename ignores.
- Fork-specific release defaults from current dirty tree, if any; upstream branches must reset defaults to upstream (`pixincreate` / `PixeneOS`) unless the branch makes them dynamic while preserving that default.

## Legally sensitive bucket

Do not include these in upstream PRs without maintainer/legal review:

- `LICENSE`: replacement of MIT root license text with AGPLv3 text plus provenance caveats.
- `README.md` license section changes referring to ADR-0003 / AGPL.
- SPDX/copyright header rollout in:
  - `src/declarations.sh`
  - `src/util_functions.sh`
  - `src/debug_module_setup.sh`
  - `src/debugmod.py`
  - `src/exchange.sh`
  - `src/fetcher.sh`
  - `src/hooks/pre-commit`
  - `src/logger.sh`
  - `src/main.sh`
  - `src/setup_hooks.sh`
  - `src/verifier.sh`

Reason: third-party-derived provenance is legally sensitive. Do not strengthen AGPL claims or relicense someone else's code in an upstream PR.

## Branch/commit order

1. Ensure no work is lost: keep the current mixed tree untouched or save a local patch/stash before branch extraction.
2. Fetch upstream: `git fetch upstream main --prune`.
3. Create `upstream/configurable-release-repository` from `upstream/main`.
   - Reapply only the minimal release owner/repository hunks listed above.
   - Validate and commit one focused change.
4. Create `upstream/renovate-manager-file-patterns` from `upstream/main`.
   - Reapply only `.github/renovate.json5` key migration if still applicable.
   - Validate and commit one focused change.
5. Create `upstream/ignore-python-local-artifacts` from `upstream/main` if maintainer wants the housekeeping PR.
   - Reapply only the three `.gitignore` Python/local artifact entries.
   - Validate and commit one focused change.
6. After upstream PR branches are reviewed/cut, move the remaining completed fork-local work onto a separate local integration branch.
7. Keep legal/license changes separate and do not publish them upstream without explicit review.

## Explicit exclusions for all upstream PRs

Do not open upstream PRs containing any of the following unless separately approved:

- SPDX/license header churn;
- root `LICENSE` relicensing or AGPL wording;
- debug-ADB release guardrails;
- secrets-scanner work or signing-key path policy changes;
- local planning/ticket docs;
- one catch-all commit of the mixed working tree.

## UPSTREAM-1 validation

Planning validation performed:

- `git status --short --ignored=matching`
- `git remote -v`, `git branch -vv --all --no-abbrev`, and `.git/config` inspection
- `git ls-remote --heads https://github.com/pixincreate/PixeneOS.git main`
- `git fetch upstream main --prune`
- `git diff --name-status` and per-file diff inspection for all currently modified/untracked files

No commit was created.
