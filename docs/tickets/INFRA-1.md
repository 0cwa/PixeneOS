# INFRA-1 — GH self-hosted runner recipe (hardened, ephemeral)

## Goal

Produce a runbook for setting up a hardened, ephemeral GitHub Actions self-hosted runner suitable for the build matrix. Layperson-friendly but secure-by-default.

## Acceptance

- `docs/planning/self-hosted-runner.md` with: hardware sizing (disk for Lineage OTAs), systemd unit, ephemeral-runner pattern (one job → fresh state), network egress allowlist, secret handling, minimum-trust setup checklist.
- The runbook explicitly states the threat-model boundary chosen in META-11.

## Depends

- META-11
