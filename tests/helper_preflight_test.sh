#!/usr/bin/env bash
set -euo pipefail

source src/util_functions.sh

ROOT="$(mktemp -d)"
trap 'rm -rf "${ROOT}"' EXIT
fail() { echo "$*" >&2; exit 1; }

test_dependency_format_selection() (
  WORKDIR="${ROOT}/deps"
  ADDITIONALS[AVBROOT]="false"
  ADDITIONALS[AFSR]="false"
  ADDITIONALS[CUSTOTA_TOOL]="false"
  mkdir -p "${WORKDIR}/tools/my-avbroot-setup" "${WORKDIR}/tools/my-avbroot-setup/venv/bin"
  touch "${WORKDIR}/tools/my-avbroot-setup/venv/bin/activate"
  printf 'generate_update_info(update_info, args.output.name)\n' >"${WORKDIR}/tools/my-avbroot-setup/patch.py"
  enable_venv() { :; }
  command() { [[ "$1" == "-v" && "$2" == "uv" ]]; }
  python() { printf '%s\n' "$*" >"${ROOT}/pip-call"; }
  uv() { printf '%s\n' "$*" >"${ROOT}/uv-call"; }
  printf 'pkg==1\n' >"${WORKDIR}/tools/my-avbroot-setup/requirements.txt"
  env_setup >/dev/null
  [[ -s "${ROOT}/pip-call" ]] || fail "requirements.txt did not select pip"
  [[ ! -e "${ROOT}/uv-call" ]] || fail "requirements.txt incorrectly selected uv"
)

test_missing_dependency_manifests_fail() (
  WORKDIR="${ROOT}/missing"
  ADDITIONALS[AVBROOT]="false"
  ADDITIONALS[AFSR]="false"
  ADDITIONALS[CUSTOTA_TOOL]="false"
  mkdir -p "${WORKDIR}/tools/my-avbroot-setup"
  enable_venv() { :; }
  if env_setup >/dev/null 2>&1; then fail "missing dependency manifests were accepted"; fi
)

test_helper_contract_preflight() (
  local helper="${ROOT}/contract/tools/my-avbroot-setup"
  WORKDIR="${ROOT}/contract"
  mkdir -p "${helper}"
  git -C "${helper}" init -q
  printf '#!/usr/bin/env python3\nimport sys\nprint("ok")\n' >"${helper}/patch.py"
  chmod +x "${helper}/patch.py"
  git -C "${helper}" add patch.py
  git -C "${helper}" -c user.name=test -c user.email=test@example.invalid commit -qm fixture
  VERSION[AVBROOT_SETUP]="$(git -C "${helper}" rev-parse HEAD)"
  python() { [[ "$2" == "--help" ]]; }
  helper_contract_preflight
  VERSION[AVBROOT_SETUP]=0000000000000000000000000000000000000000
  if helper_contract_preflight 2>/dev/null; then fail "mismatched helper was accepted"; fi
)

test_make_directories_keeps_bootstrap_tools_private() (
  WORKDIR="${ROOT}/private-workdir"

  make_directories

  [[ "$(stat -c '%a' "${WORKDIR}/tools")" == "700" ]] ||
    fail "bootstrap tools directory is not private"
)

test_dependency_format_selection
test_missing_dependency_manifests_fail
test_helper_contract_preflight
test_make_directories_keeps_bootstrap_tools_private
echo "helper preflight tests: ok"
