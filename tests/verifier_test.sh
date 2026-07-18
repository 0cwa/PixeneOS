#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -eo pipefail

source src/verifier.sh

set -u

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

RETRY_CALLED="false"

auto_retry_check() {
  RETRY_CALLED="true"
  return 23
}

fail() {
  echo "$*" >&2
  exit 1
}

reset_fixture() {
  local case_name="${1}"

  WORKDIR="${TEST_ROOT}/${case_name}"
  mkdir -p "${WORKDIR}/modules" "${WORKDIR}/signatures" "${WORKDIR}/tools"
  RETRY_CALLED="false"
}

assert_retry_failure() {
  local tool="${1}"
  local context="${2}"
  local status

  if verify_downloads "${tool}" >/dev/null; then
    fail "${context}: verification unexpectedly succeeded"
  else
    status=$?
  fi

  [[ "${status}" -eq 23 ]] ||
    fail "${context}: expected mocked retry status 23, got ${status}"
  [[ "${RETRY_CALLED}" == "true" ]] ||
    fail "${context}: expected retry handler to be called"
}

test_matching_signature_succeeds() {
  reset_fixture matching-signature
  touch "${WORKDIR}/modules/bcr.zip" "${WORKDIR}/signatures/bcr.zip.sig"

  verify_downloads bcr >/dev/null

  [[ "${RETRY_CALLED}" == "false" ]] ||
    fail "matching signature: retry handler should not be called"
}

test_missing_signature_fails() {
  reset_fixture missing-signature
  touch "${WORKDIR}/modules/bcr.zip"

  assert_retry_failure bcr "missing signature"
}

test_wrong_module_signature_fails() {
  reset_fixture wrong-signature
  touch "${WORKDIR}/modules/bcr.zip" "${WORKDIR}/signatures/msd.zip.sig"

  assert_retry_failure bcr "wrong-module signature"
}

test_unsigned_exceptions_succeed() {
  reset_fixture unsigned-helper
  mkdir -p "${WORKDIR}/tools/my-avbroot-setup"
  verify_downloads my-avbroot-setup >/dev/null

  reset_fixture unsigned-magisk
  touch "${WORKDIR}/modules/magisk.apk"
  verify_downloads magisk >/dev/null
}

test_matching_signature_succeeds
test_missing_signature_fails
test_wrong_module_signature_fails
test_unsigned_exceptions_succeed

echo "verifier tests passed"
