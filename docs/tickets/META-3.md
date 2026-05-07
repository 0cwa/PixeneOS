# META-3 — Compatible-fork vs upstream-PR cut for `91e49bc`

## Goal

Decide which hunks of `my-avbroot-setup@91e49bc` go upstream vs stay fork-only. Consume ROMCOMPAT-1's analysis; produce the final disposition table.

## Acceptance

- Decision recorded in ADR-0002 follow-up section (or a new ADR `ADR-NNNN-91e49bc-disposition.md`).
- Per-hunk table at [`0cwa/my-avbroot-setup:docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md) is approved or amended (the fork doc is the authoritative copy; PixeneOS does not duplicate it).
- The fork's docs branch has been merged into the fork's `master`.
- ROMCOMPAT-1 + ROMCOMPAT-2 unblocked.

## Ratification

META-3 has ratified the fork-side [`docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md) as the authoritative per-hunk disposition for the `0cwa/my-avbroot-setup` delta ending at `91e49bc`. PixeneOS keeps this ticket and cross-repo pointers only; the per-hunk table stays in the fork repo.

Accepted split:

- **U — upstream PR candidates:** hunk 5 partition-specific `file_contexts`; hunk 6 sepolicy existence checks; hunk 7a `append_seapp_contexts` helper extraction.
- **F — fork-only for now:** `--compatible-sepolicy` flag/plumbing, ODM handling, multi-partition seapp, CIL fallback, `cil_rules.py`, and the ueventd CIL patch.
- **D — drop on cleanup/rebase:** formatter churn, README license-wording regression, and the leaky argparse log line.

Approved upstream sequence: **PR-A**, then **PR-C**, then **PR-B**. This is the smallest-first path: partition-specific `file_contexts` first, pure `append_seapp_contexts` refactor second, defensive sepolicy existence checks third.

`cil_rules.py` is **not** self-contained upstreamable: without the CIL fallback path it has no caller and would land as dead code. Keep it with the fork-only CIL fallback unless upstream explicitly accepts that broader design.

## Depends

- ROMCOMPAT-1's analysis is complete and ratified here.

## Trigger condition

Satisfied. ROMCOMPAT-1 produced the fork-side disposition and META-3 has ratified it above.
