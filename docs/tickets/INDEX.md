# Ticket Index

Single source of truth for ticket status. Each row links to the per-ticket file. Status lives **only** here to avoid drift; ticket files do not embed status.

Process: see [`PROCESS.md`](PROCESS.md). The short version is: small implementation slice, validate, document at the end, and create follow-ups only for concrete remaining work.

Status legend: `open` `in_progress` `done` `blocked` `deferred` `cancelled`

## Active lanes

### Now — pick from here first

| ID | Title | Why now |
|---|---|---|
| UPSTREAM-2 | Prepare upstream PR: configurable release owner/repository | Best upstream candidate; should be cut before more feature work changes the same files. |
| UPSTREAM-3 | Prepare upstream PR: Renovate `managerFilePatterns` | Small standalone maintenance PR if still applicable upstream. |
| UPSTREAM-4 | Prepare upstream PR: ignore Python/local artifacts | Optional small housekeeping PR; keep signing-key ignores separate. |

### Next — small foundations after Now

| ID | Title | Simplified direction |
|---|---|---|
| RELEASE-1 | Decouple generated update URLs from hard-coded GitHub releases | Can be planned in parallel after branch split is safe; keep separate from upstream PR branch prep. |
| ROMCOMPAT-1 | Per-hunk disposition for `my-avbroot-setup@91e49bc` | Analysis is allowed to run before any META ratification; output informs upstream/fork choice. |
| MATRIX-1 | Minimal TOML device matrix | Use TOML by default; fold privacy flag, smoke-test placeholder, and version-capture notes into one thin slice. |

### Later / defer by default

| ID | Why deferred |
|---|---|
| DOCS-1 | Fold privacy/no-telemetry wording into the next authorized public-doc change instead of running a standalone local note. |
| BUILDOPT-1..3 | Optimize after ROM compatibility and partition needs are known. |
| CLI-1..3 | Do not block script/config improvements on a future CLI product surface. |
| MODCONV-1..3 | Module conversion is a future product line; survey only when implementation is near. |
| INFRA-1..3 | Self-hosted/Forgejo/key-custody runbooks are useful later, not needed for the next release slice. |
| Most META-* | Replaced by safe defaults or trigger-only decision notes; do not treat as active blockers. |

## Ticket table

