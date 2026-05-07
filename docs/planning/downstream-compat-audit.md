# Downstream Compatibility Audit

Generated: 2026-05-06. Scope: public paths and identifiers that existing Custota clients or flashed builds may depend on before any rebrand/tooling rename.

## Plain-language breakage answer

If we ship a rebrand tomorrow with no migration, existing devices can break in two ways:

1. **Custota update polling breaks** if `https://0cwa.github.io/PixeneOS/<flavor>/<device>.json` disappears or moves. Custota stores the server URL the user configured; it does not discover a renamed GitHub user/repo/path.
2. **Older README-following users may already be pinned to `https://pixincreate.github.io/PixeneOS/<flavor>/`**. Live checks found that old-owner site still serves `bluejay` and `caiman` JSONs but returns 404 for other sampled devices. A migration must account for both hosts.
3. **Current update downloads break** if a still-served device JSON points at release assets that 404. This already appears true for `magisk/bramble.json`, whose `pixincreate/PixeneOS` `2025021000` asset URLs returned `404` during this audit.

Therefore, keep the old GitHub Pages paths alive indefinitely, or redirect them for a documented deprecation window of at least 12 months. For safety, treat every gh-pages-served URL as user-pinned forever unless telemetry proves there are no users.

## Public surface inventory

Observed from `git ls-tree -r origin/gh-pages` and live `curl -I` checks. The actual Custota base URLs are flavor directories; the client then requests `<device>.json` below that base.

### Custota JSON endpoints served from GitHub Pages

Base patterns:

- `https://0cwa.github.io/PixeneOS/rootless/<device>.json`
- `https://0cwa.github.io/PixeneOS/magisk/<device>.json`

| Flavor | Device/path | Live URL | Current OTA URL host | Notes |
|---|---|---|---|---|
| magisk | `XQ-DC72.json` | `https://0cwa.github.io/PixeneOS/magisk/XQ-DC72.json` | `github.com/0cwa/PixeneOS` | JSON device name differs from OTA filename prefix `pdx235`. |
| magisk | `barbet.json` | `https://0cwa.github.io/PixeneOS/magisk/barbet.json` | `github.com/0cwa/PixeneOS` | Live HTTP 200 verified. |
| magisk | `bluejay.json` | `https://0cwa.github.io/PixeneOS/magisk/bluejay.json` | `github.com/pixincreate/PixeneOS` | Old owner still referenced. |
| magisk | `bramble.json` | `https://0cwa.github.io/PixeneOS/magisk/bramble.json` | `github.com/pixincreate/PixeneOS` | Current release asset URLs returned 404 in audit. |
| magisk | `local.json` | `https://0cwa.github.io/PixeneOS/magisk/local.json` | relative `./barbet-...` | Public sample/test endpoint; not a real device but still publicly served. |
| magisk | `shiba.json` | `https://0cwa.github.io/PixeneOS/magisk/shiba.json` | `github.com/0cwa/PixeneOS` | Live HTTP 200 verified. |
| rootless | `XQ-DC72.json` | `https://0cwa.github.io/PixeneOS/rootless/XQ-DC72.json` | `github.com/0cwa/PixeneOS` | JSON device name differs from OTA filename prefix `pdx235`. |
| rootless | `barbet.json` | `https://0cwa.github.io/PixeneOS/rootless/barbet.json` | `github.com/0cwa/PixeneOS` | Live HTTP 200 verified. |
| rootless | `bluejay.json` | `https://0cwa.github.io/PixeneOS/rootless/bluejay.json` | `github.com/pixincreate/PixeneOS` | Old owner still referenced; live HTTP 200 verified. |
| rootless | `bramble.json` | `https://0cwa.github.io/PixeneOS/rootless/bramble.json` | `github.com/0cwa/PixeneOS` | Live HTTP 200 via pattern. |
| rootless | `caiman.json` | `https://0cwa.github.io/PixeneOS/rootless/caiman.json` | `github.com/pixincreate/PixeneOS` | Old owner still referenced. |
| rootless | `shiba.json` | `https://0cwa.github.io/PixeneOS/rootless/shiba.json` | `github.com/0cwa/PixeneOS` | Live HTTP 200 via pattern. |

Verified examples:

