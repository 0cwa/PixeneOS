# META-9 — Module-IR scope

## Goal

Decide the IR's coverage: Magisk-only superset, or include KernelSU and APatch?

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-module-ir-scope.md` records: supported input formats, the rationale, and the explicit deferral list (which formats we'll add later if needed).
- The IR schema's "extension points" are noted so adding a format later doesn't require a redesign.

## Depends

- MODCONV-1 (catalog must exist first)

## Trigger condition

When MODCONV-1's catalog is complete and the relative ecosystem sizes are known.
