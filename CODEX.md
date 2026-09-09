# CODEX.md — Notes for OpenAI Codex

**Read [`AGENTS.md`](AGENTS.md) first.** It's the canonical instruction set
for this repo (language policy, confirmed stack, do/don't list, build
commands) and Codex reads it automatically in any repo — this file only
adds Codex-specific notes on top of it.

## Working in this repo

- Treat the language policy in `AGENTS.md` Section 2 as a hard constraint,
  equivalent to a failing test — if a change would introduce a hardcoded
  English default or a non-FSL sign asset, stop and flag it rather than
  proceeding or "fixing it later."
- Before implementing any sign-recognition or sign-rendering feature, check
  [`docs/ml-resources.md`](docs/ml-resources.md) for an existing FSL dataset
  or reference repo to build from. Don't design a data pipeline from
  scratch when a reviewed FSL dataset (e.g. FSL-105) already fits.
- Stack is **Flutter, confirmed** (`AGENTS.md` Section 3) — don't scaffold,
  suggest, or fall back to a different framework, even if it would be
  faster to prototype in.
- When editing localization strings, add/update the Filipino string first
  (it's the default), then the English variant.

## Suggested task breakdown if starting from an empty repo

1. Scaffold Flutter: `flutter create .` in the repo root (only if
   `pubspec.yaml` doesn't already exist — check first, don't overwrite).
2. Add `hand_landmarker` to `pubspec.yaml` and wire up the MediaPipe camera
   pipeline (landmarks only, no classification yet); verify a live landmark
   overlay renders on an Android emulator/device before moving on.
3. Integrate the FSL-105 baseline model (or a reference repo from
   `docs/ml-resources.md`) for isolated-word recognition.
4. Build the localization layer with English as default locale before
   writing any screen copy.
5. Build screens per `docs/product-spec.md` Section 7 (roadmap), Phase 1
   first.

## Verification before finishing a task

- Run `flutter analyze` and `flutter test` before considering a change
  complete.
- If the change touches any user-facing string, manually confirm the
  Filipino string is the one used when no locale override is set.
- If the change touches the camera/ML pipeline, confirm it still targets
  `LIVE_STREAM` mode, not `IMAGE` mode (see `docs/architecture.md`).

## What not to do without checking in

- Don't propose or scaffold a different framework — Flutter is confirmed.
- Don't add a new sign language, avatar signer, or non-FSL dataset without
  explicit confirmation from the person you're working with.
- Don't commit recorded camera footage, video clips, or landmark data files
  to the repo — treat them as sensitive, and keep large binary assets out
  of git entirely (see `.gitignore`).

