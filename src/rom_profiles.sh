#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

# ROM differences are data consumed by the common build path. Provider-specific
# metadata parsing lives in ota_providers.sh.
declare -gA ROM_PROFILE

function _require_profile_boolean() {
  local name="${1}"
  local value="${2}"

  if [[ "${value}" != 'true' && "${value}" != 'false' ]]; then
    echo "Error: ${name} must be true or false." >&2
    return 1
  fi
}

function resolve_rom_profile() {
  case "${ROM_FAMILY}" in
  grapheneos)
    ROM_PROFILE[PROVIDER]="grapheneos"
    ROM_PROFILE[DEFAULT_UPDATE_CHANNEL]="stable"
    ROM_PROFILE[DEFAULT_UPDATE_TYPE]="ota_update"
    ROM_PROFILE[DEFAULT_COMPATIBLE_SEPOLICY]="false"
    ROM_PROFILE[CLEAR_VBMETA_FLAGS]="false"
    ROM_PROFILE[OTA_BASE_URL]="https://releases.grapheneos.org"
    ;;
  lineageos)
    ROM_PROFILE[PROVIDER]="lineageos"
    ROM_PROFILE[DEFAULT_UPDATE_CHANNEL]="nightly"
    ROM_PROFILE[DEFAULT_UPDATE_TYPE]="ota_update"
    ROM_PROFILE[DEFAULT_COMPATIBLE_SEPOLICY]="true"
    ROM_PROFILE[CLEAR_VBMETA_FLAGS]="true"
    ROM_PROFILE[OTA_BASE_URL]="https://download.lineageos.org/api/v2"
    ;;
  *)
    echo "Error: unsupported ROM_FAMILY: ${ROM_FAMILY}" >&2
    return 1
    ;;
  esac

  GRAPHENEOS[OTA_BASE_URL]="${ROM_PROFILE[OTA_BASE_URL]}"
  GRAPHENEOS[UPDATE_CHANNEL]="${GRAPHENEOS_UPDATE_CHANNEL:-${ROM_PROFILE[DEFAULT_UPDATE_CHANNEL]}}"
  GRAPHENEOS[UPDATE_TYPE]="${ROM_UPDATE_TYPE:-${ROM_PROFILE[DEFAULT_UPDATE_TYPE]}}"
  GRAPHENEOS[OTA_URL]="${GRAPHENEOS[OTA_URL]:-}"
  GRAPHENEOS[OTA_TARGET]="${GRAPHENEOS[OTA_TARGET]:-}"

  if [[ -n "${ADDITIONALS_MAS_COMPATIBLE_SEPOLICY:-}" ]]; then
    ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="${ADDITIONALS_MAS_COMPATIBLE_SEPOLICY}"
  else
    ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="${ROM_PROFILE[DEFAULT_COMPATIBLE_SEPOLICY]}"
  fi

  _require_profile_boolean \
    ADDITIONALS_MAS_COMPATIBLE_SEPOLICY \
    "${ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]}"
  _require_profile_boolean \
    ROM_PROFILE_CLEAR_VBMETA_FLAGS \
    "${ROM_PROFILE[CLEAR_VBMETA_FLAGS]}"
}

function enforce_output_policy() {
  local output_scope="${1}"

  case "${output_scope}" in
  local-unpublished | private | shared | published) ;;
  *)
    echo "Error: unknown output scope: ${output_scope}" >&2
    return 1
    ;;
  esac

  if [[ "${ADDITIONALS[DEBUG]}" == 'true' &&
    "${output_scope}" != 'local-unpublished' ]]; then
    echo "Error: debug ADB output must remain local and unpublished." >&2
    return 1
  fi

  if [[ "${ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]}" == 'true' &&
    "${output_scope}" != 'local-unpublished' ]]; then
    echo "Error: F-Droid output is restricted to local-unpublished." >&2
    return 1
  fi
}

function _locked_input_digest() {
  local input_path="${1}"

  if ! declare -F verify_checked_in_locked_input >/dev/null; then
    source src/verifier.sh
  fi
  verify_checked_in_locked_input "${input_path}" || return 1
  sha256sum -- "${input_path}" | awk '{print $1}'
}

function module_selection_fingerprint() {
  local lock_digest="disabled"
  local profile_digest="disabled"
  local entry
  local -a module_entries=(
    "alterinstaller:ALTERINSTALLER"
    "bcr:BCR"
    "custota:CUSTOTA"
    "fdroid-privileged-extension:FDROID_PRIVILEGED_EXTENSION"
    "msd:MSD"
    "oemunlockonboot:OEMUNLOCKONBOOT"
  )

  resolve_rom_profile || return 1
  enforce_output_policy "${OUTPUT_SCOPE}" || return 1

  _require_profile_boolean ADDITIONALS_ROOT "${ADDITIONALS[ROOT]}" || return 1
  _require_profile_boolean ADDITIONALS_DEBUG "${ADDITIONALS[DEBUG]}" || return 1
  for entry in "${module_entries[@]}"; do
    _require_profile_boolean \
      "ADDITIONALS_${entry#*:}" \
      "${ADDITIONALS[${entry#*:}]}" || return 1
  done

  if [[ "${ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]}" == 'true' ]]; then
    lock_digest="$(_locked_input_digest "${FDROID_PRIVILEGED_EXTENSION_LOCK}")" || {
      echo "Error: the F-Droid lock is not clean and checked in." >&2
      return 1
    }
    profile_digest="$(_locked_input_digest "${FDROID_PRIVILEGED_EXTENSION_PROFILE}")" || {
      echo "Error: the F-Droid profile is not clean and checked in." >&2
      return 1
    }
  fi

  MODULE_SELECTION_FINGERPRINT="$({
    printf '%s\n' \
      'pixene-module-selection-v1' \
      "rom_family=${ROM_FAMILY}" \
      "output_scope=${OUTPUT_SCOPE}" \
      "root=${ADDITIONALS[ROOT]}" \
      "debug=${ADDITIONALS[DEBUG]}" \
      "compatible_sepolicy=${ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]}" \
      "clear_vbmeta_flags=${ROM_PROFILE[CLEAR_VBMETA_FLAGS]}" \
      "helper_commit=${VERSION[AVBROOT_SETUP]}" \
      "lock_sha256=${lock_digest}" \
      "profile_sha256=${profile_digest}"
    for entry in "${module_entries[@]}"; do
      printf 'module.%s=%s\n' "${entry%%:*}" "${ADDITIONALS[${entry#*:}]}"
    done
  } | sha256sum | awk '{print $1}')"

  if [[ ! "${MODULE_SELECTION_FINGERPRINT}" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Error: failed to compute the module-selection fingerprint." >&2
    return 1
  fi
  printf '%s\n' "${MODULE_SELECTION_FINGERPRINT}"
}
