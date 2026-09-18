#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

check_url() {
  local name="${1}" url="${2}" status
  status="$(curl -sSIL --retry 2 --retry-all-errors --connect-timeout 15 --max-time 45 -o /dev/null -w '%{http_code}' "${url}" || true)"
  [[ "${status}" == 200 ]] || {
    echo "::error::${name} did not resolve successfully (HTTP ${status:-000}): ${url}"
    return 1
  }
  echo "ok ${name}: ${url}"
}

while IFS=$'\t' read -r id url signature; do
  check_url "${id}" "${url}"
  check_url "${id}.sig" "${signature}"
done < <(
  python3 - <<'PY'
import json
from pathlib import Path
lock = json.loads(Path("locks/executable-tools-v1.json").read_text())
for tool in lock["tools"]:
    print(tool["id"], tool["url"], tool["signature"]["url"], sep="\t")
PY
)

source src/declarations.sh
helper_source="${PIXENEOS_AVBROOT_SETUP_SOURCE:-https://github.com/0cwa/my-avbroot-setup}"
helper_probe="$(mktemp -d)"
trap 'rm -rf "${helper_probe}"' EXIT
git -C "${helper_probe}" init -q
git -C "${helper_probe}" remote add origin "${helper_source}"
if ! git -C "${helper_probe}" fetch --quiet --depth=1 origin "${VERSION[AVBROOT_SETUP]}"; then
  echo "::error::Pinned helper revision is not fetchable from ${helper_source}: ${VERSION[AVBROOT_SETUP]}"
  exit 1
fi
[[ "$(git -C "${helper_probe}" rev-parse FETCH_HEAD)" == "${VERSION[AVBROOT_SETUP]}" ]] || {
  echo "::error::Helper fetch did not resolve to the pinned revision."
  exit 1
}
echo "ok helper revision: ${VERSION[AVBROOT_SETUP]}"

source src/fetcher.sh
resolve_rom_profile
get_latest_version
check_url "rom-ota" "${GRAPHENEOS[OTA_URL]}"
