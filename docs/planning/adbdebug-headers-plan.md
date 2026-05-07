# ADBDEBUG SPDX/Header Plan

Scope: plan only for `src/debugmod.py` and `src/debug_module_setup.sh`. Do not edit source in this ticket.

## Proposed headers

For `src/debugmod.py`:

```python
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025 0cwa
```

For `src/debug_module_setup.sh`:

```bash
#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025 0cwa
```

Keep the shebang as line 1 for the shell script.

## Attribution / provenance

`git log --follow` findings:

- `src/debugmod.py` introduced by `c301b85` (`2025-08-29`, author `0cwa <kainau@yahoo.com>`), subject: `Add release option for debug, add debug module code to src`.
- `src/debug_module_setup.sh` introduced by `4f36dfc` (`2025-08-29`, author `0cwa <kainau@yahoo.com>`), subject: `Add recovery mode option`.

No existing copyright, SPDX, source URL, or template attribution was found in either file.

Derivative-code note: `debugmod.py` subclasses the downloaded `my-avbroot-setup` `Module` API, but this audit found no evidence that either file is copied from a third-party Magisk/debug module template. If the maintainer knows otherwise, keep/cite the upstream license instead of applying the project AGPL header.

## PR strategy

Single small PR, ADB-debug only:

1. Add headers to the two files above.
2. Do not include the wider HYGIENE-3 rollout.
3. In the PR body, cite ADR-0003 and the two introducing commits.
4. Ask reviewer to confirm “not derivative of a third-party module template” before merge.
