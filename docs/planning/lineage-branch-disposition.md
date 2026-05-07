# HYGIENE-5 — `lineage` branch divergence and archive plan

Observed: 2026-05-06

Scope: documentation only. No tag, branch delete, cherry-pick, merge, rebase, or fast-forward was performed.

## Current divergence

Command used:

```sh
git rev-list --left-right --count origin/main...origin/lineage
```

Observed result:

```text
14	56
```

Interpretation for `origin/main...origin/lineage`:

- `origin/main` has 14 commits not reachable from `origin/lineage`.
- `origin/lineage` has 56 commits not reachable from `origin/main`.

Relevant refs at observation time:

- `origin/main`: `ef5641a`
- `origin/lineage`: `e44125a`
- merge-base: `a2c4173` (`upstream/main` at observation time)

Additional check:

```sh
git rev-list --left-right --count upstream/main...origin/lineage
# 0	145
```

That upstream comparison is less useful for this ticket because `origin/lineage` already contains current `upstream/main`; the actionable divergence is between fork `origin/main` and fork `origin/lineage`. The ticket text's older `44 / 144` number is stale; current observed fork-vs-fork divergence is 14 behind / 56 ahead.

Net diff of `origin/main..origin/lineage` at observation time:

```text
.github/workflows/release.yml | 21 +++++++++++----------
env.toml                      |  4 ++--
src/declarations.sh           | 10 +++++-----
src/fetcher.sh                | 22 +++++++++++++++-------
src/util_functions.sh         | 13 ++++++++++++-
5 files changed, 45 insertions(+), 25 deletions(-)
```

## Required branch rule

Do **not** rebase, merge, or fast-forward `lineage`.

The branch is now a historical experiment branch with ROM-specific patcher changes, per-device CI defaults, and several trial/revert commits. Directly reconciling it would create a high-conflict surface and would blur which hunks are actually still needed. Useful behavior should be reintroduced through ROMCOMPAT-2 / ROMCOMPAT-1 as explicit, reviewed capabilities rather than by moving the branch tip.

## Categorized ahead-of-main commits

Categories:

- **(a)** Lineage-only patcher logic ROMCOMPAT-2 will subsume
- **(b)** one-off device fixes
- **(c)** experimental dead ends
- **(d)** potentially upstreamable hunks

