#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: src/scan_secrets.sh [--staged|--all]

Runs the PixeneOS secrets scan. If gitleaks is installed, the standard
scanner runs with .gitleaks.toml. A small project-specific fallback also
runs so AVB/OTA signing material is still covered on contributor machines
that have not installed gitleaks yet.
EOF
}

mode="all"
case "${1:-}" in
  ""|--all) mode="all" ;;
  --staged) mode="staged" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

config=".gitleaks.toml"

run_gitleaks() {
  if [[ "${PIXENEOS_SKIP_GITLEAKS:-false}" == "true" ]]; then
    return 0
  fi

  if ! command -v gitleaks >/dev/null 2>&1; then
    echo "warning: gitleaks is not installed; running PixeneOS fallback scanner only." >&2
    echo "         Install gitleaks for full standard secret scanning coverage." >&2
    return 0
  fi

  if [[ "${mode}" == "staged" ]]; then
    gitleaks protect --staged --redact --config "${config}"
  else
    gitleaks detect --source . --redact --config "${config}"
  fi
}

failures=0

record_failure() {
  local path="$1"
  local reason="$2"
  printf 'secret scan failure: %s: %s\n' "${path}" "${reason}" >&2
  failures=$((failures + 1))
}

is_sensitive_path() {
  local path="$1"
  local base="${path##*/}"

  case "${path}" in
    .keys|.keys/*|*/.keys|*/.keys/*) return 0 ;;
  esac

  case "${base}" in
    avb.key|ota.key|ota.crt|avb_pkmd.bin) return 0 ;;
  esac

  return 1
}

check_content_file() {
  local path="$1"
  local file="$2"
  local base64_secret_regex=$'\\b(KEYS_AVB_BASE64|KEYS_CERT_OTA_BASE64|KEYS_OTA_BASE64|AVB_KEY|CERT_OTA|OTA_KEY)\\b[[:space:]]*[:=][[:space:]]*["\\\']?[A-Za-z0-9+/]{40,}={0,2}'
  local passphrase_regex=$'\\b(PASSPHRASE_AVB|PASSPHRASE_OTA)\\b[[:space:]]*[:=][[:space:]]*["\\\']?[^$[:space:]"\\\'][^[:space:]"\\\']{7,}'

  if grep -IEq -- '-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' "${file}"; then
    record_failure "${path}" "contains a private-key PEM marker"
  fi

  if grep -IEq -- "${base64_secret_regex}" "${file}"; then
    record_failure "${path}" "contains a PixeneOS base64 signing secret assignment"
  fi

  if grep -IEq -- "${passphrase_regex}" "${file}"; then
    record_failure "${path}" "contains a PixeneOS signing passphrase assignment"
  fi
}

scan_path() {
  local path="$1"

  if is_sensitive_path "${path}"; then
    record_failure "${path}" "matches PixeneOS signing material path"
  fi

  if [[ "${mode}" == "staged" ]]; then
    local staged_tmp
    staged_tmp="$(mktemp)"
    if git cat-file -e ":${path}" 2>/dev/null && git show ":${path}" >"${staged_tmp}" 2>/dev/null; then
      check_content_file "${path}" "${staged_tmp}"
    fi
    rm -f "${staged_tmp}"
  elif [[ -f "${path}" ]]; then
    check_content_file "${path}" "${path}"
  fi
}

run_fallback_scan() {
  local path
  if [[ "${mode}" == "staged" ]]; then
    while IFS= read -r -d '' path; do
      scan_path "${path}"
    done < <(git diff --cached --name-only -z --diff-filter=ACMR)
  else
    while IFS= read -r -d '' path; do
      scan_path "${path}"
    done < <(git ls-files -z --cached --others --exclude-standard)
  fi

  if (( failures > 0 )); then
    echo "PixeneOS secrets scan failed. Move signing material to local-only storage and use GitHub secrets for CI values." >&2
    return 1
  fi
}

run_gitleaks
run_fallback_scan

echo "PixeneOS secrets scan passed."
