# Gap Analysis / Risk Register

This file is a memory aid, not the active work queue. The planning system was reoriented so gaps become tickets only when they are concrete, near-term, and actionable. Otherwise they stay here as Later/Icebox context.

Default process: small implementation slice → validate → document at the end. See `docs/tickets/PROCESS.md` and `docs/tickets/INDEX.md`.


## Missing dimensions (17)

1. ~~**License + copyright provenance.**~~ Existing source has mixed/missing SPDX. Needs a project-wide policy *before* any rebrand or upstream-PR push. → **resolved**: META-1 closed, ADR-0003 records `AGPL-3.0-or-later` for new code; rollout planned by HYGIENE-3 + ADBDEBUG-2 and implementation follow-ups HYGIENE-7/8/9. 2026-05-06.
2. ~~**Reproducibility of patched OTAs.**~~ No current mechanism to verify that two builds of the same source on different machines produce the same OTA bytes. Out of scope for v1, but the matrix should at least record toolchain versions. → promoted to MATRIX-5 for the reproducibility baseline; byte-for-byte reproducibility remains deferred.
3. **Key custody story for laypeople.** Threat-model scenario A is the default but undocumented. → META-10/11, INFRA-3.
4. **OTA download caching.** Re-downloading multi-GB OEM OTAs every CI run is wasteful. → BUILDOPT-2.
5. **Failure-mode taxonomy.** What happens when avbroot fails midway? Which states are recoverable? → CLI-1 ergonomics.
6. ~~**Telemetry / privacy.**~~ No telemetry today; document this explicitly so users trust it stays absent. → promoted to DOCS-1.
7. ~~**Secrets scanning.**~~ Pre-commit hook exists (`src/hooks/pre-commit`) but scope unverified. → promoted to HYGIENE-11.
8. ~~**Renovate config drift.**~~ Renovate branch is stale; config probably needs refresh. → promoted to HYGIENE-12.
9. **Pre-commit hook portability.** Currently bash; works for maintainer; layperson self-host on Windows/macOS may diverge. → CLI-3 distribution discussion.
10. ~~**Test surface.**~~ No unit / integration tests visible. Patcher correctness depends on `avbroot` itself + integration with real OTAs. Need at least a smoke test per device. → promoted to MATRIX-4.
11. **Disk-space budgets.** Lineage OTA alone is 1.2 GB. CI runners need explicit budget; self-hosted runner sizing matters. → INFRA-1.
12. **Network egress allowlist.** Self-hosted runner needs to reach exactly: Google OTA mirrors, Lineage OTA mirrors, GitHub releases, Custota host. Document. → INFRA-1.
13. ~~**Backwards-compat for existing users.**~~ Users running today's `0cwa/PixeneOS` build expect Custota to keep finding their device. Any rename or path change breaks update flow. → promoted to **COMPAT-1** (blocks META-2 + META-7). 2025-05-06.
14. **Multi-arch.** All current devices are arm64; not a gap today, but the matrix abstraction should not assume it. → MATRIX-1 schema note.
15. **Documentation surface.** `README.md` is GrapheneOS-centric; FAQ exists. Both need updating after MATRIX + CLI land. Not first wave.
16. **Module-conversion legal posture.** Converting third-party Magisk modules touches authors' licenses. → MODCONV-1 must include license-survey step.
17. **Public roadmap publication.** Should this `docs/planning/` ever become public, or stay local? → META-12.

## META notes after simplification

The old META ladder is no longer a dependency ladder. META files remain as decision notes that trigger only when an implementation step truly needs maintainer ratification. Safe defaults in `docs/tickets/PROCESS.md` cover reversible choices such as TOML matrix format, default-private new artifacts, GitHub-cache-first optimization, and local-only planning docs.

## How this file evolves

- When a gap becomes concrete near-term work, convert it into a ticket or fold it into an existing ticket's end-of-ticket documentation.
- If a gap is merely interesting, leave it here; do not create a ticket just to remember it.
- New gaps surfaced during work: append; do not edit-in-place upstream items.
