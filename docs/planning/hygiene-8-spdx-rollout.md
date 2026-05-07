# HYGIENE-8 — Core source SPDX rollout note

Observed: 2026-05-06

Scope: remaining source shell files from `docs/planning/spdx-rollout.md` only. ADB-debug canary files were already handled by HYGIENE-7 and were not modified here.

Policy citation: ADR-0003 (`docs/planning/decisions/ADR-0003-license-agpl.md`) resolves project source headers as `AGPL-3.0-or-later` for maintainer-authored project code.

## Files stamped

Added a shebang-preserving header to:

- `src/declarations.sh`
- `src/exchange.sh`
- `src/fetcher.sh`
- `src/hooks/pre-commit`
- `src/logger.sh`
- `src/main.sh`
- `src/setup_hooks.sh`
- `src/util_functions.sh`
- `src/verifier.sh`

No existing SPDX headers were present in these files before stamping. No duplicate SPDX headers were added to `src/debugmod.py` or `src/debug_module_setup.sh`.

## Provenance checks

For every touched file, ran `git log --follow -- <file>` and checked the file for existing license/source/template comments. The logs show project-local introduction by PixeneOS maintainers/contributors; no existing upstream license notice or copied-template attribution was present.

| File | Introduced by `git log --follow --diff-filter=A` | Latest relevant provenance note | Header years used |
|---|---|---|---|
| `src/declarations.sh` | `97c0d147a50d0cf5e2714089cd35acd0e205d578` — 2024-08-03, PiX `<69745008+pixincreate@users.noreply.github.com>`, `initial commit` | Later project dependency/config updates through 2026. | `2024-2026` |
| `src/exchange.sh` | `2f3bb705de786104ddf901bd031c9c24b901823e` — 2024-08-19, PiX `<69745008+pixincreate@users.noreply.github.com>`, `feat: add encoding support for passing keys` | Later project edits through 2025. | `2024-2026` |
| `src/fetcher.sh` | `d600ca598ac6f1b11859513731e3fd7b3b25d69b` — 2024-08-16, PiX `<69745008+pixincreate@users.noreply.github.com>`, `refactor: downloader -> fetcher and move things around` | Later project fetcher/dependency handling edits through 2025. | `2024-2026` |
| `src/hooks/pre-commit` | `3c83fb754a333e3b4eeaa5c4b0f6c02f9bfb74de` — 2024-10-20, Pa1NarK `<69745008+pixincreate@users.noreply.github.com>`, `docs: add detailed documentation for PixeneOS (#52)` | Hook is a small project-specific `.keys/` guard; no upstream notice. | `2024-2026` |
| `src/logger.sh` | `2be269c352564c7994bca9ee9484857fefd82b95` — 2025-07-20, Pa1NarK `<69745008+pixincreate@users.noreply.github.com>`, `chore(docs/ci): introduce faq and forced releases (#162)` | Project-local logging helper; no upstream notice. | `2025-2026` |
| `src/main.sh` | `76730b3676436cde66aae095e3688c1bb6de0850` — 2024-08-04, PiX `<69745008+pixincreate@users.noreply.github.com>`, `rewrite` | File says the project depends on chenxiaolong projects, but no copied upstream license/source notice was present. | `2024-2026` |
| `src/setup_hooks.sh` | `3c83fb754a333e3b4eeaa5c4b0f6c02f9bfb74de` — 2024-10-20, Pa1NarK `<69745008+pixincreate@users.noreply.github.com>`, `docs: add detailed documentation for PixeneOS (#52)` | Project-local hook installer; no upstream notice. | `2024-2026` |
| `src/util_functions.sh` | `97c0d147a50d0cf5e2714089cd35acd0e205d578` — 2024-08-03, PiX `<69745008+pixincreate@users.noreply.github.com>`, `initial commit` | Contains integration code and references to `my-avbroot-setup`, but no existing upstream license/source notice or vendored copied source block was present. | `2024-2026` |
| `src/verifier.sh` | `76730b3676436cde66aae095e3688c1bb6de0850` — 2024-08-04, PiX `<69745008+pixincreate@users.noreply.github.com>`, `rewrite` | References third-party tools as dependencies only; no upstream notice. | `2024-2026` |

## Third-party / unclear provenance callouts

None left untouched within this scoped `src/**` shell batch. The source comments that mention `chenxiaolong` / `my-avbroot-setup` describe runtime dependency/integration behavior, not a vendored source tree or copied file notice. If a maintainer knows any of these shell files were copied from an upstream template outside Git history, confirm before upstream merge.

Automation/config files from `docs/planning/spdx-rollout.md` (`.github/workflows/*.yml`, `.github/renovate.json5`, `env.toml`) remain out of scope for this source-only HYGIENE-8 pass.

## Validation

```sh
for f in src/declarations.sh src/exchange.sh src/fetcher.sh src/hooks/pre-commit src/logger.sh src/main.sh src/setup_hooks.sh src/util_functions.sh src/verifier.sh; do bash -n "$f"; done
```

Passed locally.

```sh
for f in src/declarations.sh src/exchange.sh src/fetcher.sh src/hooks/pre-commit src/logger.sh src/main.sh src/setup_hooks.sh src/util_functions.sh src/verifier.sh src/debugmod.py src/debug_module_setup.sh; do grep -c 'SPDX-License-Identifier' "$f"; done
```

Each checked file reports exactly `1` SPDX identifier.
