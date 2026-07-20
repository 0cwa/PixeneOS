#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

# Contains the functions to fetch the required files. In short, this takes care of downloading the OTA, Magisk, and other dependencies.

source src/declarations.sh
source src/rom_profiles.sh
source src/ota_providers.sh

# Fetch the latest version of GrapheneOS and Magisk and sets up the OTA URL
function get_latest_version() {
  local latest_magisk_version=$(
    git ls-remote --tags "${DOMAIN}/${MAGISK[REPOSITORY]}.git" |
      awk -F'\t' '{print $2}' |
      grep -E 'refs/tags/' |
      sed 's/refs\/tags\///' |
      sort -V |
      tail -n1
  )

  resolve_rom_profile || return 1

  if [[ "${GRAPHENEOS[UPDATE_TYPE]}" == "install" ]]; then
    echo -e "The update type is set to \`install\` which is not supported by AVBRoot.\nExiting..."
    exit 1
  fi

  fetch_rom_ota_metadata || return 1
  echo -e "${ROM_FAMILY} OTA target: \`${GRAPHENEOS[OTA_TARGET]}\`\nOTA URL: ${GRAPHENEOS[OTA_URL]}\n"

  if [[ -z "${latest_magisk_version}" ]]; then
    echo -e "Failed to get the latest Magisk version."
    exit 1
  else
    VERSION[MAGISK]="${latest_magisk_version}"
  fi
}

# Getter function to download the magisk, modules, signatures and tools
function get() {
  local filename="${1}"
  local url="${2}"
  local signature_url="${3:-}"

  echo "Downloading \`${filename}\`..."

  if [[ "${filename}" == "afsr" || "${filename}" == "avbroot" || "${filename}" == "custota-tool" ]]; then
    echo "Error: executable tools require immutable-lock bootstrap verification." >&2
    return 1
  fi

  # `my-avbroot-setup` is a special case as it is a git repository
  if [[ "${filename}" == "my-avbroot-setup" ]]; then
    git clone "${url}" "${WORKDIR}/tools/${filename}" && git -C "${WORKDIR}/tools/${filename}" checkout "${VERSION[AVBROOT_SETUP]}"
  else
    if [[ "${filename}" == "magisk" ]]; then
      suffix="apk"
    else
      suffix="zip"
    fi

    # Download the files directly to modules directory
    curl -sLf "${url}" --output "${WORKDIR}/modules/${filename}.${suffix}"

    if [[ "${filename}" != "my-avbroot-setup" ]]; then
      # Download signatures
      if [ -n "${signature_url}" ]; then
        echo "Downloading signature for \`${filename}\`..."
        curl -sLf "${signature_url}" --output "${WORKDIR}/signatures/${filename}.zip.sig"
      fi

    fi
  fi
  echo -e "\`${filename}\` downloaded."
}

# Function to check and download the dependencies
function download_ota() {
  local ota="${WORKDIR}/${GRAPHENEOS[OTA_TARGET]}.zip"

  # Set the URLs if not set
  if [[ -z "${GRAPHENEOS[OTA_URL]}" || -z "${GRAPHENEOS[OTA_TARGET]}" ]]; then
    get_latest_version
  fi

  # Download if not downloaded already
  if [ ! -f "${ota}" ]; then
    echo -e "Downloading OTA from: ${GRAPHENEOS[OTA_URL]}...\nPlease be patient while the download happens."
    curl -sLf "${GRAPHENEOS[OTA_URL]}" --output "${ota}"
    echo -e "OTA downloaded to: \`${ota}\`\n"
  else
    echo -e "OTA is already downloaded in: \`${ota}\`\n"
  fi
  verify_rom_ota_digest "${ota}"
}
