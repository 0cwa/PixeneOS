# META-11 — Self-hosted runner threat-model boundary

## Goal

Decide which threat-model adversaries the self-hosted runner recipe defends against (S1, S2, S5 from `docs/planning/threat-model.md` are the live ones). Specifically: does the runner ever hold signing keys, or is signing local-only?

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-self-host-boundary.md` with chosen boundary + scenario-letter (A/B/C/D) and a brief justification.
- INFRA-1's runbook is shaped to enforce the chosen boundary.

## Depends

— (decision-only)

## Trigger condition

Before INFRA-1 begins drafting the runbook in earnest.
