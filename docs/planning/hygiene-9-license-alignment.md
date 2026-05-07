# HYGIENE-9 — Root license and README alignment

Scope: root license/README wording only. No source headers were changed in this ticket.

Policy citation: ADR-0003 (`docs/planning/decisions/ADR-0003-license-agpl.md`) resolves new project-authored PixeneOS code as `AGPL-3.0-or-later`, while third-party-derived code keeps upstream licenses and notices.

## Changes made

- Replaced the root `LICENSE` MIT text with:
  - a PixeneOS licensing notice that points to ADR-0003;
  - explicit wording that new project-authored code is `AGPL-3.0-or-later`;
  - explicit wording that third-party-derived code, docs, release artifacts, modules, tools, downloaded components, and separately-noticed snippets retain their upstream licenses;
  - a preserved historical note for the old MIT-oriented root wording: `Copyright (c) 2024 Pa1NarK`;
  - the full GNU Affero General Public License version 3 text.
- Updated the README `## License` section to remove the MIT project-license statement and mirror the ADR-0003/root-`LICENSE` policy.

## Historical-notice handling

The old root `LICENSE` text was not silently erased: the previous MIT-oriented wording and `Copyright (c) 2024 Pa1NarK` notice are now recorded in the root `LICENSE` provenance paragraph and summarized in README license wording.

## Acceptance check

- Root `LICENSE` and README license wording reviewed against ADR-0003: done.
- Changed wording states new project-authored code is `AGPL-3.0-or-later`: done.
- Changed wording states third-party-derived material retains upstream licenses/notices: done.
- Existing historical MIT/copyright notice preserved with rationale: done.
- Source headers changed by this ticket: none.
