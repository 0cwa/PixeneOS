# PixeneOS ticket process — small slice, validate, document

This local ticket system is an execution queue, not a complete product-spec generator. Keep the broader roadmap as a risk register/icebox, but do not turn every uncertainty into a blocking META gate.

## Operating rule

Prefer:

1. small focused change;
2. local validation;
3. documentation update at the end;
4. only then create follow-ups for concrete remaining work.

Avoid:

- planning-only tickets unless a wrong implementation would be legally risky, security-sensitive, or expensive to unwind;
- broad research surveys before the feature is imminent;
- META decisions that can be replaced by a safe reversible default;
- follow-up tickets for vague concerns.

## Default Definition of Done

Every normal ticket is complete only when:

- the code/config/doc change is minimal and focused;
- the validation command or manual check is recorded in the ticket output or planning note;
- user-facing docs are updated if behavior changed;
- local planning docs are updated only for decisions, risks, or operational notes not obvious from code;
- the ticket index is updated;
- new follow-up tickets are created only for specific actionable work.

## Documentation policy

Documentation is part of the ticket, not a separate default ticket.

- If behavior changes for users, update `README.md`, `docs/FAQ.md`, or another public doc in the same ticket, subject to maintainer/publication approval.
- If behavior changes only for maintainers or future agents, add a short local note under `docs/planning/`.
- If the change is self-evident and validated, do not write a large planning report.
- Keep licensing/provenance wording conservative; do not add or strengthen license claims for third-party-derived code unless provenance is clear.

## Lanes

### Now

Immediate safety and release-correctness work. These should be implementation-first.

### Next

Small foundation work that unlocks the next release shape. Prefer one thin vertical slice over a comprehensive abstraction.

### Later

Useful but not needed for the next release. Do not pick these unless the maintainer asks or Now/Next are blocked.

### Icebox

Research or product-expansion ideas. Keep as reminders, not active obligations.

## Safe defaults replacing META gates

Use these defaults unless a maintainer explicitly challenges them:

- Matrix format: TOML.
- Artifact privacy: default private; explicitly mark currently public compatibility rows before changing publishing behavior.
- Cache backend: GitHub Actions cache first; defer S3/self-hosted cache.
- CLI/tooling name: do not block implementation on naming.
- CLI distribution: Docker/direct script docs first; pipx/brew/apt later.
- Module conversion scope: Magisk first if/when converter work begins; KernelSU/APatch later.
- Manifest signing and self-hosted-runner threat model: defer until those features are real.
- Planning docs remain local-only unless the maintainer says to publish a curated subset.

## When a planning-only ticket is allowed

Use planning-only when at least one is true:

- legal/provenance risk is central;
- signing keys/secrets/public artifacts could be exposed;
- remote branch/history/release assets could be destroyed;
- a design decision would be hard to reverse after implementation;
- the ticket's output is explicitly requested by the maintainer.
