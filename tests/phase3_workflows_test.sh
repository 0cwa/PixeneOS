#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

WORKFLOW_DIR=".github/workflows"
REUSABLE="${WORKFLOW_DIR}/build-rom.yml"

fail() {
  echo "$*" >&2
  exit 1
}

assert_contains() {
  local file="${1}"
  local pattern="${2}"
  local context="${3}"

  grep -Eq -- "${pattern}" "${file}" ||
    fail "${context}: ${file} does not match ${pattern}"
}

assert_not_contains() {
  local file="${1}"
  local pattern="${2}"
  local context="${3}"

  if grep -Eq -- "${pattern}" "${file}"; then
    fail "${context}: ${file} unexpectedly matches ${pattern}"
  fi
}

assert_thin_trigger() {
  local file="${1}"
  local family="${2}"

  [[ -f "${file}" ]] || fail "missing ${family} release trigger: ${file}"
  assert_contains \
    "${file}" \
    'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' \
    "${family} trigger must call the shared workflow"
  assert_contains \
    "${file}" \
    "rom-family:[[:space:]]*['\"]?${family}['\"]?" \
    "${family} trigger must select its ROM family"
  assert_not_contains \
    "${file}" \
    'uses:[[:space:]]*actions/checkout@' \
    "thin triggers must not duplicate checkout/build steps"
  assert_not_contains \
    "${file}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "release triggers must not check out a divergent lineage branch"
}

assert_dispatch_default() {
  local file="${1}"
  local input="${2}"
  local expected="${3}"
  local actual

  actual="$(awk -v input="${input}" '
    $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047\"]/, "")
      print
      exit
    }
  ' "${file}")"

  [[ "${actual}" == "${expected}" ]] ||
    fail "${file}: ${input} default expected ${expected}, got ${actual:-missing}"
}

find_manual_acceptance_workflow() {
  local file

  for file in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
    [[ -f "${file}" ]] || continue
    [[ "${file}" == "${REUSABLE}" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release.yml" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release-lineage.yml" ]] && continue
    if grep -Eq 'workflow_dispatch:' "${file}" &&
      grep -Eq 'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' "${file}" &&
      grep -Eqi 'build-only|publish:[[:space:]]*false' "${file}"; then
      printf '%s\n' "${file}"
      return 0
    fi
  done

  return 1
}

test_reusable_workflow() {
  [[ -f "${REUSABLE}" ]] || fail "missing reusable ROM workflow: ${REUSABLE}"
  assert_contains \
    "${REUSABLE}" \
    'workflow_call:' \
    "shared ROM workflow must be reusable"
  assert_contains \
    "${REUSABLE}" \
    'rom-family:' \
    "shared ROM workflow must accept a ROM family"
  assert_contains \
    "${REUSABLE}" \
    'uses:[[:space:]]*actions/checkout@' \
    "shared ROM workflow must own checkout"
  assert_contains \
    "${REUSABLE}" \
    'MODULE_SELECTION_FINGERPRINT' \
    "shared workflow must retain the full selection fingerprint as metadata"
  assert_contains \
    "${REUSABLE}" \
    'OUTPUT_SCOPE' \
    "shared workflow must set an explicit output scope"
  assert_contains \
    "${REUSABLE}" \
    'enforce_output_policy' \
    "shared workflow must enforce policy before release or upload"
  assert_not_contains \
    "${REUSABLE}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "shared ROM workflow must not check out a divergent lineage branch"
}

test_release_triggers() {
  assert_thin_trigger "${WORKFLOW_DIR}/release.yml" grapheneos
  assert_thin_trigger "${WORKFLOW_DIR}/release-lineage.yml" lineageos

  assert_dispatch_default "${WORKFLOW_DIR}/release.yml" device-id shiba
  assert_dispatch_default "${WORKFLOW_DIR}/release.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release.yml" compatible-sepolicy-patching false
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" device-id pdx235
  assert_dispatch_default "${WORKFLOW_DIR}/release-lineage.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" compatible-sepolicy-patching true
}

test_manual_build_only_acceptance() {
  local acceptance

  acceptance="$(find_manual_acceptance_workflow)" ||
    fail "missing manual build-only workflow that calls build-rom.yml"
  assert_contains \
    "${acceptance}" \
    'workflow_dispatch:' \
    "acceptance workflow must be manually dispatched"
}

test_no_lineage_checkout_anywhere() {
  local file

  while IFS= read -r -d '' file; do
    assert_not_contains \
      "${file}" \
      '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
      "workflows must use the main branch implementation"
  done < <(find "${WORKFLOW_DIR}" -maxdepth 1 -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print0)
}

test_reusable_workflow
test_release_triggers
test_manual_build_only_acceptance
test_no_lineage_checkout_anywhere

echo "Phase 3 workflow tests passed"
