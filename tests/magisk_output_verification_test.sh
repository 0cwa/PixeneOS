#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

set -euo pipefail

source src/util_functions.sh

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "${TEST_ROOT}"' EXIT
WORKDIR="${TEST_ROOT}/work"
mkdir -p "${WORKDIR}"

PARTITIONS=$'boot\ninit_boot\nvendor_boot'
MAGISK_INFO='PREINITDEVICE=sda10'
EXTRACTED_TARGET=''
VERIFY_CALLS=()

fail() {
  echo "$*" >&2
  exit 1
}

run_executable_tool() {
  local tool="${1}"
  shift
  [[ "${tool}" == avbroot ]] || fail "unexpected tool: ${tool}"

  case "${1} ${2}" in
    'ota list')
      printf '%s\n' "${PARTITIONS}"
      ;;
    'ota extract')
      local directory='' partition=''
      shift 2
      while (($#)); do
        case "${1}" in
          --directory)
            directory="${2}"
            shift 2
            ;;
          --partition)
            partition="${2}"
            shift 2
            ;;
          --input)
            shift 2
            ;;
          *)
            fail "unexpected ota extract argument: ${1}"
            ;;
        esac
      done
      [[ -n "${directory}" && -n "${partition}" ]] ||
        fail "extract did not receive directory/partition"
      mkdir -p -- "${directory}"
      printf 'fixture' >"${directory}/${partition}.img"
      EXTRACTED_TARGET="${partition}"
      ;;
    'boot magisk-info')
      printf '%s\n' "${MAGISK_INFO}"
      ;;
    *)
      fail "unexpected avbroot call: $*"
      ;;
  esac
}

ota="${TEST_ROOT}/rooted.zip"
printf 'ota' >"${ota}"

verify_magisk_ota "${ota}" sda10 >/dev/null ||
  fail "valid Magisk OTA verification failed"
[[ "${EXTRACTED_TARGET}" == init_boot ]] ||
  fail "init_boot was not preferred over boot"

PARTITIONS='boot'
EXTRACTED_TARGET=''
verify_magisk_ota "${ota}" sda10 >/dev/null ||
  fail "boot fallback verification failed"
[[ "${EXTRACTED_TARGET}" == boot ]] ||
  fail "boot fallback was not selected"

PARTITIONS=$'boot\ninit_boot'
MAGISK_INFO='PREINITDEVICE=wrong'
if verify_magisk_ota "${ota}" sda10 >/dev/null 2>&1; then
  fail "wrong Magisk preinit device was accepted"
fi

MAGISK_INFO=''
if verify_magisk_ota "${ota}" sda10 >/dev/null 2>&1; then
  fail "non-Magisk boot image was accepted"
fi

PARTITIONS='vendor_boot'
MAGISK_INFO='PREINITDEVICE=sda10'
if verify_magisk_ota "${ota}" sda10 >/dev/null 2>&1; then
  fail "OTA without boot/init_boot was accepted"
fi

verify_magisk_ota() {
  VERIFY_CALLS+=("${1}")
  [[ "${VERIFY_RESULT:-success}" == success ]]
}

MAGISK[PREINIT]=sda10
OUTPUTS[PATCHED_OTA]="${TEST_ROOT}/single-magisk.zip"
OUTPUTS[PATCHED_OTA_MAGISK]="${TEST_ROOT}/paired-magisk.zip"

RESOLVED_ROOT_MODE=rootless
verify_requested_root_outputs
[[ "${#VERIFY_CALLS[@]}" -eq 0 ]] ||
  fail "rootless output unexpectedly ran Magisk verification"

RESOLVED_ROOT_MODE=magisk
VERIFY_CALLS=()
verify_requested_root_outputs
[[ "${VERIFY_CALLS[*]}" == "${OUTPUTS[PATCHED_OTA]}" ]] ||
  fail "single Magisk mode verified the wrong OTA"

RESOLVED_ROOT_MODE=both
VERIFY_CALLS=()
verify_requested_root_outputs
[[ "${VERIFY_CALLS[*]}" == "${OUTPUTS[PATCHED_OTA_MAGISK]}" ]] ||
  fail "paired mode verified the wrong OTA"

printf 'bad ota' >"${OUTPUTS[PATCHED_OTA_MAGISK]}"
printf 'bad csig' >"${OUTPUTS[PATCHED_OTA_MAGISK}.csig"
VERIFY_RESULT=failure
if verify_requested_root_outputs >/dev/null 2>&1; then
  fail "failed Magisk verification did not fail the build"
fi
[[ ! -e "${OUTPUTS[PATCHED_OTA_MAGISK]}" &&
  ! -e "${OUTPUTS[PATCHED_OTA_MAGISK}.csig" ]] ||
  fail "failed Magisk artifacts were not removed"

grep -Fq 'verify_requested_root_outputs || return 1' src/util_functions.sh ||
  fail "patch pipeline does not enforce Magisk output verification"

echo "Magisk output verification tests passed"
