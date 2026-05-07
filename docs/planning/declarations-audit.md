# HYGIENE-4 — `src/declarations.sh` overrides and rebrand boundaries

Observed: 2026-05-06

Scope: local audit only. `src/declarations.sh` was not edited.

Comparison base: `upstream/main:src/declarations.sh` (`a2c4173`). Current branch: `origin/main` / `main` (`ef5641a`).

## Upstream diff summary

Current `src/declarations.sh` differs from `upstream/main` in four assignment-level places:

- `USER="0cwa"` replaces upstream `USER="pixincreate"`.
- `MAGISK[REPOSITORY]="topjohnwu/Magisk"` replaces upstream `MAGISK[REPOSITORY]="${USER}/Magisk"`.
- `ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]="${ADDITIONALS_MAS_COMPATIBLE_SEPOLICY:-false}"` is fork-only.
- `ADDITIONALS[DEBUG]="${ADDITIONALS_DEBUG:-false}"` is fork-only.

Everything else currently matches upstream defaults, but all assignments are included below so future rebrand work has a complete checklist.

## Assignment table

Allowed rebrand actions: `keep`, `rename-to-tool-name`, `make-configurable`, `delete-after-MATRIX-1`.

| Variable | Current value | Upstream default | Reason for override | Rebrand action |
|---|---|---|---|---|
| `ARCH` | `x86_64-unknown-linux-gnu` | same | Linux build target default; not fork-specific. | `keep` |
| `CLEANUP` | `${CLEANUP:-'false'}` | same | Runtime cleanup toggle; environment-overridable. | `keep` |
| `DEVICE_NAME` | `${DEVICE_NAME:-}` | same | Device selection comes from CI/manual invocation; will become matrix/device config. | `make-configurable` |
| `INTERACTIVE_MODE` | `${INTERACTIVE_MODE:-true}` | same | Local vs CI behavior toggle; already environment-overridable. | `keep` |
| `WORKDIR` | `.tmp` | same | Internal temporary workspace; not brand-specific. | `keep` |
| `DOMAIN` | `https://github.com` | same | Base host for GitHub release/dependency URLs. | `keep` |
| `REPOSITORY` ⚠️ | `PixeneOS` | same | Repository name appears in generated release URLs; tied to current project brand. | `rename-to-tool-name` |
| `USER` ⚠️ | `0cwa` | `pixincreate` | Fork owner override; used in generated release download URLs and therefore leaks maintainer identity into downstream output. | `make-configurable` |
| `VERSION[AFSR]` | `${VERSION[AFSR]:-1.0.4}` | same | Dependency version pin. | `keep` |
| `VERSION[ALTERINSTALLER]` | `${VERSION[ALTERINSTALLER]:-2.3}` | same | Dependency version pin. | `keep` |
| `VERSION[AVBROOT]` | `${VERSION[AVBROOT]:-3.29.1}` | same | Dependency version pin. | `keep` |
| `VERSION[AVBROOT_SETUP]` | `e59576e1f729fac00a56baff848b1c442ea36d6d` | same | Upstream `my-avbroot-setup` commit pin currently used on main. Lineage-specific `91e49bc` handling belongs in ROMCOMPAT work, not here. | `keep` |
| `VERSION[BCR]` | `${VERSION[BCR]:-2.10}` | same | Dependency version pin. | `keep` |
| `VERSION[CUSTOTA]` | `${VERSION[CUSTOTA]:-5.22}` | same | Dependency version pin. | `keep` |
| `VERSION[GRAPHENEOS]` | `${VERSION[GRAPHENEOS]:-}` | same | Runtime-discovered ROM version placeholder; ROM-specific and should move under device/ROM config. | `delete-after-MATRIX-1` |
| `VERSION[MAGISK]` | `${VERSION[MAGISK]:-}` | same | Runtime-discovered Magisk version placeholder. | `keep` |
| `VERSION[MSD]` | `${VERSION[MSD]:-1.22}` | same | Dependency version pin. | `keep` |
| `VERSION[OEMUNLOCKONBOOT]` | `${VERSION[OEMUNLOCKONBOOT]:-1.3}` | same | Dependency version pin. | `keep` |
| `MAGISK[PREINIT]` | `${MAGISK_PREINIT:-}` | same | Device-specific Magisk preinit input; should be per-device/per-build configuration. | `make-configurable` |
| `MAGISK[REPOSITORY]` | `topjohnwu/Magisk` | `${USER}/Magisk` | Fork override to use upstream Magisk instead of a repo-owner fork; avoids coupling Magisk source to `USER`. | `keep` |
| `MAGISK[URL]` | `${DOMAIN}/${MAGISK[REPOSITORY]}` | same | Derived internal dependency URL. | `keep` |
| `KEYS[AVB]` | `${KEYS[AVB]:-avb.key}` | same | Local signing key filename default. | `keep` |
| `KEYS[AVB_BASE64]` | `${KEYS[AVB_BASE64]:-''}` | same | CI secret placeholder for AVB key material. | `keep` |
| `KEYS[CERT_OTA]` | `${KEYS[CERT_OTA]:-ota.crt}` | same | Local OTA certificate filename default. | `keep` |
| `KEYS[CERT_OTA_BASE64]` | `${KEYS[CERT_OTA_BASE64]:-''}` | same | CI secret placeholder for OTA certificate material. | `keep` |
| `KEYS[OTA]` | `${KEYS[OTA]:-ota.key}` | same | Local OTA key filename default. | `keep` |
| `KEYS[OTA_BASE64]` | `${KEYS[OTA_BASE64]:-''}` | same | CI secret placeholder for OTA key material. | `keep` |
| `KEYS[PKMD]` | `${KEYS[PKMD]:-avb_pkmd.bin}` | same | Local AVB public key metadata filename default. | `keep` |
| `GRAPHENEOS[OTA_BASE_URL]` ⚠️ | `https://releases.grapheneos.org` | same | Hard-coded ROM release endpoint. This is correct for GrapheneOS but becomes per-ROM config for Lineage/OEM support. | `delete-after-MATRIX-1` |
| `GRAPHENEOS[UPDATE_CHANNEL]` ⚠️ | `${GRAPHENEOS_UPDATE_CHANNEL:-stable}` | same | User-visible ROM channel default; should be per-device/per-ROM config. | `delete-after-MATRIX-1` |
| `GRAPHENEOS[UPDATE_TYPE]` | `${GRAPHENEOS[UPDATE_TYPE]:-ota_update}` | same | avbroot image type selector; ROM/device-specific but still needed as config. | `make-configurable` |
| `GRAPHENEOS[OTA_URL]` | `${GRAPHENEOS[OTA_URL]:-}` | same | Optional/generated OTA URL placeholder; may be supplied directly by config in future. | `make-configurable` |
| `GRAPHENEOS[OTA_TARGET]` | `${GRAPHENEOS[OTA_TARGET]:-}` | same | Generated OTA target filename placeholder. | `keep` |
| `ADDITIONALS[AFSR]` | `${ADDITIONALS[AFSR]:-true}` | same | Module/tool inclusion default. | `keep` |
| `ADDITIONALS[ALTERINSTALLER]` | `${ADDITIONALS[ALTERINSTALLER]:-true}` | same | Module inclusion default. | `keep` |
| `ADDITIONALS[BCR]` | `${ADDITIONALS[BCR]:-true}` | same | Module inclusion default. | `keep` |
| `ADDITIONALS[CUSTOTA]` | `${ADDITIONALS[CUSTOTA]:-true}` | same | Module inclusion default. | `keep` |
| `ADDITIONALS[MSD]` | `${ADDITIONALS[MSD]:-true}` | same | Module inclusion default. | `keep` |
| `ADDITIONALS[OEMUNLOCKONBOOT]` | `${ADDITIONALS[OEMUNLOCKONBOOT]:-true}` | same | Module inclusion default. | `keep` |
| `ADDITIONALS[AVBROOT]` | `${ADDITIONALS[AVBROOT]:-true}` | same | Tool inclusion default. | `keep` |
| `ADDITIONALS[CUSTOTA_TOOL]` | `${ADDITIONALS[CUSTOTA_TOOL]:-true}` | same | Tool inclusion default. | `keep` |
| `ADDITIONALS[MY_AVBROOT_SETUP]` | `${ADDITIONALS[MY_AVBROOT_SETUP]:-true}` | same | Tool inclusion default. | `keep` |
| `ADDITIONALS[MAS_COMPATIBLE_SEPOLICY]` | `${ADDITIONALS_MAS_COMPATIBLE_SEPOLICY:-false}` | absent | Fork-only compatibility switch for `my-avbroot-setup` / ROM compatibility experiments; ROMCOMPAT should decide the durable shape. | `delete-after-MATRIX-1` |
| `ADDITIONALS[ROOT]` ⚠️ | `${ADDITIONALS_ROOT:-false}` | same | Build flavor toggle; affects output artifact names (`magisk` vs `rootless`). | `make-configurable` |
| `ADDITIONALS[RETRY]` | `${ADDITIONALS[RETRY]:-true}` | same | Download retry behavior. | `keep` |
| `ADDITIONALS[DEBUG]` ⚠️ | `${ADDITIONALS_DEBUG:-false}` | absent | Fork-only unauthorized ADB debug module switch; useful for local/device debug but dangerous as a global default. | `make-configurable` |
| `OUTPUTS[PATCHED_OTA]` ⚠️ | `${OUTPUTS[PATCHED_OTA]:-}` | same | Output artifact path placeholder. Actual filename embeds device, version, flavor, and commit. | `rename-to-tool-name` |

