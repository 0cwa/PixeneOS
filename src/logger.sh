#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025-2026 PixeneOS contributors

# Simple timestamped logging. %b preserves the project's existing escaped
# multi-line messages while keeping severity explicit.
log() {
  printf "[%s] [INFO] -- %b\n" "$(date +"%Y-%m-%d %T")" "$1"
}

warn() {
  printf "[%s] [WARN] -- %b\n" "$(date +"%Y-%m-%d %T")" "$1" >&2
}

error() {
  printf "[%s] [ERROR] -- %b\n" "$(date +"%Y-%m-%d %T")" "$1" >&2
}
