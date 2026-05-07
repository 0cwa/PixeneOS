# ADR-0002 — Maintain a compatible fork of `my-avbroot-setup`

- **Status:** accepted
- **Date:** 2025-05-06
- **Deciders:** maintainer
- **Related tickets:** ROMCOMPAT-1, META-3

## Context

`chenxiaolong/my-avbroot-setup` is the upstream we depend on. The existing fork `0cwa/my-avbroot-setup` carries a single large LineageOS-compatibility commit (`91e49bc`, +594/-175) that adds:

- `--compatible-sepolicy` flag
- ODM partition handling
- Partition-specific `file_contexts`
- CIL fallback
- `cil_rules.py` (new file)

Some of this is plausibly upstreamable; some is opinionated enough that upstream may reject it. Carrying a fork forever costs maintenance attention; sending nothing upstream hoards changes from the wider community.

Three options:

1. Rebase the fork commit on top of every upstream release and ship the diff as-is.
2. Submit the entire `91e49bc` upstream as a single PR.
3. **Compatible fork** — keep a fork branch tracking upstream, but actively split `91e49bc` into upstreamable hunks (PR'd one at a time) versus fork-local hunks (kept until upstream takes them or never).

## Decision

We adopt **option 3, the compatible fork**. The fork's `main` always tracks `chenxiaolong/my-avbroot-setup:master`. Local-only changes live on a single rebased topic branch (`compat-lineage`) that is regularly squashed. Upstreamable hunks are extracted as separate PRs against upstream and dropped from `compat-lineage` once merged.

The split between "upstreamable" and "fork-only" for `91e49bc` is the work of ROMCOMPAT-1 and is gated by META-3.

## Consequences

- **Easier:** clear upstream relationship; user sees the fork is honest about its delta.
- **Harder:** every upstream release means a rebase pass on `compat-lineage`. We need a checklist.
- **Risk:** upstream rejects an upstream PR — we just keep that hunk in `compat-lineage` and document why upstream said no. No drama.

## Alternatives considered

- **Vendor-and-forget (option 1).** Rejected — accumulates drift; encourages divergence with no exit ramp.
- **Single-mega-PR upstream (option 2).** Rejected — `+594/-175` of ROM-specific changes is too large for a clean review and bundles concerns (sepolicy + ODM + CIL) that upstream may want to evaluate separately.

## Notes

- The `91e49bc` analysis was performed against `.pi/research/my-avbroot-fork/` and `.pi/research/my-avbroot-upstream/` clones during this planning session.
- META-3 is the gate that decides which specific hunks from `91e49bc` go upstream vs stay fork-local. Expected output: a per-hunk table with PR-vs-fork disposition.
