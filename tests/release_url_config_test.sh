#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -eo pipefail

source src/util_functions.sh

set -u

assert_file_contains() {
  local file="${1}"
  local expected="${2}"

  if ! grep -Fq "${expected}" "${file}"; then
    echo "Expected to find in ${file}:" >&2
    echo "${expected}" >&2
    echo "Actual file:" >&2
    cat "${file}" >&2
    exit 1
  fi
}

reset_release_config() {
  unset GITHUB_REPOSITORY
  PIXENEOS_RELEASE_OWNER=""
  PIXENEOS_RELEASE_REPOSITORY=""
  PIXENEOS_RELEASE_BASE_URL=""
  PIXENEOS_AVBROOT_SETUP_SOURCE=""
  VERSION[GRAPHENEOS]="2026050400"
  OUTPUTS[PATCHED_OTA]="shiba-2026050400-rootless-abc1234.zip"
}

write_patch_script() {
  mkdir -p "${WORKDIR}/tools/my-avbroot-setup"
  cat >"${WORKDIR}/tools/my-avbroot-setup/patch.py" <<'PY'
result = generate_update_info(update_info, args.output.name)
PY
}

test_default_release_url() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  WORKDIR="${tmpdir}/work"
  reset_release_config
  write_patch_script

  my_avbroot_setup >/dev/null

  assert_file_contains \
    "${WORKDIR}/tools/my-avbroot-setup/patch.py" \
    "generate_update_info(update_info, 'https://github.com/0cwa/PixeneOS/releases/download/2026050400/shiba-2026050400-rootless-abc1234.zip')"

  rm -rf "${tmpdir}"
}

test_github_repository_release_url() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  WORKDIR="${tmpdir}/work"
  reset_release_config
  GITHUB_REPOSITORY="myorg/myrepo"
  write_patch_script

  my_avbroot_setup >/dev/null

  assert_file_contains \
    "${WORKDIR}/tools/my-avbroot-setup/patch.py" \
    "generate_update_info(update_info, 'https://github.com/myorg/myrepo/releases/download/2026050400/shiba-2026050400-rootless-abc1234.zip')"

  rm -rf "${tmpdir}"
}

test_release_base_url_override() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  WORKDIR="${tmpdir}/work"
  reset_release_config
  PIXENEOS_RELEASE_BASE_URL="https://releases.example.com/PixeneOS/shiba/2026050400"
  write_patch_script

  my_avbroot_setup >/dev/null

  assert_file_contains \
    "${WORKDIR}/tools/my-avbroot-setup/patch.py" \
    "generate_update_info(update_info, 'https://releases.example.com/PixeneOS/shiba/2026050400/shiba-2026050400-rootless-abc1234.zip')"

  rm -rf "${tmpdir}"
}

test_release_base_url_trailing_slash() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  WORKDIR="${tmpdir}/work"
  reset_release_config
  PIXENEOS_RELEASE_BASE_URL="https://releases.example.com/PixeneOS/shiba/2026050400/"
  write_patch_script

  my_avbroot_setup >/dev/null

  assert_file_contains \
    "${WORKDIR}/tools/my-avbroot-setup/patch.py" \
    "generate_update_info(update_info, 'https://releases.example.com/PixeneOS/shiba/2026050400/shiba-2026050400-rootless-abc1234.zip')"

  rm -rf "${tmpdir}"
}

test_release_base_url_sed_metacharacters() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  WORKDIR="${tmpdir}/work"
  reset_release_config
  PIXENEOS_RELEASE_BASE_URL="https://releases.example.com/PixeneOS/amp&pipe|segment"
  write_patch_script

  my_avbroot_setup >/dev/null

  assert_file_contains \
    "${WORKDIR}/tools/my-avbroot-setup/patch.py" \
    "generate_update_info(update_info, 'https://releases.example.com/PixeneOS/amp&pipe|segment/shiba-2026050400-rootless-abc1234.zip')"

  rm -rf "${tmpdir}"
}

test_my_avbroot_setup_source_override() {
  reset_release_config
  PIXENEOS_AVBROOT_SETUP_SOURCE="https://example.com/tools/my-avbroot-setup.git"
  unset SIGNATURE_URL URL

  get() { :; }

  url_constructor "my-avbroot-setup" "false" >/dev/null

  if [[ "${URL}" != "${PIXENEOS_AVBROOT_SETUP_SOURCE}" ]]; then
    echo "Expected my-avbroot-setup URL override ${PIXENEOS_AVBROOT_SETUP_SOURCE}, got ${URL}" >&2
    exit 1
  fi
}

test_my_avbroot_setup_source_fallback() {
  reset_release_config
  unset SIGNATURE_URL URL

  get() { :; }

  url_constructor "my-avbroot-setup" "false" >/dev/null

  if [[ "${URL}" != "https://github.com/0cwa/my-avbroot-setup" ]]; then
    echo "Expected my-avbroot-setup fallback URL, got ${URL}" >&2
    exit 1
  fi
}

test_default_release_url
test_github_repository_release_url
test_release_base_url_override
test_release_base_url_trailing_slash
test_release_base_url_sed_metacharacters
test_my_avbroot_setup_source_override
test_my_avbroot_setup_source_fallback

echo "release URL configuration tests passed"
