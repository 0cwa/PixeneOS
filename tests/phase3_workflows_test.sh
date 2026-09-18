#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

set -euo pipefail

WORKFLOW_DIR=".github/workflows"
REUSABLE="${WORKFLOW_DIR}/build-rom.yml"
RELEASE="${WORKFLOW_DIR}/release.yml"

fail() {
  echo "$*" >&2
  exit 1
}

assert_contains() {
  local file="${1}"
  local pattern="${2}"
  local context="${3}"

  grep -Eq -- "${pattern}" "${file}" ||
    fail "${context}: ${file} does not match ${pattern}"
}

assert_not_contains() {
  local file="${1}"
  local pattern="${2}"
  local context="${3}"

  if grep -Eq -- "${pattern}" "${file}"; then
    fail "${context}: ${file} unexpectedly matches ${pattern}"
  fi
}

assert_thin_trigger() {
  local file="${1}"
  local family="${2}"

  [[ -f "${file}" ]] || fail "missing ${family} release trigger: ${file}"
  assert_contains \
    "${file}" \
    'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' \
    "${family} trigger must call the shared workflow"
  assert_contains \
    "${file}" \
    "rom-family:[[:space:]]*['\"]?${family}['\"]?" \
    "${family} trigger must select its ROM family"
  assert_not_contains \
    "${file}" \
    'uses:[[:space:]]*actions/checkout@' \
    "thin triggers must not duplicate checkout/build steps"
  assert_not_contains \
    "${file}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "release triggers must not check out a divergent lineage branch"
}

assert_dispatch_default() {
  local file="${1}"
  local input="${2}"
  local expected="${3}"
  local actual
  local trigger='workflow_call'

  if grep -Eq '^[[:space:]]{2}workflow_dispatch:[[:space:]]*

  [[ "${actual}" == "${expected}" ]] ||
    fail "${file}: ${input} default expected ${expected}, got ${actual:-missing}"
}

assert_workflow_input_contract() {
  local file="${1}"
  local input="${2}"
  local expected_type="${3}"
  local expected_default="${4}"
  local actual
  local trigger='workflow_call'

  if grep -Eq '^[[:space:]]{2}workflow_dispatch:[[:space:]]*

  [[ "${actual}" == "${expected_type}|${expected_default}" ]] ||
    fail "${file}: ${input} input expected ${expected_type}|${expected_default}, got ${actual:-missing}"
}

find_manual_acceptance_workflow() {
  local file

  for file in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
    [[ -f "${file}" ]] || continue
    [[ "${file}" == "${REUSABLE}" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release.yml" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release-lineage.yml" ]] && continue
    if grep -Eq 'workflow_dispatch:' "${file}" &&
      grep -Eq 'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' "${file}" &&
      grep -Eqi 'build-only|publish:[[:space:]]*false' "${file}"; then
      printf '%s\n' "${file}"
      return 0
    fi
  done

  return 1
}

test_reusable_workflow() {
  [[ -f "${REUSABLE}" ]] || fail "missing reusable ROM workflow: ${REUSABLE}"
  assert_contains \
    "${REUSABLE}" \
    'workflow_call:' \
    "shared ROM workflow must be reusable"
  assert_contains \
    "${REUSABLE}" \
    'rom-family:' \
    "shared ROM workflow must accept a ROM family"
  assert_dispatch_default "${REUSABLE}" boot-animation false
  assert_dispatch_default "${REUSABLE}" afsr true
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_BOOT_ANIMATION' \
    "shared workflow must pass the boot-animation selection"
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_AFSR' \
    "shared workflow must pass the AFSR selection"
  local contract input expected_type expected_default
  for contract in \
    'afsr:boolean:true' \
    'alterinstaller:boolean:true' \
    'bcr:boolean:true' \
    'custota:boolean:true' \
    'msd:boolean:true' \
    'oemunlockonboot:boolean:true' \
    'fdroid-privileged-extension:boolean:false'; do
    IFS=: read -r input expected_type expected_default <<<"${contract}"
    assert_workflow_input_contract \
      "${REUSABLE}" "${input}" "${expected_type}" "${expected_default}"
  done
  assert_contains \
    "${REUSABLE}" \
    'uses:[[:space:]]*actions/checkout@' \
    "shared ROM workflow must own checkout"
  assert_contains \
    "${REUSABLE}" \
    'MODULE_SELECTION_FINGERPRINT' \
    "shared workflow must retain the full selection fingerprint as metadata"
  assert_contains \
    "${REUSABLE}" \
    '"artifact_name": artifact_name' \
    "selection metadata must bind the exact output filename"
  assert_contains \
    "${REUSABLE}" \
    '"grapheneos_version": version' \
    "selection metadata must bind the GrapheneOS version"
  assert_contains \
    "${REUSABLE}" \
    '"schema_version": 2' \
    "selection metadata must use the variant-aware schema"
  assert_contains \
    "${REUSABLE}" \
    'OUTPUT_SCOPE' \
    "shared workflow must set an explicit output scope"
  assert_contains \
    "${REUSABLE}" \
    'enforce_output_policy' \
    "shared workflow must enforce policy before release or upload"
  assert_contains \
    "${REUSABLE}" \
    'enforce_publication_evidence' \
    "shared workflow must enforce publication evidence"
  assert_not_contains \
    "${REUSABLE}" \
    'actions/upload-artifact@' \
    "local-unpublished outputs must not be uploaded"
  assert_not_contains \
    "${REUSABLE}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "shared ROM workflow must not check out a divergent lineage branch"
}

test_release_triggers() {
  assert_thin_trigger "${RELEASE}" grapheneos
  assert_thin_trigger "${WORKFLOW_DIR}/release-lineage.yml" lineageos

  assert_dispatch_default "${RELEASE}" device-id shiba
  assert_dispatch_default "${RELEASE}" root true
  assert_dispatch_default "${RELEASE}" alterinstaller true
  assert_dispatch_default "${RELEASE}" bcr true
  assert_dispatch_default "${RELEASE}" custota true
  assert_dispatch_default "${RELEASE}" msd true
  assert_dispatch_default "${RELEASE}" oemunlockonboot true
  assert_dispatch_default "${RELEASE}" fdroid-privileged-extension false
  assert_dispatch_default "${RELEASE}" boot-animation false
  assert_dispatch_default \
    "${RELEASE}" compatible-sepolicy-patching false
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" device-id pdx235
  assert_dispatch_default "${WORKFLOW_DIR}/release-lineage.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" compatible-sepolicy-patching true
}

test_config_loading_isolated_to_grapheneos_schedule() {
  local lineage="${WORKFLOW_DIR}/release-lineage.yml"
  local build_only="${WORKFLOW_DIR}/phase3-build-only.yml"

  assert_not_contains "${lineage}" 'env\.toml|check_toml_env' \
    "LineageOS release must not load GrapheneOS env.toml configuration"
  assert_not_contains "${build_only}" 'env\.toml|check_toml_env' \
    "build-only acceptance must keep its declared defaults"
  assert_contains "${build_only}" 'publish:[[:space:]]*false' \
    "build-only acceptance must remain local-unpublished"
}

