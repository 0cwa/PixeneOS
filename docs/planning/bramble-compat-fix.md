# COMPAT-2 — `magisk/bramble` compatibility fix plan

Observed: 2026-05-06

Scope: documentation/planning only. No `gh-pages` JSON, release asset, branch, or tag was changed.

## Current JSON endpoints

| Endpoint | Status | Notes |
|---|---:|---|
| `https://0cwa.github.io/PixeneOS/magisk/bramble.json` | HTTP 200 | Current live/new-owner Custota JSON endpoint. |
| `https://pixincreate.github.io/PixeneOS/magisk/bramble.json` | HTTP 404 | Legacy/old-owner Pages endpoint is not serving this device/flavor. |

Live body from the current endpoint:

```json
{
  "version": 2,
  "full": {
    "location_ota": "https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip",
    "location_csig": "https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig"
  }
}
```

`origin/gh-pages:magisk/bramble.json` matches the live body above at this observation time.

## Current `location_ota` / `location_csig` checks

| Field | Current value | Resolves? | Result |
|---|---|---:|---|
| `location_ota` | `https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip` | No | HTTP 404 |
| `location_csig` | `https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig` | No | HTTP 404 |

The same filenames do resolve under the current `0cwa/PixeneOS` release host:

| Candidate replacement | Resolves? | Result |
|---|---:|---|
| `https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip` | Yes | HTTP 302 → HTTP 200, `content-length: 1270690973` |
| `https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig` | Yes | HTTP 302 → HTTP 200, `content-length: 3017` |

## Recommendation

Repair `magisk/bramble.json` on `gh-pages` by changing only the two release-asset URLs from `github.com/pixincreate/PixeneOS` to `github.com/0cwa/PixeneOS`, preserving the JSON endpoint path, version, artifact filenames, and `.csig` sibling relationship.

Recommended JSON:

```json
{
  "version": 2,
  "full": {
    "location_ota": "https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip",
    "location_csig": "https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig"
  }
}
```

Do **not** retire `magisk/bramble` solely for this issue: the expected assets exist, but the served JSON points at the wrong historical owner/repo. Mirroring assets is optional defense-in-depth, not required for the immediate breakage.

## Custota compatibility and rollback

- Old Custota clients configured with `https://0cwa.github.io/PixeneOS/magisk/` keep requesting the same `bramble.json` path; a JSON-only repair is compatible with that pinning model.
- The fix changes only where the already-named OTA and csig are downloaded from. It does not change the device path, version number, artifact basename, or update format.
- Before publishing, re-run HEAD checks for both replacement URLs and confirm the JSON remains valid.
- Rollback path: keep a copy of the pre-change JSON, publish the two-line URL-host change only, and if clients report failures, revert `magisk/bramble.json` on `gh-pages` to the previous body while investigating. Note that the previous body is already broken with HTTP 404 assets, so rollback restores prior behavior rather than a known-good update path.

## Commands used

```sh
git show origin/gh-pages:magisk/bramble.json
curl -L -sS -o /dev/null -w 'http_code=%{http_code} final_url=%{url_effective} content_type=%{content_type} size=%{size_download}\n' \
  https://0cwa.github.io/PixeneOS/magisk/bramble.json
curl -L -sS -o /dev/null -w 'http_code=%{http_code} final_url=%{url_effective} content_type=%{content_type} size=%{size_download}\n' \
  https://pixincreate.github.io/PixeneOS/magisk/bramble.json
curl -L -sS -o /dev/null -w 'http_code=%{http_code} final_url=%{url_effective} content_type=%{content_type} size=%{size_download}\n' \
  https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip
curl -L -sS -o /dev/null -w 'http_code=%{http_code} final_url=%{url_effective} content_type=%{content_type} size=%{size_download}\n' \
  https://github.com/pixincreate/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig
curl -L -I -sS --max-time 20 \
  https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip
curl -L -I -sS --max-time 20 \
  https://github.com/0cwa/PixeneOS/releases/download/2025021000/bramble-2025021000-magisk-v30.6-d86ffcf.zip.csig
```