| # | Commit | Category | Disposition note |
|---:|---|---|---|
| 1 | `d9035e7` fetch Lineage ROMs | (a) | First Lineage OTA source adaptation; subsume as ROM source/provider logic. |
| 2 | `6c81516` Update env.toml | (b) | Hard-codes `pdx235` / nightly defaults; device-specific. |
| 3 | `c28111c` get debugging | (c) | Fetcher debug instrumentation, not a durable hunk. |
| 4 | `d4e949b` Update declarations.sh | (a) | Lineage declarations/config experiment. |
| 5 | `b07058e` debugging | (c) | Debug-only fetcher instrumentation. |
| 6 | `1495b2b` Update declarations.sh | (a) | Lineage declarations/config experiment. |
| 7 | `4c925e4` Update declarations.sh | (a) | Lineage declarations/config experiment. |
| 8 | `5249c27` Update fetcher.sh | (a) | Lineage fetcher API adaptation. |
| 9 | `84bdf03` Update ci to build rootless Xperia 10 V by default | (b) | Xperia 10 V / `pdx235` CI default. |
| 10 | `fce222a` Update fetcher.sh | (a) | Lineage fetcher API adaptation. |
| 11 | `266263c` Update fetcher.sh | (a) | Lineage fetcher API adaptation. |
| 12 | `2b26c04` Update fetcher.sh | (a) | Lineage fetcher API adaptation. |
| 13 | `4636d47` Update release.yml | (b) | Workflow default changes for the Lineage device path. |
| 14 | `0c35d29` Hack patcher to skip patching vendor_boot | (a) | ROM-specific partition handling; replace with capability/manifest behavior. |
| 15 | `cb82219` Update fetcher.sh | (a) | Lineage fetcher refinement. |
| 16 | `cab181d` Skip non-existent sepolicy files | (d) | General robustness idea: skip absent sepolicy files instead of failing blindly. |
| 17 | `eabba69` Update util_functions.sh | (a) | Lineage patching/util adaptation. |
| 18 | `98fd60c` Clear vbmeta flags for Lineage | (a) | ROM-specific patch argument; model as ROM capability flag. |
| 19 | `7bd0793` Update util_functions.sh | (a) | Lineage patching/util adaptation. |
| 20 | `1355f0a` Explicit rootless | (a) | Rootless flavor handling for Lineage path; should become explicit config. |
| 21 | `9264e9f` hopefully clear enough diskspace | (d) | General CI/workdir cleanup idea; evaluate independently from Lineage branch. |
| 22 | `7a64744` Make OTA release the device name? | (c) | Superseded/reverted release naming experiment. |
| 23 | `8742ff5` revert prev | (c) | Explicitly reverts prior naming experiment. |
| 24 | `95336ae` Fix when the pre-device ota zip metadata doesn't match the provided device_name | (d) | General publish robustness; can be reviewed separately from ROM support. |
| 25 | `f47c318` remove spare bracket | (c) | Syntax cleanup inside experimental chain. |
| 26 | `6f323ef` Sign all partitions | (a) | ROM-specific signing behavior; belongs in ROM capability design. |
| 27 | `d328e96` fetching debug | (c) | Debug-only fetcher logging. |
| 28 | `0d77990` Update declarations.sh | (a) | Lineage declarations/config experiment. |
| 29 | `ad28ef7` Merge branch 'lineage' into fix-magisk-and-fail-fast | (c) | Merge bookkeeping for a branch later reverted. |
| 30 | `6d6e441` Merge pull request #44 from 0cwa/fix-magisk-and-fail-fast | (c) | PR merge for later-reverted work. |
| 31 | `5b5a641` Revert "Fix magisk and fail fast" | (c) | Revert commit; documents dead-end path. |
| 32 | `3d9ed36` Merge pull request #45 from 0cwa/revert-44-fix-magisk-and-fail-fast | (c) | PR merge for revert. |
| 33 | `39dd736` Remove --all | (a) | avbroot argument change tied to Lineage patching. |
| 34 | `0e1b19f` Use personal avbroot-setup with --compatible-sepolicy | (a) | ROM compatibility setup path; ROMCOMPAT should absorb without personal fork coupling. |
| 35 | `2107a3d` Update declarations.sh | (a) | `my-avbroot-setup` / compatibility pin iteration. |
| 36 | `57c600a` Only pull avbroot-setup from my repo | (a) | Personal fork source override; replace with explicit ROMCOMPAT dependency decision. |
| 37 | `9e17561` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 38 | `4b7138b` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 39 | `709f32d` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 40 | `7918cf8` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 41 | `843d07f` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 42 | `1a15958` Update declarations.sh | (a) | Compatibility declaration iteration. |
| 43 | `5d2e2f4` syntax | (c) | Syntax fix in experimental path. |
| 44 | `d45a004` Update fetcher.sh | (a) | Lineage fetcher refinement. |
| 45 | `b30f0dd` Update util_functions.sh | (a) | Lineage patching/util refinement. |
| 46 | `b1fc60a` Update fetcher.sh | (a) | Lineage fetcher refinement. |
| 47 | `b657107` Resolve merge conflicts | (c) | Staging/merge-conflict bookkeeping, not a hunk to port as-is. |
| 48 | `a77e488` Merge pull request #55 from 0cwa/staging | (c) | PR merge bookkeeping. |
| 49 | `b9f7a34` Update util_functions.sh | (a) | Compatibility patch argument/util refinement. |
| 50 | `833c65c` Try V2 MAS | (c) | MAS compatibility experiment. |
| 51 | `0838c0f` Update declarations.sh | (c) | MAS compatibility experiment iteration. |
| 52 | `02889e1` Update declarations.sh | (c) | MAS compatibility experiment iteration. |
| 53 | `a148162` Update declarations.sh | (c) | MAS compatibility experiment iteration. |
| 54 | `bb49b56` try v1.1 | (c) | MAS compatibility experiment iteration. |
| 55 | `c9caf28` Update my-avbroot-setup to 91e49bc for LineageOS SELinux compatibility | (d) | Potentially useful `91e49bc` hunk; cross-reference ROMCOMPAT-1 rather than duplicating analysis here. |
| 56 | `e44125a` merge with upstream | (c) | Branch maintenance merge; do not replay. |

Category totals:

- (a) ROMCOMPAT-2 should subsume: 29 commits
- (b) one-off device fixes: 3 commits
- (c) experimental dead ends / bookkeeping: 19 commits
- (d) potentially upstreamable hunks: 5 commits

## Archive plan

When the trigger condition is met:

1. Create an archive tag at the current lineage tip:

   ```sh
   git tag archive/lineage-pre-romcompat origin/lineage
   git push origin archive/lineage-pre-romcompat
   ```

2. Delete the remote branch:

   ```sh
   git push origin --delete lineage
   ```

No archive action should happen during HYGIENE-5. This is only the documented plan.

## Trigger condition

Archive `origin/lineage` only after both are true:

1. `ROMCOMPAT-2` is marked `done`.
2. At least one Lineage device is green on the matrix.

Until that trigger is met, preserve the branch as historical reference only. Do not rebase it, merge it into `main`, fast-forward it, or cherry-pick from it without a separate ROMCOMPAT-scoped review.