test_release_configuration_forwarding() {
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Load scheduled env\.toml configuration' \
    "scheduled release must load env.toml"
  assert_contains \
    "${RELEASE}" \
    'if:[[:space:]]*github\.event_name == .schedule.' \
    "scheduled configuration must be schedule-only"
  assert_contains \
    "${RELEASE}" \
    'source src/util_functions\.sh' \
    "scheduled configuration must use shared config parsing"
  assert_contains \
    "${RELEASE}" \
    'check_toml_env' \
    "scheduled configuration must use allowlisted TOML parsing"
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Resolve expected selection identity' \
    "release preflight must resolve the canonical selection identity"
  assert_contains \
    "${RELEASE}" \
    'module_selection_fingerprint' \
    "release preflight must use the shared selection fingerprint"
  assert_contains \
    "${RELEASE}" \
    'expected_variant:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "release preflight must expose the resolved identity"
  assert_contains \
    "${RELEASE}" \
    'EXPECTED_VARIANT:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "existing-build preflight must receive the resolved identity"
  for identity_input in \
    'ROM_FAMILY:[[:space:]]*grapheneos' \
    'OUTPUT_SCOPE:[[:space:]]*published' \
    'ADDITIONALS_MAS_COMPATIBLE_SEPOLICY' \
    'ADDITIONALS_DEBUG' \
    'ADDITIONALS_BOOT_ANIMATION' \
    'ADDITIONALS_AFSR' \
    'MAGISK_VERSION:[[:space:]]*\$\{\{ steps\.resolve_version\.outputs\.magisk_version \}\}'; do
    assert_contains "${RELEASE}" "${identity_input}" \
      "release preflight must pass ${identity_input%%:*} to identity resolution"
  done
  assert_contains \
    "${RELEASE}" \
    'ADDITIONALS_AFSR:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "release preflight must preserve scheduled AFSR=false"
  assert_contains \
    "${RELEASE}" \
    'force_update="\$\(toml_resolve_value force_update "\$\{DEFAULT_FORCE_UPDATE\}"\)"' \
    "scheduled configuration must resolve FORCE_UPDATE through the typed contract"
  assert_contains \
    "${RELEASE}" \
    'validate_scheduled_boolean "\$\{force_update\}" "FORCE_UPDATE must be true or false"' \
    "scheduled FORCE_UPDATE must be validated as a boolean"
  assert_contains \
    "${RELEASE}" \
    'echo "FORCE_UPDATE=\$\{force_update\}"' \
    "scheduled configuration must export FORCE_UPDATE"
  assert_contains \
    "${RELEASE}" \
    'echo "force_update=\$\{force_update\}"' \
    "scheduled configuration must expose FORCE_UPDATE to preflight"
  assert_contains \
    "${RELEASE}" \
    'force_update:[[:space:]]*\$\{\{ steps\.scheduled_config\.outputs\.force_update \}\}' \
    "preflight must expose scheduled FORCE_UPDATE as a job output"
  assert_contains \
    "${RELEASE}" \
    'FORCE_UPDATE:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.force_update \|\| false \}\}' \
    "existing-build preflight must receive scheduled FORCE_UPDATE"
  for default in \
    'DEFAULT_DEVICE_NAME:[[:space:]]*bramble' \
    'DEFAULT_UPDATE_CHANNEL:[[:space:]]*stable' \
    'DEFAULT_ROOT:[[:space:]]*false' \
    'DEFAULT_AFSR:[[:space:]]*true' \
    'DEFAULT_MAGISK_PREINIT:[[:space:]]*sda10' \
    'DEFAULT_BOOT_ANIMATION:[[:space:]]*false' \
    'DEFAULT_FORCE_UPDATE:[[:space:]]*false'; do
    assert_contains "${RELEASE}" "${default}" \
      "scheduled configuration must retain explicit defaults"
  done
  assert_contains \
    "${RELEASE}" \
    'device-id:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.device_id \|\| inputs\.device-id \}\}' \
    "manual device input must remain authoritative"
  assert_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation == .true. \|\| inputs\.boot-animation \|\| false \}\}' \
    "boot animation must be forwarded with a default-off fallback"
  assert_contains \
    "${RELEASE}" \
    'afsr:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "AFSR must be forwarded without converting scheduled false to true"
  assert_not_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation \|\| inputs\.boot-animation' \
    "boot animation must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root == .true. \|\| inputs\.root \}\}' \
    "root must explicitly coerce the scheduled string output to boolean"
  assert_not_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root \|\| inputs\.root \}\}' \
    "root must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'magisk-preinit-device:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.magisk_preinit_device' \
    "scheduled preinit configuration must be forwarded"
  assert_contains \
    "${RELEASE}" \
    'update-channel:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.update_channel' \
    "scheduled update channel must be forwarded"
}

test_module_forwarding_contract() {
  local contract input config output

  for contract in \
    'afsr:AFSR:afsr' \
    'alterinstaller:ALTERINSTALLER:alterinstaller' \
    'bcr:BCR:bcr' \
    'custota:CUSTOTA:custota' \
    'msd:MSD:msd' \
    'oemunlockonboot:OEMUNLOCKONBOOT:oemunlockonboot' \
    'fdroid-privileged-extension:FDROID_PRIVILEGED_EXTENSION:fdroid_privileged_extension'; do
    IFS=: read -r input config output <<<"${contract}"

    assert_contains \
      "${RELEASE}" \
      "toml_resolve_value ${output}" \
      "scheduled configuration must resolve ${config} through the typed contract"
    assert_contains \
      "${RELEASE}" \
      "echo \"${output}=" \
      "scheduled configuration must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "steps\\.scheduled_config\\.outputs\\.${output}" \
      "preflight must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "ADDITIONALS_${config}:[[:space:]].*steps\\.scheduled_config\\.outputs\\.${output}.*inputs\\.${input}" \
      "expected identity must use scheduled/manual ${input}"
    assert_contains \
      "${RELEASE}" \
      "needs\\.preflight\\.outputs\\.${output}[[:space:]]*==[[:space:]]*['\"]true['\"].*inputs\\.${input}" \
      "build invocation must use scheduled/manual ${input}"
    assert_contains \
      "${REUSABLE}" \
      "ADDITIONALS_${config}:[[:space:]].*inputs\\.${input}" \
      "reusable build must map ${config} from input ${input}"
  done
}

test_publication_identity_is_step_scoped() {
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_EMAIL:[[:space:]]*\$\{\{ secrets\.EMAIL \}\}' \
    "publication identity email must be step-scoped"
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_NAME:[[:space:]]*\$\{\{ github\.repository_owner \}\}' \
    "publication identity name must be step-scoped"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.email "\$\{GIT_COMMIT_EMAIL-\}"' \
    "publication helper must configure local email from the step environment"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.name "\$\{GIT_COMMIT_NAME-\}"' \
    "publication helper must configure local name from the step environment"
  assert_not_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'git config user\.email .*secrets\.EMAIL' \
    "publication must not interpolate the email secret in shell source"
}

test_manual_build_only_acceptance() {
  local acceptance

  acceptance="$(find_manual_acceptance_workflow)" ||
    fail "missing manual build-only workflow that calls build-rom.yml"
  assert_contains \
    "${acceptance}" \
    'workflow_dispatch:' \
    "acceptance workflow must be manually dispatched"
  assert_contains \
    "${acceptance}" \
    '^[[:space:]]*contents:[[:space:]]*write[[:space:]]*$' \
    "acceptance workflow must grant contents write permission"
}

