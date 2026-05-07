# ADBDEBUG-3 — debug ADB release guardrails

Implemented a minimal guardrail so unauthorized-ADB debug builds cannot be mistaken for normal PixeneOS release/update artifacts.

## Behavior

- Debug ADB remains opt-in only via the existing workflow input `allow_unauthorized_adb` / `ADDITIONALS_DEBUG=true` path.
- `generate_ota_info` now adds `debug-adb` to the patched OTA filename whenever `ADDITIONALS[DEBUG] == true`.
  - Example debug name: `shiba-2025010100-magisk-27.0-debug-adb-<commit>.zip`
  - Example normal name: `shiba-2025010100-magisk-27.0-<commit>.zip`
- Both release workflows now fail early if a manual debug build is requested with `release-type` other than `build-only`.
- Both release workflows also exclude debug builds from the `Make Release` and `Publish OTA to server` steps as defense in depth.

Net policy: debug ADB builds may be produced only as build-only workflow runs. They do not create GitHub release assets and do not update `gh-pages` OTA JSON/update metadata.

## Validation

Commands/checks run:

```sh
bash -n src/util_functions.sh
ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p); puts "#{p} parses as YAML" }' .github/workflows/release.yml .github/workflows/release-lineage.yml
```

Filename labeling check:

```sh
source src/util_functions.sh >/tmp/adbdebug-source.out 2>&1
DEVICE_NAME=shiba
VERSION[GRAPHENEOS]=2025010100
VERSION[MAGISK]=27.0
ADDITIONALS[ROOT]=true
ADDITIONALS[DEBUG]=true
generate_ota_info
# debug=shiba-2025010100-magisk-27.0-debug-adb-<commit>-dirty.zip
ADDITIONALS[DEBUG]=false
generate_ota_info
# normal=shiba-2025010100-magisk-27.0-<commit>-dirty.zip
```

Focused adversarial check:

```sh
python3 - <<'PY'
from pathlib import Path
for path in [Path('.github/workflows/release.yml'), Path('.github/workflows/release-lineage.yml')]:
    text = path.read_text()
    checks = {
        'explicit debug publish blocker': "Block debug ADB release publishing" in text and "release-type=build-only" in text,
        'release upload excludes debug': "Make Release" in text and "github.event.inputs.allow_unauthorized_adb != 'true'" in text,
        'metadata publish excludes debug': "Publish OTA to server" in text and "github.event.inputs.allow_unauthorized_adb != 'true'" in text,
    }
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        raise SystemExit(f'{path}: failed checks: {failed}')
    print(f'{path}: debug publish guardrails present')
PY
```

Result: both workflows contain the explicit debug publish blocker and the release/upload metadata steps exclude debug builds, so a debug build cannot silently replace normal release artifacts or normal OTA metadata.
