# META-5 — Default `public_artifacts: false` acceptable to downstream users?

## Goal

Confirm with the maintainer (and any known downstream users) that flipping the default artifact-publishing posture to private is OK. Currently every gh-pages device is implicitly public; making private the default may surprise existing users.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-default-private-artifacts.md` records the decision and the per-device override list (devices that explicitly stay public).
- A migration note: which currently-public gh-pages devices must keep `public_artifacts: true` to avoid breaking downstream Custota flows.

## Depends

— (decision-only)

## Trigger condition

Once MATRIX-1 has a candidate matrix file with the explicit per-device public-or-private column.