test_no_lineage_checkout_anywhere() {
  local file

  while IFS= read -r -d '' file; do
    assert_not_contains \
      "${file}" \
      '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
      "workflows must use the main branch implementation"
  done < <(find "${WORKFLOW_DIR}" -maxdepth 1 -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print0)
}

test_reusable_workflow
test_release_triggers
test_config_loading_isolated_to_grapheneos_schedule
test_release_configuration_forwarding
test_module_forwarding_contract
test_publication_identity_is_step_scoped
test_manual_build_only_acceptance
test_no_lineage_checkout_anywhere

echo "Phase 3 workflow tests passed"
 "${file}"; then
    trigger='workflow_dispatch'
  fi

  actual="$(awk -v input="${input}" -v trigger="${trigger}" '
    $0 ~ "^[[:space:]]{2}" trigger ":[[:space:]]*$" { in_trigger = 1; next }
    in_trigger && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_trigger && $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      print
      exit
    }
  ' "${file}")"

  [[ "${actual}" == "${expected}" ]] ||
    fail "${file}: ${input} default expected ${expected}, got ${actual:-missing}"
}

assert_workflow_input_contract() {
  local file="${1}"
  local input="${2}"
  local expected_type="${3}"
  local expected_default="${4}"
  local actual

  actual="$(awk -v input="${input}" '
    $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+type:[[:space:]]*" {
      sub(/^.*type:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      type = $0
    }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      default_value = $0
    }
    END {
      if (type != "" && default_value != "") print type "|" default_value
    }
  ' "${file}")"

  [[ "${actual}" == "${expected_type}|${expected_default}" ]] ||
    fail "${file}: ${input} input expected ${expected_type}|${expected_default}, got ${actual:-missing}"
}

find_manual_acceptance_workflow() {
  local file

  for file in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
    [[ -f "${file}" ]] || continue
    [[ "${file}" == "${REUSABLE}" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release.yml" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release-lineage.yml" ]] && continue
    if grep -Eq 'workflow_dispatch:' "${file}" &&
      grep -Eq 'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' "${file}" &&
      grep -Eqi 'build-only|publish:[[:space:]]*false' "${file}"; then
      printf '%s\n' "${file}"
      return 0
    fi
  done

  return 1
}

test_reusable_workflow() {
  [[ -f "${REUSABLE}" ]] || fail "missing reusable ROM workflow: ${REUSABLE}"
  assert_contains \
    "${REUSABLE}" \
    'workflow_call:' \
    "shared ROM workflow must be reusable"
  assert_contains \
    "${REUSABLE}" \
    'rom-family:' \
    "shared ROM workflow must accept a ROM family"
  assert_dispatch_default "${REUSABLE}" boot-animation false
  assert_dispatch_default "${REUSABLE}" afsr true
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_BOOT_ANIMATION' \
    "shared workflow must pass the boot-animation selection"
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_AFSR' \
    "shared workflow must pass the AFSR selection"
  local contract input expected_type expected_default
  for contract in \
    'afsr:boolean:true' \
    'alterinstaller:boolean:true' \
    'bcr:boolean:true' \
    'custota:boolean:true' \
    'msd:boolean:true' \
    'oemunlockonboot:boolean:true' \
    'fdroid-privileged-extension:boolean:false'; do
    IFS=: read -r input expected_type expected_default <<<"${contract}"
    assert_workflow_input_contract \
      "${REUSABLE}" "${input}" "${expected_type}" "${expected_default}"
  done
  assert_contains \
    "${REUSABLE}" \
    'uses:[[:space:]]*actions/checkout@' \
    "shared ROM workflow must own checkout"
  assert_contains \
    "${REUSABLE}" \
    'MODULE_SELECTION_FINGERPRINT' \
    "shared workflow must retain the full selection fingerprint as metadata"
  assert_contains \
    "${REUSABLE}" \
    '"artifact_name": artifact_name' \
    "selection metadata must bind the exact output filename"
  assert_contains \
    "${REUSABLE}" \
    '"grapheneos_version": version' \
    "selection metadata must bind the GrapheneOS version"
  assert_contains \
    "${REUSABLE}" \
    '"schema_version": 2' \
    "selection metadata must use the variant-aware schema"
  assert_contains \
    "${REUSABLE}" \
    'OUTPUT_SCOPE' \
    "shared workflow must set an explicit output scope"
  assert_contains \
    "${REUSABLE}" \
    'enforce_output_policy' \
    "shared workflow must enforce policy before release or upload"
  assert_contains \
    "${REUSABLE}" \
    'enforce_publication_evidence' \
    "shared workflow must enforce publication evidence"
  assert_not_contains \
    "${REUSABLE}" \
    'actions/upload-artifact@' \
    "local-unpublished outputs must not be uploaded"
  assert_not_contains \
    "${REUSABLE}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "shared ROM workflow must not check out a divergent lineage branch"
}

test_release_triggers() {
  assert_thin_trigger "${RELEASE}" grapheneos
  assert_thin_trigger "${WORKFLOW_DIR}/release-lineage.yml" lineageos

  assert_dispatch_default "${RELEASE}" device-id shiba
  assert_dispatch_default "${RELEASE}" root true
  assert_dispatch_default "${RELEASE}" alterinstaller true
  assert_dispatch_default "${RELEASE}" bcr true
  assert_dispatch_default "${RELEASE}" custota true
  assert_dispatch_default "${RELEASE}" msd true
  assert_dispatch_default "${RELEASE}" oemunlockonboot true
  assert_dispatch_default "${RELEASE}" fdroid-privileged-extension false
  assert_dispatch_default "${RELEASE}" boot-animation false
  assert_dispatch_default \
    "${RELEASE}" compatible-sepolicy-patching false
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" device-id pdx235
  assert_dispatch_default "${WORKFLOW_DIR}/release-lineage.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" compatible-sepolicy-patching true
}

test_config_loading_isolated_to_grapheneos_schedule() {
  local lineage="${WORKFLOW_DIR}/release-lineage.yml"
  local build_only="${WORKFLOW_DIR}/phase3-build-only.yml"

  assert_not_contains "${lineage}" 'env\.toml|check_toml_env' \
    "LineageOS release must not load GrapheneOS env.toml configuration"
  assert_not_contains "${build_only}" 'env\.toml|check_toml_env' \
    "build-only acceptance must keep its declared defaults"
  assert_contains "${build_only}" 'publish:[[:space:]]*false' \
    "build-only acceptance must remain local-unpublished"
}

