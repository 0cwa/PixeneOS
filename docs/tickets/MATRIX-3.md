# MATRIX-3 — Refactor workflows into single matrix job (planning)

## Goal

Plan the consolidation of `.github/workflows/release.yml` and `release-lineage.yml` into a single matrix-driven workflow that reads `devices.<ext>` (from MATRIX-1) and respects `public_artifacts` (from MATRIX-2). Plan only — actual workflow edits land in a follow-up implementation ticket.

## Acceptance

- A migration plan doc (`docs/planning/workflow-consolidation.md`) listing: shared steps, per-row variations, secrets needs, artifact retention rules, runner selection.
- A regression checklist: what must keep working post-merge (every gh-pages device still publishes; pdx235 stays private; etc.).

## Depends

- MATRIX-1
- MATRIX-2
