# PixeneOS Roadmap — simplified execution view

This file is now a lightweight execution guide. The older phase/gap planning remains useful as context, but the project should not treat every future idea as an active blocker.

Current process: small implementation slice → validate → document at the end. See `docs/tickets/PROCESS.md`.

## Guiding constraints

- `main` is actively used by the maintainer and downstream — never rewrite it and keep it shippable.
- Licensing/provenance remains sensitive: new project-authored PixeneOS code follows ADR-0003, while third-party-derived code keeps upstream license/copyright.
- Signing keys, secret material, release assets, `gh-pages`, and remote branches are sensitive; destructive remote operations need explicit maintainer approval.
- Debug/unauthorized-ADB builds must be opt-in and unmistakably labeled.
- Existing update/release URLs must not be broken accidentally.
- Planning docs are local-only unless the maintainer asks for a curated public roadmap.

## Active execution lanes

### Now — clean history and upstream PR prep

The current working tree has several completed local tickets mixed together. Do not push or open PRs from it as-is.

1. **UPSTREAM-1 — Split current work into upstream PR candidates and fork-local work.** Identify the real upstream base, bucket the dirty tree, and write the branch order.
2. **UPSTREAM-2 — Configurable release owner/repository PR.** Best upstream candidate; cut this cleanly before more feature work touches release URL files.
3. **UPSTREAM-3 — Renovate `managerFilePatterns` PR.** Tiny maintenance PR if still applicable upstream.
4. **UPSTREAM-4 — Python/local artifact ignore PR.** Optional housekeeping PR; keep key-file ignores separate.

### Next — release URL, Lineage, and matrix foundation

1. **RELEASE-1 — Generated update URL cleanup.** Can be planned in parallel once branch splitting is safe; do not mix it into upstream PR prep branches.
2. **ROMCOMPAT-1 — Hunk disposition for `my-avbroot-setup@91e49bc`.** Analyze first; maintainer ratifies upstream-vs-fork choices afterward.
3. **MATRIX-1 — Minimal TOML device matrix.** Use TOML by default and fold privacy/version/smoke placeholders into one thin matrix slice.
4. **ROMCOMPAT-2/3 — Minimal ROM/device capability config and Lineage validation.** Run after ROMCOMPAT-1 clarifies what Lineage actually needs.

### Later — optimization and polish

- Selective `avbroot ota extract --partition` after ROM partition needs are known.
- Cache and parallelism after correctness and matrix shape are stable.
- Workflow consolidation after the TOML matrix proves useful.
- CLI surface/distribution after current scripts/configuration settle.
- Public privacy/no-telemetry wording during an authorized public-doc pass.

### Icebox — future product lines

- Module conversion and manifest format/signing.
- Self-hosted runner hardening, Forgejo/Gitea parity, and advanced key-custody runbooks.
- SLSA/reproducible-build attestations.
- Web UI/dashboard.

## Safe defaults

These defaults replace several former META blockers unless the maintainer explicitly challenges them:

| Area | Default |
|---|---|
| Matrix file format | TOML |
| New artifact rows | private by default; preserve existing public compatibility explicitly |
| Cache backend | GitHub Actions cache first, later if needed |
| CLI/tool name | defer; do not block config/script work |
| CLI distribution | Docker/direct docs first if a CLI appears; pipx/brew/apt later |
| Module conversion | Magisk-first if work begins; KernelSU/APatch later |
| Manifest signing | defer until manifests exist |
| Self-hosted runner threat model | defer until self-hosting is requested |
| Planning publication | local-only unless curated by maintainer |

## Current build matrix context

| Device codename | ROM(s) | Source | Notes |
|---|---|---|---|
| XQ-DC72 | GrapheneOS | `gh-pages` | Existing public/update compatibility must be preserved unless explicitly changed. |
| barbet | GrapheneOS | `gh-pages` | Pinned to old `barbet-2024101200`. |
| bluejay | GrapheneOS | `gh-pages` | Existing public/update compatibility must be preserved unless explicitly changed. |
| bramble | GrapheneOS | `gh-pages` | Existing public/update compatibility must be preserved unless explicitly changed. |
| caiman | GrapheneOS | `gh-pages` | Existing public/update compatibility must be preserved unless explicitly changed. |
| shiba | GrapheneOS | `gh-pages` | Existing public/update compatibility must be preserved unless explicitly changed. |
| pdx235 | LineageOS 23 | local/private | Treat as private/manual until explicitly published. |

## What changed from the old roadmap

- The 7-phase plan is now a context map, not the active queue.
- META tickets are trigger-only decision notes, not a dependency ladder.
- Several planning-only tickets were deferred or collapsed into end-of-ticket documentation.
- Active work should prioritize release safety and Lineage/matrix foundations over optimization, CLI productization, module conversion, and self-hosted infra.