test_release_configuration_forwarding() {
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Load scheduled env\.toml configuration' \
    "scheduled release must load env.toml"
  assert_contains \
    "${RELEASE}" \
    'if:[[:space:]]*github\.event_name == .schedule.' \
    "scheduled configuration must be schedule-only"
  assert_contains \
    "${RELEASE}" \
    'source src/util_functions\.sh' \
    "scheduled configuration must use shared config parsing"
  assert_contains \
    "${RELEASE}" \
    'check_toml_env' \
    "scheduled configuration must use allowlisted TOML parsing"
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Resolve expected selection identity' \
    "release preflight must resolve the canonical selection identity"
  assert_contains \
    "${RELEASE}" \
    'module_selection_fingerprint' \
    "release preflight must use the shared selection fingerprint"
  assert_contains \
    "${RELEASE}" \
    'expected_variant:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "release preflight must expose the resolved identity"
  assert_contains \
    "${RELEASE}" \
    'EXPECTED_VARIANT:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "existing-build preflight must receive the resolved identity"
  for identity_input in \
    'ROM_FAMILY:[[:space:]]*grapheneos' \
    'OUTPUT_SCOPE:[[:space:]]*published' \
    'ADDITIONALS_MAS_COMPATIBLE_SEPOLICY' \
    'ADDITIONALS_DEBUG' \
    'ADDITIONALS_BOOT_ANIMATION' \
    'ADDITIONALS_AFSR' \
    'MAGISK_VERSION:[[:space:]]*\$\{\{ steps\.resolve_version\.outputs\.magisk_version \}\}'; do
    assert_contains "${RELEASE}" "${identity_input}" \
      "release preflight must pass ${identity_input%%:*} to identity resolution"
  done
  assert_contains \
    "${RELEASE}" \
    'ADDITIONALS_AFSR:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "release preflight must preserve scheduled AFSR=false"
  assert_contains \
    "${RELEASE}" \
    'force_update="\$\(toml_resolve_value force_update "\$\{DEFAULT_FORCE_UPDATE\}"\)"' \
    "scheduled configuration must resolve FORCE_UPDATE through the typed contract"
  assert_contains \
    "${RELEASE}" \
    'validate_scheduled_boolean "\$\{force_update\}" "FORCE_UPDATE must be true or false"' \
    "scheduled FORCE_UPDATE must be validated as a boolean"
  assert_contains \
    "${RELEASE}" \
    'echo "FORCE_UPDATE=\$\{force_update\}"' \
    "scheduled configuration must export FORCE_UPDATE"
  assert_contains \
    "${RELEASE}" \
    'echo "force_update=\$\{force_update\}"' \
    "scheduled configuration must expose FORCE_UPDATE to preflight"
  assert_contains \
    "${RELEASE}" \
    'force_update:[[:space:]]*\$\{\{ steps\.scheduled_config\.outputs\.force_update \}\}' \
    "preflight must expose scheduled FORCE_UPDATE as a job output"
  assert_contains \
    "${RELEASE}" \
    'FORCE_UPDATE:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.force_update \|\| false \}\}' \
    "existing-build preflight must receive scheduled FORCE_UPDATE"
  for default in \
    'DEFAULT_DEVICE_NAME:[[:space:]]*bramble' \
    'DEFAULT_UPDATE_CHANNEL:[[:space:]]*stable' \
    'DEFAULT_ROOT:[[:space:]]*false' \
    'DEFAULT_AFSR:[[:space:]]*true' \
    'DEFAULT_MAGISK_PREINIT:[[:space:]]*sda10' \
    'DEFAULT_BOOT_ANIMATION:[[:space:]]*false' \
    'DEFAULT_FORCE_UPDATE:[[:space:]]*false'; do
    assert_contains "${RELEASE}" "${default}" \
      "scheduled configuration must retain explicit defaults"
  done
  assert_contains \
    "${RELEASE}" \
    'device-id:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.device_id \|\| inputs\.device-id \}\}' \
    "manual device input must remain authoritative"
  assert_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation == .true. \|\| inputs\.boot-animation \|\| false \}\}' \
    "boot animation must be forwarded with a default-off fallback"
  assert_contains \
    "${RELEASE}" \
    'afsr:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "AFSR must be forwarded without converting scheduled false to true"
  assert_not_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation \|\| inputs\.boot-animation' \
    "boot animation must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root == .true. \|\| inputs\.root \}\}' \
    "root must explicitly coerce the scheduled string output to boolean"
  assert_not_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root \|\| inputs\.root \}\}' \
    "root must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'magisk-preinit-device:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.magisk_preinit_device' \
    "scheduled preinit configuration must be forwarded"
  assert_contains \
    "${RELEASE}" \
    'update-channel:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.update_channel' \
    "scheduled update channel must be forwarded"
}

test_module_forwarding_contract() {
  local contract input config output

  for contract in \
    'afsr:AFSR:afsr' \
    'alterinstaller:ALTERINSTALLER:alterinstaller' \
    'bcr:BCR:bcr' \
    'custota:CUSTOTA:custota' \
    'msd:MSD:msd' \
    'oemunlockonboot:OEMUNLOCKONBOOT:oemunlockonboot' \
    'fdroid-privileged-extension:FDROID_PRIVILEGED_EXTENSION:fdroid_privileged_extension'; do
    IFS=: read -r input config output <<<"${contract}"

    assert_contains \
      "${RELEASE}" \
      "toml_resolve_value ${output}" \
      "scheduled configuration must resolve ${config} through the typed contract"
    assert_contains \
      "${RELEASE}" \
      "echo \"${output}=" \
      "scheduled configuration must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "steps\\.scheduled_config\\.outputs\\.${output}" \
      "preflight must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "ADDITIONALS_${config}:[[:space:]].*steps\\.scheduled_config\\.outputs\\.${output}.*inputs\\.${input}" \
      "expected identity must use scheduled/manual ${input}"
    assert_contains \
      "${RELEASE}" \
      "needs\\.preflight\\.outputs\\.${output}[[:space:]]*==[[:space:]]*['\"]true['\"].*inputs\\.${input}" \
      "build invocation must use scheduled/manual ${input}"
    assert_contains \
      "${REUSABLE}" \
      "ADDITIONALS_${config}:[[:space:]].*inputs\\.${input}" \
      "reusable build must map ${config} from input ${input}"
  done
}

test_publication_identity_is_step_scoped() {
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_EMAIL:[[:space:]]*\$\{\{ secrets\.EMAIL \}\}' \
    "publication identity email must be step-scoped"
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_NAME:[[:space:]]*\$\{\{ github\.repository_owner \}\}' \
    "publication identity name must be step-scoped"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.email "\$\{GIT_COMMIT_EMAIL-\}"' \
    "publication helper must configure local email from the step environment"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.name "\$\{GIT_COMMIT_NAME-\}"' \
    "publication helper must configure local name from the step environment"
  assert_not_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'git config user\.email .*secrets\.EMAIL' \
    "publication must not interpolate the email secret in shell source"
}

test_manual_build_only_acceptance() {
  local acceptance

  acceptance="$(find_manual_acceptance_workflow)" ||
    fail "missing manual build-only workflow that calls build-rom.yml"
  assert_contains \
    "${acceptance}" \
    'workflow_dispatch:' \
    "acceptance workflow must be manually dispatched"
  assert_contains \
    "${acceptance}" \
    '^[[:space:]]*contents:[[:space:]]*write[[:space:]]*$' \
    "acceptance workflow must grant contents write permission"
}

test_no_lineage_checkout_anywhere() {
  local file

  while IFS= read -r -d '' file; do
    assert_not_contains \
      "${file}" \
      '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
      "workflows must use the main branch implementation"
  done < <(find "${WORKFLOW_DIR}" -maxdepth 1 -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print0)
}

test_reusable_workflow
test_release_triggers
test_config_loading_isolated_to_grapheneos_schedule
test_release_configuration_forwarding
test_module_forwarding_contract
test_publication_identity_is_step_scoped
test_manual_build_only_acceptance
test_no_lineage_checkout_anywhere

