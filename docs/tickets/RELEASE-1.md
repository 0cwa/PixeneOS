# RELEASE-1 — Decouple generated update URLs from hard-coded GitHub releases

## Goal

`src/util_functions.sh` constructs Custota/update metadata URLs using `${DOMAIN}/${USER}/${REPOSITORY}/releases/download/...`. That couples generated update metadata to a specific GitHub owner/repository and makes future rebrand or alternate hosting harder.

Plan the URL-source boundary and then, in a later implementation ticket, make generated update URLs configurable without breaking existing GitHub Releases publishing.

## Acceptance

- `docs/planning/release-url-decoupling.md` documents:
  - every place that constructs or consumes a release/update URL;
  - the current generated URL shape;
  - which URLs are embedded in published artifacts/update metadata;
  - proposed config keys for release base URL / owner / repository / asset path;
  - backwards-compatible defaults for GitHub Actions and local runs;
  - migration risks for existing Custota clients.
- The plan states whether this should be implemented before or after META-7's final tooling name decision.
- The plan includes a test strategy for generated update metadata.

## Depends

- REBRAND-1

## Notes

Known starting points:

- `src/util_functions.sh` constructs `location_path="${DOMAIN}/${USER}/${REPOSITORY}/releases/download/${VERSION[GRAPHENEOS]}/${OUTPUTS[PATCHED_OTA]}"`.
- `docs/planning/declarations-audit.md` flags `USER`, `REPOSITORY`, and `OUTPUTS[PATCHED_OTA]` as user-facing or artifact-visible.
- This is related to but narrower than the full project rebrand: hosting URLs can be made configurable before choosing a final tool name.

## Out of scope

- Changing the release workflow implementation.
- Moving releases off GitHub.
- Rewriting Custota metadata format.
- Renaming the project or CLI.

## Implementation sketch

1. Read `docs/planning/declarations-audit.md` and the REBRAND-1 output.
2. Grep for `releases/download`, `location_path`, `generate_update_info`, `OUTPUTS[PATCHED_OTA]`, `USER`, and `REPOSITORY`.
3. Write the decoupling plan and a follow-up implementation ticket if appropriate.
