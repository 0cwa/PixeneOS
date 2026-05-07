# Threat Model

Scope: the PixeneOS patcher and any successor tool (`patcher-cli`). Covers source, build, signing, distribution, and self-hosted CI.

## Assets

1. **Signing keys** — AVB key, OTA key, and any module-signing key. Compromise = arbitrary firmware on user devices.
2. **OTA payload integrity** — patched OTAs must match the unpatched OEM payload byte-for-byte outside the intentional patches.
3. **Module integrity** — converted/patched modules must not silently elevate privilege beyond what the original module declared.
4. **Build provenance** — who built which artifact, from which commit, with which toolchain.
5. **User secrets** — anything in `env.toml`, `.keys/`, or self-hosted-runner state.

## Trust boundaries

```
┌──────────────────────────────────────────────────┐
│ Maintainer workstation                           │
│  - source edits, key custody, manual signing     │
└──────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────┐
│ CI runner (GH-hosted | GH self-hosted | Forgejo) │
│  - reads source, downloads OEM OTA, runs avbroot │
│  - signing key access: VARIES (see scenarios)    │
└──────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────┐
│ Artifact host (gh-pages / private S3 / Custota)  │
│  - serves patched OTA + csig                     │
└──────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────┐
│ User device                                      │
│  - verifies AVB chain, applies OTA               │
└──────────────────────────────────────────────────┘
```

## Adversaries

| Adversary                         | Capability                                          | In-scope?     |
|-----------------------------------|-----------------------------------------------------|---------------|
| Random GitHub user                | Reads public source, opens malicious PR             | yes           |
| Compromised dev dependency        | Runs in CI                                          | yes           |
| GitHub Actions runner takeover    | Reads anything the workflow has access to           | yes           |
| Compromised maintainer workstation| Full repo + key access                              | partial       |
| Targeted state-level attacker     | Supply-chain, code-signing infra                    | out of scope  |
| User's own device, post-flash     | Local persistence, root re-acquisition              | out of scope  |

## Key custody scenarios

| Scenario           | Where keys live                  | CI signs?  | Pros                          | Cons                                 |
|--------------------|----------------------------------|-----------|-------------------------------|--------------------------------------|
| **A. Local-only**  | Maintainer's machine             | no        | minimum exposure              | manual step every release            |
| **B. CI secret**   | GH/Forgejo encrypted secret      | yes       | hands-off                     | runner takeover = key compromise     |
| **C. KMS / HSM**   | External (cloud KMS, Yubikey)    | yes (sign-only API) | runner can't exfiltrate key | infra cost + complexity            |
| **D. Hybrid**      | CI builds unsigned, maintainer signs locally | partial | low-exposure + automated builds | tooling needs detached-sign path |

ADR-pending (META-10 + META-11). Default for layperson self-host: **scenario A** (local-only).

## Attacker scenarios

### S1. Malicious PR slips into source

- Mitigation: review every PR; require CI green; `--compatible-sepolicy` and similar flags must be defaulted explicitly per device, not via env.
- Detect: `git log --diff-filter=A` + manual review of new SPDX-less files (HYGIENE-3).

### S2. Compromised CI runner exfiltrates signing key

- Mitigation A: don't put keys on CI (scenario A).
- Mitigation B: ephemeral self-hosted runners; key only loaded for the signing step; key-loading wrapper logs every access.
- Detect: signing audit log. Out-of-band key-use alerts (signing webhook → maintainer).

### S3. Tampered OEM OTA

- Mitigation: `avbroot` already verifies upstream OEM signatures before patching. We MUST NOT disable that check in any flag combination. Add a regression test in MATRIX-1's lint step.

### S4. Module-conversion privilege escalation

- A converted Magisk module that originally only read `/data/...` must not gain `/system_ext` write via the conversion. Converter MUST emit a permission-diff report and refuse on widening unless `--allow-widen` is passed (MODCONV-2).

### S5. Self-hosted runner gets pwned

- Mitigation: ephemeral runner pattern (one job → fresh VM/container); no persistent secrets at rest; per-device job network-egress allowlist (avbroot needs google APIs + custota repo).
- Default INFRA-1 recipe encodes this.

## Non-goals

- Defending against a compromised maintainer workstation. The maintainer is in the TCB by definition.
- Reproducible-bit-for-bit builds across machines. Nice-to-have but not required for trust; the AVB+OTA signature chain is the user-visible trust anchor.
- DRM / anti-tamper for the patcher itself. Source is open; users should be able to audit.

## Open questions (tracked as META)

- ~~META-1: SPDX header policy~~ — **resolved**: AGPL-3.0-or-later (ADR-0003); affects S1 detect-rate via HYGIENE-3 rollout.
- META-10: signing model — drives S2.
- META-11: self-hosted runner boundary — drives S5.