echo "Phase 3 workflow tests passed"
 "${file}"; then
    trigger='workflow_dispatch'
  fi

  actual="$(awk -v input="${input}" -v trigger="${trigger}" '
    $0 ~ "^[[:space:]]{2}" trigger ":[[:space:]]*$" { in_trigger = 1; next }
    in_trigger && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_trigger && $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+type:[[:space:]]*" {
      sub(/^.*type:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      type = $0
    }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      default_value = $0
    }
    END {
      if (type != "" && default_value != "") print type "|" default_value
    }
  ' "${file}")"

  [[ "${actual}" == "${expected_type}|${expected_default}" ]] ||
    fail "${file}: ${input} input expected ${expected_type}|${expected_default}, got ${actual:-missing}"
}

find_manual_acceptance_workflow() {
  local file

  for file in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
    [[ -f "${file}" ]] || continue
    [[ "${file}" == "${REUSABLE}" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release.yml" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release-lineage.yml" ]] && continue
    if grep -Eq 'workflow_dispatch:' "${file}" &&
      grep -Eq 'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' "${file}" &&
      grep -Eqi 'build-only|publish:[[:space:]]*false' "${file}"; then
      printf '%s\n' "${file}"
      return 0
    fi
  done

  return 1
}

test_reusable_workflow() {
  [[ -f "${REUSABLE}" ]] || fail "missing reusable ROM workflow: ${REUSABLE}"
  assert_contains \
    "${REUSABLE}" \
    'workflow_call:' \
    "shared ROM workflow must be reusable"
  assert_contains \
    "${REUSABLE}" \
    'rom-family:' \
    "shared ROM workflow must accept a ROM family"
  assert_dispatch_default "${REUSABLE}" boot-animation false
  assert_dispatch_default "${REUSABLE}" afsr true
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_BOOT_ANIMATION' \
    "shared workflow must pass the boot-animation selection"
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_AFSR' \
    "shared workflow must pass the AFSR selection"
  local contract input expected_type expected_default
  for contract in \
    'afsr:boolean:true' \
    'alterinstaller:boolean:true' \
    'bcr:boolean:true' \
    'custota:boolean:true' \
    'msd:boolean:true' \
    'oemunlockonboot:boolean:true' \
    'fdroid-privileged-extension:boolean:false'; do
    IFS=: read -r input expected_type expected_default <<<"${contract}"
    assert_workflow_input_contract \
      "${REUSABLE}" "${input}" "${expected_type}" "${expected_default}"
  done
  assert_contains \
    "${REUSABLE}" \
    'uses:[[:space:]]*actions/checkout@' \
    "shared ROM workflow must own checkout"
  assert_contains \
    "${REUSABLE}" \
    'MODULE_SELECTION_FINGERPRINT' \
    "shared workflow must retain the full selection fingerprint as metadata"
  assert_contains \
    "${REUSABLE}" \
    '"artifact_name": artifact_name' \
    "selection metadata must bind the exact output filename"
  assert_contains \
    "${REUSABLE}" \
    '"grapheneos_version": version' \
    "selection metadata must bind the GrapheneOS version"
  assert_contains \
    "${REUSABLE}" \
    '"schema_version": 2' \
    "selection metadata must use the variant-aware schema"
  assert_contains \
    "${REUSABLE}" \
    'OUTPUT_SCOPE' \
    "shared workflow must set an explicit output scope"
  assert_contains \
    "${REUSABLE}" \
    'enforce_output_policy' \
    "shared workflow must enforce policy before release or upload"
  assert_contains \
    "${REUSABLE}" \
    'enforce_publication_evidence' \
    "shared workflow must enforce publication evidence"
  assert_not_contains \
    "${REUSABLE}" \
    'actions/upload-artifact@' \
    "local-unpublished outputs must not be uploaded"
  assert_not_contains \
    "${REUSABLE}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "shared ROM workflow must not check out a divergent lineage branch"
}

test_release_triggers() {
  assert_thin_trigger "${RELEASE}" grapheneos
  assert_thin_trigger "${WORKFLOW_DIR}/release-lineage.yml" lineageos

  assert_dispatch_default "${RELEASE}" device-id shiba
  assert_dispatch_default "${RELEASE}" root true
  assert_dispatch_default "${RELEASE}" alterinstaller true
  assert_dispatch_default "${RELEASE}" bcr true
  assert_dispatch_default "${RELEASE}" custota true
  assert_dispatch_default "${RELEASE}" msd true
  assert_dispatch_default "${RELEASE}" oemunlockonboot true
  assert_dispatch_default "${RELEASE}" fdroid-privileged-extension false
  assert_dispatch_default "${RELEASE}" boot-animation false
  assert_dispatch_default \
    "${RELEASE}" compatible-sepolicy-patching false
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" device-id pdx235
  assert_dispatch_default "${WORKFLOW_DIR}/release-lineage.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" compatible-sepolicy-patching true
}

test_config_loading_isolated_to_grapheneos_schedule() {
  local lineage="${WORKFLOW_DIR}/release-lineage.yml"
  local build_only="${WORKFLOW_DIR}/phase3-build-only.yml"

  assert_not_contains "${lineage}" 'env\.toml|check_toml_env' \
    "LineageOS release must not load GrapheneOS env.toml configuration"
  assert_not_contains "${build_only}" 'env\.toml|check_toml_env' \
    "build-only acceptance must keep its declared defaults"
  assert_contains "${build_only}" 'publish:[[:space:]]*false' \
    "build-only acceptance must remain local-unpublished"
}

