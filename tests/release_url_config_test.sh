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

test_toml_env_allowlisted_assignments() {
  local force_update="${1:-true}"
  local tmpdir marker expected_literal status=0 module
  local -a module_toggles=(
    AFSR
    ALTERINSTALLER
    BCR
    CUSTOTA
    MSD
    OEMUNLOCKONBOOT
    BOOT_ANIMATION
    FDROID_PRIVILEGED_EXTENSION
  )
  tmpdir="$(mktemp -d)"
  marker="${tmpdir}/command-executed"
  expected_literal="literal value = \$(echo should-not-run) \`touch ${marker}\` ; &"

  (
    cd "${tmpdir}"
    printf '%s\n' \
      '[device]' \
      'DEVICE_NAME = "fixture-device"' \
      'INTERACTIVE_MODE = "false"' \
      'ROM_FAMILY = "grapheneos"' \
      'OUTPUT_SCOPE = "local-published"' \
      'PIXENEOS_RELEASE_OWNER = ""' \
      'PIXENEOS_RELEASE_REPOSITORY = "fixture-repo"' \
      "PIXENEOS_RELEASE_BASE_URL = \"${expected_literal}\"" \
      'PIXENEOS_AVBROOT_SETUP_SOURCE = "https://example.com/setup.git"' \
      "'GRAPHENEOS[UPDATE_CHANNEL]' = \"alpha\"" \
      'MAGISK[REPOSITORY] = "fixture/magisk=source"' \
      'ROOT = "true"' \
      'MAGISK_PREINIT = "sda10"' \
      "FORCE_UPDATE = \"${force_update}\"" \
      >env.toml

    for module in "${module_toggles[@]}"; do
      if [[ "${module}" == "BOOT_ANIMATION" ]]; then
        printf "'ADDITIONALS[%s]' = \"true\"\n" "${module}" >>env.toml
      else
        printf "'ADDITIONALS[%s]' = \"false\"\n" "${module}" >>env.toml
      fi
    done

    DEVICE_NAME="default-device"
    INTERACTIVE_MODE="default-interactive"
    ROM_FAMILY="default-rom"
    OUTPUT_SCOPE="default-scope"
    PIXENEOS_RELEASE_OWNER="default-owner"
    PIXENEOS_RELEASE_REPOSITORY="default-repository"
    PIXENEOS_RELEASE_BASE_URL="default-base-url"
    PIXENEOS_AVBROOT_SETUP_SOURCE="default-setup-source"
    GRAPHENEOS[UPDATE_CHANNEL]="default-channel"
    for module in "${module_toggles[@]}"; do
      ADDITIONALS[${module}]="default-${module}"
    done
    ADDITIONALS[ROOT]="false"
    MAGISK[PREINIT]="default-preinit"
    MAGISK[REPOSITORY]="default-repository"
    FORCE_UPDATE="default-force-update"

    check_toml_env >/dev/null

    [[ "${DEVICE_NAME}" == "fixture-device" ]]
    [[ "${INTERACTIVE_MODE}" == "false" ]]
    [[ "${ROM_FAMILY}" == "grapheneos" ]]
    [[ "${OUTPUT_SCOPE}" == "local-published" ]]
    [[ "${PIXENEOS_RELEASE_OWNER}" == "default-owner" ]]
    [[ "${PIXENEOS_RELEASE_REPOSITORY}" == "fixture-repo" ]]
    [[ "${PIXENEOS_RELEASE_BASE_URL}" == "${expected_literal}" ]]
    [[ "${PIXENEOS_AVBROOT_SETUP_SOURCE}" == "https://example.com/setup.git" ]]
    [[ "${GRAPHENEOS[UPDATE_CHANNEL]}" == "alpha" ]]
    for module in "${module_toggles[@]}"; do
      if [[ "${module}" == "BOOT_ANIMATION" ]]; then
        [[ "${ADDITIONALS[${module}]}" == "true" ]]
      else
        [[ "${ADDITIONALS[${module}]}" == "false" ]]
      fi
    done
    [[ "${ADDITIONALS[ROOT]}" == "true" ]]
    [[ "${MAGISK[PREINIT]}" == "sda10" ]]
    [[ "${MAGISK[REPOSITORY]}" == "fixture/magisk=source" ]]
    [[ "${FORCE_UPDATE}" == "${force_update}" ]]
    [[ ! -e "${marker}" ]]
  ) || status=$?

  rm -rf "${tmpdir}"
  return "${status}"
}

assert_toml_env_rejected() {
  local assignment="${1}" tmpdir status=0
  tmpdir="$(mktemp -d)"

  (
    cd "${tmpdir}"
    printf '%s\n' "${assignment}" >env.toml
    check_toml_env >/dev/null 2>&1
  ) || status=$?

  rm -rf "${tmpdir}"
  if [[ "${status}" -eq 0 ]]; then
    echo "Expected check_toml_env to reject: ${assignment}" >&2
    return 1
  fi
}

test_toml_env_rejects_unknown_and_malformed_keys() {
  assert_toml_env_rejected 'UNKNOWN_KEY = "value"'
  assert_toml_env_rejected 'GITHUB_USER = "attacker"'
  assert_toml_env_rejected 'GRAPHENEOS[UNKNOWN] = "value"'
  assert_toml_env_rejected 'ADDITIONALS[UNKNOWN] = "value"'
  assert_toml_env_rejected 'FORCE_UPDATE[VALUE] = "true"'
  assert_toml_env_rejected 'GRAPHENEOS[UPDATE_CHANNEL = "value"'
  assert_toml_env_rejected 'DEVICE-NAME = "value"'
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
test_toml_env_allowlisted_assignments true
test_toml_env_allowlisted_assignments false
test_toml_env_rejects_unknown_and_malformed_keys

echo "release URL configuration tests passed"
