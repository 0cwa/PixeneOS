# BUILDOPT-3 — Parallelise per-device builds without leaking state

## Goal

Run multiple per-device build rows concurrently within a single workflow without cross-contamination (separate working directories, separate cache namespaces, separate temp dirs).

## Acceptance

- `docs/planning/parallel-build-design.md` with: isolation strategy, per-job working-dir scheme, cache namespace pattern, max parallelism guidance per runner type.
- Anti-leak checklist: `.tmp`, key paths, `env.toml` overrides, working-dir reuse.

## Depends

- BUILDOPT-2
