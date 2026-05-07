# MATRIX-2 — Per-device `public_artifacts` privacy flag

## Goal

Add a `public_artifacts` boolean to each matrix row (default `false`) and plumb it through the (future) workflow so private rows produce build-only artifacts not pushed to gh-pages.

## Acceptance

- Schema doc for `public_artifacts` semantics (`docs/planning/matrix-privacy.md`).
- Decision matrix: what publishing path is taken for each combination (`true` → gh-pages, `false` → build-only retention).
- Plan reflected in MATRIX-3's workflow refactor scope.

## Depends

- MATRIX-1
- META-5
