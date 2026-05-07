# META-1 — SPDX/license header policy

## Status

**Resolved.** Decision recorded in `docs/planning/decisions/ADR-0003-license-agpl.md` (2025-05-06): `AGPL-3.0-or-later` for new maintainer-authored code; third-party-derived files keep their original license. HYGIENE-3 and ADBDEBUG-2 are unblocked.

## Goal (historical)

Decide the project's license-header policy: which SPDX identifier, which file types get a header, and how third-party-derived files are treated.

## Acceptance (met)

- ✅ ADR-0003 records the decision: `AGPL-3.0-or-later` for new code.
- ✅ Header format per language + bucket rules (new / derivative / trivial) specified in ADR-0003.
- ✅ HYGIENE-3 and ADBDEBUG-2 unblocked.

## Depends

— (decision-only; resolved)

## Follow-up

- HYGIENE-3 must include a `git log --follow` provenance pass to bucket files correctly before any header is stamped.
- Confirm root `LICENSE` file aligns with ADR-0003 (replacement, if needed, is a HYGIENE-3 substep, not this ticket).