| ID | Title | Lane | Status | Depends / trigger |
|---|---|---:|---|---|
| HYGIENE-1 | Inventory + flag stale branches | hygiene | done | — |
| HYGIENE-2 | `.gitignore` additions: `.ruff_cache/`, `__pycache__/` | hygiene | done | — |
| HYGIENE-3 | SPDX header policy rollout plan | hygiene | done | META-1 ✅ |
| HYGIENE-4 | Document `declarations.sh` overrides + rebrand boundaries | hygiene | done | — |
| HYGIENE-5 | Document `lineage` branch divergence + archive plan | hygiene | done | — |
| HYGIENE-6 | Refresh stale `lineage` divergence assumptions | hygiene | done | HYGIENE-5 ✅ |
| HYGIENE-7 | Apply ADB-debug SPDX header canary | hygiene | done | ADBDEBUG-2 ✅, META-1 ✅ |
| HYGIENE-8 | Apply remaining source SPDX headers after provenance checks | hygiene | done | HYGIENE-7 ✅, HYGIENE-3 ✅ |
| HYGIENE-9 | Align root license and README wording with ADR-0003 | hygiene | done | HYGIENE-3 ✅, META-1 ✅ |
| HYGIENE-10 | Archive/delete stale remote branches after maintainer approval | later | blocked | HYGIENE-1 ✅, explicit maintainer approval |
| HYGIENE-11 | Audit pre-commit secrets hook scope | hygiene | done | — |
| HYGIENE-12 | Refresh Renovate config drift | hygiene | done | HYGIENE-1 ✅ |
| HYGIENE-13 | Supplement secrets scanning beyond `.keys/` | hygiene | done | HYGIENE-11 ✅ |
| ADBDEBUG-1 | Document ADB debug module design + threat surface | adbdebug | done | — |
| ADBDEBUG-2 | Plan SPDX/license headers for `debugmod.py`, `debug_module_setup.sh` | adbdebug | done | META-1 ✅, ADBDEBUG-1 ✅ |
| ADBDEBUG-3 | Gate debug artifact publishing and labeling | adbdebug | done | ADBDEBUG-1 ✅ |
| COMPAT-1 | Downstream backwards-compatibility audit | compat | done | — |
| COMPAT-2 | Fix or retire broken `magisk/bramble` update metadata | compat | done | COMPAT-1 ✅ |
| REBRAND-1 | Make release owner/repository identifiers configurable | rebrand | done | HYGIENE-4 ✅, COMPAT-1 ✅ |
| UPSTREAM-1 | Split current work into upstream PR candidates and fork-local work | now | done | REBRAND-1 |
| UPSTREAM-2 | Prepare upstream PR: configurable release owner/repository | now | done | UPSTREAM-1 |
| UPSTREAM-3 | Prepare upstream PR: Renovate `managerFilePatterns` | now | done | UPSTREAM-1 |
| UPSTREAM-4 | Prepare upstream PR: ignore Python/local artifacts | now | done | UPSTREAM-1 |
| RELEASE-1 | Decouple generated update URLs from hard-coded GitHub releases | next | open | REBRAND-1 |
| ROMCOMPAT-1 | Per-hunk disposition for `my-avbroot-setup@91e49bc` | next | open | Trigger for META-3 ratification, not blocked by it |
| ROMCOMPAT-2 | Minimal ROM/device capability config | next | open | ROMCOMPAT-1 |
| ROMCOMPAT-3 | Lineage csig / OTA / Custota validation on pdx235 | next | open | ROMCOMPAT-2 |
| ROMCOMPAT-4 | Triage Lineage-derived potentially-upstreamable hunks | next | blocked | HYGIENE-5 ✅, ROMCOMPAT-1 |
| MATRIX-1 | Minimal TOML single-source-of-truth matrix file | next | open | TOML default; no META-4 blocker |
| MATRIX-2 | Per-device `public_artifacts` privacy flag | later | deferred | Fold minimal column semantics into MATRIX-1; workflow plumbing later |
| MATRIX-3 | Refactor workflows into single matrix job | later | deferred | MATRIX-1; implement after matrix proves useful |
| MATRIX-4 | Per-device smoke test plan | later | deferred | Fold placeholder fields into MATRIX-1; CI tests later |
| MATRIX-5 | Record toolchain versions for reproducibility baseline | later | deferred | Fold metadata notes into MATRIX-1; attestations deferred |
| BUILDOPT-1 | Adopt `avbroot ota extract --partition` | later | deferred | Wait for ROMCOMPAT-2 partition needs |
| BUILDOPT-2 | Cache strategy: GH cache → BuildKit → self-hosted | later | deferred | GitHub cache default when needed |
| BUILDOPT-3 | Parallelise per-device builds without leaking state | later | deferred | BUILDOPT-2 or concrete runtime pressure |
| CLI-1 | Surface design: subcommand layout | icebox | deferred | Do not block current script/config work on naming |
| CLI-2 | Config schema: project-level + per-device overrides | icebox | deferred | CLI-1 or concrete CLI implementation |
| CLI-3 | Distribution: pipx + Docker | icebox | deferred | CLI product exists |
| MODCONV-1 | Catalog of in-the-wild module shapes + license survey | icebox | deferred | Converter work becomes near-term |
| MODCONV-2 | Converter design: input → IR → output | icebox | deferred | MODCONV-1 |
| MODCONV-3 | Manifest format spec | icebox | deferred | MODCONV-2 |
| DOCS-1 | Document no-telemetry/privacy posture | later | deferred | Next authorized public-doc pass |
| INFRA-1 | GH self-hosted runner recipe | icebox | deferred | Concrete self-hosted user/maintainer request |
| INFRA-2 | Forgejo/Gitea Actions parity | icebox | deferred | INFRA-1 |
| INFRA-3 | Key custody guidance | icebox | deferred | Concrete self-hosting/key-management work |

## META / decision notes

META tickets are no longer a ladder that blocks all downstream work. They are trigger-only decision notes unless listed as a hard dependency above.

| ID | Question | Status | Current default / trigger |
|---|---|---|---|
| META-1 | SPDX/license header policy | done | ADR-0003 resolved: AGPL-3.0-or-later for new project-authored code; third-party-derived code keeps upstream license/copyright. |
| META-2 | Rebrand in-place vs fresh repo | deferred | Trigger when an actual repo rename is proposed. |
| META-3 | Upstream PR vs compatible fork for `91e49bc` | open | ROMCOMPAT-1 may run first; maintainer ratifies the completed hunk table. |
| META-4 | Matrix file format | done | Default TOML; revisit only if tooling proves painful. |
| META-5 | Default `public_artifacts: false` | done | Default private for new rows; preserve currently public compatibility rows explicitly before changing publishing. |
| META-6 | Cache backend | deferred | GitHub Actions cache first when optimization resumes. |
| META-7 | Final tooling name | deferred | Naming does not block owner/repo configurability or script cleanup. |
| META-8 | CLI distribution channels | deferred | Docker/direct docs first if a CLI ships; pipx/brew/apt later. |
| META-9 | Module-IR scope | deferred | Magisk-first if converter work becomes real. |
| META-10 | Manifest signing model | deferred | Trigger when manifests exist. |
| META-11 | Self-hosted runner threat boundary | deferred | Trigger when self-hosted runner runbook starts. |
| META-12 | Publish `docs/planning/`? | deferred | Planning stays local-only unless maintainer requests a curated public roadmap. |

## Picking a ticket

1. Start with the Now lane.
2. If Now is blocked, use Next.
3. Do not pick Later/Icebox unless the maintainer explicitly asks.
4. At the end of every ticket, update docs by default per `PROCESS.md`.
