#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -eo pipefail

source src/util_functions.sh

set -u

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

declare -a CAPTURED_ARGS=()
declare -a EXPECTED_ARGS=()

python() {
  CAPTURED_ARGS=("$@")
}

deactivate() {
  :
}

setup_debug_module() {
  :
}

fail() {
  echo "$*" >&2
  exit 1
}

assert_array_equals() {
  local expected_name="${1}"
  local actual_name="${2}"
  local context="${3}"
  local -n expected_ref="${expected_name}"
  local -n actual_ref="${actual_name}"
  local index

  if [[ "${#expected_ref[@]}" -ne "${#actual_ref[@]}" ]]; then
    printf '%s: expected %d arguments, got %d\n' \
      "${context}" "${#expected_ref[@]}" "${#actual_ref[@]}" >&2
    printf 'Expected: %q\n' "${expected_ref[@]}" >&2
    printf 'Actual:   %q\n' "${actual_ref[@]}" >&2
    exit 1
  fi

  for index in "${!expected_ref[@]}"; do
    if [[ "${expected_ref[${index}]}" != "${actual_ref[${index}]}" ]]; then
      printf '%s: argument %d differs: expected %q, got %q\n' \
        "${context}" "${index}" "${expected_ref[${index}]}" "${actual_ref[${index}]}" >&2
      exit 1
    fi
  done
}

assert_contains() {
  local expected="${1}"
  local context="${2}"
  local value

  for value in "${CAPTURED_ARGS[@]}"; do
    [[ "${value}" == "${expected}" ]] && return 0
  done

  fail "${context}: expected argument not found: ${expected}"
}

assert_not_contains() {
  local unexpected="${1}"
  local context="${2}"
  local value

  for value in "${CAPTURED_ARGS[@]}"; do
    if [[ "${value}" == "${unexpected}" ]]; then
      fail "${context}: unexpected argument found: ${unexpected}"
    fi
  done
}

reset_fixture() {
  local case_name="${1}"

  WORKDIR="${TEST_ROOT}/${case_name}"
  mkdir -p \
    "${WORKDIR}/extracted/extracts" \
    "${WORKDIR}/extracted/ota/META-INF/com/android" \
    "${WORKDIR}/tools/my-avbroot-setup"
  touch \
    "${WORKDIR}/extracted/avb_pkmd.bin" \
    "${WORKDIR}/extracted/ota/META-INF/com/android/otacert"

  GRAPHENEOS[OTA_TARGET]="fixture-ota"
  OUTPUTS[PATCHED_OTA]="${WORKDIR}/patched.zip"
  KEYS[AVB]="${WORKDIR}/keys/avb.key"
  KEYS[OTA]="${WORKDIR}/keys/ota.key"
  KEYS[CERT_OTA]="${WORKDIR}/keys/ota.crt"
  KEYS[PKMD]="${WORKDIR}/keys/avb_pkmd.bin"
  MAGISK[PREINIT]="sda10"
  INTERACTIVE_MODE="true"
  VIRTUAL_ENV="fixture"

  ADDITIONALS[CUSTOTA]="true"
  ADDITIONALS[MSD]="true"
  ADDITIONALS[BCR]="true"
  ADDITIONALS[OEMUNLOCKONBOOT]="true"
  ADDITIONALS[ALTERINSTALLER]="true"
  ADDITIONALS[DEBUG]="false"
  ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="false"
  ADDITIONALS[ROOT]="false"

  CAPTURED_ARGS=()
}

