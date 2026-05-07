# META-3 — Compatible-fork vs upstream-PR cut for `91e49bc`

## Goal

Decide which hunks of `my-avbroot-setup@91e49bc` go upstream vs stay fork-only. Consume ROMCOMPAT-1's analysis; produce the final disposition table.

## Acceptance

- Decision recorded in ADR-0002 follow-up section (or a new ADR `ADR-NNNN-91e49bc-disposition.md`).
- Per-hunk table from ROMCOMPAT-1 is approved or amended.
- ROMCOMPAT-1 + ROMCOMPAT-2 unblocked.

## Depends

- ROMCOMPAT-1's analysis must be drafted (the analysis can run *while* META-3 is open; the gate just needs the analysis to ratify).

## Trigger condition

ROMCOMPAT-1 doc has a complete per-hunk table awaiting maintainer sign-off.
