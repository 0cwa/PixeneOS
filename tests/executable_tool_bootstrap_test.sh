#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

set -euo pipefail

test_make_directories_keeps_bootstrap_parents_private() (
  local test_root workdir path mode
  umask 022
  test_root="$(mktemp -d)"
  trap 'rm -rf -- "${test_root}"' EXIT
  workdir="${test_root}/work"

  source src/util_functions.sh
  WORKDIR="${workdir}"
  make_directories
  mkdir -m 0700 -- "${WORKDIR}/tools/by-sha256"

  for path in \
    "${WORKDIR}" \
    "${WORKDIR}/.keys" \
    "${WORKDIR}/tools" \
    "${WORKDIR}/tools/by-sha256"; do
    mode="$(stat -c '%a' -- "${path}")"
    [[ "${mode}" == '700' ]] || {
      echo "bootstrap directory is not private: ${path}" >&2
      return 1
    }
  done
)

test_make_directories_keeps_bootstrap_parents_private
python3 tests/test_bootstrap_archive.py
python3 tests/executable_tool_bootstrap_test.py

echo "executable tool bootstrap tests passed"