set_default_expected_args() {
  EXPECTED_ARGS=(
    "${WORKDIR}/tools/my-avbroot-setup/patch.py"
    "--input" "${WORKDIR}/fixture-ota.zip"
    "--output" "${WORKDIR}/patched.zip"
    "--verify-public-key-avb" "${WORKDIR}/extracted/avb_pkmd.bin"
    "--verify-cert-ota" "${WORKDIR}/extracted/ota/META-INF/com/android/otacert"
    "--sign-key-avb" "${WORKDIR}/keys/avb.key"
    "--sign-key-ota" "${WORKDIR}/keys/ota.key"
    "--sign-cert-ota" "${WORKDIR}/keys/ota.crt"
    "--pass-avb-env-var" "PASSPHRASE_AVB"
    "--pass-ota-env-var" "PASSPHRASE_OTA"
    "--module-custota" "${WORKDIR}/modules/custota.zip"
    "--module-msd" "${WORKDIR}/modules/msd.zip"
    "--module-bcr" "${WORKDIR}/modules/bcr.zip"
    "--module-oemunlockonboot" "${WORKDIR}/modules/oemunlockonboot.zip"
    "--module-alterinstaller" "${WORKDIR}/modules/alterinstaller.zip"
    "--module-custota-sig" "${WORKDIR}/signatures/custota.zip.sig"
    "--module-msd-sig" "${WORKDIR}/signatures/msd.zip.sig"
    "--module-bcr-sig" "${WORKDIR}/signatures/bcr.zip.sig"
    "--module-oemunlockonboot-sig" "${WORKDIR}/signatures/oemunlockonboot.zip.sig"
    "--module-alterinstaller-sig" "${WORKDIR}/signatures/alterinstaller.zip.sig"
    "--patch-arg=--rootless"
  )
}

remove_expected_modules() {
  local module
  local value
  local remove
  local -a filtered=()
  local -a modules=("$@")

  for value in "${EXPECTED_ARGS[@]}"; do
    remove="false"
    for module in "${modules[@]}"; do
      if [[ "${value}" == "--module-${module}" ||
        "${value}" == "${WORKDIR}/modules/${module}.zip" ||
        "${value}" == "--module-${module}-sig" ||
        "${value}" == "${WORKDIR}/signatures/${module}.zip.sig" ]]; then
        remove="true"
        break
      fi
    done

    [[ "${remove}" == "false" ]] && filtered+=("${value}")
  done

  EXPECTED_ARGS=("${filtered[@]}")
}

run_patch() {
  patch_ota >/dev/null
}

test_default_arguments() {
  reset_fixture default
  set_default_expected_args
  run_patch
  assert_array_equals EXPECTED_ARGS CAPTURED_ARGS "default module selection"
}

test_each_module_can_be_disabled() {
  local entry module flag
  local -a entries=(
    "custota:CUSTOTA"
    "msd:MSD"
    "bcr:BCR"
    "oemunlockonboot:OEMUNLOCKONBOOT"
    "alterinstaller:ALTERINSTALLER"
  )

  for entry in "${entries[@]}"; do
    module="${entry%%:*}"
    flag="${entry#*:}"
    reset_fixture "disable-${module}"
    ADDITIONALS[${flag}]="false"
    set_default_expected_args
    remove_expected_modules "${module}"
    run_patch
    assert_array_equals EXPECTED_ARGS CAPTURED_ARGS "disable ${module}"
  done
}

test_all_modules_can_be_disabled() {
  local flag
  local -a modules=(custota msd bcr oemunlockonboot alterinstaller)
  local -a flags=(CUSTOTA MSD BCR OEMUNLOCKONBOOT ALTERINSTALLER)

  reset_fixture disable-all
  for flag in "${flags[@]}"; do
    ADDITIONALS[${flag}]="false"
  done
  set_default_expected_args
  remove_expected_modules "${modules[@]}"
  run_patch
  assert_array_equals EXPECTED_ARGS CAPTURED_ARGS "disable all modules"
}

test_special_cases_remain_available() {
  reset_fixture compatible-sepolicy
  ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="true"
  run_patch
  assert_contains "--compatible-sepolicy" "compatible SELinux"
  assert_contains "--patch-arg=--rootless" "compatible SELinux"

  reset_fixture root
  ADDITIONALS[ROOT]="true"
  run_patch
  assert_contains "--patch-arg=--magisk" "root"
  assert_contains "${WORKDIR}/modules/magisk.apk" "root"
  assert_contains "--patch-arg=--magisk-preinit-device" "root"
  assert_contains "sda10" "root"
  assert_not_contains "--patch-arg=--rootless" "root"

  reset_fixture debug
  ADDITIONALS[DEBUG]="true"
  run_patch
  assert_contains "--module-debug" "debug"
  assert_contains "${WORKDIR}/modules/dummy.zip" "debug"
  assert_contains "--module-debug-sig" "debug"
  assert_contains "${WORKDIR}/modules/dummy.zip.sig" "debug"
  assert_contains "--patch-arg=--rootless" "debug"
}

test_default_arguments
test_each_module_can_be_disabled
test_all_modules_can_be_disabled
test_special_cases_remain_available

echo "module selection tests passed"
