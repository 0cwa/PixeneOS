# HYGIENE-8 — Apply remaining source SPDX headers after provenance checks

## Goal

Implement the core-source SPDX rollout planned by HYGIENE-3 after the ADB-debug canary lands. Add headers only after per-file provenance checks confirm the file is project-authored or otherwise safe to stamp.

## Acceptance

- A local or PR note records `git log --follow -- <file>` provenance for every touched file.
- AGPL SPDX/copyright headers are added to eligible remaining source files from `docs/planning/spdx-rollout.md`, including shell scripts under `src/**` and `src/hooks/pre-commit`, while preserving shebang line 1 where present.
- Any file with unclear or third-party provenance is left untouched and called out for follow-up.
- Syntax checks pass for touched shell files, at minimum `bash -n`.
- ADB-debug files are not duplicated here if HYGIENE-7 already handled them.

## Depends

- HYGIENE-7
- HYGIENE-3
- META-1

## Notes

Follow `docs/planning/spdx-rollout.md` exactly. Prefer a small scoped PR over a whole-repo churn patch.

## Out of scope

- Workflow/config headers.
- Root `LICENSE` / README license wording alignment.
- Relicensing third-party-derived files.
