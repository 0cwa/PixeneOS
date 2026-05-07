# META-4 — Matrix file format: TOML vs YAML vs JSON

## Goal

Pick the matrix file format. Affects MATRIX-1 directly.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-matrix-format.md` records the choice with rationale.
- Format must support comments (rules out JSON unless a `# comment` superset like JSON5 is OK).
- Tooling availability for parsers in shell + Python is confirmed.

## Depends

— (decision-only)

## Trigger condition

Open whenever the maintainer is ready to commit to the matrix format. Recommendation: TOML (good comment support, stable parsers, human-edit friendly).
