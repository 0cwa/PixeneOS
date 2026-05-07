# HYGIENE-7 — ADB-debug SPDX canary note

Observed: 2026-05-06

Scope: source-header canary only. Added the AGPL SPDX/copyright header to:

- `src/debugmod.py`
- `src/debug_module_setup.sh`

Policy citation: ADR-0003 (`docs/planning/decisions/ADR-0003-license-agpl.md`) resolves project source headers as `AGPL-3.0-or-later`.

Provenance citations from `docs/planning/adbdebug-headers-plan.md`:

- `src/debugmod.py` introduced by `c301b85` (`2025-08-29`, author `0cwa <kainau@yahoo.com>`), subject: `Add release option for debug, add debug module code to src`.
- `src/debug_module_setup.sh` introduced by `4f36dfc` (`2025-08-29`, author `0cwa <kainau@yahoo.com>`), subject: `Add recovery mode option`.

Derivative-code note: the existing plan found no evidence that either file was copied from a third-party Magisk/debug module template. Maintainer should still confirm before upstream merge if they know otherwise.

Validation:

```sh
python3 -m py_compile src/debugmod.py
bash -n src/debug_module_setup.sh
```

Both commands passed locally.
