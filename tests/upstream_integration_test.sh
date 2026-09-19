#!/usr/bin/env bash
set -euo pipefail

fail() { echo "$*" >&2; exit 1; }

grep -Fq "workflow_call:" .github/workflows/release.yml || fail "release.yml is not reusable"
grep -Fq "uses: ./.github/workflows/release.yml" .github/workflows/multi-release.yml || fail "multi-release does not reuse release.yml"
grep -Fq "_config_schema_define devices DEVICES" src/config_schema.sh || fail "DEVICES is not typed config"
grep -Fq "Remove superseded release assets" .github/workflows/build-rom.yml || fail "build workflow does not prune superseded assets"
grep -Fq 'MODULE_SELECTION_FINGERPRINT' src/ci/remove_superseded_assets.sh || fail "asset cleanup is not selection-aware"
grep -Fq 'VERSION[BCR]="${VERSION[BCR]:-3.9}"' src/declarations.sh || fail "BCR pin is not 3.9"
grep -Fq 'VERSION[CUSTOTA]="${VERSION[CUSTOTA]:-6.5}"' src/declarations.sh || fail "Custota pin is not 6.5"
grep -Fq 'VERSION[AVBROOT_SETUP]="ff9d4192d348569e0292e31b9739cd7647257b20"' src/declarations.sh || fail "maintained helper pin is unexpected"
grep -Fq '"version": "2.0.0"' locks/executable-tools-v1.json || fail "AFSR 2.0 lock entry is missing"
grep -Fq "pixincreate/Magisk" src/config_schema.sh || fail "GrapheneOS-oriented Magisk default is missing"

if grep -Fq "Charge Limit" README.md; then
  fail "README still advertises unsupported Charge Limit integration"
fi

echo "upstream integration invariants passed"
