#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -eo pipefail

fail() {
  echo "$*" >&2
  exit 1
}

assert_module_config() {
  local module="${1}"
  local scalar="${2}"
  local actual

  actual="$(
    env -u "${scalar}" bash -c '
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "true" ]] ||
    fail "${module}: expected default true, got ${actual}"

  actual="$(
    env "${scalar}=false" bash -c '
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "false" ]] ||
    fail "${module}: expected ${scalar}=false override, got ${actual}"

  actual="$(
    env -u "${scalar}" bash -c '
      declare -A ADDITIONALS
      ADDITIONALS[$1]=false
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "false" ]] ||
    fail "${module}: expected associative-array fallback false, got ${actual}"
}

assert_default_off_module_config() {
  local module="${1}"
  local scalar="${2}"
  local actual

  actual="$(
    env -u "${scalar}" bash -c '
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "false" ]] ||
    fail "${module}: expected default false, got ${actual}"

  actual="$(
    env "${scalar}=true" bash -c '
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "true" ]] ||
    fail "${module}: expected ${scalar}=true override, got ${actual}"

  actual="$(
    env -u "${scalar}" bash -c '
      declare -A ADDITIONALS
      ADDITIONALS[$1]=true
      source src/declarations.sh
      printf "%s" "${ADDITIONALS[$1]}"
    ' _ "${module}"
  )"
  [[ "${actual}" == "true" ]] ||
    fail "${module}: expected associative-array fallback true, got ${actual}"
}

assert_module_config ALTERINSTALLER ADDITIONALS_ALTERINSTALLER
assert_module_config BCR ADDITIONALS_BCR
assert_module_config CUSTOTA ADDITIONALS_CUSTOTA
assert_module_config MSD ADDITIONALS_MSD
assert_module_config OEMUNLOCKONBOOT ADDITIONALS_OEMUNLOCKONBOOT
assert_default_off_module_config \
  FDROID_PRIVILEGED_EXTENSION \
  ADDITIONALS_FDROID_PRIVILEGED_EXTENSION

echo "declarations configuration tests passed"
