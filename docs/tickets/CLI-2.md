# CLI-2 — Config schema: project-level + per-device overrides

## Goal

Define the configuration schema the CLI consumes: a project-level config plus per-device overrides. Should compose with the matrix file (MATRIX-1) without duplication.

## Acceptance

- `docs/planning/cli-config-schema.md` with the full schema, override-resolution order (defaults → project → device → CLI flag), and validation rules.
- Worked examples covering: layperson minimum, full power-user, CI usage.

## Depends

- CLI-1