- `https://0cwa.github.io/PixeneOS/rootless/barbet.json` — HTTP 200, `content-type: application/json`, `last-modified: Fri, 01 May 2026 18:36:10 GMT`.
- `https://0cwa.github.io/PixeneOS/magisk/barbet.json` — HTTP 200, same last-modified.
- `https://0cwa.github.io/PixeneOS/rootless/XQ-DC72.json` — HTTP 200, same last-modified.
- `https://0cwa.github.io/PixeneOS/magisk/shiba.json` — HTTP 200, `last-modified: Fri, 01 May 2026 18:36:09 GMT`.
- `https://0cwa.github.io/PixeneOS/rootless/bluejay.json` — HTTP 200 and currently points at `github.com/pixincreate/PixeneOS` assets.

### Legacy README/old-owner GitHub Pages URLs

`README.md` still documents `https://pixincreate.github.io/PixeneOS/<rootless/magisk>`. Live checks against common device JSON names found:

| URL | Status during audit | Notes |
|---|---|---|
| `https://pixincreate.github.io/PixeneOS/rootless/bluejay.json` | HTTP 200 | Points at `github.com/pixincreate/PixeneOS/releases/download/2026050400/...`. |
| `https://pixincreate.github.io/PixeneOS/magisk/bluejay.json` | HTTP 200 | Points at `github.com/pixincreate/PixeneOS/releases/download/2025121700/...`. |
| `https://pixincreate.github.io/PixeneOS/rootless/caiman.json` | HTTP 200 | Points at `github.com/pixincreate/PixeneOS/releases/download/2024120400/...`. |
| `https://pixincreate.github.io/PixeneOS/rootless/barbet.json` and `.../magisk/barbet.json` | HTTP 404 | Current README-style host does not serve these sampled devices. |
| `https://pixincreate.github.io/PixeneOS/rootless/XQ-DC72.json`, `bramble.json`, `shiba.json`, `local.json` | HTTP 404 | Sampled old-owner rootless paths not live. |
| `https://pixincreate.github.io/PixeneOS/magisk/XQ-DC72.json`, `bramble.json`, `caiman.json`, `shiba.json`, `local.json` | HTTP 404 | Sampled old-owner magisk paths not live. |

Compatibility implication: preserve/redirect the `pixincreate.github.io/PixeneOS` paths that still resolve, and avoid telling users to switch hosts until the old and new paths are both tested.

### OTA and csig URL patterns

Current JSONs use:

- `https://github.com/0cwa/PixeneOS/releases/download/<version>/<artifact>.zip`
- `https://github.com/0cwa/PixeneOS/releases/download/<version>/<artifact>.zip.csig`
- legacy/old-owner variants: `https://github.com/pixincreate/PixeneOS/releases/download/<version>/<artifact>.zip[.csig]`
- one local test entry: `./barbet-2024101200-magisk-28001-fc2078c.zip[.csig]`

Current artifact filename patterns observed:

- Graphene rootless: `<device>-<graphene-build>-rootless-<commit>.zip`
- Graphene magisk: `<device>-<graphene-build>-magisk-<magisk-version>-<commit>.zip`
- Historical magisk variant: `<device>-<graphene-build>-magisk-<magisk-build>-v1-<commit>.zip`
- Lineage/pdx235 releases exist in GitHub releases as `pdx235-lineage-23.0-<date>-magisk-<magisk-version>-<commit>.zip`, although current gh-pages JSON uses `XQ-DC72.json` for pdx235.
- Each OTA has a sibling csig file: same filename plus `.csig`.

Release asset spot checks:

- `https://github.com/0cwa/PixeneOS/releases/download/2025021000/barbet-2025021000-rootless-dc2e4ff.zip` — HTTP 302 to release asset, then HTTP 200, `content-length: 1264192338`.
- `https://github.com/0cwa/PixeneOS/releases/download/2025021000/barbet-2025021000-rootless-dc2e4ff.zip.csig` — HTTP 302 then HTTP 200, `content-length: 3018`.
- `https://github.com/pixincreate/PixeneOS/releases/download/2025020300/bluejay-2025020300-rootless-e7ca009.zip.csig` — HTTP 302 then HTTP 200, `content-length: 3015`.
- `https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip[.csig]` — HTTP 404 during audit.

### csig content

Downloaded csig files are CMS/PKCS#7-ish binary blobs containing JSON with `version`, `files[].name`, `offset`, `size`, `digest`, and `vbmeta_digest`. Observed `files[].name` values are OTA-internal names such as `payload.bin`, `payload_metadata.bin`, `payload_properties.txt`, `metadata`, and `metadata.pb`; no project/rebrand string was visible in sampled csigs. Treat these names as update-format internals, not user-pinned branding.