## User-facing vs internal values

User-facing or artifact-visible values:

- `USER` and `REPOSITORY`: used by `get_package_url` to construct GitHub release download URLs.
- `OUTPUTS[PATCHED_OTA]`: generated artifact filename published by CI.
- `DEVICE_NAME`, `GRAPHENEOS[UPDATE_CHANNEL]`, `GRAPHENEOS[OTA_BASE_URL]`, `GRAPHENEOS[OTA_URL]`, and `GRAPHENEOS[OTA_TARGET]`: visible in logs, OTA filenames, release lookup behavior, or published update metadata.
- `ADDITIONALS[ROOT]`: changes artifact flavor (`magisk` / `rootless`).
- `ADDITIONALS[DEBUG]`: not a branding value, but security-sensitive and should not become an accidental public default.

Primarily internal values:

- Build/runtime controls: `ARCH`, `CLEANUP`, `INTERACTIVE_MODE`, `WORKDIR`, `DOMAIN`.
- Dependency pins and derived URLs: `VERSION[*]`, `MAGISK[REPOSITORY]`, `MAGISK[URL]`.
- Signing key filenames/secret placeholders: `KEYS[*]`.
- Module/tool inclusion toggles except the flavor/debug cases called out above: most `ADDITIONALS[*]` entries.

## Rebrand boundary notes

- The immediate rebrand hazard is not the repository name alone; it is the combination of `USER`, `REPOSITORY`, and release URL generation. `USER="0cwa"` should not remain a hard-coded default for downstream users.
- `MAGISK[REPOSITORY]="topjohnwu/Magisk"` intentionally decouples Magisk from the repo owner. Do not mechanically rename it during the META-7 tool rename.
- ROM-specific values should not be solved by further edits to `declarations.sh`. MATRIX-1 / ROMCOMPAT should move ROM URL/channel/device defaults into the future matrix/config layer.
