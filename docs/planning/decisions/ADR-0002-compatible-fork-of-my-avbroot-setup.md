# ADR-0002 — Maintain a compatible fork of `my-avbroot-setup`

- **Status:** accepted
- **Date:** 2025-05-06
- **Deciders:** maintainer
- **Related tickets:** ROMCOMPAT-1, META-3

## Context

`chenxiaolong/my-avbroot-setup` is the upstream we depend on. The existing fork `0cwa/my-avbroot-setup` carries LineageOS-compatibility work whose cumulative delta against upstream master is +594 / -175 (21 commits ahead of merge-base, ending at `91e49bc`). At ADR-write time this was framed as a "single commit" — corrected during ROMCOMPAT-1 (see Notes). The work adds:

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

We adopt **option 3, the compatible fork**. As ratified by META-3, the practical branch shape is a single rebase-clean fork `master` carrying PixeneOS-required compatibility work, plus short-lived upstream PR branches for upstreamable hunks. Upstreamable hunks are extracted as separate PRs against upstream and dropped from the fork delta once merged.

The split between "upstreamable" and "fork-only" for `91e49bc` is documented in the fork-side `docs/upstream-disposition.md` and ratified by META-3.

## Consequences

- **Easier:** clear upstream relationship; user sees the fork is honest about its delta.
- **Harder:** every upstream release means a rebase pass on the fork's `master`. We need a checklist.
- **Risk:** upstream rejects an upstream PR — we just keep that hunk in the fork delta and document why upstream said no. No drama.

## Alternatives considered

- **Vendor-and-forget (option 1).** Rejected — accumulates drift; encourages divergence with no exit ramp.
- **Single-mega-PR upstream (option 2).** Rejected — `+594/-175` of ROM-specific changes is too large for a clean review and bundles concerns (sepolicy + ODM + CIL) that upstream may want to evaluate separately.

## Notes

- The `91e49bc` analysis was performed during this planning session and is now hosted in the fork repo as the authoritative copy: [`0cwa/my-avbroot-setup:docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md). PixeneOS keeps only the ticket (`ROMCOMPAT-1`), this ADR, and cross-repo pointers — the per-hunk table is not duplicated here.
- The fork-side companion docs are [`MAINTAINERS.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/MAINTAINERS.md), `upstream-strategy.md`, and [`docs/upstream-prs/`](https://github.com/0cwa/my-avbroot-setup/tree/master/docs/upstream-prs).
- META-3 ratified which specific hunks from `91e49bc` go upstream vs stay fork-local: U = hunk 5 partition-specific `file_contexts`, hunk 6 sepolicy existence checks, hunk 7a `append_seapp_contexts`; F = `--compatible-sepolicy`, ODM handling, multi-partition seapp, CIL fallback, `cil_rules.py`, ueventd CIL patch; D = formatter churn, README license-wording regression, leaky argparse log line. The approved upstream sequence is PR-A → PR-C → PR-B.
- This ADR's original "compat-lineage topic branch" sketch was simplified by the disposition: with only 21 commits ahead of merge-base, a single rebase-clean fork `master` is simpler than maintaining a separate topic branch. The fork's upstream strategy document records the actual branch layout.
- An earlier shallow research clone (`.pi/research/my-avbroot-fork/`, depth=1) initially produced a "single root commit" misreading of the fork; the corrected analysis used a full clone at `../my-avbroot-setup/`.
