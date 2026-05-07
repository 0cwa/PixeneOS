# CLI-1 — Surface design: subcommand layout

## Goal

Design the public `patcher-cli` (placeholder name) subcommand surface: `patch`, `module`, `verify`, `matrix`, `keys`, plus their flags. Output is a CLI reference document; no code yet.

## Acceptance

- `docs/planning/cli-surface.md` enumerates every subcommand, every flag, exit codes, and a few worked examples per subcommand.
- Backward-compat note: how today's `src/main.sh` invocations map onto the new surface.
- Versioning + stability commitment is stated (e.g. "0.x — surface may break; 1.0 freezes it").

## Depends

- META-7 (final tooling name)
