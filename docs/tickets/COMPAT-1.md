# COMPAT-1 — Downstream backwards-compatibility audit

## Goal

Catalog every public path, URL, filename pattern, and identifier that *existing* downstream users (Custota clients, anyone who flashed a current build) depend on. This ticket gates META-2 (rebrand-target) and META-7 (tooling name): no rebrand or rename can ship without consulting the audit and a published migration plan.

The risk being mitigated: a rebrand or repo move silently breaks Custota update polling for users already on the current builds. Custota clients are pinned to specific URLs at flash time and have no auto-discovery — once their pinned URL 404s, the device never updates again.

## Acceptance

- `docs/planning/downstream-compat-audit.md` (local-only) contains:
  1. **Public surface inventory.** Every URL pattern currently served from `gh-pages` for every device in the matrix: `https://0cwa.github.io/PixeneOS/<device>.json`, csig URLs, OTA download URLs. Include real example URLs verified against the live site.
  2. **Identifier inventory.** Every project-name string that ends up *on a user device or in their config*: `USER="0cwa"` from `declarations.sh` (cross-ref HYGIENE-4), any artifact filename pattern, any `module.prop` `id=` field for shipped modules, any csig `name` field.
  3. **Pinning map.** For each URL/identifier, mark whether it is *user-pinned* (changing it breaks already-flashed devices) vs *build-pinned* (only affects new builds).
  4. **Migration strategies** per pinning class:
     - User-pinned URLs: must be preserved indefinitely or redirected for a stated deprecation window (recommend ≥12 months).
     - Build-pinned identifiers: can change at rebrand boundary; document the cutover.
  5. **Pre-rebrand checklist** (lifted into META-2 and META-7 as a hard prerequisite) covering: hosting old paths, redirect setup, communication channel(s) to reach existing users, deprecation timeline, rollback plan if Custota clients hang.
  6. **Best-effort install count.** Whatever signal we have for how many devices are pinned to today's build (e.g. gh-pages traffic logs, GitHub release downloads, anything else). If zero signal, document that and lean toward maximally-compatible defaults.

- The doc explicitly answers: *"If we ship a rebrand tomorrow with no migration, what breaks for which users?"* in plain language.

## Depends

— (runnable now; analysis-only)

## Blocks

- META-2 (cannot decide rebrand-target without the audit)
- META-7 (cannot finalise tooling name without knowing what name-strings ship to user devices)
- Any rebrand-adjacent CLI work (CLI-1 Backward-compat note in particular)

## Notes

- Custota's update model is: device queries `<update-server-base>/<device>.json` periodically. Move the device JSON, you break updates. Period.
- The csig file's `name` field is *not* user-pinned — it's checked at install time per OTA, not stored on device. Confirm this in the audit, don't assume.
- `declarations.sh`'s `USER="0cwa"` likely shows up in artifact filenames and possibly in `module.prop` `id=`. Check both. (HYGIENE-4 should produce most of this; cross-reference rather than duplicate.)
- The ADB-debug module ships with a Magisk `module.prop`; that file's `id=` is user-pinned (Magisk uses it as the module's persistent key). Renaming it on an installed device would orphan the old install.
- If best-effort install count is unrecoverable: write down the assumption "we cannot count, so we treat every gh-pages-served URL as user-pinned forever."

## Out of scope

- Performing the rebrand.
- Setting up redirect infrastructure.
- Communicating with users.
- Resolving META-2 or META-7.

## Implementation sketch

1. `git ls-tree -r origin/gh-pages | head -200` → enumerate live public paths.
2. Hit a few URLs with `curl -I` to confirm they resolve; record exact path patterns.
3. Grep `src/` for every literal containing `0cwa`, `PixeneOS`, the artifact filename template, and any `module.prop`-bound `id=`.
4. Check the gh-pages branch's `index.json` / per-device JSONs to see exactly what Custota consumes.
5. Classify each finding (user-pinned vs build-pinned) and write the doc.
6. Draft the pre-rebrand checklist as a numbered list — META-2 / META-7 will copy it verbatim.
