# INFRA-3 — Key custody guidance (HSM / sops / age / Yubikey)

## Goal

Lay out an opinionated key-custody guide that a layperson can follow. Default scenario A (local-only); documented upgrade path to scenarios C/D from the threat model.

## Acceptance

- `docs/planning/key-custody.md` with: per-scenario setup, rotation procedure, recovery procedure, audit-log expectations, what to do on suspected compromise.
- Each scenario clearly states its trust assumptions and threat coverage.

## Depends

- META-10
- META-11
