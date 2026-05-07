#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2024-2026 PixeneOS contributors

# Copy the pre-commit hook to the .git/hooks directory
cp "src/hooks/pre-commit" ".git/hooks/"
chmod +x .git/hooks/pre-commit

echo -e "Pre-commit hook installed successfully!"
echo -e "Tip: install gitleaks for full standard secrets-scanning coverage; the hook also runs a PixeneOS fallback scanner."
