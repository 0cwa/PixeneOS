# BUILDOPT-2 — Cache strategy: GH cache → BuildKit → self-hosted

## Goal

Choose a cache backend (GH Actions cache, S3-compatible, or self-hosted volume) and design the cache-key layout so OEM OTA downloads, extracted partitions, and avbroot intermediates are reused across builds.

## Acceptance

- `docs/planning/cache-design.md` with: backend choice (locked by META-6), cache-key schema, eviction policy, security boundary (no leaking signing-keys into cache).
- Per-key TTL and per-key max-size guidance.
- Compatibility note for self-hosted vs GH-hosted runners.

## Depends

- META-6
