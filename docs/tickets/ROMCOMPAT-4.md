# ROMCOMPAT-4 — Triage Lineage-derived potentially-upstreamable hunks

## Goal

HYGIENE-5 identified several `origin/lineage` commits whose ideas may be useful beyond the abandoned branch. Triage those hunks into explicit dispositions so useful behavior is ported through ROMCOMPAT work rather than by merging/cherry-picking the branch.

## Acceptance

- `docs/planning/lineage-upstreamable-hunks.md` documents a per-hunk disposition for at least:
  - skipping absent sepolicy files;
  - pre-device OTA metadata vs `DEVICE_NAME` mismatch handling;
  - CI/workdir disk cleanup before `csig` generation;
  - `my-avbroot-setup@91e49bc` Lineage SELinux compatibility;
  - any other HYGIENE-5 category `(d)` hunk that still appears relevant after inspection.
- Each hunk is classified as one of:
  - `upstream-pr-candidate`,
  - `romcompat-manifest-capability`,
  - `local-only-workflow-hardening`,
  - `obsolete-after-ROMCOMPAT-2`,
  - `reject`.
- The document cross-references ROMCOMPAT-1 for the `91e49bc` analysis rather than duplicating it.
- No code is cherry-picked from `origin/lineage` during this ticket.

## Depends

- HYGIENE-5
- ROMCOMPAT-1

## Notes

HYGIENE-5 category `(d)` starting points:

- `cab181d` — skip non-existent sepolicy files.
- `9264e9f` — clear disk space before `csig`/large artifacts.
- `95336ae` — handle OTA zip metadata that does not match the provided `DEVICE_NAME`.
- `c9caf28` — update `my-avbroot-setup` to `91e49bc` for LineageOS SELinux compatibility.

This ticket should wait until ROMCOMPAT-1 has decided how to handle `91e49bc` hunks.

## Out of scope

- Merging, rebasing, fast-forwarding, or deleting `origin/lineage`.
- Implementing ROMCOMPAT-2's manifest.
- Applying any hunk directly to `main`.

## Implementation sketch

1. Read `docs/planning/lineage-branch-disposition.md`.
2. Inspect each category `(d)` commit with `git show`.
3. Compare against current `main` to see whether the idea is already present, obsolete, or still valuable.
4. Write the disposition doc.
5. Create smaller implementation tickets for any accepted hunks.
