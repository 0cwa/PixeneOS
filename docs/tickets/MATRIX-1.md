# MATRIX-1 — Minimal TOML device matrix

## Goal

Add a small single-source-of-truth matrix file using TOML by default. The first slice should record current device/ROM/flavor rows and the minimum metadata needed to avoid hard-coded workflow sprawl later.

This replaces the earlier plan of separate matrix-format, privacy-flag, smoke-test, and reproducibility-baseline planning tickets. Keep the first matrix thin; workflows do not have to consume it yet.

## Acceptance

- A new project-tracked TOML file is added at a clear root path, such as `devices.toml`.
- The file includes current known rows for GrapheneOS devices and `pdx235` Lineage/manual work.
- Each row includes at minimum:
  - device codename;
  - ROM/channel/source;
  - flavor when applicable (`rootless`, `magisk`, etc.);
  - `public_artifacts` with a conservative default and explicit preservation of currently-public compatibility rows before publishing behavior changes;
  - notes for pinned versions or private/manual rows.
- The matrix has lightweight placeholders/notes for future smoke checks and build metadata capture, without creating separate planning-only tickets.
- `docs/planning/matrix-schema.md` briefly describes columns, allowed values, and how to add fields later.
- The file is parsed/validated with an available TOML parser or documented manual validation.
- Workflows are **not** refactored to consume the matrix in this ticket unless the maintainer explicitly expands scope.
- End-of-ticket docs record validation and any rows intentionally omitted.

## Depends

—

## Notes

- TOML is the default format; no separate META gate is needed unless TOML becomes impractical.
- `public_artifacts` defaults private for new rows, but currently-public release/update compatibility must not be broken accidentally.
- Keep cross-arch and full reproducibility attestations out of the first slice; add comments/notes for future fields if needed.

## Out of scope

- Consolidating `.github/workflows/release.yml` and `.github/workflows/release-lineage.yml`.
- Changing artifact publishing behavior.
- Adding new devices beyond documenting known current targets.
- Full smoke-test CI implementation.
