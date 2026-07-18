#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "${TEST_ROOT}"' EXIT

[[ -f src/rom_profiles.sh ]] || {
  echo "missing ROM profile implementation: src/rom_profiles.sh" >&2
  exit 1
}
source src/rom_profiles.sh
source src/util_functions.sh

fail() {
  echo "$*" >&2
  exit 1
}

assert_equals() {
  local expected="${1}"
  local actual="${2}"
  local context="${3}"

  [[ "${actual}" == "${expected}" ]] ||
    fail "${context}: expected ${expected}, got ${actual}"
}

load_contract() {
  declare -F resolve_rom_profile >/dev/null ||
    fail "resolve_rom_profile is not defined"
  declare -F module_selection_fingerprint >/dev/null ||
    fail "module_selection_fingerprint is not defined"
  declare -F enforce_output_policy >/dev/null ||
    fail "enforce_output_policy is not defined"
  declare -p ROM_PROFILE >/dev/null 2>&1 ||
    fail "ROM_PROFILE is not declared"
}

assert_profile() (
  local family="${1}"
  local provider="${2}"
  local channel="${3}"
  local update_type="${4}"
  local compatible_sepolicy="${5}"
  local base_url="${6}"

  load_contract
  ROM_FAMILY="${family}"
  resolve_rom_profile

  assert_equals "${provider}" "${ROM_PROFILE[PROVIDER]}" \
    "${family} provider"
  assert_equals "${channel}" "${ROM_PROFILE[DEFAULT_UPDATE_CHANNEL]}" \
    "${family} default update channel"
  assert_equals "${update_type}" "${ROM_PROFILE[DEFAULT_UPDATE_TYPE]}" \
    "${family} default update type"
  assert_equals "${compatible_sepolicy}" \
    "${ROM_PROFILE[DEFAULT_COMPATIBLE_SEPOLICY]}" \
    "${family} compatible-SEPolicy default"
  assert_equals "${base_url}" "${ROM_PROFILE[OTA_BASE_URL]}" \
    "${family} OTA base URL"
)

test_profiles_are_stable() {
  assert_profile \
    grapheneos grapheneos stable ota_update false \
    https://releases.grapheneos.org
  assert_profile \
    lineageos lineageos nightly ota_update true \
    https://download.lineageos.org/api/v2
}

test_unknown_rom_fails_closed() (
  load_contract
  ROM_FAMILY="unknown-rom"

  if resolve_rom_profile >/dev/null 2>&1; then
    fail "unknown ROM family unexpectedly resolved"
  fi
)

set_selection_fixture() {
  ROM_FAMILY="grapheneos"
  ADDITIONALS[ROOT]="false"
  ADDITIONALS[CUSTOTA]="true"
  ADDITIONALS[MSD]="true"
  ADDITIONALS[BCR]="true"
  ADDITIONALS[OEMUNLOCKONBOOT]="true"
  ADDITIONALS[ALTERINSTALLER]="true"
  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="false"
  resolve_rom_profile
}

fingerprint() {
  local output_file value

  output_file="${TEST_ROOT}/fingerprint-${BASHPID}"
  module_selection_fingerprint >"${output_file}"
  value="$(<"${output_file}")"
  [[ "${value}" =~ ^[0-9a-f]{64}$ ]] ||
    fail "module selection fingerprint is not a full lowercase SHA-256: ${value}"
  assert_equals "${value}" "${MODULE_SELECTION_FINGERPRINT}" \
    "fingerprint function side effect"
  printf '%s\n' "${value}"
}

test_selection_fingerprint() (
  local baseline repeated root_changed rom_changed module_changed

  load_contract
  set_selection_fixture
  baseline="$(fingerprint)"
  repeated="$(fingerprint)"
  assert_equals "${baseline}" "${repeated}" "deterministic fingerprint"

  ADDITIONALS[ROOT]="true"
  root_changed="$(fingerprint)"
  [[ "${root_changed}" != "${baseline}" ]] ||
    fail "root selection did not change the fingerprint"

  ADDITIONALS[ROOT]="false"
  ROM_FAMILY="lineageos"
  resolve_rom_profile
  rom_changed="$(fingerprint)"
  [[ "${rom_changed}" != "${baseline}" ]] ||
    fail "ROM family did not change the fingerprint"

  ROM_FAMILY="grapheneos"
  resolve_rom_profile
  ADDITIONALS[BCR]="false"
  module_changed="$(fingerprint)"
  [[ "${module_changed}" != "${baseline}" ]] ||
    fail "module selection did not change the fingerprint"
)

test_output_filename_contains_fingerprint() (
  local full compact

  load_contract
  set_selection_fixture
  DEVICE_NAME="shiba"
  VERSION[GRAPHENEOS]="2026071700"
  full="$(fingerprint)"
  compact="${full:0:16}"

  git() {
    if [[ "${1:-}" == "rev-parse" ]]; then
      printf '%s\n' deadbee
    else
      command git "$@"
    fi
  }
  dirty_suffix() { :; }

  generate_ota_info
  [[ "${OUTPUTS[PATCHED_OTA]}" == *"-${compact}-"* ]] ||
    fail "output filename does not include selection fingerprint: ${OUTPUTS[PATCHED_OTA]}"
)

test_output_policy() (
  local scope

  load_contract
  set_selection_fixture

  for scope in local-unpublished private shared published; do
    enforce_output_policy "${scope}" >/dev/null ||
      fail "disabled legacy profile rejected allowed scope ${scope}"
  done

  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="true"
  enforce_output_policy local-unpublished >/dev/null ||
    fail "F-Droid profile rejected local-unpublished output"
  for scope in private shared published; do
    if enforce_output_policy "${scope}" >/dev/null 2>&1; then
      fail "F-Droid profile unexpectedly allowed ${scope} output"
    fi
  done

  if enforce_output_policy unknown-scope >/dev/null 2>&1; then
    fail "unknown output scope unexpectedly passed policy enforcement"
  fi
)

test_profiles_are_stable
test_unknown_rom_fails_closed
test_selection_fingerprint
test_output_filename_contains_fingerprint
test_output_policy

echo "Phase 3 ROM contract tests passed"
