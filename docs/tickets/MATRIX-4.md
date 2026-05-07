# MATRIX-4 — Per-device smoke test plan

## Goal

`docs/planning/gaps.md` notes that there is no visible unit/integration test surface and that patcher correctness depends on real OTA integration. Define a minimal per-device smoke-test plan that can run once the matrix exists.

## Acceptance

- `docs/planning/device-smoke-test-plan.md` documents:
  - minimum smoke checks per device/ROM/flavor;
  - which checks can run without signing keys;
  - which checks require private keys or private devices;
  - artifact checks for OTA zip and `.csig` presence/resolution;
  - failure-mode reporting expectations.
- The plan states how it plugs into MATRIX-1's device matrix.
- No real OTA build is required in this planning ticket.

## Depends

- MATRIX-1

## Notes

This is MATRIX-adjacent and should not block MATRIX-1, but the final test shape needs the matrix schema.

## Out of scope

- Implementing CI jobs.
- Running real device flashes.
- Reproducibility/byte-for-byte attestations.
