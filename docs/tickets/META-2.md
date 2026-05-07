# META-2 — Is rebranding `main` (vs fresh repo) acceptable later?

## Goal

Decide whether the eventual rebrand (META-7) happens in-place on this repo, or via a new repo with redirect tags.

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-rebrand-target.md` records the choice and the migration plan for downstream Custota update flows.
- If "fresh repo" is chosen: the migration plan covers tag mirroring + a redirect README on the old repo.
- If "in-place" is chosen: ADR-0001 is referenced (history is preserved; no force-push).

## Depends

- COMPAT-1 (downstream backwards-compat audit must be complete before this gate can be evaluated honestly)

## Hard prerequisites

- The pre-rebrand checklist from COMPAT-1 is referenced in the ADR and every item is either resolved or has an explicit deferred-with-mitigation entry.

## Trigger condition

Once META-7 has a candidate tooling name and the rebrand becomes a real PR target.
