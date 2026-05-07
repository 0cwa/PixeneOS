# ADBDEBUG-1 — Document ADB debug module design + threat surface

## Goal

Produce a design + threat-surface document for the ADB debug module (`src/debugmod.py`, `src/debug_module_setup.sh`). Today it ships as part of the Magisk-flavor build but its contract isn't written down. Before we expose it more broadly (or move it into the public `patcher-cli` surface), we need to know exactly what it does and what trust assumptions it makes.

## Acceptance

- `docs/planning/adbdebug-design.md` (local-only) contains:
  - **What it touches.** Every file/property/permission the module modifies, as a table.
  - **Lifecycle.** When it activates (boot stage), persistence (across reboots? OTAs?), and uninstall path.
  - **Privilege model.** What user/SELinux context the module runs as; whether it needs root.
  - **Network exposure.** Whether ADB is exposed over network, USB-only, or wireless-pair.
  - **Threat surface.** A short version of the threat-model checklist (`docs/planning/threat-model.md` S1–S5) applied specifically to this module.
  - **User-facing trade-offs.** What a user gains (debug access) vs gives up (attack surface, attestation breakage, etc.).
  - **Recommended default.** Should the module ship enabled by default, available-but-off, or opt-in build only?
- The doc is reviewable in <10 minutes. Keep it terse.

## Depends

— (runnable now)

## Notes

- This is documentation only. Source can be public; artifacts default private (per the planning constraints).
- The "available-but-off" default is probably the right answer but capture the trade-off rather than asserting it.
- Cross-link to `docs/planning/threat-model.md` for shared adversary definitions; do not redefine adversaries here.

## Out of scope

- Editing the module source.
- ADBDEBUG-2's SPDX work.
- Distribution / artifact-publishing decisions for the module.

## Implementation sketch

1. Read `src/debugmod.py` and `src/debug_module_setup.sh` end-to-end.
2. List every system property, file, and `setprop`/`adb`/`magisk` call.
3. Map to threat-model adversaries S1–S5; note any new threats unique to this module.
4. Draft the doc. Get a sanity check on the "default state" recommendation before closing.
