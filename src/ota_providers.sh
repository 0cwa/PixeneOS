#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

function fetch_grapheneos_ota_metadata() {
  local release_metadata latest_version

  release_metadata="$(curl -sLf \
    "${ROM_PROFILE[OTA_BASE_URL]}/${DEVICE_NAME}-${GRAPHENEOS[UPDATE_CHANNEL]}")" || {
    echo "Error: failed to fetch GrapheneOS release metadata." >&2
    return 1
  }
  latest_version="${release_metadata%%[[:space:]]*}"
  if [[ ! "${latest_version}" =~ ^[0-9]{8,14}$ ]]; then
    echo "Error: GrapheneOS returned an invalid release version." >&2
    return 1
  fi

  VERSION[GRAPHENEOS]="${GRAPHENEOS_VERSION:-${latest_version}}"
  GRAPHENEOS[OTA_TARGET]="${DEVICE_NAME}-${GRAPHENEOS[UPDATE_TYPE]}-${latest_version}"
  GRAPHENEOS[OTA_URL]="${ROM_PROFILE[OTA_BASE_URL]}/${GRAPHENEOS[OTA_TARGET]}.zip"
}

function fetch_lineageos_ota_metadata() {
  local release_metadata parsed filename ota_url latest_version
  local endpoint="${ROM_PROFILE[OTA_BASE_URL]}/devices/${DEVICE_NAME}/builds"

  release_metadata="$(curl -sLf "${endpoint}")" || {
    echo "Error: failed to fetch LineageOS release metadata." >&2
    return 1
  }
  parsed="$(printf '%s' "${release_metadata}" | python3 -c '
import json
import re
import sys
from urllib.parse import urlsplit

try:
    builds = json.load(sys.stdin)
    channel = sys.argv[1]
    device = sys.argv[2]
    build = next(item for item in builds if item["type"] == channel)
    item = next(
        item for item in build["files"]
        if item["filename"].endswith(".zip") and item["type"] == channel
    )
    filename = item["filename"]
    url = item["url"]
except (KeyError, IndexError, StopIteration, TypeError, ValueError, json.JSONDecodeError):
    raise SystemExit(1)
if not isinstance(filename, str) or not re.fullmatch(r"[A-Za-z0-9._+-]+[.]zip", filename):
    raise SystemExit(1)
if not re.fullmatch(r"[a-z0-9_]+", device) or f"-{device}-" not in filename:
    raise SystemExit(1)
parts = urlsplit(url)
if (
    parts.scheme != "https"
    or parts.hostname not in {"download.lineageos.org", "mirrorbits.lineageos.org"}
    or parts.username
    or parts.password
):
    raise SystemExit(1)
print(filename)
print(url)
' "${GRAPHENEOS[UPDATE_CHANNEL]}" "${DEVICE_NAME}")" || {
    echo "Error: LineageOS returned invalid release metadata." >&2
    return 1
  }
  filename="${parsed%%$'\n'*}"
  ota_url="${parsed#*$'\n'}"
  latest_version="$(printf '%s\n' "${filename}" | sed -nE 's/.*(^|[^0-9])([0-9]{8})([^0-9]|$).*/\2/p')"
  if [[ ! "${latest_version}" =~ ^[0-9]{8}$ ]]; then
    echo "Error: LineageOS filename lacks an unambiguous build date." >&2
    return 1
  fi

  VERSION[GRAPHENEOS]="${GRAPHENEOS_VERSION:-${latest_version}}"
  GRAPHENEOS[OTA_TARGET]="${filename%.zip}"
  GRAPHENEOS[OTA_URL]="${ota_url}"
}

function fetch_rom_ota_metadata() {
  case "${ROM_PROFILE[PROVIDER]}" in
  grapheneos) fetch_grapheneos_ota_metadata ;;
  lineageos) fetch_lineageos_ota_metadata ;;
  *)
    echo "Error: unsupported OTA metadata provider." >&2
    return 1
    ;;
  esac
}
