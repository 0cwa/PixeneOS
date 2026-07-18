#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025-2026 PixeneOS contributors

# ---
# LOGGING
# Provides simple, timestamped logging functions.
# ---

# Usage: log "Doing something..."
log() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d %T")
  printf "[%s] [INFO] -- %s\\n" "$timestamp" "$1"
}

# Prints an error message to stderr.
# Usage: error "Something went wrong."
error() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d %T")
  printf "[%s] [ERROR] -- %s\\n" "$timestamp" "$1" >&2
}
