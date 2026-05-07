# MODCONV-2 — Converter design: input → IR → output

## Goal

Design the module converter: input parsers (per format from MODCONV-1), an internal representation (IR), and output emitters. Converter is the *primary* surface; manifest format (MODCONV-3) is secondary.

## Acceptance

- `docs/planning/converter-design.md` with: data-flow diagram, IR schema, parser interface, emitter interface, error-handling model, permission-diff report (refuse on widening unless `--allow-widen`).
- A worked example: a real Magisk module → IR → manifest, including any permission-widen warnings.

## Depends

- MODCONV-1
- META-9
