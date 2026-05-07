# RELEASE-1 — Release URL decoupling plan

Date: 2026-05-07. Scope: local planning only.

## TL;DR

REBRAND-1 already made the **owner** and **repository** segments configurable. The remaining coupling is:

1. `DOMAIN` is hard-coded to `https://github.com` in `src/declarations.sh` — blocks non-GitHub OTA hosting.
2. The path template `/releases/download/{VERSION}/{FILENAME}` is hard-coded inside `my_avbroot_setup()` — also blocks alternate hosting.
3. The `my-avbroot-setup` source clone URL (`url_constructor`) still hard-codes `0cwa` — not a release URL, but a loose end worth fixing separately.

Everything else (release existence check, artifact upload, gh-pages copy) already uses `${{ github.repository }}` dynamically and needs no change.

---

## Every place that constructs or consumes a release/update URL

### A. Generated OTA release URL — embedded in published artifacts (most critical)

**File:** `src/util_functions.sh`, function `my_avbroot_setup()` (line 308)

```bash
local location_path="${DOMAIN}/${PIXENEOS_RELEASE_OWNER}/${PIXENEOS_RELEASE_REPOSITORY}/releases/download/${VERSION[GRAPHENEOS]}/${OUTPUTS[PATCHED_OTA]}"
```

This string is written verbatim into `custota-tool gen-update-info --location <url>`, which produces `<device>.json`. That JSON is then:

1. Copied by the release workflow into the `gh-pages` branch under `{flavor}/{device}.json`.
2. Served at `https://<gh-pages-owner>.github.io/<repo>/{flavor}/{device}.json`.
3. Polled by Custota on user devices to find the next OTA download link.

**Consequence:** the full OTA download URL is baked into a published artifact at release time. Changing it for existing devices requires publishing a new JSON that points at the new URL.

**After REBRAND-1:** `PIXENEOS_RELEASE_OWNER` and `PIXENEOS_RELEASE_REPOSITORY` resolve via:
1. explicit env vars `PIXENEOS_RELEASE_OWNER` / `PIXENEOS_RELEASE_REPOSITORY`;
2. `GITHUB_REPOSITORY=owner/repo` from Actions context;
3. hard-coded fallback `0cwa` / `PixeneOS`.

Still hardcoded: `${DOMAIN}` (always `https://github.com`) and the path template `/releases/download/${VERSION[GRAPHENEOS]}/`.

### B. Artifact filename — determines the tail of the release URL

**File:** `src/util_functions.sh`, function `generate_ota_info()` (line 528)

```bash
OUTPUTS[PATCHED_OTA]="${DEVICE_NAME}-${VERSION[GRAPHENEOS]}-${flavor}${debug_suffix}-$(git rev-parse --short HEAD)$(dirty_suffix).zip"
```

Not a URL itself, but the filename becomes the last path segment of `location_path`. The current structure is:

```
{DEVICE_NAME}-{GRAPHENEOS_VERSION}-{flavor}[-debug-adb]-{git-short-hash}[dirty].zip
```

Clients (Custota) treat this as an opaque filename; the shape can change across releases as long as the served JSON always points at the real asset.

### C. Workflow: release existence check

**Files:** `.github/workflows/release.yml` line 109, `release-lineage.yml` line 115

```bash
repo_url="https://api.github.com/repos/${{ github.repository }}/releases/tags/${GRAPHENEOS_VERSION}"
```

Already dynamically correct — uses `github.repository`. No change needed.

### D. Workflow: artifact upload to GitHub Releases

**Files:** `release.yml` lines ~225-231, `release-lineage.yml` lines ~233-238

The `gh release upload` / `softprops/action-gh-release` step uploads `${{ env.OUTPUTS_PATCHED_OTA }}` and `.csig` to a tag on the current repo. The resulting download URL is constructed by GitHub — `https://github.com/{github.repository}/releases/download/{tag}/{filename}` — not by any script. No change needed.

### E. Workflow: gh-pages JSON copy (Custota update server)

**Files:** `release.yml` lines ~234-285, `release-lineage.yml` analogous block

The workflow checks out `gh-pages`, copies `{DEVICE_NAME}.json` (already written with `location_path` during patch) into `{flavor}/{DEVICE_NAME}.json`, commits, and pushes. The gh-pages serving URL (`https://<owner>.github.io/<repo>/...`) is determined by GitHub Pages settings, not by any script.

No change needed here for URL decoupling — but note: the gh-pages serving URL itself is not configurable without either a custom domain or a repo rename. This is a separate concern from the OTA download URL.

### F. Tool dependency download URL — my-avbroot-setup source

**File:** `src/util_functions.sh`, function `url_constructor()` (line 406)

```bash
if [[ "${repository}" == "my-avbroot-setup" ]]; then
  URL="${DOMAIN}/0cwa/${repository}"
```

