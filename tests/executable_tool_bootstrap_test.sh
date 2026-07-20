#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2026 PixeneOS contributors

set -euo pipefail

python3 tests/test_bootstrap_archive.py
python3 tests/executable_tool_bootstrap_test.py

echo "executable tool bootstrap tests passed"