## Identifier inventory

| Identifier/path | Source | Where it ships or is stored | Pinning class | Compatibility note |
|---|---|---|---|---|
| `https://0cwa.github.io/PixeneOS/rootless/` | origin gh-pages | Custota server URL configured by user | user-pinned | Must keep alive or redirect. |
| `https://0cwa.github.io/PixeneOS/magisk/` | origin gh-pages | Custota server URL configured by user | user-pinned | Must keep alive or redirect. |
| `https://pixincreate.github.io/PixeneOS/rootless/` | README + live old-owner site | Custota server URL configured by users following older/current README examples | user-pinned | Must preserve/redirect at least for live `bluejay`/`caiman` users. |
| `https://pixincreate.github.io/PixeneOS/magisk/` | README + live old-owner site | Custota server URL configured by users following older/current README examples | user-pinned | Must preserve/redirect at least for live `bluejay` users. |
| `<flavor>/<device>.json` | `origin/gh-pages` | Requested by Custota under configured base URL | user-pinned | Preserve exact path for every device above. |
| `USER="0cwa"` | `src/declarations.sh` | Build-time generation of GitHub release URLs and dependency fork URL | build-pinned, becomes user-visible through JSON | Changing affects newly generated JSON; old JSON paths must continue to serve valid update info. Cross-ref HYGIENE-4. |
| `REPOSITORY="PixeneOS"` | `src/declarations.sh` | Build-time generation of release URLs and GitHub Pages repo path | build-pinned, becomes user-visible through JSON | Rebrand must preserve old repo path or redirect. |
| `PixeneOS` strings | README, workflow/release URLs, generated release URLs | User docs, URL paths, release artifact host | mixed | Docs can change at cutover; old URL surfaces cannot disappear. |
| Artifact filename `<device>-<version>-<flavor>-<commit>.zip` | `src/util_functions.sh:generate_ota_info` | GitHub release asset name and JSON `location_ota` | JSON-pinned until replaced | Not stored as server base, but any current JSON that references it must resolve until a newer JSON replaces it. |
| `.zip.csig` sibling filename | workflows + generated by patch tool | GitHub release asset name and JSON `location_csig` | JSON-pinned until replaced | Same as OTA asset; must resolve while current JSON references it. |
| Upstream module IDs (`custota`, `msd`, `bcr`, `oemunlockonboot`, `alterinstaller`, Magisk) | Downloaded module zips, not in repo | Installed Magisk/APK/module state on device | user-pinned if installed | Do not rename/fork these shipped modules without per-module migration. Repo source does not contain their `module.prop` files. |
| ADB debug module key `debug` | `src/debug_module_setup.sh` injects `debug: DebugMod` into my-avbroot modules map | Build-time avbroot module selector | build-pinned | Audit found no local `module.prop`/`id=` for the ADB debug code; it patches system/vendor images directly via my-avbroot. Verify built artifacts before asserting a Magisk persistent module ID exists. |
| csig `files[].name` values | csig content | Consumed during OTA signature/update verification | format-pinned, not brand-pinned | Do not change OTA-internal names; rebrand does not require changing them. |

No `module.prop` or literal `id=` field for a shipped local module was found in the tracked source tree. The important unresolved check is artifact-level inspection of downloaded third-party modules and any built ADB-debug output.

## Pinning map

### User-pinned

- Custota base URLs under `https://0cwa.github.io/PixeneOS/rootless/` and `.../magisk/`.
- Legacy/README Custota base URLs under `https://pixincreate.github.io/PixeneOS/rootless/` and `.../magisk/` where they still serve JSON.
- The device JSON filenames served under those bases.
- Installed third-party module IDs, if present on device (`custota`, `msd`, `bcr`, etc.).

### Transitively pinned by current JSON

- The exact OTA and csig release asset URLs referenced by currently served JSON files.
- These can change for future builds only after the old JSON path is updated and remains reachable.

### Build-pinned only

- `USER="0cwa"`, `REPOSITORY="PixeneOS"`, workflow release tag/name conventions, and generated artifact filename templates for new builds.
- The ADB-debug avbroot module selector `debug`.

## Migration strategies

### User-pinned URLs

