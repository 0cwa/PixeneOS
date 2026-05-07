# META-10 — Manifest signing model

## Goal

Pick the manifest signing model: per-module key, single repo key, or web-of-trust.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-manifest-signing.md` with chosen model + verifier responsibilities + key rotation policy.
- Threat-model implications cross-referenced (`docs/planning/threat-model.md` S2).

## Depends

— (decision-only; informed by MODCONV-2 maturity)

## Trigger condition

When MODCONV-2 is far enough along to know what the manifest contains.
