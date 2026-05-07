# UPSTREAM-1 — Split current work into upstream PR candidates and fork-local work

## Goal

Stop feature work long enough to turn the mixed working tree into a clean upstream-PR plan and local integration plan.

## Acceptance

- The real upstream remote/base is identified, or a blocking maintainer question is recorded if it is unknown.
- Current modified/untracked files are bucketed into:
  - upstream PR candidate branches;
  - fork-local/local-only changes;
  - legally sensitive changes that should not be proposed upstream without maintainer/legal review.
- A branch/commit order is written down, starting with:
  1. configurable release owner/repository;
  2. Renovate `managerFilePatterns` compatibility if applicable;
  3. Python/local artifact `.gitignore` housekeeping if applicable.
- The plan explicitly says not to open upstream PRs containing SPDX/license header churn, root `LICENSE` relicensing, debug-ADB guardrails, secrets-scanner work, or local planning docs unless separately approved.
- No mixed catch-all commit is created.

## Depends

- REBRAND-1

## Notes

Planning source: `docs/planning/upstream-pr-clean-history.md`.

Current checkout has only `origin=https://github.com/0cwa/PixeneOS.git`; verify the actual upstream before creating PR branches.

## Out of scope

- Rewriting remote history.
- Force-pushing branches.
- Opening PRs before branch contents are reviewed.
