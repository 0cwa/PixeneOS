# HYGIENE-7 — Apply ADB-debug SPDX header canary

## Goal

Implement the small canary header pass planned by ADBDEBUG-2: add AGPL SPDX/copyright headers to `src/debugmod.py` and `src/debug_module_setup.sh` before the wider source-tree SPDX rollout.

## Acceptance

- `src/debugmod.py` contains:
  - `# SPDX-License-Identifier: AGPL-3.0-or-later`
  - `# Copyright (C) 2025 0cwa`
- `src/debug_module_setup.sh` keeps its shebang on line 1 and then contains the same SPDX/copyright lines.
- The PR/body or local notes cite ADR-0003 and the introducing commits recorded in `docs/planning/adbdebug-headers-plan.md`.
- Basic syntax checks pass:
  - `python3 -m py_compile src/debugmod.py`
  - `bash -n src/debug_module_setup.sh`
- No wider SPDX rollout is included in this ticket.

## Depends

- ADBDEBUG-2
- META-1

## Notes

This is the low-risk canary from `docs/planning/spdx-rollout.md` and `docs/planning/adbdebug-headers-plan.md`.

## Out of scope

- Adding headers to other `src/**` files.
- Changing license text in `LICENSE` or `README.md`.
- Changing ADB debug behavior.
