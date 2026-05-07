# META-7 — Final tooling name (replaces `patcher-cli`)

## Goal

Pick the final name for the CLI / project rebrand. Working placeholder is `patcher-cli`.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-tooling-name.md` records: chosen name, namespace availability check (PyPI, GitHub org, Docker Hub, brew tap if applicable), domain availability if a website is planned.
- Cross-references META-2 (rebrand target).

## Depends

- COMPAT-1 (the audit tells us which name-strings, if any, are user-pinned and therefore constrain what "renaming" actually costs)

## Hard prerequisites

- COMPAT-1's identifier inventory has been read; the chosen name has been checked against every user-pinned identifier so we know which mitigations the rebrand needs.

## Trigger condition

Open when the maintainer has at least 2–3 candidate names + a check on namespace availability.
