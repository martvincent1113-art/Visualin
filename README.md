# Visualin

**Filipino Sign Language (FSL) translation app.** Sign ↔ text ↔ speech, built
around FSL as recognized under Republic Act No. 11106 (The Filipino Sign
Language Act).

> 🇵🇭 Sign language in this app is **FSL only**. Default UI and output text
> language is **Filipino**; users may switch output text to **English** in
> Settings. See [docs/product-spec.md](docs/product-spec.md) for the full
> language policy.

## What this app does

- **FSL → Text/Speech** — live camera captures a signer, MediaPipe extracts
  hand/pose/face landmarks, a temporal model classifies the signed sequence,
  output is rendered as text (Filipino by default) with optional TTS.
- **Text → FSL** — typed/dictated text is rendered back as FSL, via
  pre-recorded native-signer video clips (MVP) with fingerspelling fallback.
- **Geofencing** — location-aware accessibility features (see
  [docs/product-spec.md](docs/product-spec.md#5-geofencing-features)).

## Repo guide for agents (Codex / Claude Code)

If you're an AI coding agent working in this repo, **read these first**:

1. [`AGENTS.md`](AGENTS.md) — build/run conventions, language policy rules,
   do's and don'ts. Canonical instructions for any agent (Codex, Claude Code,
   or otherwise).
2. [`CLAUDE.md`](CLAUDE.md) — Claude Code-specific notes (points back to
   `AGENTS.md` as the source of truth).
   [`CODEX.md`](CODEX.md) — Codex-specific notes (same idea).
3. [`docs/architecture.md`](docs/architecture.md) — technical design:
   MediaPipe pipeline, model choices, recommended stack.
4. [`docs/ml-resources.md`](docs/ml-resources.md) — FSL datasets and
   reference repos to build from (don't start from scratch).
5. [`docs/design-system.md`](docs/design-system.md) — colors, type, spacing.

## Status

Early-stage / pre-implementation. This repo currently contains planning and
architecture docs only — no app code yet.

## License

TBD — pick a license before your first public push. Note that some
third-party FSL resources referenced in `docs/ml-resources.md` carry their
own licenses (e.g. CC-BY-4.0) requiring attribution; check each before use.
