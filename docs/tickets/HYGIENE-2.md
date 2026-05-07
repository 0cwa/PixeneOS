# HYGIENE-2 — `.gitignore` additions: `.ruff_cache/`, `__pycache__/`

## Goal

Add `.ruff_cache/` and `__pycache__/` to the project's tracked `.gitignore` so future contributors don't accidentally commit Python build/lint cruft. (Currently handled only by `.git/info/exclude` for the maintainer.)

## Acceptance

- `.gitignore` contains, at minimum:
  ```
  .ruff_cache/
  __pycache__/
  *.py[cod]
  ```
- A short comment explains why each entry exists.
- `git status --ignored` confirms both directories now match a `.gitignore` rule (not just `.git/info/exclude`).
- No previously tracked file is removed by this change (verify with `git ls-files | grep -E '(ruff_cache|__pycache__)'` before edit; expect zero hits).

## Depends

— (runnable now; planning-only this session, file edit deferred to implementation phase)

## Notes

- Existing `.gitignore` already covers `*.zip`, `.tmp`, `venv`, `.keys`, `.DS_Store`. Keep style consistent (comment-block above grouped patterns).
- `*.py[cod]` is a small bonus that's harmless and consistent with Python project norms.
- Do NOT add `docs/**` to `.gitignore` — that's a maintainer-local exclusion via `.git/info/exclude`. The tracked `.gitignore` is for *all* contributors.

## Out of scope

- Editing `.git/info/exclude` (already done in the planning prep step).
- Broader Python-tooling configuration (ruff config itself, pre-commit ruff hook).
- `.prettierrc.json` rework or any JS-side hygiene.

## Implementation sketch

1. Read current `.gitignore`.
2. Append a `# Python tooling caches` comment block + the three patterns.
3. Verify nothing tracked matches. Stage only `.gitignore`. Commit message: `chore: ignore .ruff_cache and __pycache__`.
