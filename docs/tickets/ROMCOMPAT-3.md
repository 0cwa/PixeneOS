# ROMCOMPAT-3 — Lineage csig / OTA / Custota validation on pdx235

## Goal

End-to-end validate the patched-OTA → csig → Custota flow on the `pdx235` Lineage device. Confirms ROMCOMPAT-1 + ROMCOMPAT-2 actually work on real hardware.

## Acceptance

- A short report `docs/planning/pdx235-lineage-validation.md` documenting: build → install → boot → Custota poll → next-OTA cycle.
- All five steps green, or any failure has a tracked follow-up ticket.

## Depends

- ROMCOMPAT-2