This is **not** the generated OTA release URL. It is the URL used to `git clone` or download the `my-avbroot-setup` tooling during build setup. It still hardcodes `0cwa`. This should be made configurable (e.g., a `PIXENEOS_AVBROOT_SETUP_SOURCE` variable) but is separate from the OTA release URL concern.

### G. Other tool dependency URLs (Custota, avbroot, etc.)

**File:** `src/util_functions.sh`, `url_constructor()` (lines 419, 423)

```bash
local download_page="${DOMAIN}/${user}/Custota/releases/download"   # user='chenxiaolong'
local download_page="${DOMAIN}/${user}/${repository}/releases/download"
```

These are **external upstream tool downloads**, not PixeneOS release URLs. Not in scope for this ticket.

---

## Current generated URL shape

```
https://github.com/{PIXENEOS_RELEASE_OWNER}/{PIXENEOS_RELEASE_REPOSITORY}/releases/download/{VERSION[GRAPHENEOS]}/{OUTPUTS[PATCHED_OTA]}
```

Where right now:
- `https://github.com` — `DOMAIN`, hardcoded in `src/declarations.sh`
- `{PIXENEOS_RELEASE_OWNER}` — configurable since REBRAND-1; defaults to `0cwa`
- `{PIXENEOS_RELEASE_REPOSITORY}` — configurable since REBRAND-1; defaults to `PixeneOS`
- `/releases/download/` — hardcoded path template in `my_avbroot_setup()`
- `{VERSION[GRAPHENEOS]}` — the GrapheneOS build tag, e.g. `2026050400`
- `{OUTPUTS[PATCHED_OTA]}` — artifact filename, e.g. `shiba-2026050400-rootless-abc1234.zip`

---

## Which URLs are embedded in published artifacts

The critical embedding happens in `my_avbroot_setup()`:

```bash
sed -i -e "s|generate_update_info(update_info, args.output.name)|generate_update_info(update_info, '${location_path}')|" "${setup_script}"
```

`custota-tool gen-update-info --location <url>` then writes `<device>.json` with the full URL as the OTA download link. That JSON is the artifact that Custota polls on devices.

**Implication:** the OTA download URL is frozen at build time into `<device>.json`. Future URL changes require re-publishing `<device>.json` with the new URL. Custota clients that have a stale JSON will keep trying the old URL until they are updated.

---

## Proposed config keys for full decoupling

Two levels of work; implement level 1 first.

### Level 1 — configurable release base URL (unblocks non-GitHub hosting)

Add one new variable to `src/declarations.sh`:

```bash
PIXENEOS_RELEASE_BASE_URL="${PIXENEOS_RELEASE_BASE_URL:-}"
```

Modify `my_avbroot_setup()` in `src/util_functions.sh` to construct `location_path` as:

```bash
# Resolve base URL: explicit override wins; otherwise construct from DOMAIN + owner + repo + GH path template
if [[ -n "${PIXENEOS_RELEASE_BASE_URL}" ]]; then
  local location_path="${PIXENEOS_RELEASE_BASE_URL}/${OUTPUTS[PATCHED_OTA]}"
else
  local location_path="${DOMAIN}/${PIXENEOS_RELEASE_OWNER}/${PIXENEOS_RELEASE_REPOSITORY}/releases/download/${VERSION[GRAPHENEOS]}/${OUTPUTS[PATCHED_OTA]}"
fi
```

`PIXENEOS_RELEASE_BASE_URL` is the full prefix up to but not including the filename:
```
https://github.com/myorg/myrepo/releases/download/2026050400
# or for alternate hosting:
https://releases.example.com/PixeneOS/shiba/2026050400
```

**Backwards compatibility:** when `PIXENEOS_RELEASE_BASE_URL` is empty (the default), behaviour is unchanged — the existing owner/repo/version construction is used.

### Level 2 — fix my-avbroot-setup source URL (separate small change)

Add to `src/declarations.sh`:

```bash
PIXENEOS_AVBROOT_SETUP_SOURCE="${PIXENEOS_AVBROOT_SETUP_SOURCE:-}"
```

In `url_constructor()`:

```bash
if [[ "${repository}" == "my-avbroot-setup" ]]; then
  URL="${PIXENEOS_AVBROOT_SETUP_SOURCE:-${DOMAIN}/0cwa/${repository}}"
```

This is a dependency-source concern, not a release-URL concern, so it belongs in a separate small commit or folded into a future `RELEASE-2` implementation ticket.

---

## Backwards-compatible defaults

