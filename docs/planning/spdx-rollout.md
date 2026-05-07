# SPDX Header Rollout Plan

Planning only. Do not add headers in this ticket.

Policy source: ADR-0003 (`docs/planning/decisions/ADR-0003-license-agpl.md`). New project-authored code is `AGPL-3.0-or-later`; third-party-derived files keep their upstream license.

## Header text

For new maintainer-authored source files that support `#` comments:

```text
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) <year> <author-or-project>
```

For shell scripts, keep shebang first:

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) <year> <author-or-project>
```

For third-party-derived files, keep upstream SPDX exactly. Only add a modifications line when provenance and license compatibility are clear, per ADR-0003.

## File types

Add headers to:

- `*.py`
- `*.sh`
- executable shell hooks such as `src/hooks/pre-commit`
- GitHub workflow YAML (`.github/workflows/*.yml`) using `#` comments
- JSON5 configs where comments are valid (`.github/renovate.json5`)
- sample TOML if it is source/config documentation (`env.toml`) using `#` comments

Do not add headers to:

- `LICENSE`
- Markdown docs (`README.md`, `docs/*.md`) unless a separate docs-license decision asks for it
- strict JSON files (`.prettierrc.json`) because comments are invalid
- trivial ignore/config files (`.gitignore`) unless the maintainer wants uniform comments
- generated, vendored, binary, or downloaded files

## Rollout order

1. **New files first:** require SPDX on new source files after ADR-0003.
2. **ADB-debug canary:** land ADBDEBUG-2 for `src/debugmod.py` and `src/debug_module_setup.sh` as a small PR.
3. **Core source:** batch remaining `src/**` shell files in one PR after per-file provenance checks.
4. **Automation/config:** batch `.github/workflows/*.yml`, `.github/renovate.json5`, and `env.toml` in a second PR.
5. **License text alignment:** separate PR to reconcile root `LICENSE` and README license wording with ADR-0003 if desired; do not mix with source-header churn.

Batching: prefer small directory/scoped PRs over one project-wide churn PR. Suggested PRs:

- PR 1: ADBDEBUG headers only.
- PR 2: remaining `src/**` scripts.
- PR 3: `.github/**` + `env.toml`.
- PR 4: root license/README alignment, if approved.

## Current grep sweep

Command used:

```bash
grep -RL 'SPDX-License-Identifier' $(git ls-files src .github env.toml README.md docs/FAQ.md .prettierrc.json .gitignore LICENSE)
```

No tracked candidate currently contains `SPDX-License-Identifier`.

### Missing header checklist

Source files to consider for SPDX rollout:

- [ ] `src/debugmod.py` — handled by ADBDEBUG-2 canary, not the bulk PR.
- [ ] `src/debug_module_setup.sh` — handled by ADBDEBUG-2 canary, not the bulk PR.
- [ ] `src/declarations.sh`
- [ ] `src/exchange.sh`
- [ ] `src/fetcher.sh`
- [ ] `src/hooks/pre-commit`
- [ ] `src/logger.sh`
- [ ] `src/main.sh`
- [ ] `src/setup_hooks.sh`
- [ ] `src/util_functions.sh`
- [ ] `src/verifier.sh`
- [ ] `.github/workflows/release-lineage.yml`
- [ ] `.github/workflows/release.yml`
- [ ] `.github/workflows/renovate.yml`
- [ ] `.github/renovate.json5`
- [ ] `env.toml`

Tracked files intentionally excluded from header insertion:

- `LICENSE` — license text file; no SPDX header.
- `README.md` — docs; fix license wording separately.
- `docs/FAQ.md` — docs.
- `.prettierrc.json` — strict JSON; comments invalid.
- `.gitignore` — trivial config; no header needed.

## Legacy / conflicting notices

Found non-SPDX notices:

- `LICENSE` is currently MIT with `Copyright (c) 2024 Pa1NarK`.
- `README.md` says the project is licensed under MIT and includes additional warranty/disclaimer text.

These conflict with ADR-0003 for new project code. Handle as a separate license-alignment step; do not silently replace historical notices in the header rollout.

## Third-party-derived files

Rules:

- Anything copied from `chenxiaolong/my-avbroot-setup` or another upstream keeps the original upstream header/license.
- If the file has maintainer modifications, add a modifications notice only after confirming the upstream license permits it.
- When provenance is unclear, leave the file untouched and open a follow-up decision.

Current notes from this sweep:

- The repo downloads `my-avbroot-setup`; it is not vendored as a tracked source tree.
- `src/debugmod.py` uses the my-avbroot module API, but ADBDEBUG-2 found no evidence that it was copied from an upstream template.
- Remaining shell scripts need `git log --follow` provenance checks before stamping; do not assume all initial-import files are newly authored.

## Per-file preflight before adding a header

For each file in a header PR:

1. `git log --follow -- <file>` and note first author/year.
2. Search the file for existing license/source/template comments.
3. If third-party-derived, preserve upstream license.
4. If project-authored, add the AGPL header with the correct year/author.
5. Run a syntax-safe check for file type (`bash -n` for shell, workflow parse/lint if available).
