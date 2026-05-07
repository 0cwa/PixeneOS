# MODCONV-1 — Catalog of in-the-wild module shapes + license survey

## Goal

When module conversion becomes near-term, survey existing module ecosystems and document the structural shapes and license posture needed for a safe converter.

This is not an active near-term ticket. Avoid doing a broad ecosystem survey before converter implementation is actually planned.

## Acceptance

When this ticket is revived:

- `docs/planning/module-shapes.md` covers only the formats needed for the first converter slice, likely Magisk first.
- For each included format, document directory layout, manifest file, boot-time hook semantics, persistence model, and common pitfalls.
- Include a short license-survey appendix covering common license declarations and what conversion implies for those licenses.
- Explicitly defer KernelSU/APatch/plain flashable zip unless they are required for the first converter slice.

## Depends

—

## Notes

Keep the legal posture conservative: converting or repackaging third-party modules must preserve upstream licenses/copyright and should not imply PixeneOS relicensing.
