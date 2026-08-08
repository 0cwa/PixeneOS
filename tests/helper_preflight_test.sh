#!/usr/bin/env bash
set -euo pipefail

source src/util_functions.sh

ROOT="$(mktemp -d)"
trap 'rm -rf "${ROOT}"' EXIT

fail() {
  echo "$*" >&2
  exit 1
}

assert_mode() {
  local path="${1}"
  local expected="${2}"

  [[ "$(stat -c '%a' "${path}")" == "${expected}" ]] ||
    fail "Expected ${path} mode ${expected}"
}

assert_file_equals() {
  local expected="${1}"
  local path="${2}"

  [[ "$(<"${path}")" == "${expected}" ]] ||
    fail "Expected ${path} to contain '${expected}'"
}

test_helper_version_is_pinned() {
  [[ "${VERSION[AVBROOT_SETUP]}" == "a14c242a89abb1a13b8c7474dd8235ee75fd31d6" ]] ||
    fail "Helper version is not pinned to the compatible commit"
}

test_helper_contract_preflight() (
  local helper="${ROOT}/contract/tools/my-avbroot-setup"
  local helper_head

  WORKDIR="${ROOT}/contract"
  mkdir -p "${helper}"
  git -C "${helper}" init -q
  printf '#!/usr/bin/env python3\n' >"${helper}/patch.py"
  git -C "${helper}" add patch.py
  git -C "${helper}" -c user.name=test -c user.email=test@example.invalid commit -qm fixture
  helper_head="$(git -C "${helper}" rev-parse HEAD)"
  VERSION[AVBROOT_SETUP]="${helper_head}"
  python() { [[ "${1}" == "${helper}/patch.py" && "${2}" == "--help" ]]; }

  helper_contract_preflight

  VERSION[AVBROOT_SETUP]=0000000000000000000000000000000000000000
  if helper_contract_preflight 2>/dev/null; then
    fail "Mismatched helper was accepted"
  fi
)

test_repository_preflight_failure_stops_before_download_and_helper_rewrite() (
  WORKDIR="${ROOT}/ordering"
  mkdir -p "${WORKDIR}"

  helper_repository_preflight() { return 1; }
  download_ota() { touch "${ROOT}/ota-downloaded"; }
  my_avbroot_setup() { touch "${ROOT}/helper-rewritten"; }
  create_ota() { my_avbroot_setup; }

  if create_and_make_release >/dev/null 2>&1; then
    fail "Failed helper repository preflight was reported as success"
  fi
  [[ ! -e "${ROOT}/ota-downloaded" ]] ||
    fail "OTA download ran after helper repository preflight failed"
  [[ ! -e "${ROOT}/helper-rewritten" ]] ||
    fail "Helper rewrite ran after helper repository preflight failed"
)

test_fresh_path_installs_requirements_before_smoke_and_rewrite() (
  local helper="${ROOT}/fresh/tools/my-avbroot-setup"
  local events="${ROOT}/fresh-events"

  WORKDIR="${ROOT}/fresh"
  ADDITIONALS[AVBROOT]="false"
  ADDITIONALS[AFSR]="false"
  ADDITIONALS[CUSTOTA_TOOL]="false"

  check_and_download_dependencies() {
    mkdir -p "${helper}"
    git -C "${helper}" init -q
    printf '#!/usr/bin/env python3\n' >"${helper}/patch.py"
    printf 'tomlkit==0.13.2\n' >"${helper}/requirements.txt"
    git -C "${helper}" add patch.py requirements.txt
    git -C "${helper}" -c user.name=test -c user.email=test@example.invalid commit -qm fixture
    VERSION[AVBROOT_SETUP]="$(git -C "${helper}" rev-parse HEAD)"
  }
  download_ota() { printf 'download\n' >>"${events}"; }
  generate_ota_info() { :; }
  enable_venv() { printf 'venv\n' >>"${events}"; }
  pip() { return 0; }
  pip3() { printf 'requirements\n' >>"${events}"; }
  python() {
    [[ "${1}" == "${helper}/patch.py" && "${2}" == "--help" ]] || return 1
    printf 'smoke\n' >>"${events}"
  }
  my_avbroot_setup() { printf 'rewrite\n' >>"${events}"; }
  patch_ota() { printf 'patch\n' >>"${events}"; }

  create_and_make_release >/dev/null

  assert_file_equals $'download\nvenv\nrequirements\nsmoke\nrewrite\npatch' "${events}"
)

test_make_directories_keeps_private_paths_private() (
  WORKDIR="${ROOT}/private-workdir"

  make_directories

  assert_mode "${WORKDIR}" 700
  assert_mode "${WORKDIR}/.keys" 700
  assert_mode "${WORKDIR}/tools" 700
)

test_helper_version_is_pinned
test_helper_contract_preflight
test_repository_preflight_failure_stops_before_download_and_helper_rewrite
test_fresh_path_installs_requirements_before_smoke_and_rewrite
test_make_directories_keeps_private_paths_private
echo "helper preflight tests: ok"
