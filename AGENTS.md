# AGENTS.md — Instructions for AI coding agents (Codex, Claude Code, etc.)

This file is the canonical set of instructions for any AI agent working in
this repository. Read this in full before making changes. `CLAUDE.md` exists
for Claude Code but simply points back here — don't treat it as a separate
source of truth.

## 1. What this project is

Visualin is a mobile app for two-way translation between **Filipino Sign
Language (FSL)** and Filipino/English text, plus text-to-speech. Full product
spec: [`docs/product-spec.md`](docs/product-spec.md). Full technical
architecture: [`docs/architecture.md`](docs/architecture.md).

## 2. Non-negotiable language policy

This is the single most important constraint in this codebase — violating it
is treated as a functional bug, not a style choice:

- **Signed language is FSL only.** Never add another sign language (ASL,
  BSL, etc.) as an option, fallback, or "for now" placeholder. Do not use
  ASL datasets, models, or fingerspelling charts as if they were FSL —
  ASL and FSL are different languages with different handshapes and grammar.
  If an ASL resource is used as a *code/architecture* reference (e.g. a
  MediaPipe pipeline pattern), that's fine — but the trained model and sign
  data must be FSL-specific before anything ships.
- **Default UI copy and default output text language is English.**
  Every user-facing string (buttons, onboarding, labels, translated
  captions, TTS default voice) defaults to English.
- **Filipino is opt-in**, via a single Settings toggle that changes the
  *output text/speech language* (what a translated sign renders as). This
  toggle never adds or changes the sign language — FSL stays constant
  regardless of this setting, and remains FSL-only regardless of which text
  language is selected.
- Do not hardcode Filipino strings directly in UI components. All UI copy
  goes through the localization layer with English as the default locale,
  so the Filipino toggle actually works and so future locale additions
  don't require rewriting components.
## 3. Confirmed stack

- **Client:** Flutter (confirmed — don't propose switching frameworks).
- **On-device ML:** `hand_landmarker` (Android, MIT) for hand tracking —
  primary FSL signal, start here. Add `kwon_mediapipe_landmarker` (Android +
  iOS, Apache 2.0) in Phase 2 for face/pose. Full package rationale and
  version pins: `docs/architecture.md` Section 1.
- **Known constraint:** MediaPipe pose has no official iOS SDK — Android is
  the primary MVP platform; don't assume iOS parity from day one.
- **Sign classification model:** start from the FSL-105 MediaPipe+GRU
  baseline referenced in `docs/ml-resources.md` before designing a new model
  from scratch.
- **TTS:** platform-native TTS (Android/iOS) with an English voice as
  default; Filipino voice available when the user switches the output
  language toggle — confirm Filipino voice availability on target OS
  versions before committing to a TTS provider.

## 4. Do / Don't

**Do:**
- Check `docs/ml-resources.md` before sourcing any dataset or pretrained
  model — several FSL-specific ones already exist; don't default to
  ASL/WLASL resources out of convenience.
- Normalize MediaPipe landmark coordinates (relative position + scale)
  before feeding any model — raw pixel coordinates will not generalize.
- Keep camera/microphone permission prompts explicit about *why* they're
  needed, before triggering the OS-level permission dialog.
- Write tests for the localization layer specifically — this is the part
  most likely to regress silently (a Filipino string slipping into the
  English default path).
- Apply the accessibility standing requirements from
  `docs/design-system.md` (44×44pt touch targets, screen-reader labels on
  icon-only controls, respecting font-scaling, never color-alone state
  indication) to every screen as it's built — not as a later pass. This
  app's core audience makes this non-negotiable in the same way the
  language policy is.
- Use the standardized feature names "FSL to Text" and "Text to FSL"
  everywhere (see design-system.md Feature Terminology) — don't introduce
  alternate names for the same feature in different parts of the app.

**Don't:**
- Don't add other sign languages, even behind a flag "for future use."
- Don't invent FSL sign data — if a sign isn't in a verified dataset or
  reviewed by an FSL-fluent consultant, mark it as unverified/missing rather
  than guessing a rendering for it.
- Don't ship avatar-based sign synthesis as a default experience without
  FSL-fluent Deaf review — prefer real signer video clips for anything
  user-facing until an avatar pipeline has been validated.
- Don't commit any recorded user camera footage or landmark data to the
  repo or to logs — treat it as sensitive biometric-adjacent data.

## 5. Build / run / test

```bash
flutter pub get
flutter run       # Android is the primary target device/emulator for now
flutter test
```

## 6. Commit conventions

- Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).
- Reference the relevant doc section in the commit body when a change
  touches the language policy or the ML pipeline (e.g. "see
  docs/architecture.md#normalization").