test_release_configuration_forwarding() {
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Load scheduled env\.toml configuration' \
    "scheduled release must load env.toml"
  assert_contains \
    "${RELEASE}" \
    'if:[[:space:]]*github\.event_name == .schedule.' \
    "scheduled configuration must be schedule-only"
  assert_contains \
    "${RELEASE}" \
    'source src/util_functions\.sh' \
    "scheduled configuration must use shared config parsing"
  assert_contains \
    "${RELEASE}" \
    'check_toml_env' \
    "scheduled configuration must use allowlisted TOML parsing"
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Resolve expected selection identity' \
    "release preflight must resolve the canonical selection identity"
  assert_contains \
    "${RELEASE}" \
    'module_selection_fingerprint' \
    "release preflight must use the shared selection fingerprint"
  assert_contains \
    "${RELEASE}" \
    'expected_variant:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "release preflight must expose the resolved identity"
  assert_contains \
    "${RELEASE}" \
    'EXPECTED_VARIANT:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "existing-build preflight must receive the resolved identity"
  for identity_input in \
    'ROM_FAMILY:[[:space:]]*grapheneos' \
    'OUTPUT_SCOPE:[[:space:]]*published' \
    'ADDITIONALS_MAS_COMPATIBLE_SEPOLICY' \
    'ADDITIONALS_DEBUG' \
    'ADDITIONALS_BOOT_ANIMATION' \
    'ADDITIONALS_AFSR' \
    'MAGISK_VERSION:[[:space:]]*\$\{\{ steps\.resolve_version\.outputs\.magisk_version \}\}'; do
    assert_contains "${RELEASE}" "${identity_input}" \
      "release preflight must pass ${identity_input%%:*} to identity resolution"
  done
  assert_contains \
    "${RELEASE}" \
    'ADDITIONALS_AFSR:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "release preflight must preserve scheduled AFSR=false"
  assert_contains \
    "${RELEASE}" \
    'force_update="\$\(toml_resolve_value force_update "\$\{DEFAULT_FORCE_UPDATE\}"\)"' \
    "scheduled configuration must resolve FORCE_UPDATE through the typed contract"
  assert_contains \
    "${RELEASE}" \
    'validate_scheduled_boolean "\$\{force_update\}" "FORCE_UPDATE must be true or false"' \
    "scheduled FORCE_UPDATE must be validated as a boolean"
  assert_contains \
    "${RELEASE}" \
    'echo "FORCE_UPDATE=\$\{force_update\}"' \
    "scheduled configuration must export FORCE_UPDATE"
  assert_contains \
    "${RELEASE}" \
    'echo "force_update=\$\{force_update\}"' \
    "scheduled configuration must expose FORCE_UPDATE to preflight"
  assert_contains \
    "${RELEASE}" \
    'force_update:[[:space:]]*\$\{\{ steps\.scheduled_config\.outputs\.force_update \}\}' \
    "preflight must expose scheduled FORCE_UPDATE as a job output"
  assert_contains \
    "${RELEASE}" \
    'FORCE_UPDATE:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.force_update \|\| false \}\}' \
    "existing-build preflight must receive scheduled FORCE_UPDATE"
  for default in \
    'DEFAULT_DEVICE_NAME:[[:space:]]*bramble' \
    'DEFAULT_UPDATE_CHANNEL:[[:space:]]*stable' \
    'DEFAULT_ROOT:[[:space:]]*false' \
    'DEFAULT_AFSR:[[:space:]]*true' \
    'DEFAULT_MAGISK_PREINIT:[[:space:]]*sda10' \
    'DEFAULT_BOOT_ANIMATION:[[:space:]]*false' \
    'DEFAULT_FORCE_UPDATE:[[:space:]]*false'; do
    assert_contains "${RELEASE}" "${default}" \
      "scheduled configuration must retain explicit defaults"
  done
  assert_contains \
    "${RELEASE}" \
    'device-id:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.device_id \|\| inputs\.device-id \}\}' \
    "manual device input must remain authoritative"
  assert_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation == .true. \|\| inputs\.boot-animation \|\| false \}\}' \
    "boot animation must be forwarded with a default-off fallback"
  assert_contains \
    "${RELEASE}" \
    'afsr:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "AFSR must be forwarded without converting scheduled false to true"
  assert_not_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation \|\| inputs\.boot-animation' \
    "boot animation must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root == .true. \|\| inputs\.root \}\}' \
    "root must explicitly coerce the scheduled string output to boolean"
  assert_not_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root \|\| inputs\.root \}\}' \
    "root must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'magisk-preinit-device:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.magisk_preinit_device' \
    "scheduled preinit configuration must be forwarded"
  assert_contains \
    "${RELEASE}" \
    'update-channel:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.update_channel' \
    "scheduled update channel must be forwarded"
}

test_module_forwarding_contract() {
  local contract input config output

  for contract in \
    'afsr:AFSR:afsr' \
    'alterinstaller:ALTERINSTALLER:alterinstaller' \
    'bcr:BCR:bcr' \
    'custota:CUSTOTA:custota' \
    'msd:MSD:msd' \
    'oemunlockonboot:OEMUNLOCKONBOOT:oemunlockonboot' \
    'fdroid-privileged-extension:FDROID_PRIVILEGED_EXTENSION:fdroid_privileged_extension'; do
    IFS=: read -r input config output <<<"${contract}"

    assert_contains \
      "${RELEASE}" \
      "toml_resolve_value ${output}" \
      "scheduled configuration must resolve ${config} through the typed contract"
    assert_contains \
      "${RELEASE}" \
      "echo \"${output}=" \
      "scheduled configuration must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "steps\\.scheduled_config\\.outputs\\.${output}" \
      "preflight must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "ADDITIONALS_${config}:[[:space:]].*steps\\.scheduled_config\\.outputs\\.${output}.*inputs\\.${input}" \
      "expected identity must use scheduled/manual ${input}"
    assert_contains \
      "${RELEASE}" \
      "needs\\.preflight\\.outputs\\.${output}[[:space:]]*==[[:space:]]*['\"]true['\"].*inputs\\.${input}" \
      "build invocation must use scheduled/manual ${input}"
    assert_contains \
      "${REUSABLE}" \
      "ADDITIONALS_${config}:[[:space:]].*inputs\\.${input}" \
      "reusable build must map ${config} from input ${input}"
  done
}

test_publication_identity_is_step_scoped() {
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_EMAIL:[[:space:]]*\$\{\{ secrets\.EMAIL \}\}' \
    "publication identity email must be step-scoped"
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_NAME:[[:space:]]*\$\{\{ github\.repository_owner \}\}' \
    "publication identity name must be step-scoped"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.email "\$\{GIT_COMMIT_EMAIL-\}"' \
    "publication helper must configure local email from the step environment"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.name "\$\{GIT_COMMIT_NAME-\}"' \
    "publication helper must configure local name from the step environment"
  assert_not_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'git config user\.email .*secrets\.EMAIL' \
    "publication must not interpolate the email secret in shell source"
}

test_manual_build_only_acceptance() {
  local acceptance

  acceptance="$(find_manual_acceptance_workflow)" ||
    fail "missing manual build-only workflow that calls build-rom.yml"
  assert_contains \
    "${acceptance}" \
    'workflow_dispatch:' \
    "acceptance workflow must be manually dispatched"
  assert_contains \
    "${acceptance}" \
    '^[[:space:]]*contents:[[:space:]]*write[[:space:]]*$' \
    "acceptance workflow must grant contents write permission"
}

test_no_lineage_checkout_anywhere() {
  local file

  while IFS= read -r -d '' file; do
    assert_not_contains \
      "${file}" \
      '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
      "workflows must use the main branch implementation"
  done < <(find "${WORKFLOW_DIR}" -maxdepth 1 -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print0)
}

test_reusable_workflow
test_release_triggers
test_config_loading_isolated_to_grapheneos_schedule
test_release_configuration_forwarding
test_module_forwarding_contract
test_publication_identity_is_step_scoped
test_manual_build_only_acceptance
test_no_lineage_checkout_anywhere

echo "Phase 3 workflow tests passed"
 "${file}"; then
    trigger='workflow_dispatch'
  fi

  actual="$(awk -v input="${input}" -v trigger="${trigger}" '
    $0 ~ "^[[:space:]]{2}" trigger ":[[:space:]]*$" { in_trigger = 1; next }
    in_trigger && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_trigger && $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      print
      exit
    }
  ' "${file}")"

  [[ "${actual}" == "${expected}" ]] ||
    fail "${file}: ${input} default expected ${expected}, got ${actual:-missing}"
}

