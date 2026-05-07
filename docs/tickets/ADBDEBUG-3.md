# ADBDEBUG-3 — Gate debug artifact publishing and labeling

## Goal

Prevent unauthorized-ADB debug builds from being accidentally published, named, or indexed as normal PixeneOS release artifacts.

This is implementation-first: make the smallest workflow/script change that enforces the guardrail, then document the resulting policy at the end.

## Acceptance

- Debug builds are opt-in only; normal release paths do not enable `ADDITIONALS_DEBUG=true` implicitly.
- Debug artifact names/labels include an unmistakable marker such as `debug-adb`.
- Normal release JSON / update metadata is not updated by a debug build unless there is an explicit, obvious maintainer confirmation path.
- A focused adversarial check is recorded: a debug build cannot silently replace normal artifacts.
- End-of-ticket docs are updated:
  - public docs if user-facing behavior changes and publication is authorized;
  - otherwise a short local note at `docs/planning/adbdebug-release-guardrails.md`.

## Depends

- ADBDEBUG-1

## Notes

Starting point: `docs/planning/adbdebug-design.md` recommended opt-in builds only and clear artifact labeling.

Prefer direct guardrails over a large design document. If workflow behavior is changed, include the exact validation command or manual check in the end-of-ticket note.

## Output

Implemented in this slice:

- `generate_ota_info` appends `debug-adb` to patched OTA filenames when `ADDITIONALS[DEBUG] == true`.
- `.github/workflows/release.yml` and `.github/workflows/release-lineage.yml` fail early when `allow_unauthorized_adb=true` is combined with a publishing `release-type`.
- The same workflows exclude debug builds from both `Make Release` and `Publish OTA to server` steps as defense in depth.

Validation recorded in `docs/planning/adbdebug-release-guardrails.md`:

- shell syntax check for the touched shell file;
- YAML parse check for both release workflows;
- debug filename includes `debug-adb`, normal filename does not;
- focused adversarial check verified both workflows contain the explicit debug publish blocker and exclude debug builds from release upload and metadata publishing.

## Out of scope

- Changing debug module SELinux/property behavior.
- Adding SPDX headers; HYGIENE-7 owns that.
