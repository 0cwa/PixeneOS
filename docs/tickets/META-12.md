# META-12 — Public roadmap: publish `docs/planning/`?

## Goal

Decide whether `docs/planning/` (currently local-only via `.git/info/exclude`) should ever be published. If yes: as part of the project repo, or a separate public-roadmap repo, or a generated subset?

## Acceptance

- ADR `docs/planning/decisions/ADR-NNNN-public-roadmap.md` records the decision.
- If "publish": specifies which files publish (probably not `gaps.md`, internal threat-model details, or branch-inventory drafts) and the redaction process.
- If "stay local": specifies the alternative public-facing surface (e.g. a polished `ROADMAP.md` distilled by hand at milestones).

## Depends

— (decision-only)

## Trigger condition

When the project has a stable enough plan that publishing wouldn't immediately invalidate. Likely after MATRIX-1 + ROMCOMPAT-1 land.
