#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

# Declare associative arrays and variables
declare -A ADDITIONALS
declare -A AVBROOT
declare -A GRAPHENEOS
declare -A KEYS
declare -A MAGISK
declare -A OUTPUTS
declare -A ROM_PROFILE
declare -A VERSION

# Build Specifications
ARCH="x86_64-unknown-linux-gnu" # for Linux
# ARCH="universal-apple-darwin" # for macOS
# ARCH="x86_64-pc-windows-msvc" # for Windows

# Initial setup environment variables
CLEANUP="${CLEANUP:-'false'}"                # Clean up after the script finishes
DEVICE_NAME="${DEVICE_NAME:-}"               # Device name, passed from the CI environment
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}" # Enable interactive mode
ROM_FAMILY="${ROM_FAMILY:-grapheneos}"
OUTPUT_SCOPE="${OUTPUT_SCOPE:-local-unpublished}"
MODULE_SELECTION_FINGERPRINT="${MODULE_SELECTION_FINGERPRINT:-}"
ROM_OTA_SHA256="${ROM_OTA_SHA256:-}"
WORKDIR=".tmp"

# GitHub variables
DOMAIN="https://github.com"
# Release asset owner/repository. Resolved at use time so env.toml values loaded
# after this file, GitHub Actions context, and defaults all participate safely.
PIXENEOS_RELEASE_OWNER="${PIXENEOS_RELEASE_OWNER:-}"
PIXENEOS_RELEASE_REPOSITORY="${PIXENEOS_RELEASE_REPOSITORY:-}"
PIXENEOS_RELEASE_BASE_URL="${PIXENEOS_RELEASE_BASE_URL:-}"
PIXENEOS_AVBROOT_SETUP_SOURCE="${PIXENEOS_AVBROOT_SETUP_SOURCE:-}"

# Application version variables
VERSION[AFSR]="${VERSION[AFSR]:-1.0.4}"
VERSION[ALTERINSTALLER]="${VERSION[ALTERINSTALLER]:-2.4}"
VERSION[AVBROOT]="${VERSION[AVBROOT]:-3.31.0}"
VERSION[AVBROOT_SETUP]="09d32371829fb3b34455edbd2fee58fd84db613c" # Commit hash
VERSION[BCR]="${VERSION[BCR]:-3.4}"
VERSION[CUSTOTA]="${VERSION[CUSTOTA]:-6.2}"
VERSION[GRAPHENEOS]="${VERSION[GRAPHENEOS]:-}"
VERSION[MAGISK]="${VERSION[MAGISK]:-}"
VERSION[MSD]="${VERSION[MSD]:-2.3}"
VERSION[OEMUNLOCKONBOOT]="${VERSION[OEMUNLOCKONBOOT]:-1.4}"

# Magisk
MAGISK[PREINIT]="${MAGISK_PREINIT:-}"
MAGISK[REPOSITORY]="topjohnwu/Magisk"
MAGISK[URL]="${DOMAIN}/${MAGISK[REPOSITORY]}"

# Keys
KEYS[AVB]="${KEYS[AVB]:-avb.key}"
KEYS[AVB_BASE64]="${KEYS[AVB_BASE64]:-''}"
KEYS[CERT_OTA]="${KEYS[CERT_OTA]:-ota.crt}"
KEYS[CERT_OTA_BASE64]="${KEYS[CERT_OTA_BASE64]:-''}"
KEYS[OTA]="${KEYS[OTA]:-ota.key}"
KEYS[OTA_BASE64]="${KEYS[OTA_BASE64]:-''}"
KEYS[PKMD]="${KEYS[PKMD]:-avb_pkmd.bin}"

# Compatibility keys retained for existing callers. resolve_rom_profile fills
# these through the common ROM capability profile.
GRAPHENEOS[OTA_BASE_URL]="${GRAPHENEOS[OTA_BASE_URL]:-}"
GRAPHENEOS[UPDATE_CHANNEL]="${GRAPHENEOS[UPDATE_CHANNEL]:-}"
GRAPHENEOS[UPDATE_TYPE]="${GRAPHENEOS[UPDATE_TYPE]:-}"
GRAPHENEOS[OTA_URL]="${GRAPHENEOS[OTA_URL]:-}"
GRAPHENEOS[OTA_TARGET]="${GRAPHENEOS[OTA_TARGET]:-}"

# Additionals

# Modules
ADDITIONALS[AFSR]="${ADDITIONALS[AFSR]:-true}"                       # Android File system repack
# Spoof Android package manager installer fields
ADDITIONALS[ALTERINSTALLER]="${ADDITIONALS_ALTERINSTALLER:-${ADDITIONALS[ALTERINSTALLER]:-true}}"
# Basic Call Recorder
ADDITIONALS[BCR]="${ADDITIONALS_BCR:-${ADDITIONALS[BCR]:-true}}"
# Custom OTA Updater app
ADDITIONALS[CUSTOTA]="${ADDITIONALS_CUSTOTA:-${ADDITIONALS[CUSTOTA]:-true}}"
# Mass Storage Device on USB
ADDITIONALS[MSD]="${ADDITIONALS_MSD:-${ADDITIONALS[MSD]:-true}}"
# Toggle OEM unlock button on boot
ADDITIONALS[OEMUNLOCKONBOOT]="${ADDITIONALS_OEMUNLOCKONBOOT:-${ADDITIONALS[OEMUNLOCKONBOOT]:-true}}"
# F-Droid client and Privileged Extension through the locked native adapter.
# There is intentionally no production lock/profile default yet.
ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]="${ADDITIONALS_FDROID_PRIVILEGED_EXTENSION:-${ADDITIONALS[FDROID_PRIVILEGED_EXTENSION]:-false}}"
FDROID_PRIVILEGED_EXTENSION_LOCK="${FDROID_PRIVILEGED_EXTENSION_LOCK:-}"
FDROID_PRIVILEGED_EXTENSION_PROFILE="${FDROID_PRIVILEGED_EXTENSION_PROFILE:-}"
FDROID_PRIVILEGED_EXTENSION_CACHE="${FDROID_PRIVILEGED_EXTENSION_CACHE:-}"
FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT="${FDROID_PRIVILEGED_EXTENSION_PATCH_REPORT:-}"
# Tools
ADDITIONALS[AVBROOT]="${ADDITIONALS[AVBROOT]:-true}"                   # Android Verified Boot Root
ADDITIONALS[CUSTOTA_TOOL]="${ADDITIONALS[CUSTOTA_TOOL]:-true}"         # Custom OTA Tool
ADDITIONALS[MY_AVBROOT_SETUP]="${ADDITIONALS[MY_AVBROOT_SETUP]:-true}" # My AVBRoot setup
ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="${ADDITIONALS_MAS_COMPATIBLE_SEPOLICY:-false}" # My AVBRoot setup

ADDITIONALS[ROOT]="${ADDITIONALS_ROOT:-false}"   # Only Magisk is supported
ADDITIONALS[RETRY]="${ADDITIONALS[RETRY]:-true}" # Auto download signatures
ADDITIONALS[DEBUG]="${ADDITIONALS_DEBUG:-false}" # Enable unauthorized ADB

# Outputs
OUTPUTS[PATCHED_OTA]="${OUTPUTS[PATCHED_OTA]:-}"
