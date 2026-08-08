#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
fixture_repo="$(mktemp -d)"
trap 'rm -rf "${fixture_repo}"' EXIT

cp "${repo_root}/.gitleaks.toml" "${fixture_repo}/.gitleaks.toml"
cp "${repo_root}/src/scan_secrets.sh" "${fixture_repo}/scan_secrets.sh"
chmod +x "${fixture_repo}/scan_secrets.sh"
git -C "${fixture_repo}" init --quiet

cat >"${fixture_repo}/workflow.yml" <<'EOF'
secrets:
  PASSPHRASE_AVB:
    required: true
  PASSPHRASE_OTA:
    required: true
EOF

(
  cd "${fixture_repo}"
  PIXENEOS_SKIP_GITLEAKS=true ./scan_secrets.sh --all >/dev/null
)

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks dir \
    --redact \
    --no-banner \
    --log-level error \
    --config "${fixture_repo}/.gitleaks.toml" \
    "${fixture_repo}"
fi

synthetic_value="synthetic"
synthetic_value+="-passphrase"
printf 'PASSPHRASE_AVB=%s\n' "${synthetic_value}" >"${fixture_repo}/unsafe.env"

if (
  cd "${fixture_repo}"
  PIXENEOS_SKIP_GITLEAKS=true ./scan_secrets.sh --all >/dev/null 2>&1
); then
  echo "fallback scanner accepted a same-line signing passphrase" >&2
  exit 1
fi

if command -v gitleaks >/dev/null 2>&1 &&
  gitleaks dir \
    --redact \
    --no-banner \
    --log-level error \
    --config "${fixture_repo}/.gitleaks.toml" \
    "${fixture_repo}" >/dev/null 2>&1; then
  echo "gitleaks accepted a same-line signing passphrase" >&2
  exit 1
fi

echo "Secrets scan regression tests passed"
