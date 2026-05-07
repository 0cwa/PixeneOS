# COMPAT-2 — Fix or retire broken `magisk/bramble` update metadata

## Goal

COMPAT-1 found that `magisk/bramble.json` points at legacy `pixincreate/PixeneOS` release assets that returned 404 during the audit. Decide whether this device/flavor is still supported and either repair the metadata path or document/retire it safely.

## Acceptance

- Re-verify the current live URL(s) and release assets for `magisk/bramble.json`.
- `docs/planning/bramble-compat-fix.md` records:
  - current JSON URL(s);
  - current `location_ota` / `location_csig` values;
  - whether each asset resolves;
  - recommended action: repair JSON, mirror assets, retire device/flavor, or preserve as historical only.
- If JSON or release assets are changed, old Custota clients are considered and a rollback path is documented.

## Depends

- COMPAT-1

## Notes

COMPAT-1 observed `https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip[.csig]` returning 404.

## Out of scope

- Full rebrand migration.
- Changing all device JSONs.
- Rewriting historical releases without maintainer approval.
