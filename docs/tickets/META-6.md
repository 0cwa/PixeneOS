# META-6 — Cache backend: GH cache vs S3 vs self-hosted volume

## Goal

Pick the cache backend used by BUILDOPT-2.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-cache-backend.md` with chosen backend, rationale, fallback (e.g. "GH cache primary, self-hosted volume on self-hosted runner").
- Cost / size / TTL constraints captured.

## Depends

— (decision-only)

## Trigger condition

When BUILDOPT-2 is ready to design cache-key layout.