assert_workflow_input_contract() {
  local file="${1}"
  local input="${2}"
  local expected_type="${3}"
  local expected_default="${4}"
  local actual

  actual="$(awk -v input="${input}" '
    $0 ~ "^[[:space:]]{6}" input ":[[:space:]]*$" { in_input = 1; next }
    in_input && $0 ~ "^[[:space:]]{6}[A-Za-z0-9_-]+:[[:space:]]*$" { exit }
    in_input && $0 ~ "^[[:space:]]+type:[[:space:]]*" {
      sub(/^.*type:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      type = $0
    }
    in_input && $0 ~ "^[[:space:]]+default:[[:space:]]*" {
      sub(/^.*default:[[:space:]]*/, "")
      gsub(/[[:space:]\047"]/, "")
      default_value = $0
    }
    END {
      if (type != "" && default_value != "") print type "|" default_value
    }
  ' "${file}")"

  [[ "${actual}" == "${expected_type}|${expected_default}" ]] ||
    fail "${file}: ${input} input expected ${expected_type}|${expected_default}, got ${actual:-missing}"
}

find_manual_acceptance_workflow() {
  local file

  for file in "${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml; do
    [[ -f "${file}" ]] || continue
    [[ "${file}" == "${REUSABLE}" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release.yml" ]] && continue
    [[ "${file}" == "${WORKFLOW_DIR}/release-lineage.yml" ]] && continue
    if grep -Eq 'workflow_dispatch:' "${file}" &&
      grep -Eq 'uses:[[:space:]]*\./\.github/workflows/build-rom\.yml' "${file}" &&
      grep -Eqi 'build-only|publish:[[:space:]]*false' "${file}"; then
      printf '%s\n' "${file}"
      return 0
    fi
  done

  return 1
}

test_reusable_workflow() {
  [[ -f "${REUSABLE}" ]] || fail "missing reusable ROM workflow: ${REUSABLE}"
  assert_contains \
    "${REUSABLE}" \
    'workflow_call:' \
    "shared ROM workflow must be reusable"
  assert_contains \
    "${REUSABLE}" \
    'rom-family:' \
    "shared ROM workflow must accept a ROM family"
  assert_dispatch_default "${REUSABLE}" boot-animation false
  assert_dispatch_default "${REUSABLE}" afsr true
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_BOOT_ANIMATION' \
    "shared workflow must pass the boot-animation selection"
  assert_contains \
    "${REUSABLE}" \
    'ADDITIONALS_AFSR' \
    "shared workflow must pass the AFSR selection"
  local contract input expected_type expected_default
  for contract in \
    'afsr:boolean:true' \
    'alterinstaller:boolean:true' \
    'bcr:boolean:true' \
    'custota:boolean:true' \
    'msd:boolean:true' \
    'oemunlockonboot:boolean:true' \
    'fdroid-privileged-extension:boolean:false'; do
    IFS=: read -r input expected_type expected_default <<<"${contract}"
    assert_workflow_input_contract \
      "${REUSABLE}" "${input}" "${expected_type}" "${expected_default}"
  done
  assert_contains \
    "${REUSABLE}" \
    'uses:[[:space:]]*actions/checkout@' \
    "shared ROM workflow must own checkout"
  assert_contains \
    "${REUSABLE}" \
    'MODULE_SELECTION_FINGERPRINT' \
    "shared workflow must retain the full selection fingerprint as metadata"
  assert_contains \
    "${REUSABLE}" \
    '"artifact_name": artifact_name' \
    "selection metadata must bind the exact output filename"
  assert_contains \
    "${REUSABLE}" \
    '"grapheneos_version": version' \
    "selection metadata must bind the GrapheneOS version"
  assert_contains \
    "${REUSABLE}" \
    '"schema_version": 2' \
    "selection metadata must use the variant-aware schema"
  assert_contains \
    "${REUSABLE}" \
    'OUTPUT_SCOPE' \
    "shared workflow must set an explicit output scope"
  assert_contains \
    "${REUSABLE}" \
    'enforce_output_policy' \
    "shared workflow must enforce policy before release or upload"
  assert_contains \
    "${REUSABLE}" \
    'enforce_publication_evidence' \
    "shared workflow must enforce publication evidence"
  assert_not_contains \
    "${REUSABLE}" \
    'actions/upload-artifact@' \
    "local-unpublished outputs must not be uploaded"
  assert_not_contains \
    "${REUSABLE}" \
    '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
    "shared ROM workflow must not check out a divergent lineage branch"
}

test_release_triggers() {
  assert_thin_trigger "${RELEASE}" grapheneos
  assert_thin_trigger "${WORKFLOW_DIR}/release-lineage.yml" lineageos

  assert_dispatch_default "${RELEASE}" device-id shiba
  assert_dispatch_default "${RELEASE}" root true
  assert_dispatch_default "${RELEASE}" alterinstaller true
  assert_dispatch_default "${RELEASE}" bcr true
  assert_dispatch_default "${RELEASE}" custota true
  assert_dispatch_default "${RELEASE}" msd true
  assert_dispatch_default "${RELEASE}" oemunlockonboot true
  assert_dispatch_default "${RELEASE}" fdroid-privileged-extension false
  assert_dispatch_default "${RELEASE}" boot-animation false
  assert_dispatch_default \
    "${RELEASE}" compatible-sepolicy-patching false
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" device-id pdx235
  assert_dispatch_default "${WORKFLOW_DIR}/release-lineage.yml" root true
  assert_dispatch_default \
    "${WORKFLOW_DIR}/release-lineage.yml" compatible-sepolicy-patching true
}

test_config_loading_isolated_to_grapheneos_schedule() {
  local lineage="${WORKFLOW_DIR}/release-lineage.yml"
  local build_only="${WORKFLOW_DIR}/phase3-build-only.yml"

  assert_not_contains "${lineage}" 'env\.toml|check_toml_env' \
    "LineageOS release must not load GrapheneOS env.toml configuration"
  assert_not_contains "${build_only}" 'env\.toml|check_toml_env' \
    "build-only acceptance must keep its declared defaults"
  assert_contains "${build_only}" 'publish:[[:space:]]*false' \
    "build-only acceptance must remain local-unpublished"
}

test_release_configuration_forwarding() {
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Load scheduled env\.toml configuration' \
    "scheduled release must load env.toml"
  assert_contains \
    "${RELEASE}" \
    'if:[[:space:]]*github\.event_name == .schedule.' \
    "scheduled configuration must be schedule-only"
  assert_contains \
    "${RELEASE}" \
    'source src/util_functions\.sh' \
    "scheduled configuration must use shared config parsing"
  assert_contains \
    "${RELEASE}" \
    'check_toml_env' \
    "scheduled configuration must use allowlisted TOML parsing"
  assert_contains \
    "${RELEASE}" \
    'name:[[:space:]]*Resolve expected selection identity' \
    "release preflight must resolve the canonical selection identity"
  assert_contains \
    "${RELEASE}" \
    'module_selection_fingerprint' \
    "release preflight must use the shared selection fingerprint"
  assert_contains \
    "${RELEASE}" \
    'expected_variant:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "release preflight must expose the resolved identity"
  assert_contains \
    "${RELEASE}" \
    'EXPECTED_VARIANT:[[:space:]]*\$\{\{ steps\.selection_identity\.outputs\.expected_variant \}\}' \
    "existing-build preflight must receive the resolved identity"
  for identity_input in \
    'ROM_FAMILY:[[:space:]]*grapheneos' \
    'OUTPUT_SCOPE:[[:space:]]*published' \
    'ADDITIONALS_MAS_COMPATIBLE_SEPOLICY' \
    'ADDITIONALS_DEBUG' \
    'ADDITIONALS_BOOT_ANIMATION' \
    'ADDITIONALS_AFSR' \
    'MAGISK_VERSION:[[:space:]]*\$\{\{ steps\.resolve_version\.outputs\.magisk_version \}\}'; do
    assert_contains "${RELEASE}" "${identity_input}" \
      "release preflight must pass ${identity_input%%:*} to identity resolution"
  done
  assert_contains \
    "${RELEASE}" \
    'ADDITIONALS_AFSR:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "release preflight must preserve scheduled AFSR=false"
  assert_contains \
    "${RELEASE}" \
    'force_update="\$\(toml_resolve_value force_update "\$\{DEFAULT_FORCE_UPDATE\}"\)"' \
    "scheduled configuration must resolve FORCE_UPDATE through the typed contract"
  assert_contains \
    "${RELEASE}" \
    'validate_scheduled_boolean "\$\{force_update\}" "FORCE_UPDATE must be true or false"' \
    "scheduled FORCE_UPDATE must be validated as a boolean"
  assert_contains \
    "${RELEASE}" \
    'echo "FORCE_UPDATE=\$\{force_update\}"' \
    "scheduled configuration must export FORCE_UPDATE"
  assert_contains \
    "${RELEASE}" \
    'echo "force_update=\$\{force_update\}"' \
    "scheduled configuration must expose FORCE_UPDATE to preflight"
  assert_contains \
    "${RELEASE}" \
    'force_update:[[:space:]]*\$\{\{ steps\.scheduled_config\.outputs\.force_update \}\}' \
    "preflight must expose scheduled FORCE_UPDATE as a job output"
  assert_contains \
    "${RELEASE}" \
    'FORCE_UPDATE:[[:space:]]*\$\{\{ github\.event_name == .schedule. && steps\.scheduled_config\.outputs\.force_update \|\| false \}\}' \
    "existing-build preflight must receive scheduled FORCE_UPDATE"
  for default in \
    'DEFAULT_DEVICE_NAME:[[:space:]]*bramble' \
    'DEFAULT_UPDATE_CHANNEL:[[:space:]]*stable' \
    'DEFAULT_ROOT:[[:space:]]*false' \
    'DEFAULT_AFSR:[[:space:]]*true' \
    'DEFAULT_MAGISK_PREINIT:[[:space:]]*sda10' \
    'DEFAULT_BOOT_ANIMATION:[[:space:]]*false' \
    'DEFAULT_FORCE_UPDATE:[[:space:]]*false'; do
    assert_contains "${RELEASE}" "${default}" \
      "scheduled configuration must retain explicit defaults"
  done
  assert_contains \
    "${RELEASE}" \
    'device-id:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.device_id \|\| inputs\.device-id \}\}' \
    "manual device input must remain authoritative"
  assert_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation == .true. \|\| inputs\.boot-animation \|\| false \}\}' \
    "boot animation must be forwarded with a default-off fallback"
  assert_contains \
    "${RELEASE}" \
    'afsr:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.afsr == .true. \|\| github\.event_name != .schedule. && inputs\.afsr \}\}' \
    "AFSR must be forwarded without converting scheduled false to true"
  assert_not_contains \
    "${RELEASE}" \
    'boot-animation:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.boot_animation \|\| inputs\.boot-animation' \
    "boot animation must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root == .true. \|\| inputs\.root \}\}' \
    "root must explicitly coerce the scheduled string output to boolean"
  assert_not_contains \
    "${RELEASE}" \
    'root:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.root \|\| inputs\.root \}\}' \
    "root must not forward a string output as a boolean"
  assert_contains \
    "${RELEASE}" \
    'magisk-preinit-device:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.magisk_preinit_device' \
    "scheduled preinit configuration must be forwarded"
  assert_contains \
    "${RELEASE}" \
    'update-channel:[[:space:]]*\$\{\{ github\.event_name == .schedule. && needs\.preflight\.outputs\.update_channel' \
    "scheduled update channel must be forwarded"
}

test_module_forwarding_contract() {
  local contract input config output

  for contract in \
    'afsr:AFSR:afsr' \
    'alterinstaller:ALTERINSTALLER:alterinstaller' \
    'bcr:BCR:bcr' \
    'custota:CUSTOTA:custota' \
    'msd:MSD:msd' \
    'oemunlockonboot:OEMUNLOCKONBOOT:oemunlockonboot' \
    'fdroid-privileged-extension:FDROID_PRIVILEGED_EXTENSION:fdroid_privileged_extension'; do
    IFS=: read -r input config output <<<"${contract}"

    assert_contains \
      "${RELEASE}" \
      "toml_resolve_value ${output}" \
      "scheduled configuration must resolve ${config} through the typed contract"
    assert_contains \
      "${RELEASE}" \
      "echo \"${output}=" \
      "scheduled configuration must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "steps\\.scheduled_config\\.outputs\\.${output}" \
      "preflight must expose ${output}"
    assert_contains \
      "${RELEASE}" \
      "ADDITIONALS_${config}:[[:space:]].*steps\\.scheduled_config\\.outputs\\.${output}.*inputs\\.${input}" \
      "expected identity must use scheduled/manual ${input}"
    assert_contains \
      "${RELEASE}" \
      "needs\\.preflight\\.outputs\\.${output}[[:space:]]*==[[:space:]]*['\"]true['\"].*inputs\\.${input}" \
      "build invocation must use scheduled/manual ${input}"
    assert_contains \
      "${REUSABLE}" \
      "ADDITIONALS_${config}:[[:space:]].*inputs\\.${input}" \
      "reusable build must map ${config} from input ${input}"
  done
}

test_publication_identity_is_step_scoped() {
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_EMAIL:[[:space:]]*\$\{\{ secrets\.EMAIL \}\}' \
    "publication identity email must be step-scoped"
  assert_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'GIT_COMMIT_NAME:[[:space:]]*\$\{\{ github\.repository_owner \}\}' \
    "publication identity name must be step-scoped"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.email "\$\{GIT_COMMIT_EMAIL-\}"' \
    "publication helper must configure local email from the step environment"
  assert_contains \
    "src/ci/publish_ota.sh" \
    'git config user\.name "\$\{GIT_COMMIT_NAME-\}"' \
    "publication helper must configure local name from the step environment"
  assert_not_contains \
    "${WORKFLOW_DIR}/build-rom.yml" \
    'git config user\.email .*secrets\.EMAIL' \
    "publication must not interpolate the email secret in shell source"
}

test_manual_build_only_acceptance() {
  local acceptance

  acceptance="$(find_manual_acceptance_workflow)" ||
    fail "missing manual build-only workflow that calls build-rom.yml"
  assert_contains \
    "${acceptance}" \
    'workflow_dispatch:' \
    "acceptance workflow must be manually dispatched"
  assert_contains \
    "${acceptance}" \
    '^[[:space:]]*contents:[[:space:]]*write[[:space:]]*$' \
    "acceptance workflow must grant contents write permission"
}

test_no_lineage_checkout_anywhere() {
  local file

  while IFS= read -r -d '' file; do
    assert_not_contains \
      "${file}" \
      '(^|[[:space:]])ref:[[:space:]]*['\"]?lineage['\"]?([[:space:]#]|$)' \
      "workflows must use the main branch implementation"
  done < <(find "${WORKFLOW_DIR}" -maxdepth 1 -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print0)
}

test_reusable_workflow
test_release_triggers
test_config_loading_isolated_to_grapheneos_schedule
test_release_configuration_forwarding
test_module_forwarding_contract
test_publication_identity_is_step_scoped
test_manual_build_only_acceptance
test_no_lineage_checkout_anywhere

echo "Phase 3 workflow tests passed"
