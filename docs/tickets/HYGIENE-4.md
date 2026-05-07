# HYGIENE-4 — Document `declarations.sh` overrides + rebrand boundaries

## Goal

`src/declarations.sh` currently hard-codes `USER="0cwa"` and overrides upstream URLs to point at `topjohnwu/Magisk` (and possibly others). Document every override, why it exists, and which overrides will need to change at the META-7 rebrand. Output is a doc, not a code change.

## Acceptance

- `docs/planning/declarations-audit.md` (local-only) contains a table:
  | Variable | Current value | Upstream default | Reason for override | Rebrand action |
- Every assignment in `src/declarations.sh` is in the table — none missed.
- "Rebrand action" is one of: `keep`, `rename-to-tool-name`, `make-configurable`, `delete-after-MATRIX-1`.
- A summary section flags which overrides are user-facing (visible in built artifacts or output filenames) vs purely internal.

## Depends

— (runnable now)

## Notes

- `USER="0cwa"` is almost certainly a `make-configurable` candidate — it's user-identifying and pollutes any output a downstream user would generate.
- `topjohnwu/Magisk` URL pin: investigate whether upstream `pixincreate/PixeneOS` uses the same pin or a different one; the 8-file-diff observation may include this file.
- The ROM URL (Lineage / Graphene / OEM) is the kind of thing that becomes per-device configuration in MATRIX-1; flag those entries with `make-configurable` and note the dependency.

## Out of scope

- Editing `src/declarations.sh`.
- Performing the rebrand (META-7).
- Building the matrix file (MATRIX-1).

## Implementation sketch

1. Read `src/declarations.sh` end-to-end.
2. Diff against `upstream/main:src/declarations.sh` to confirm which lines are fork-only.
3. For each fork-only assignment, record reason (read commits via `git log -p src/declarations.sh`).
4. Assemble the audit table. Mark anything user-facing with a ⚠️.
