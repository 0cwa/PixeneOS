# REBRAND-1 — release owner/repository configurability

Implemented a minimal owner/repository override for generated GitHub release URLs without choosing a final project name or moving any published paths.

## Checked surfaces

Checked current uses of the old generic owner/repository variables and release URL construction:

- `src/declarations.sh`
  - removed the hard-coded `USER="0cwa"` / `REPOSITORY="PixeneOS"` release-owner defaults;
  - added PixeneOS-specific placeholders `PIXENEOS_RELEASE_OWNER` and `PIXENEOS_RELEASE_REPOSITORY`.
- `src/util_functions.sh`
  - `my_avbroot_setup` constructs the generated OTA release URL that is embedded into update metadata;
  - `resolve_release_repository` now resolves the owner/repository before that URL is generated.
- `.github/workflows/release.yml` and `.github/workflows/release-lineage.yml`
  - release-existence API checks already use `${{ github.repository }}`;
  - Git commit author name no longer hard-codes `0cwa`; it uses `${{ github.repository_owner }}`.
- `MAGISK[REPOSITORY]="topjohnwu/Magisk"` was preserved.
- `src/util_functions.sh` still has `URL="${DOMAIN}/0cwa/${repository}"` for the `my-avbroot-setup` dependency source. That is not the generated OTA release URL and was left unchanged in this slice to avoid broad dependency-source migration.
- README and compatibility docs still mention existing public URLs. Those are user-pinned compatibility surfaces and were not changed here.

## Precedence

Generated PixeneOS OTA release URLs now resolve owner/repository in this order:

1. explicit PixeneOS-specific values:
   - `PIXENEOS_RELEASE_OWNER`
   - `PIXENEOS_RELEASE_REPOSITORY`
2. GitHub Actions context via `GITHUB_REPOSITORY=owner/repo`;
3. backwards-compatible defaults:
   - owner: `0cwa`
   - repository: `PixeneOS`

This avoids relying on the generic shell `USER` variable for project ownership.

## Compatibility boundary

This ticket does not rename the repository, move GitHub Pages paths, rewrite release assets, or update old Custota URLs. Existing served paths such as `0cwa.github.io/PixeneOS/...` and older `pixincreate.github.io/PixeneOS/...` remain compatibility surfaces per `docs/planning/downstream-compat-audit.md`.

## Validation

Commands/checks run:

```sh
bash -n src/declarations.sh src/util_functions.sh
ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p); puts "#{p} parses as YAML" }' .github/workflows/release.yml .github/workflows/release-lineage.yml
```

Resolution checks:

```sh
source src/util_functions.sh >/tmp/rebrand-source.out 2>&1

PIXENEOS_RELEASE_OWNER=""
PIXENEOS_RELEASE_REPOSITORY=""
unset GITHUB_REPOSITORY || true
resolve_release_repository
# default=0cwa/PixeneOS

PIXENEOS_RELEASE_OWNER=""
PIXENEOS_RELEASE_REPOSITORY=""
GITHUB_REPOSITORY="example-owner/example-repo"
resolve_release_repository
# github=example-owner/example-repo

PIXENEOS_RELEASE_OWNER="custom-owner"
PIXENEOS_RELEASE_REPOSITORY="custom-repo"
GITHUB_REPOSITORY="example-owner/example-repo"
resolve_release_repository
# explicit=custom-owner/custom-repo
```

Generated URL substitution check:

```sh
WORKDIR=".tmp-rebrand-validation"
VERSION[GRAPHENEOS]="2025010100"
OUTPUTS[PATCHED_OTA]="shiba-2025010100-rootless-deadbee.zip"
mkdir -p "$WORKDIR/tools/my-avbroot-setup"
printf 'generate_update_info(update_info, args.output.name)\n' > "$WORKDIR/tools/my-avbroot-setup/patch.py"
PIXENEOS_RELEASE_OWNER="override-owner"
PIXENEOS_RELEASE_REPOSITORY="override-repo"
GITHUB_REPOSITORY="example-owner/example-repo"
my_avbroot_setup
# generate_update_info(update_info, 'https://github.com/override-owner/override-repo/releases/download/2025010100/shiba-2025010100-rootless-deadbee.zip')
rm -rf "$WORKDIR"
```

Grep check confirmed `src/declarations.sh` no longer defines generic `USER` or `REPOSITORY` for PixeneOS release ownership, and generated OTA release URL construction uses `PIXENEOS_RELEASE_OWNER` / `PIXENEOS_RELEASE_REPOSITORY`.
