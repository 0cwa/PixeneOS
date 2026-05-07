# META-8 — CLI distribution channels

## Goal

Pick the distribution channels for the CLI: pipx (always), and which of {brew, apt, Docker, AUR, …} also ship.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-cli-distribution.md` lists chosen channels + per-channel maintenance burden.
- Decline list (with reasons) for channels we explicitly won't ship to in v1.

## Depends

- META-7 (need a name first)

## Trigger condition

When CLI-1 has a candidate surface; before CLI-3 starts writing channel-specific build steps.
