# MATRIX-5 — Record toolchain versions for reproducibility baseline

## Goal

Reproducible patched OTAs are out of scope for v1, but the matrix/config layer should at least record the toolchain versions needed to explain build differences. Add a planning ticket for the reproducibility baseline so it is not lost.

## Acceptance

- `docs/planning/reproducibility-baseline.md` lists the toolchain/version fields that should be captured per build, including at least avbroot, my-avbroot-setup commit, Python, OS/runner image, Magisk, modules, and ROM build version.
- The plan says which fields belong in MATRIX-1 schema vs generated build metadata.
- The plan explicitly states that byte-for-byte reproducibility is deferred unless a later ticket promotes it.

## Depends

- MATRIX-1

## Notes

Source: `docs/planning/gaps.md` gap 2.

## Out of scope

- Implementing attestations.
- SLSA/provenance publishing.
- Running two-build reproducibility experiments.