- Preserve `https://0cwa.github.io/PixeneOS/rootless/`, `https://0cwa.github.io/PixeneOS/magisk/`, and still-live `https://pixincreate.github.io/PixeneOS/<flavor>/` paths indefinitely, or implement redirects with a stated deprecation window of at least 12 months.
- Prefer indefinite preservation because static GitHub Pages paths are cheap and Custota clients may be unattended.
- Before any repo/user rename, publish fresh JSON at old paths that points to the new release asset host.
- Keep old release assets available until their JSON no longer references them.

### Build-pinned identifiers

- At the rebrand boundary, update `USER`, `REPOSITORY`, README examples, workflow generated URLs, and artifact naming together.
- New builds may use the new name; old gh-pages JSON paths must remain valid and can point to new artifacts.
- If any module `id=` changes are introduced, ship an explicit uninstall/replace migration; do not silently change persistent module IDs.

## Pre-rebrand checklist

1. Freeze and review this audit against the exact branch/tag being rebranded.
2. Confirm old GitHub Pages paths remain hosted on both relevant hosts where applicable: `0cwa.github.io/PixeneOS/{rootless,magisk}/*.json` and still-live `pixincreate.github.io/PixeneOS/{rootless,magisk}/*.json`.
3. Confirm redirect/alias behavior with live `curl -I` for at least one active device in each flavor and host.
4. Publish new JSON at old paths that points to the new release asset host before moving docs/users.
5. Verify every current JSON `location_ota` and `location_csig` resolves; fix `magisk/bramble.json` or intentionally drop it with a user note.
6. Preserve or mirror old GitHub release assets until no served JSON references them.
7. Communicate the migration in README, releases, GitHub Discussions/issues, and any existing user channel.
8. Define a deprecation timeline; recommended minimum is 12 months, but default to indefinite old-path support.
9. Prepare rollback: old gh-pages branch/path can be restored quickly if Custota clients hang or poll errors spike.
10. Do not rename any installed module ID without a separate module migration plan.

## Best-effort install/download count

No GitHub Pages traffic logs were available in this checkout. GitHub release download counts are only a proxy: they count asset downloads, not installed devices or active Custota clients. Current gh-pages-referenced asset counts sampled through `gh api`:

| Asset | Download count |
|---|---:|
| `barbet-2025021000-magisk-28102-v1-dc2e4ff.zip` | 45 |
| `barbet-2025021000-magisk-28102-v1-dc2e4ff.zip.csig` | 45 |
| `barbet-2025021000-rootless-dc2e4ff.zip` | 0 |
| `barbet-2025021000-rootless-dc2e4ff.zip.csig` | 0 |
| `bramble-2025021000-rootless-db76589.zip` | 0 |
| `bramble-2025021000-rootless-db76589.zip.csig` | 0 |
| `shiba-2026021200-rootless-f494bd4.zip` | 3 |
| `shiba-2026021200-rootless-f494bd4.zip.csig` | 2 |
| `pdx235-20260213-magisk-v30.6-c9caf28.zip` | 18 |
| `pdx235-20260213-magisk-v30.6-c9caf28.zip.csig` | 17 |
| `shiba-2026040800-magisk-v30.7-99b7a51.zip` | 79 |
| `shiba-2026040800-magisk-v30.7-99b7a51.zip.csig` | 78 |
| `pdx235-20260501-rootless-c9caf28.zip` | 15 |
| `pdx235-20260501-rootless-c9caf28.zip.csig` | 14 |
| `bluejay-2024101700-magisk-28001-75fce14.zip` | 9 |
| `bluejay-2024101700-magisk-28001-75fce14.zip.csig` | 7 |
| `bluejay-2026050400-rootless-a2c4173.zip` (old-owner live JSON) | 0 |
| `bluejay-2026050400-rootless-a2c4173.zip.csig` (old-owner live JSON) | 0 |
| `bluejay-2025121700-magisk-v30.6-8bbc7fa.zip` (old-owner live JSON) | 1 |
| `bluejay-2025121700-magisk-v30.6-8bbc7fa.zip.csig` (old-owner live JSON) | 4 |
| `caiman-2024120400-rootless-6bb1f7b.zip` | 2 |
| `caiman-2024120400-rootless-6bb1f7b.zip.csig` | 0 |
| `bluejay-2025020300-rootless-e7ca009.zip` | 2 |
| `bluejay-2025020300-rootless-e7ca009.zip.csig` | 1 |
| `bramble-2025021000-magisk-v30.6-d86ffcf.zip[.csig]` | unknown; current URL returned 404 |

Assumption for migration planning: we cannot count active installs, so every gh-pages-served URL is treated as user-pinned forever.
