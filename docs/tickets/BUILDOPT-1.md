# BUILDOPT-1 — Adopt `avbroot ota extract --partition`

## Goal

Eventually switch to partition-selective extraction where safe, using `avbroot ota extract --partition <name>` to reduce disk and wall-clock cost.

Do not run this as a standalone planning exercise yet. Selective extraction can silently miss ROM-specific partitions, so it should wait until ROM compatibility work has identified the per-ROM partition needs.

## Acceptance

When this ticket is revived:

- The current `avbroot` version's `ota extract --partition` syntax is verified.
- Per-flavor partition needs are listed for rootless and Magisk builds.
- Per-ROM additions from ROMCOMPAT work are included, especially Lineage-specific ODM/system_ext/file-context needs.
- The migration identifies which scripts/workflows currently do bulk extraction and the exact replacement flags.
- A guard or sanity check prevents consumers from referencing partitions that were not extracted.
- Expected savings are estimated briefly; no full benchmark is required.
- End-of-ticket docs capture the final partition matrix and validation.

## Depends

- ROMCOMPAT-2 for the actual code switch.

## Notes

- The Magisk flavor may mutate `boot` or `init_boot` depending on device generation.
- Rootless commonly mutates vbmeta/chained vbmeta partitions, but confirm from code and ROM behavior.
- Cross-link to BUILDOPT-2 only if cache work is being revived too.

## Out of scope

- Editing `release.yml` / `release-lineage.yml` before partition needs are known.
- Cache backend selection.
- Parallelisation.
