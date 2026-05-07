# CLI-3 — Distribution: pipx + Docker

## Goal

Plan the distribution channels for the CLI: pipx (Python entry point), reproducible Docker image, possibly more (gated by META-8).

## Acceptance

- `docs/planning/cli-distribution.md` with one section per channel: build steps, signing, version pinning, verification instructions for end users.
- Each channel includes a "how does a user verify the binary they got is the one we shipped" answer.

## Depends

- META-7
- META-8
