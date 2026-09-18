#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

default_value="$(env -u ADDITIONALS_BOOT_ANIMATION bash -c '
  source src/declarations.sh
  printf "%s\n" "${ADDITIONALS[BOOT_ANIMATION]}"
')"
[[ "${default_value}" == "false" ]] || {
  echo "boot animation is not default-off: ${default_value}" >&2
  exit 1
}

enabled_value="$(ADDITIONALS_BOOT_ANIMATION=true bash -c '
  source src/declarations.sh
  printf "%s\n" "${ADDITIONALS[BOOT_ANIMATION]}"
')"
[[ "${enabled_value}" == "true" ]] || {
  echo "boot animation environment override was not applied" >&2
  exit 1
}

echo "boot animation configuration tests passed"
