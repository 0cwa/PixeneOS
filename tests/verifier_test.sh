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

test_locked_inputs_require_explicit_checked_in_files() {
  reset_fixture locked-inputs
  local lock_path="${WORKDIR}/fdroid.lock.json"
  local profile_path="${WORKDIR}/fdroid.profile.toml"

  if verify_fdroid_privileged_extension_inputs "" "" >/dev/null 2>&1; then
    fail "locked inputs: empty paths unexpectedly succeeded"
  fi

  touch "${lock_path}" "${profile_path}"
  if verify_fdroid_privileged_extension_inputs \
    "${lock_path}" "${profile_path}" >/dev/null 2>&1; then
    fail "locked inputs: untracked temporary files unexpectedly succeeded"
  fi
}

test_locked_input_rejects_worktree_index_mode_and_path_aliases() {
  reset_fixture locked-input-git-state
  local repository="${WORKDIR}/repository with spaces"
  local lock_path="${repository}/locks/fdroid lock.json"
  local outside_path="${WORKDIR}/outside.lock"

  git init -q -- "${repository}"
  git -C "${repository}" config user.email test@example.invalid
  git -C "${repository}" config user.name "Pixene test"
  git -C "${repository}" config core.filemode true
  mkdir -p "$(dirname -- "${lock_path}")"
  printf '%s\n' '{"fixture":"clean"}' >"${lock_path}"
  git -C "${repository}" add -- "locks/fdroid lock.json"
  git -C "${repository}" commit -q -m fixture

  (
    cd "${repository}"
    verify_checked_in_locked_input "${lock_path}"
  ) || fail "clean checked-in lock was rejected"

  printf '%s\n' '{"fixture":"dirty"}' >"${lock_path}"
  if (
    cd "${repository}"
    verify_checked_in_locked_input "${lock_path}"
  ); then
    fail "dirty working-tree lock unexpectedly succeeded"
  fi

  git -C "${repository}" add -- "locks/fdroid lock.json"
  git -C "${repository}" show 'HEAD:locks/fdroid lock.json' >"${lock_path}"
  if (
    cd "${repository}"
    verify_checked_in_locked_input "${lock_path}"
  ); then
    fail "staged-only lock change unexpectedly succeeded"
  fi

  git -C "${repository}" restore --staged --worktree -- \
    "locks/fdroid lock.json"
  chmod +x "${lock_path}"
  if (
    cd "${repository}"
    verify_checked_in_locked_input "${lock_path}"
  ); then
    fail "mode-only lock change unexpectedly succeeded"
  fi

  chmod -x "${lock_path}"
  printf '%s\n' '{"fixture":"outside"}' >"${outside_path}"
  if (
    cd "${repository}"
    verify_checked_in_locked_input "${outside_path}"
  ); then
    fail "outside-repository lock unexpectedly succeeded"
  fi

  local alias_path="${repository}/locks/fdroid-alias.json"
  ln -s -- "fdroid lock.json" "${alias_path}"
  if (
    cd "${repository}"
    verify_checked_in_locked_input "${alias_path}"
  ); then
    fail "symlink lock unexpectedly succeeded"
  fi
}

test_matching_signature_succeeds
test_missing_signature_fails
test_wrong_module_signature_fails
test_unsigned_exceptions_succeed
test_locked_inputs_require_explicit_checked_in_files
test_locked_input_rejects_worktree_index_mode_and_path_aliases

echo "verifier tests passed"
