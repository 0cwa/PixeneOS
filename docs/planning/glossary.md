# Glossary

Project-specific terms. New jargon goes here so tickets can stay terse.

## Android / firmware

- **AVB** — Android Verified Boot. Cryptographic chain that verifies every partition before mount. Project signs AVB metadata with a key the user enrolls (locked bootloader + custom AVB key).
- **AVB key** — RSA key used to sign vbmeta and chained partitions. Must remain confidential. See threat-model S2.
- **OTA** — Over-the-air update. Here a `.zip` produced by the OEM (or LineageOS) containing partition payloads.
- **payload.bin** — the actual partition binary inside an OTA, addressed by partition name.
- **OEM OTA** — the unmodified upstream OTA from Google / Sony / Lineage. We never alter it byte-by-byte; we patch slots inside a copy.
- **csig** — signed metadata file Custota consumes to advertise an OTA. One per device per release.
- **Custota** — the OTA-server / OTA-client side of the avbroot ecosystem (`chenxiaolong/Custota`). Hosts csig + zip; client running on device polls and applies.
- **Custota update server** — HTTP endpoint serving `<device>.json` + the OTAs.
- **sepolicy** — SELinux policy. Each ROM has its own; cross-ROM patching requires merging or compatible-mode emitting.
- **CIL** — Common Intermediate Language; SELinux's policy DSL. `cil_rules.py` from `91e49bc` provides a Python emitter for compat-mode rules.
- **`--compatible-sepolicy`** — flag introduced in `91e49bc` of `0cwa/my-avbroot-setup` (the PixeneOS-side fork, not upstream). Lets a single tooling pass emit sepolicy that works against multiple ROM bases.
- **ODM partition** — vendor-specific partition; some Lineage devices need ODM-aware patches. `91e49bc` added handling.
- **`file_contexts`** — file-path → SELinux-label table per partition. Partition-specific ones added in `91e49bc`.

  *(For the per-hunk decomposition of what `91e49bc` adds and which hunks are upstream-bound vs fork-only, see [`0cwa/my-avbroot-setup:docs/upstream-disposition.md`](https://github.com/0cwa/my-avbroot-setup/blob/master/docs/upstream-disposition.md).)*
- **vbmeta** — top-level AVB metadata blob; signed; references chained-partition hashes.

## Module ecosystem

- **Magisk module** — directory tree + `module.prop` flashed via Magisk Manager; runs at boot via Magisk's hook.
- **Magisk preinit** — partition Magisk reserves for state that must survive across-OTA. Per-device.
- **KernelSU** — alternative root solution; module format similar to Magisk but kernel-anchored.
- **APatch** — another root variant; mostly out of scope until META-9 says otherwise.
- **Flashable zip** — generic recovery-installable zip. Predates Magisk modules.
- **Module IR** — internal representation the converter normalises modules to. Secondary surface.
- **Manifest format** — declarative module description used by the converter's output. Tertiary; not user-facing.

## Build / tooling

- **avbroot** — Rust tool by chenxiaolong that does the actual patching. We orchestrate it.
- **`avbroot ota extract --partition`** — already-supported partition-selective extraction (BUILDOPT-1 leverages this).
- **rootless flavor** — patched OTA without Magisk/KernelSU; pure AVB-verified.
- **Magisk flavor** — patched OTA with Magisk pre-installed in boot partition.
- **patcher-cli** — working name for the tool until META-7 rebrand.
- **build matrix** — devices × ROMs × flavors. Source of truth tracked in MATRIX-1.

## Project / repo

- **Compatible fork** — long-lived fork that tracks upstream and minimises diff. Our `my-avbroot-setup` fork strategy.
- **Topic branch** — short-lived per-ticket branch; squash-merged.
- **gh-pages devices** — devices currently advertised via the gh-pages branch artifacts: XQ-DC72, barbet, bluejay, bramble, caiman, shiba.
- **pdx235** — Sony device codename (Xperia 1 V); local Lineage target.

## Decision-flow

- **META ticket** — gate ticket; blocks downstream until human decides.
- **ADR** — Architecture Decision Record. Lives under `docs/planning/decisions/`.
