# PixeneOS Planning

Local-only planning workspace. Excluded from git via `.git/info/exclude` (`docs/**` with `!docs/FAQ.md` re-include). Nothing in this directory is assumed to be upstream/public unless the maintainer explicitly says so.

## Current planning posture

This workspace has been reoriented from a broad phase/META-gate roadmap to a simpler execution process:

1. pick a small Now/Next ticket;
2. make the focused change;
3. validate it;
4. update documentation at the end;
5. create follow-ups only for concrete remaining work.

See:

- `docs/tickets/PROCESS.md` — process and Definition of Done;
- `docs/tickets/INDEX.md` — current Now/Next/Later/Icebox lanes;
- `docs/planning/roadmap.md` — simplified roadmap and safe defaults.

## Layout

```
docs/planning/
├── README.md                        # this file
├── roadmap.md                       # simplified execution view + safe defaults
├── branching-model.md               # branch topology + how main stays active
├── threat-model.md                  # security model (keys, OTA trust, build env)
├── glossary.md                      # AVB, csig, custota, sepolicy, preinit, etc.
├── gaps.md                          # risk register / icebox, not active queue
└── decisions/
    ├── ADR-template.md
    ├── ADR-0001-keep-active-main.md
    └── ADR-0002-compatible-fork-of-my-avbroot-setup.md

docs/tickets/
├── PROCESS.md                       # ticket process + default Definition of Done
├── INDEX.md                         # ticket registry: lanes, status, deps/triggers
├── HYGIENE-*.md                     # repo hygiene
├── ADBDEBUG-*.md                    # ADB debug module
├── ROMCOMPAT-*.md                   # LineageOS / multi-ROM compatibility
├── MATRIX-*.md                      # device/flavor build matrix
├── BUILDOPT-*.md                    # build performance + caching
├── CLI-*.md                         # future CLI surface
├── MODCONV-*.md                     # future module conversion
├── INFRA-*.md                       # future CI / self-hosted runners
└── META-*.md                        # trigger-only decision notes
```

## Conventions

- One markdown file per ticket. Filename = ticket id.
- Status lives only in `INDEX.md` to avoid drift.
- Ticket files describe goals, acceptance, constraints, and end-of-ticket documentation expectations.
- META tickets are no longer general blockers; they are used only when a real implementation step needs maintainer ratification.
- ADRs live under `decisions/`. New ADRs use `ADR-NNNN-kebab-title.md`.

## Working rules

- Before new work, run `git status --short --ignored=matching`.
- Read the relevant ticket file before editing.
- Check acceptance before marking a ticket done in `docs/tickets/INDEX.md`.
- Keep `main` shippable and avoid broad churn.
- Do not rewrite release assets, `gh-pages`, or stale remote branches without explicit maintainer approval.
- Keep licensing/provenance wording conservative; do not relicense third-party-derived code.
- Documentation is part of ticket completion by default, but large planning docs are not required unless the ticket needs them.

## Entry points

- New here? Read `docs/tickets/PROCESS.md`, then `docs/tickets/INDEX.md`, then `roadmap.md`.
- Ready to work? Pick from the Now lane first.
- If Now is blocked, pick from Next.
- Do not pick Later/Icebox unless the maintainer explicitly asks.
