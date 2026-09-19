#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

set -euo pipefail

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
[[ -n "${sdk_root}" && -d "${sdk_root}" ]] || {
  echo "::error::Android SDK root is unavailable on this runner." >&2
  exit 1
}

apksigner="${sdk_root}/build-tools/36.0.0/apksigner"
[[ -x "${apksigner}" && ! -L "${apksigner}" ]] || {
  echo "::error::Required Android build-tools 36.0.0 apksigner is unavailable." >&2
  exit 1
}

apkanalyzer=''
for candidate in   "${sdk_root}/cmdline-tools/latest/bin/apkanalyzer"   "${sdk_root}/cmdline-tools/12.0/bin/apkanalyzer"; do
  if [[ -x "${candidate}" ]]; then
    apkanalyzer="$(realpath -e -- "${candidate}")"
    break
  fi
done
[[ -n "${apkanalyzer}" && -x "${apkanalyzer}" ]] || {
  echo "::error::Required Android apkanalyzer is unavailable." >&2
  exit 1
}

if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$(dirname -- "${apksigner}")" >>"${GITHUB_PATH}"
  printf '%s\n' "$(dirname -- "${apkanalyzer}")" >>"${GITHUB_PATH}"
else
  echo "::error::GITHUB_PATH is required to configure APK verifier tools." >&2
  exit 1
fi

echo "Configured Android APK identity verification tools."
