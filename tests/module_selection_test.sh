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
declare -a PREPARE_STAGES=()
PREPARE_FAILURE=""
PREPARE_CACHE_SENTINEL=""
LOCKED_INPUTS_VALID="true"

python() {
  local stage

  if [[ "${1}" == */module-tool.py ]]; then
    if [[ "${2}" == "artifacts" ]]; then
      stage="artifacts-${3}"
    else
      stage="${2}"
    fi
    PREPARE_STAGES+=("${stage}")
    if [[ "${stage}" == "artifacts-fetch" &&
      -n "${PREPARE_CACHE_SENTINEL}" ]]; then
      mkdir -p "$(dirname -- "${PREPARE_CACHE_SENTINEL}")"
      touch -- "${PREPARE_CACHE_SENTINEL}"
    fi
    [[ "${stage}" != "${PREPARE_FAILURE}" ]]
    return
  fi

  CAPTURED_ARGS=("$@")
}

verify_checked_in_locked_input() {
  [[ "${LOCKED_INPUTS_VALID}" == "true" ]]
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

assert_pair() {
  local option="${1}"
  local expected_value="${2}"
  local context="${3}"
  local index

  for index in "${!CAPTURED_ARGS[@]}"; do
    if [[ "${CAPTURED_ARGS[${index}]}" == "${option}" ]]; then
      [[ "${CAPTURED_ARGS[$((index + 1))]:-}" == "${expected_value}" ]] ||
        fail "${context}: ${option} has the wrong value"
      return 0
    fi
  done
  fail "${context}: missing ${option}"
}

assert_prepare_stages() {
  local context="${1}"
  shift
  local -a expected=("$@")
  local index

  [[ "${#expected[@]}" -eq "${#PREPARE_STAGES[@]}" ]] ||
    fail "${context}: wrong preparation stage count"
  for index in "${!expected[@]}"; do
    [[ "${expected[${index}]}" == "${PREPARE_STAGES[${index}]}" ]] ||
      fail "${context}: preparation order differs"
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
    "${WORKDIR}/extracted/ota/META-INF/com/android/otacert" \
    "${WORKDIR}/tools/my-avbroot-setup/module-tool.py"

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
  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="false"
  ADDITIONALS[DEBUG]="false"
  ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="false"
  ADDITIONALS[ROOT]="false"

  FDROID_PRIVILEGED_EXTENSION_LOCK=""
  FDROID_PRIVILEGED_EXTENSION_PROFILE=""
  FDROID_PRIVILEGED_EXTENSION_CACHE=""
  FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT=""
  LOCKED_INPUTS_VALID="true"
  PREPARE_FAILURE=""
  PREPARE_CACHE_SENTINEL=""

  CAPTURED_ARGS=()
  PREPARE_STAGES=()
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

enable_fdroid_fixture() {
  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="true"
  FDROID_PRIVILEGED_EXTENSION_LOCK="${WORKDIR}/fdroid.lock.json"
  FDROID_PRIVILEGED_EXTENSION_PROFILE="${WORKDIR}/fdroid.profile.toml"
  touch \
    "${FDROID_PRIVILEGED_EXTENSION_LOCK}" \
    "${FDROID_PRIVILEGED_EXTENSION_PROFILE}"
}

test_fdroid_locked_preparation_and_arguments() {
  reset_fixture fdroid-enabled
  enable_fdroid_fixture
  run_patch

  assert_prepare_stages \
    "F-Droid preparation" \
    resolve artifacts-fetch artifacts-verify
  assert_pair \
    "--module-lock" "${FDROID_PRIVILEGED_EXTENSION_LOCK}" "F-Droid"
  assert_pair \
    "--module-profile" "${FDROID_PRIVILEGED_EXTENSION_PROFILE}" "F-Droid"
  assert_pair \
    "--module-cache" "${WORKDIR}/locked-artifacts" "F-Droid"
  assert_pair \
    "--patch-report" "${OUTPUTS[PATCHED_OTA]}.patch-report.json" "F-Droid"
  assert_not_contains \
    "--module-fdroid-privileged-extension" "F-Droid legacy archive"
  assert_not_contains \
    "--module-fdroid-privileged-extension-sig" "F-Droid legacy signature"
}

assert_patch_fails_before_execution() {
  local context="${1}"

  if patch_ota >/dev/null 2>&1; then
    fail "${context}: patch unexpectedly succeeded"
  fi
  [[ "${#CAPTURED_ARGS[@]}" -eq 0 ]] ||
    fail "${context}: patch command was executed"
}

test_fdroid_missing_or_untracked_inputs_fail_closed() {
  reset_fixture fdroid-missing-inputs
  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="true"
  assert_patch_fails_before_execution "missing locked inputs"
  assert_prepare_stages "missing locked inputs"

  reset_fixture fdroid-untracked-inputs
  enable_fdroid_fixture
  LOCKED_INPUTS_VALID="false"
  assert_patch_fails_before_execution "untracked locked inputs"
  assert_prepare_stages "untracked locked inputs"
}

test_fdroid_preparation_stages_fail_closed() {
  local failure

  for failure in resolve artifacts-fetch artifacts-verify; do
    reset_fixture "fdroid-fail-${failure}"
    enable_fdroid_fixture
    PREPARE_FAILURE="${failure}"
    assert_patch_fails_before_execution "failed ${failure}"
    case "${failure}" in
    resolve)
      assert_prepare_stages "failed resolve" resolve
      ;;
    artifacts-fetch)
      assert_prepare_stages \
        "failed fetch" resolve artifacts-fetch
      ;;
    artifacts-verify)
      assert_prepare_stages \
        "failed verify" resolve artifacts-fetch artifacts-verify
      ;;
    esac
  done
}

test_fdroid_locked_paths_survive_cleanup_and_quoting() {
  reset_fixture "fdroid paths with spaces [literal]*"
  enable_fdroid_fixture
  FDROID_PRIVILEGED_EXTENSION_CACHE="${WORKDIR}/extracted/extracts/cache [literal]*"
  FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT="${WORKDIR}/reports/patch report [literal]*.json"
  PREPARE_CACHE_SENTINEL="${FDROID_PRIVILEGED_EXTENSION_CACHE}/verified-object"

  run_patch

  [[ -f "${PREPARE_CACHE_SENTINEL}" ]] ||
    fail "F-Droid cache was removed after locked verification"
  assert_pair \
    "--module-cache" "${FDROID_PRIVILEGED_EXTENSION_CACHE}" \
    "F-Droid quoted cache"
  assert_pair \
    "--patch-report" "${FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT}" \
    "F-Droid quoted report"
}

test_fdroid_enabled_does_not_reuse_legacy_output_marker() {
  reset_fixture fdroid-legacy-marker
  ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="true"
  touch -- "${WORKDIR}/${GRAPHENEOS[OTA_TARGET]}.patched*.zip"

  assert_patch_fails_before_execution "enabled F-Droid legacy marker"
  assert_prepare_stages "enabled F-Droid legacy marker"
}

test_default_arguments
test_each_module_can_be_disabled
test_all_modules_can_be_disabled
test_special_cases_remain_available
test_fdroid_locked_preparation_and_arguments
test_fdroid_missing_or_untracked_inputs_fail_closed
test_fdroid_preparation_stages_fail_closed
test_fdroid_locked_paths_survive_cleanup_and_quoting
test_fdroid_enabled_does_not_reuse_legacy_output_marker

echo "module selection tests passed"
