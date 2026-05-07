# RELEASE-2 — Implement `PIXENEOS_RELEASE_BASE_URL` and fix `my-avbroot-setup` source URL

## Goal

Implement the Level 1 and Level 2 changes specified in `docs/planning/release-url-decoupling.md`:

1. Add `PIXENEOS_RELEASE_BASE_URL` to allow the full OTA download URL prefix to be overridden without changing the default GitHub Releases behaviour.
2. Optionally: introduce `PIXENEOS_AVBROOT_SETUP_SOURCE` to remove the hard-coded `0cwa` reference from the `my-avbroot-setup` tool clone URL in `url_constructor()`.

## Acceptance

- `src/declarations.sh` declares `PIXENEOS_RELEASE_BASE_URL="${PIXENEOS_RELEASE_BASE_URL:-}"`.
- `my_avbroot_setup()` in `src/util_functions.sh` uses `PIXENEOS_RELEASE_BASE_URL` when set:
  - if set: `location_path="${PIXENEOS_RELEASE_BASE_URL}/${OUTPUTS[PATCHED_OTA]}"`
  - if empty: existing behaviour unchanged (`${DOMAIN}/${PIXENEOS_RELEASE_OWNER}/${PIXENEOS_RELEASE_REPOSITORY}/releases/download/${VERSION[GRAPHENEOS]}/${OUTPUTS[PATCHED_OTA]}`)
- `bash -n src/declarations.sh src/util_functions.sh` passes with no errors.
- Shell unit tests (inline or in a test script) cover:
  - no-override path produces the same URL as before;
  - override path uses `PIXENEOS_RELEASE_BASE_URL` as the prefix.
- `README.md` updated if the variable is user-facing (at minimum document it in the env-var reference section).
- Optional: `url_constructor()` uses `PIXENEOS_AVBROOT_SETUP_SOURCE` as the `my-avbroot-setup` clone URL when set, falling back to `${DOMAIN}/0cwa/my-avbroot-setup`.

## Depends

- RELEASE-1

## Implementation sketch

1. Read `docs/planning/release-url-decoupling.md` for full context before editing.
2. Add variable to `src/declarations.sh` (single line).
3. Modify `my_avbroot_setup()` in `src/util_functions.sh` (~5 lines).
4. Optionally add `PIXENEOS_AVBROOT_SETUP_SOURCE` and update `url_constructor()` (~3 lines).
5. Run `bash -n` checks and the shell test cases from the planning doc.
6. Update `README.md` env-var reference.

## Completion notes

Implemented:

- `PIXENEOS_RELEASE_BASE_URL` for generated Custota OTA download metadata.
- `PIXENEOS_AVBROOT_SETUP_SOURCE` for overriding the `my-avbroot-setup` clone URL.
- Focused shell regression coverage in `tests/release_url_config_test.sh`.
- README documentation for the new environment variables.

Validation:

```shell
bash -n src/declarations.sh && bash -n src/util_functions.sh && bash -n tests/release_url_config_test.sh
bash tests/release_url_config_test.sh
```

## Out of scope

- Changing the gh-pages serving URL or GitHub Pages configuration.
- Moving releases off GitHub Releases.
- Rewriting the artifact filename structure.
- Any Custota metadata format changes.
- Renaming the project (META-7).
