#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

: "${GRAPHENEOS_VERSION:?}"
: "${DEVICE_NAME:?}"
: "${ROM_FAMILY:?}"
: "${MODULE_SELECTION_FINGERPRINT:?}"
: "${OTA_ARTIFACT_PATH:?}"
: "${SELECTION_METADATA_PATH:?}"
: "${GITHUB_REPOSITORY:?}"

current_artifact="$(basename -- "${OTA_ARTIFACT_PATH}")"
current_selection="$(basename -- "${SELECTION_METADATA_PATH}")"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mapfile -t assets < <(gh release view "${GRAPHENEOS_VERSION}" --repo "${GITHUB_REPOSITORY}" --json assets --jq '.assets[].name')

for selection in "${assets[@]}"; do
  [[ "${selection}" == *.selection.json ]] || continue
  [[ "${selection}" != "${current_selection}" ]] || continue

  rm -f -- "${tmp}/${selection}"
  gh release download "${GRAPHENEOS_VERSION}" --repo "${GITHUB_REPOSITORY}" --pattern "${selection}" --dir "${tmp}" --clobber >/dev/null
  metadata="${tmp}/${selection}"

  jq -e     --arg device "${DEVICE_NAME}"     --arg family "${ROM_FAMILY}"     --arg fingerprint "${MODULE_SELECTION_FINGERPRINT}"     '.schema_version >= 2
     and .device == $device
     and .rom_family == $family
     and .module_selection_fingerprint == $fingerprint
     and .output_scope == "published"'     "${metadata}" >/dev/null || continue

  old_artifact="$(jq -r '.artifact_name // empty' "${metadata}")"
  [[ -n "${old_artifact}" && "${old_artifact}" != "${current_artifact}" ]] || continue

  for asset in "${old_artifact}" "${old_artifact}.csig" "${selection}"; do
    if printf '%s\n' "${assets[@]}" | grep -Fxq -- "${asset}"; then
      echo "Deleting superseded release asset: ${asset}"
      gh release delete-asset "${GRAPHENEOS_VERSION}" "${asset}" --repo "${GITHUB_REPOSITORY}" --yes
    fi
  done
done
