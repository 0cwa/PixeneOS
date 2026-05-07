# REBRAND-1 — Make release owner/repository identifiers configurable

## Goal

`src/declarations.sh` currently hard-codes `USER="0cwa"` and `REPOSITORY="PixeneOS"`. Those values flow into generated release URLs and can leak maintainer identity into downstream outputs.

Make the owner/repository values configurable with the smallest safe change. Do **not** solve the full project rename, final CLI name, repository migration, or release-history migration here.

## Acceptance

- Every current use of `USER`, `REPOSITORY`, and generated GitHub release URLs is checked before editing.
- A minimal precedence order is implemented or documented, preferably:
  1. explicit PixeneOS-specific env/config value;
  2. GitHub Actions context when running in CI;
  3. existing safe default for backwards compatibility.
- Avoid relying on generic shell `USER` as a project owner variable; use a PixeneOS-specific name for any new override.
- Existing release URL behavior remains backwards-compatible unless the maintainer explicitly approves a migration.
- `MAGISK[REPOSITORY]="topjohnwu/Magisk"` is preserved unless a separate dependency-source decision changes it.
- End-of-ticket docs are updated with the final behavior and validation, either in public docs if authorized or in `docs/planning/rebrand-config-boundaries.md`.

## Depends

- HYGIENE-4
- COMPAT-1

## Notes

- `USER="0cwa"` was flagged in HYGIENE-4 as a `make-configurable` value.
- `REPOSITORY="PixeneOS"` was flagged as a `rename-to-tool-name` value.
- Avoid choosing the final product name here; naming is deferred until it is a real release concern.

## Output

Implemented in this slice:

- `src/declarations.sh` no longer defines generic `USER` / `REPOSITORY` as PixeneOS release owner values.
- Added PixeneOS-specific release URL variables:
  - `PIXENEOS_RELEASE_OWNER`
  - `PIXENEOS_RELEASE_REPOSITORY`
- Added `resolve_release_repository` with precedence:
  1. explicit PixeneOS-specific env/config values;
  2. `GITHUB_REPOSITORY=owner/repo` when running in GitHub Actions or equivalent CI;
  3. backwards-compatible defaults `0cwa/PixeneOS`.
- Updated generated OTA release URL construction to use the resolved PixeneOS-specific owner/repository.
- Preserved `MAGISK[REPOSITORY]="topjohnwu/Magisk"`.
- Updated release workflow git author names from hard-coded `0cwa` to `${{ github.repository_owner }}`.

Validation and checked surfaces are recorded in `docs/planning/rebrand-config-boundaries.md`:

- shell syntax checks for touched shell files;
- YAML parse checks for both release workflows;
- default, GitHub context, and explicit override resolution checks;
- generated update URL substitution check with explicit override;
- grep check for old generic release owner variables and generated release URL construction.

## Out of scope

- Picking the final CLI/tool name.
- Renaming the repository.
- Editing release history or published artifacts.
- Changing Magisk source repositories.
- Designing a full CLI/config schema.

## Implementation sketch

1. Read `docs/planning/declarations-audit.md` and `docs/planning/downstream-compat-audit.md`.
2. Grep for `USER`, `REPOSITORY`, `get_package_url`, and GitHub release URL construction.
3. Implement the smallest owner/repository override surface that preserves current defaults.
4. Validate with default values and at least one explicit override.
5. Document the final behavior at the end of the ticket.
