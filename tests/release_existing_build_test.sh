#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT_DIR}/src/ci/check_existing_build.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEST_DIR}"' EXIT

FAKE_BIN="${TEST_DIR}/bin"
mkdir -p -- "${FAKE_BIN}"
cat >"${FAKE_BIN}/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=''
request_url=''
while (($#)); do
  case "$1" in
    --output)
      output="$2"
      shift 2
      ;;
    --retry|--retry-delay)
      shift 2
      ;;
    --silent|--show-error|--location|--fail)
      shift
      ;;
    *)
      request_url="$1"
      shift
      ;;
  esac
done

if [[ "${CURL_MODE:-success}" == 'fail' ]]; then
  exit 22
fi

if [[ "${request_url}" == */releases/download/* ]]; then
  metadata_asset="${request_url##*/}"
  metadata_source="${FIXTURE_METADATA_DIR:-}/${metadata_asset}"
  [[ -f "${metadata_source}" ]] || exit 1
  cp -- "${metadata_source}" "${output}"
else
  cp -- "${FIXTURE_RESPONSE}" "${output}"
fi
EOF
chmod 0700 -- "${FAKE_BIN}/curl"

TOKEN='0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
OTHER_TOKEN='abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789'

fail() {
  echo "$*" >&2
  exit 1
}

setup_repo() {
  local repo_dir="${1}"

  mkdir -p -- "${repo_dir}"
  git -C "${repo_dir}" init -q
  git -C "${repo_dir}" config user.email fixture@example.invalid
  git -C "${repo_dir}" config user.name fixture
  printf 'fixture\n' >"${repo_dir}/tracked"
  git -C "${repo_dir}" add tracked
  git -C "${repo_dir}" commit -q -m fixture
  git -C "${repo_dir}" tag 20260911
}

write_metadata() {
  local directory="${1}"
  local artifact="${2}"
  local fingerprint="${3}"
  local device="${4:-bramble}"
  local family="${5:-grapheneos}"
  local version="${6:-20260911}"
  local scope="${7:-published}"

  mkdir -p -- "${directory}"
  printf '{\n  "artifact_name": "%s",\n  "device": "%s",\n  "grapheneos_version": "%s",\n  "module_selection_fingerprint": "%s",\n  "output_scope": "%s",\n  "rom_family": "%s",\n  "schema_version": 2\n}\n' \
    "${artifact}" "${device}" "${version}" "${fingerprint}" "${scope}" "${family}" \
    >"${directory}/${artifact}.selection.json"
}

write_malformed_metadata() {
  local directory="${1}"
  local artifact="${2}"

  mkdir -p -- "${directory}"
  printf '{not-json\n' >"${directory}/${artifact}.selection.json"
}

write_old_schema_metadata() {
  local directory="${1}"
  local artifact="${2}"

  mkdir -p -- "${directory}"
  printf '{\n  "artifact_name": "%s",\n  "device": "bramble",\n  "grapheneos_version": "20260911",\n  "module_selection_fingerprint": "%s",\n  "output_scope": "published",\n  "rom_family": "grapheneos",\n  "schema_version": 1\n}\n' \
    "${artifact}" "${TOKEN}" >"${directory}/${artifact}.selection.json"
}

run_case() {
  local name="${1}"
  local expected_status="${2}"
  local expected_build="${3}"
  local fixture="${4}"
  local expected_variant="${5}"
  local metadata_dir="${6:-}"
  local force_update="${7:-false}"
  local root="${8:-false}"
  local debug="${9:-false}"
  local magisk_version="${10:-}"
  local case_dir="${TEST_DIR}/${name}"
  local repo_dir="${case_dir}/repo"
  local output_file="${case_dir}/output"
  local env_file="${case_dir}/env"
  local stdout_file="${case_dir}/stdout"
  local stderr_file="${case_dir}/stderr"
  local status actual_build force_rebuild

  mkdir -p -- "${case_dir}"
  setup_repo "${repo_dir}"
  printf '%s\n' "${fixture}" >"${case_dir}/response.json"
  : >"${output_file}"
  : >"${env_file}"

  set +e
  (
    cd "${repo_dir}"
    PATH="${FAKE_BIN}:${PATH}" \
      FIXTURE_RESPONSE="${case_dir}/response.json" \
      FIXTURE_METADATA_DIR="${metadata_dir}" \
      DEVICE_NAME='bramble' \
      GRAPHENEOS_VERSION='20260911' \
      REPOSITORY='0cwa/PixeneOS' \
      ROM_FAMILY='grapheneos' \
      OUTPUT_SCOPE='published' \
      ROOT="${root}" \
      DEBUG="${debug}" \
      MAGISK_VERSION="${magisk_version}" \
      EXPECTED_VARIANT="${expected_variant}" \
      FORCE_UPDATE="${force_update}" \
      GITHUB_OUTPUT="${output_file}" \
      GITHUB_ENV="${env_file}" \
      "${SCRIPT}" >"${stdout_file}" 2>"${stderr_file}"
  )
  status=$?
  set -e

  [[ "${status}" -eq "${expected_status}" ]] || {
    cat "${stdout_file}" "${stderr_file}" >&2
    fail "${name}: expected status ${expected_status}, got ${status}"
  }

  actual_build="$(sed -n 's/^should_build=//p' "${output_file}")"
  if [[ "${expected_build}" == 'unset' ]]; then
    [[ -z "${actual_build}" ]] || fail "${name}: unexpected should_build=${actual_build}"
  else
    [[ "${actual_build}" == "${expected_build}" ]] ||
      fail "${name}: expected should_build=${expected_build}, got ${actual_build:-unset}"
  fi

  force_rebuild="$(sed -n 's/^FORCE_REBUILD=//p' "${env_file}")"
  if [[ "${force_update}" == 'true' ]]; then
    [[ "${force_rebuild}" == 'true' ]] || fail "${name}: FORCE_REBUILD was not written"
  else
    [[ -z "${force_rebuild}" ]] || fail "${name}: unexpected FORCE_REBUILD=${force_rebuild}"
  fi
}

EXACT_ARTIFACT="bramble-20260911-rootless-${TOKEN}-deadbee.zip"
EXACT_DIR="${TEST_DIR}/exact-metadata"
write_metadata "${EXACT_DIR}" "${EXACT_ARTIFACT}" "${TOKEN}"
run_case exact_triplet_skip 0 false \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${EXACT_DIR}"

OTHER_ARTIFACT="bramble-20260911-rootless-${OTHER_TOKEN}-cafebabe.zip"
OTHER_DIR="${TEST_DIR}/other-metadata"
write_metadata "${OTHER_DIR}" "${OTHER_ARTIFACT}" "${OTHER_TOKEN}"
run_case different_fingerprint_variant 0 true \
  "{\"assets\":[{\"name\":\"${OTHER_ARTIFACT}\"},{\"name\":\"${OTHER_ARTIFACT}.csig\"},{\"name\":\"${OTHER_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${OTHER_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${OTHER_DIR}"

run_case missing_metadata 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"}]}" \
  "${TOKEN}"

MISMATCH_DIR="${TEST_DIR}/mismatch-metadata"
write_metadata "${MISMATCH_DIR}" "${EXACT_ARTIFACT}" "${OTHER_TOKEN}"
run_case metadata_mismatch 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${MISMATCH_DIR}"

FILENAME_MISMATCH_DIR="${TEST_DIR}/filename-mismatch-metadata"
write_metadata "${FILENAME_MISMATCH_DIR}" "${OTHER_ARTIFACT}" "${TOKEN}"
mv -- "${FILENAME_MISMATCH_DIR}/${OTHER_ARTIFACT}.selection.json" \
  "${FILENAME_MISMATCH_DIR}/${EXACT_ARTIFACT}.selection.json"
run_case metadata_filename_mismatch 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${FILENAME_MISMATCH_DIR}"

SECOND_ARTIFACT="bramble-20260911-rootless-${TOKEN}-cafebabe.zip"
MULTIPLE_DIR="${TEST_DIR}/multiple-metadata"
write_metadata "${MULTIPLE_DIR}" "${EXACT_ARTIFACT}" "${TOKEN}"
write_metadata "${MULTIPLE_DIR}" "${SECOND_ARTIFACT}" "${TOKEN}"
run_case multiple_matching_variants 1 unset \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"},{\"name\":\"${SECOND_ARTIFACT}\"},{\"name\":\"${SECOND_ARTIFACT}.csig\"},{\"name\":\"${SECOND_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${SECOND_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${MULTIPLE_DIR}"

run_case unknown_expected_identity 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  '' "${EXACT_DIR}"

run_case force_update 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${EXACT_DIR}" true

ROOT_ARTIFACT="bramble-20260911-magisk-v29-debug-adb-${TOKEN}-deadbee.zip"
ROOT_DIR_FIXTURE="${TEST_DIR}/root-metadata"
write_metadata "${ROOT_DIR_FIXTURE}" "${ROOT_ARTIFACT}" "${TOKEN}"
run_case rooted_debug_filename 0 false \
  "{\"assets\":[{\"name\":\"${ROOT_ARTIFACT}\"},{\"name\":\"${ROOT_ARTIFACT}.csig\"},{\"name\":\"${ROOT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${ROOT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${ROOT_DIR_FIXTURE}" false true true v29

MALFORMED_DIR="${TEST_DIR}/malformed-metadata"
write_malformed_metadata "${MALFORMED_DIR}" "${EXACT_ARTIFACT}"
run_case malformed_metadata 1 unset \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${MALFORMED_DIR}"

OLD_SCHEMA_DIR="${TEST_DIR}/old-schema-metadata"
write_old_schema_metadata "${OLD_SCHEMA_DIR}" "${EXACT_ARTIFACT}"
run_case old_schema_metadata 0 true \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}.csig\"},{\"name\":\"${EXACT_ARTIFACT}.selection.json\",\"browser_download_url\":\"https://github.com/0cwa/PixeneOS/releases/download/20260911/${EXACT_ARTIFACT}.selection.json\"}]}" \
  "${TOKEN}" "${OLD_SCHEMA_DIR}"

