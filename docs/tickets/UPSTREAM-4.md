# UPSTREAM-4 — Prepare upstream PR: ignore Python/local artifacts

## Goal

Create a small upstream housekeeping PR for broadly useful local artifact ignores, if desired after the main configurable-release PR is handled.

## Acceptance

- Branch is based on the verified upstream base.
- Include only generic Python/tooling artifacts unless maintainer explicitly broadens scope:
  - `.ruff_cache/`
  - `__pycache__/`
  - `*.py[cod]`
- Do not include signing key filename ignores in this generic housekeeping PR; those belong with a separate signing-material hygiene discussion.
- Do not include Renovate, release config, SPDX/license, or local planning changes.
- Validate with `git status --ignored=matching` or equivalent to show the ignored artifacts are recognized.

## Depends

- UPSTREAM-1

## Output

Prepared clean upstream PR branch `upstream/ignore-python-local-artifacts` in worktree `../PixeneOS-upstream-4` from verified `upstream/main` (`a2c41733b042f786c387320171c4b164b3ad89e5`).

Commit: `2ba3c97` — `Ignore common Python local artifacts`.

Included only `.gitignore` additions for:

- `.ruff_cache/`
- `__pycache__/`
- `*.py[cod]`

Validation performed:

- `git check-ignore -v .ruff_cache/ __pycache__/example.pyc example.pyc example.pyo example.pyd` showed each path matched one of the new ignore rules;
- `git diff upstream/main -- .gitignore` showed only the three generic Python/local artifact patterns;
- `git diff --name-status upstream/main..HEAD` shows only `.gitignore`.

## Out of scope

- Secrets scanning.
- Key-generation path changes.
- Any code behavior changes.
