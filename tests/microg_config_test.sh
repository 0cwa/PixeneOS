#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

set -euo pipefail

fail() {
  echo "$*" >&2
  exit 1
}

python3 - <<'PY'
import json
from pathlib import Path

lock_path = Path("locks/microg-v0.3.15.250932.json")
lock = json.loads(lock_path.read_text(encoding="utf-8"))
assert lock["schema_version"] == 1
assert len(lock["modules"]) == 1
module = lock["modules"][0]
assert module["id"] == "microg"
assert module["version"] == "v0.3.15.250932"
by_id = {item["id"]: item for item in module["artifacts"]}
assert set(by_id) == {"companion-apk", "gmscore-apk"}

companion = by_id["companion-apk"]
assert companion["apk"] == {
    "package_name": "com.android.vending",
    "signer_sha256": "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165",
    "version_code": 84022630,
}
assert companion["size"] == 4639851
assert companion["sha256"] == "a973e0235a2829773a4faf36d235d5f703d1c04a2adff674ebaa535a2e78f937"

gmscore = by_id["gmscore-apk"]
assert gmscore["apk"] == {
    "package_name": "com.google.android.gms",
    "signer_sha256": "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165",
    "version_code": 250932030,
}
assert gmscore["size"] == 105948577
assert gmscore["sha256"] == "52597e77fd25fdd347574d0457ed1936a4b9561cf4c8d34e7ac8dd8191dfd4b9"

for item in by_id.values():
    assert item["legal"]["license"] == "Apache-2.0"
    assert "published" in item["legal"]["allowed_output_scopes"]
    assert item["source"]["url"] == "https://github.com/microg/GmsCore"
    assert item["source"]["revision"] == "v0.3.15.250932"
PY

fingerprint_for() (
  local microg="${1}"
  export ROM_FAMILY=lineageos
  export GRAPHENEOS_UPDATE_CHANNEL=nightly
  export OUTPUT_SCOPE=local-unpublished
  export ADDITIONALS_ROOT=false
  export ADDITIONALS_MICROG="${microg}"
  export ADDITIONALS_BOOT_ANIMATION=false
  export MAGISK_PREINIT=sda47
  source src/util_functions.sh
  module_selection_fingerprint
)

without="$(fingerprint_for false)"
with_microg="$(fingerprint_for true)"
[[ "${without}" =~ ^[0-9a-f]{64}$ ]] || fail "baseline fingerprint is invalid"
[[ "${with_microg}" =~ ^[0-9a-f]{64}$ ]] || fail "microG fingerprint is invalid"
[[ "${without}" != "${with_microg}" ]] || fail "microG did not change selection identity"

if (
  export ROM_FAMILY=grapheneos
  export GRAPHENEOS_UPDATE_CHANNEL=stable
  export OUTPUT_SCOPE=local-unpublished
  export ADDITIONALS_ROOT=false
  export ADDITIONALS_MICROG=true
  export ADDITIONALS_BOOT_ANIMATION=false
  export MAGISK_PREINIT=sda10
  source src/util_functions.sh
  module_selection_fingerprint >/dev/null 2>&1
); then
  fail "GrapheneOS unexpectedly accepted the microG selection"
fi

grep -Fq "'ADDITIONALS[MICROG]' = true"   .github/schedules/lineageos-pdx235.toml ||
  fail "pdx235 schedule does not enable microG"
grep -Fq "'ADDITIONALS[MICROG]' = false"   .github/schedules/grapheneos-shiba.toml ||
  fail "shiba schedule does not explicitly disable microG"

grep -Fq "VERSION[AVBROOT_SETUP]=\"ff9d4192d348569e0292e31b9739cd7647257b20\""   src/declarations.sh ||
  fail "PixeneOS is not pinned to the green microG helper"

echo "microG configuration tests passed"
