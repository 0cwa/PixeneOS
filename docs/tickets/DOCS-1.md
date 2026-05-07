# DOCS-1 — Document no-telemetry/privacy posture

## Goal

Document PixeneOS's no-telemetry/privacy posture when there is an authorized public documentation pass.

This should not usually be run as a standalone local planning note. If a ticket changes user-facing behavior, documentation belongs in that ticket by default.

## Acceptance

When this ticket is revived or folded into a public-doc pass:

- Current telemetry behavior observed in the source is documented.
- Necessary network calls are distinguished from telemetry, such as OTA/dependency downloads.
- README/FAQ wording is added or proposed, depending on maintainer publication approval.
- Future changes that would require security/privacy review are listed.

## Depends

—

## Notes

This is a documentation/privacy trust item, not an implementation change. Until public docs are authorized, handle privacy wording as part of the next relevant user-facing doc update.

## Out of scope

- Network egress allowlists for self-hosted runners.
- Adding telemetry or analytics.
