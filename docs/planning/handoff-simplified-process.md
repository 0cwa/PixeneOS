# Handoff prompt — PixeneOS clean-history / upstream PR reorientation

Use this prompt for the next agent/session.

```text
You are taking over PixeneOS planning/hygiene work, now reoriented toward clean history and upstream-friendly pull requests before further feature work.

Working directory: /home/x/tmp/PixeneOS. Do not cd to an absolute path.

Before new work:
- Run: git status --short --ignored=matching
- Read docs/tickets/PROCESS.md and docs/tickets/INDEX.md.
- Read docs/planning/upstream-pr-clean-history.md.
- Read the specific ticket file before editing.
- Check acceptance before marking done in docs/tickets/INDEX.md.

Local-only context:
- docs/planning/ is ignored via .git/info/exclude.
- docs/tickets/ also appears ignored/local-only in this checkout.
- Do not assume ignored docs are intended for upstream commit unless the user says so.

Important licensing caution:
- Do not relicense someone else's code.
- ADR-0003 says new project-authored PixeneOS code is AGPL-3.0-or-later, but third-party-derived code retains upstream license/copyright.
- If provenance is uncertain, do not add or strengthen AGPL claims; document uncertainty and create/flag a concrete follow-up.
- HYGIENE-9 changed root LICENSE/README wording to include AGPLv3 text plus explicit third-party/historical-notice caveats. Treat this as legally sensitive and keep wording conservative.
- For upstream PR branches, do NOT include root LICENSE changes, broad SPDX/copyright header churn, or local planning docs unless explicitly requested.

Current process:
- Small focused change → validate → document at the end → create follow-ups only for concrete remaining work.
- Documentation is part of the default Definition of Done for each ticket.
- META tickets are trigger-only decision notes unless a real implementation step needs maintainer ratification.
- Safe defaults apply unless the maintainer challenges them.

Recently completed local implementation/planning in the mixed working tree:
- HYGIENE-13 — Supplement secrets scanning beyond .keys/.
- ADBDEBUG-3 — Gate debug artifact publishing and labeling.
- REBRAND-1 — Make release owner/repository identifiers configurable.
- UPSTREAM-1 — Split current work into upstream PR candidates and fork-local work. Output: docs/planning/upstream-pr-branch-split.md.
- UPSTREAM-2 — Clean upstream branch prepared: upstream/configurable-release-repository in ../PixeneOS-upstream-2, commit 2260aa3.
- UPSTREAM-3 — Clean upstream branch prepared: upstream/renovate-manager-file-patterns in ../PixeneOS-upstream-3, commit 17ff784.
- UPSTREAM-4 — Clean upstream branch prepared: upstream/ignore-python-local-artifacts in ../PixeneOS-upstream-4, commit 2ba3c97.

Important current repository state:
- The working tree is dirty with several completed ticket changes mixed together.
- Do not push this mixed tree as-is.
- Do not create one catch-all commit.
- Current checkout now has origin=https://github.com/0cwa/PixeneOS.git and upstream fetch=https://github.com/pixincreate/PixeneOS.git; upstream push URL is DISABLED to avoid accidental direct pushes. Re-fetch and verify upstream/main before cutting each upstream PR branch.

Current active lanes:

Now:
- UPSTREAM-2, UPSTREAM-3, and UPSTREAM-4 are done locally as clean upstream PR branches/worktrees. Review/push/open those branches as separate PRs if desired; do not squash them into the mixed main working tree.

Next — pick from here first:
1. RELEASE-1 — Decouple generated update URLs from hard-coded GitHub releases.
   - Can be planned in parallel after branch splitting is safe.
   - Keep separate from upstream PR prep branches.
2. ROMCOMPAT-1 / META-3 — Analyze and ratify my-avbroot-setup@91e49bc hunks before downstream ROM work.
3. MATRIX-1 — Minimal TOML device matrix with privacy/version/smoke placeholders folded into one thin slice.

Deferred/Later/Icebox:
- DOCS-1 standalone privacy note.
- BUILDOPT-1..3 until ROM partition needs are known.
- CLI-1..3 until a CLI is near-term.
- MODCONV-1..3 until converter implementation is near-term.
- INFRA-1..3 until self-hosting is requested.
- Most META tickets unless their trigger condition becomes real.

Suggested upstream PR candidates and exclusions:
- Best candidate: configurable release owner/repository.
  - Scope likely: src/declarations.sh, src/util_functions.sh, maybe release workflow git author-name lines.
  - Must preserve upstream's existing behavior by default.
- Small candidate: Renovate fileMatch -> managerFilePatterns.
  - Scope only .github/renovate.json5.
- Optional candidate: Python/local artifact .gitignore.
  - Scope only .ruff_cache/, __pycache__/, *.py[cod].
- Keep separate / likely not upstream as-is:
  - LICENSE and broad license wording changes.
  - SPDX/copyright header rollout.
  - HYGIENE-13 secrets scanner and key path changes unless proposed as a separate security PR.
  - ADBDEBUG-3 debug artifact guardrails unless upstream has the same debug-ADB workflow need.
  - docs/planning/ and docs/tickets/ local docs.

Current working tree status at this handoff:
- Modified tracked files include:
  - .github/renovate.json5
  - .github/workflows/release.yml
  - .github/workflows/release-lineage.yml
  - .gitignore
  - LICENSE
  - README.md
  - src/debug_module_setup.sh
  - src/debugmod.py
  - src/declarations.sh
  - src/exchange.sh
  - src/fetcher.sh
  - src/hooks/pre-commit
  - src/logger.sh
  - src/main.sh
  - src/setup_hooks.sh
  - src/util_functions.sh
  - src/verifier.sh
- Untracked files include:
  - .github/workflows/secrets-scan.yml
  - .gitleaks.toml
  - src/scan_secrets.sh
- Ignored/local files include .pi/*, .ruff_cache/, docs/planning/, and docs/tickets/.

Important cautions:
- Do not start HYGIENE-10 remote archive/delete operations without explicit maintainer approval.
- Do not rewrite release assets, gh-pages, or stale remote branches without maintainer approval.
- Treat docs/planning/ and docs/tickets/ as local planning unless the maintainer says otherwise.
```