| Context | PIXENEOS_RELEASE_BASE_URL | Resulting URL |
|---|---|---|
| Local run, nothing set | empty | `https://github.com/0cwa/PixeneOS/releases/download/{VERSION}/{FILE}` |
| GitHub Actions, no override | empty, `GITHUB_REPOSITORY=0cwa/PixeneOS` | `https://github.com/0cwa/PixeneOS/releases/download/{VERSION}/{FILE}` |
| Fork running in GH Actions | empty, `GITHUB_REPOSITORY=myfork/PixeneOS` | `https://github.com/myfork/PixeneOS/releases/download/{VERSION}/{FILE}` |
| Explicit full base URL | `https://releases.example.com/PixeneOS/{VERSION}` | `https://releases.example.com/PixeneOS/{VERSION}/{FILE}` |

Existing Custota clients continue to work because the JSON URLs they poll (`0cwa.github.io/PixeneOS/...`) and the release assets they download are not changed by this config addition — the variable is empty unless explicitly set.

---

## Migration risks for existing Custota clients

| Risk | Severity | Notes |
|---|---|---|
| Custota client pinned to `0cwa.github.io/PixeneOS/{flavor}/{device}.json` | High | Clients poll a specific URL stored at Custota setup time. If the gh-pages URL changes (repo rename, owner change, custom domain addition), clients break silently until the user reconfigures. |
| gh-pages JSON pointing at wrong owner/repo release assets | Medium | Currently `bluejay.json`, `caiman.json`, and `bramble.json` reference `pixincreate/PixeneOS` release assets, some of which already 404 (per COMPAT-1/2). Any URL changes must also fix stale legacy JSONs. |
| `PIXENEOS_RELEASE_BASE_URL` set incorrectly | Medium | If the variable is set but the base URL is wrong, the next Custota JSON will point at a non-existent download. Mitigation: validate the URL in CI before publishing. |
| Alternate hosting breaks csig verification | Medium | Custota verifies the `.csig` file co-located with the OTA. If alternate hosting is used, both the `.zip` and `.zip.csig` must be published at the same base. The current workflow only uploads to GH Releases — alternate hosting would need a separate upload step. |
| Version tag in base URL vs in filename | Low | Level 1 puts `{VERSION}` in the base URL (matching current GH Releases structure). An alternate host that uses a flat directory would need `PIXENEOS_RELEASE_BASE_URL` to not include a version component — the path template is then caller responsibility. Document clearly. |

---

## Relationship to META-7 (final tooling name)

`REPOSITORY` appears in the generated release URL only indirectly (via `PIXENEOS_RELEASE_REPOSITORY`). After REBRAND-1 the default fallback is `PixeneOS`. A tool rename would change:

- The GitHub repository name (if the repo is renamed).
- The resulting `GITHUB_REPOSITORY` value in Actions.
- The default `PIXENEOS_RELEASE_REPOSITORY` fallback if the repo is renamed.

**Verdict:** implementing Level 1 now is safe and independent of META-7. The release base URL can be overridden explicitly regardless of what the project is called. Implement RELEASE-1 before or in parallel with any naming decision.

---

## Test strategy for generated update metadata

For any implementation ticket (RELEASE-2):

1. **Unit-style shell test:** source `src/util_functions.sh`, set `PIXENEOS_RELEASE_BASE_URL` to a known value, call `my_avbroot_setup()` against a test `patch.py` copy, then grep the patched script for the expected URL.
2. **No-override regression:** unset `PIXENEOS_RELEASE_BASE_URL` and verify the constructed URL still matches the current default form using `resolve_release_repository` logic.
3. **`bash -n` syntax check:** `bash -n src/declarations.sh src/util_functions.sh` after every edit.
4. **csig co-location check:** for any alternate-hosting test, verify that `${base_url}/${OUTPUTS[PATCHED_OTA]}.csig` also resolves.

---

## Implementation recommendation

Do **not** implement in this ticket (RELEASE-1 is planning only). Create a follow-up implementation ticket with:

- Add `PIXENEOS_RELEASE_BASE_URL` to `src/declarations.sh`.
- Modify `my_avbroot_setup()` in `src/util_functions.sh` to use it when set.
- Run the test strategy above.
- Update `README.md` if behavior changes for users.
- Fold `PIXENEOS_AVBROOT_SETUP_SOURCE` into the same ticket or a tiny follow-up.

The implementation is a small focused change (~10 lines of shell) once this plan is accepted.

---

## Validation of this document

Sources used:

- `src/declarations.sh` — full variable listing
- `src/util_functions.sh` — `my_avbroot_setup()`, `resolve_release_repository()`, `generate_ota_info()`, `url_constructor()`
- `.github/workflows/release.yml`, `release-lineage.yml` — release existence check, artifact upload, gh-pages update steps
- `.pi/research/my-avbroot-upstream/lib/external.py` — `generate_update_info()` implementation
- `docs/planning/declarations-audit.md` — HYGIENE-4 variable audit
- `docs/planning/rebrand-config-boundaries.md` — REBRAND-1 output
- `docs/planning/downstream-compat-audit.md` — live Custota JSON/URL compatibility surface
