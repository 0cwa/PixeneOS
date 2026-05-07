# HYGIENE-9 — Align root license and README wording with ADR-0003

## Goal

ADR-0003 says new project code is AGPL-3.0-or-later, but the current root `LICENSE` and README wording were observed as MIT-oriented in the SPDX rollout plan. Reconcile the public license text and README wording without obscuring third-party provenance.

## Acceptance

- Root `LICENSE` and README license wording are reviewed against ADR-0003.
- If changed, the update clearly states:
  - new project-authored code is AGPL-3.0-or-later;
  - third-party-derived code retains its upstream license;
  - existing historical notices are not silently erased without rationale.
- If not changed, `docs/planning/license-alignment-note.md` explains why not.
- No source headers are changed in this ticket.

## Depends

- HYGIENE-3
- META-1

## Notes

`docs/planning/spdx-rollout.md` flagged this as a separate license-alignment step. Keep it separate from header churn.

## Out of scope

- Adding SPDX headers to source files.
- Legal advice beyond documenting the project policy already captured in ADR-0003.
