# ROMCOMPAT-2 — Per-ROM manifest + capability flags

## Goal

Design a per-ROM manifest format describing the patches and capability flags each ROM (Graphene, Lineage, future) supports. This is what makes the patcher truly multi-ROM rather than a Graphene tool with Lineage glued on.

## Acceptance

- A document `docs/planning/per-rom-manifest.md` defines the schema (capabilities: rootless? magisk? AVB? Custota? OTA channel?).
- The schema covers Graphene + Lineage at minimum; pluggable for new ROMs.
- A worked example for both ROMs is included.

## Depends

- ROMCOMPAT-1
- META-3
