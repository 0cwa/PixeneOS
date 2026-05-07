# ADB Debug Module Design + Threat Surface

Scope: `src/debugmod.py`, `src/debug_module_setup.sh`, and the call site in `src/util_functions.sh` that enables `--module-debug` when `ADDITIONALS_DEBUG=true`.

## Summary

The ADB debug module is a build-time my-avbroot module. When enabled, it appends SELinux allow rules and debug ADB properties into the patched system/vendor images. It does **not** run a separate script on the device at boot; the device boots with modified properties/policy baked into the OTA.

Recommended default: **opt-in build only**. It is useful for recovery/debugging, but `ro.adb.secure=0` and permissive ADB-related SELinux rules are too risky for normal releases.

## What it touches

| Surface | Exact item | Operation | Effect |
|---|---|---|---|
| my-avbroot module tree | `${WORKDIR}/tools/my-avbroot-setup/lib/modules/debugmod.py` | `cp src/debugmod.py ...` | Adds a local module implementation to the downloaded my-avbroot setup checkout. |
| my-avbroot module registry | `${WORKDIR}/tools/my-avbroot-setup/lib/modules/__init__.py` | two `awk` rewrites | Imports `DebugMod` and registers module key `'debug': DebugMod`. |
| dummy module files | `${WORKDIR}/modules/dummy.zip`, `${WORKDIR}/modules/dummy.zip.sig` | `touch` | Satisfies the patcher's module input interface; contents are not the behavior. |
| patcher args | `--module-debug`, `--module-debug-sig` | appended in `patch_ota` | Enables the registered debug module for the OTA patch. |
| SELinux policy files | every `Path` passed in `selinux_policies` | append text rules in binary append mode | Allows adbd/init/system_server to set debug props, use USB device nodes, set uid/gid, and bind/listen TCP sockets. |
| system build props | `system/system/build.prop` in the extracted system image | append `# Added by DebugMod` and properties | Enables insecure/debuggable ADB-related properties if file exists. |
| vendor build props | `vendor/build.prop` in the extracted vendor image | append same properties | Same as above if file exists. |

### Properties appended

- `ro.debuggable=1`
- `ro.adb.secure=0`
- `persist.service.adb.enable=1`
- `persist.service.debuggable=1`
- `persist.sys.usb.config=mtp,adb`

### SELinux rules appended

- `allow adbd adbd process { fork signal_perms }`
- `allow adbd self process { setcurrent getcurrent }`
- `allow adbd device_debug_prop property_service { set }`
- `allow adbd userdebug_prop property_service { set }`
- `allow adbd shell_prop property_service { set }`
- `allow init { system_prop userdebug_prop shell_prop } property_service { set }`
- `allow system_server usb_device dir { search }`
- `allow system_server usb_device chr_file { open read write ioctl }`
- `allow system_server device_debug_prop property_service { set }`
- `allow adbd self capability { setuid setgid }`
- `allow adbd rootfs dir { read open }`
- `allow adbd port tcp_socket { name_bind }`
- `allow adbd node_type tcp_socket { node_bind }`
- `allow adbd self tcp_socket { create bind setopt accept listen read write }`

## Lifecycle

- **Activation:** build-time only, when `allow_unauthorized_adb` workflow input / `ADDITIONALS_DEBUG` is `true`. `src/util_functions.sh` calls `setup_debug_module`, then passes the dummy zip/sig pair as `--module-debug` inputs.
- **Boot stage:** no separate Magisk `post-fs-data`/`service.sh` was found. The changes are present from early boot because they are baked into build props and SELinux policy.
- **Persistence:** persists across reboots and until a later OTA replaces the modified system/vendor images. A later non-debug PixeneOS build should remove the effect by not reapplying these modifications.
- **Uninstall path:** flash/apply a non-debug build or stock/clean OTA. There is no standalone runtime module uninstall path in the tracked source.

## Privilege model

- **Build time:** runs as the CI/maintainer user executing the patcher; root is not implied by the source itself.
- **On device:** effects are consumed by Android `init`, `adbd`, and `system_server` under their normal SELinux domains, but the policy and properties deliberately grant more ADB/debug capability.
- **Root need:** the patcher needs signing/OTA patch privileges in the build process; the on-device result can make ADB much more powerful by disabling ADB authorization and allowing setuid/setgid behavior.

## Network exposure

The module explicitly sets USB config to `mtp,adb` and does **not** set `service.adb.tcp.port` or `persist.adb.tcp.port`. That points to USB ADB by default.

However, its SELinux rules allow `adbd` to bind/listen on TCP sockets. If any other setting or user action enables wireless/TCP ADB, `ro.adb.secure=0` makes that exposure high risk because ADB authorization is disabled.

## Threat-surface checklist

Uses the shared adversary definitions in `docs/planning/threat-model.md`.

| Scenario | Module-specific risk | Mitigation |
|---|---|---|
| S1 malicious PR slips into source | A small edit could silently make every debug build expose unauthenticated ADB or broader SELinux permissions. | Keep disabled by default; require explicit workflow input; review diffs to `SYSTEM_PROPS` and `SELINUX_RULES` carefully. |
| S2 compromised CI runner exfiltrates signing key | Debug builds are not the key risk themselves, but a compromised runner could sign a debug-enabled OTA. | Do not keep signing keys in general CI; require clear artifact labeling for debug builds. |
| S3 tampered OEM OTA | Module relies on normal avbroot verification before patching. | Do not disable upstream OTA verification in any debug path. |
| S4 module-conversion privilege escalation | This module is intentionally privilege-widening: adbd property setting, setuid/setgid, and TCP bind/listen are added. | Treat as a special-case debug module, not as a normal converted module; require opt-in. |
| S5 self-hosted runner gets pwned | A malicious actor with runner control could publish debug-enabled artifacts. | Separate debug artifacts from normal releases; avoid public auto-publish for debug builds. |

## User-facing trade-offs

Gains:

- Easier recovery/debug access when a build is otherwise hard to inspect.
- ADB enabled by default over USB (`mtp,adb`) and less blocked by SELinux/property restrictions.

Costs:

- Disables ADB authorization (`ro.adb.secure=0`), so physical access to USB may be enough for ADB access.
- If TCP/wireless ADB is enabled elsewhere, the device may expose unauthenticated ADB over the network.
- Debuggable properties and changed SELinux policy may weaken app/device isolation and can affect attestation/trust assumptions.
- No standalone uninstall; requires flashing a non-debug build.

## Recommended default

Use **opt-in build only**:

- Normal public/private release builds: debug module off.
- Debug/recovery builds: explicit workflow input, clearly named artifacts, and no automatic promotion to public update JSON without maintainer confirmation.