# Make the transport fail only for this API call.
TRANSPORT_DIR="${TEST_DIR}/transport-failure"
mkdir -p -- "${TRANSPORT_DIR}"
setup_repo "${TRANSPORT_DIR}/repo"
: >"${TRANSPORT_DIR}/output"
: >"${TRANSPORT_DIR}/env"
set +e
(
  cd "${TRANSPORT_DIR}/repo"
  PATH="${FAKE_BIN}:${PATH}" \
    FIXTURE_RESPONSE="${TRANSPORT_DIR}/response.json" \
    CURL_MODE=fail \
    DEVICE_NAME='bramble' \
    GRAPHENEOS_VERSION='20260911' \
    REPOSITORY='0cwa/PixeneOS' \
    ROM_FAMILY='grapheneos' \
    OUTPUT_SCOPE='published' \
    EXPECTED_VARIANT="${TOKEN}" \
    GITHUB_OUTPUT="${TRANSPORT_DIR}/output" \
    GITHUB_ENV="${TRANSPORT_DIR}/env" \
    "${SCRIPT}" >/dev/null 2>/dev/null
)
status=$?
set -e
[[ "${status}" -ne 0 ]] || fail 'transport failure: expected non-zero status'
[[ -z "$(sed -n 's/^should_build=//p' "${TRANSPORT_DIR}/output")" ]] ||
  fail 'transport failure: API failure produced a build decision'

run_case empty_assets 0 true '{"assets":[]}' "${TOKEN}"
run_case empty_object 1 unset '{}' "${TOKEN}"
run_case malformed_json 1 unset 'not-json' "${TOKEN}"
run_case non_array_assets 1 unset '{"assets":{}}' "${TOKEN}"
run_case rate_limit 1 unset '{"message":"API rate limit exceeded","documentation_url":"https://docs.github.com/rest"}' "${TOKEN}"
run_case duplicate_assets 1 unset \
  "{\"assets\":[{\"name\":\"${EXACT_ARTIFACT}\"},{\"name\":\"${EXACT_ARTIFACT}\"}]}" "${TOKEN}"

echo "existing-build preflight tests passed"
