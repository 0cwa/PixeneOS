# ADR-0003 — License new project code under AGPL-3.0-or-later

- **Status:** accepted
- **Date:** 2025-05-06
- **Deciders:** maintainer
- **Related tickets:** META-1, HYGIENE-3, ADBDEBUG-2

## Context

The project lacks a uniform SPDX header policy. Different files have inherited different license posture from upstreams. Before rolling out a project-wide header pass (HYGIENE-3) or stamping the ADB-debug files (ADBDEBUG-2), we need a definitive license choice for *new code that the maintainer adds*.

Constraints:

- Some files in this tree are derived from third-party projects (notably `chenxiaolong/my-avbroot-setup` which is GPL-3.0). Those carry their original license and copyright; we cannot unilaterally relicense them.
- The project may eventually run as a self-hostable service (CI runner, update server). A copyleft license that closes the network-service loophole is desirable.
- The project's working environment (Magisk, KernelSU, avbroot, Custota) is dominated by GPL-3.0; AGPL-3.0 is bidirectionally compatible with GPL-3.0 for combined works under the AGPL terms.

## Decision

**New code authored for this project is licensed under `AGPL-3.0-or-later`.** Pre-existing third-party code retains its original license. The SPDX rollout (HYGIENE-3) treats files in three buckets:

1. **New maintainer-authored files** → `# SPDX-License-Identifier: AGPL-3.0-or-later` plus a copyright line.
2. **Files derived from a third-party project** → keep the upstream's `SPDX-License-Identifier` exactly as it was; supplement with a `# Modifications: Copyright (C) <year> <maintainer>, AGPL-3.0-or-later` line *only if* the upstream license permits dual/combined declaration (GPL-3.0 does; check any other case individually). When in doubt, leave the original alone.
3. **Trivial / generated files** (e.g. `.prettierrc.json`, `.gitignore`) → no header. Header policy applies only to source files where it would be parseable.

A repo-root `LICENSE` file declares the project license. A `LICENSES/` directory tracks any third-party licenses we ship verbatim (added as needed).

## Consequences

- **Easier:** clear, mechanisable rule for HYGIENE-3 and ADBDEBUG-2; bucket 1 is a one-line stamp; bucket 2 is "leave alone or supplement carefully".
- **Easier:** AGPL signals that future hosted variants (a Custota-server fork, a CI dashboard) cannot be made proprietary without source disclosure.
- **Harder:** anyone integrating the code into a hosted service must publish their modifications. This is intentional.
- **Risk:** AGPL is sometimes flagged by corporate policies. We accept this — the project's audience is end users and self-hosters, not redistributors building closed services on top.
- **Risk:** mis-stamping a derivative file. Mitigation: HYGIENE-3 plan must include a `git log --follow` provenance check per file before stamping bucket-1 vs bucket-2.

## Alternatives considered

- **GPL-3.0-or-later.** Considered. Rejected because it does not cover hosted-service use, and the project's plausible self-hosted-service futures (Custota-server clone, dashboard) would benefit from copyleft.
- **MIT / Apache-2.0.** Rejected. Permissive licensing does not protect downstream users from a closed hosted variant; conflicts with the project's user-respect ethos.
- **Mixed: tooling AGPL, modules MIT.** Rejected for now as needless complexity. The CLI and the conversion tooling are one project; one license keeps SPDX rollout simple.

## Notes

- Existing `LICENSE` at repo root: confirm what it currently says. If it conflicts with AGPL-3.0-or-later for new code, that's a rollout substep — replace at the right moment, do not touch in this planning session.
- META-1 closes once HYGIENE-3 has consumed this ADR.
- The phrasing "**or later**" is deliberate — it lets the project absorb future FSF revisions without per-file edits.
