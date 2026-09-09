# CLAUDE.md — Notes for Claude Code

**Read [`AGENTS.md`](AGENTS.md) first.** It's the canonical instruction set
for this repo (language policy, stack, do/don't list, build commands) and
applies to Claude Code exactly as written. This file only adds Claude
Code–specific notes on top of it.

## Working in this repo

- Treat the language policy in `AGENTS.md` Section 2 as a hard constraint,
  equivalent to a failing test — if a change would introduce a hardcoded
  English default or a non-FSL sign asset, stop and flag it rather than
  proceeding.
- Before implementing any sign-recognition or sign-rendering feature, check
  [`docs/ml-resources.md`](docs/ml-resources.md) for an existing FSL dataset
  or reference repo to build from. Don't design a data pipeline from
  scratch when a reviewed FSL dataset (e.g. FSL-105) already fits.
- When editing localization strings, update the Filipino string first (it's
  the default), then the English variant — never the reverse, to avoid
  English becoming the de facto source of truth.
- Run whatever test suite exists for the localization layer before
  finishing a task that touches UI copy.

## Suggested task breakdown if starting from an empty repo

1. Scaffold the Flutter project (`flutter create .` in the repo root — see
   `AGENTS.md` Section 3, stack is already confirmed as Flutter, don't ask
   about React Native or any other framework).
2. Add `hand_landmarker` and wire up the MediaPipe camera pipeline
   (landmarks only, no classification yet) and confirm live landmark
   overlay works on Android.
3. Integrate the FSL-105 baseline model (or a reference repo from
   `docs/ml-resources.md`) for isolated-word recognition.
4. Build the localization layer with Filipino as default locale before
   writing any screen copy.
5. Build screens per `docs/product-spec.md` Section 7 (roadmap), Phase 1
   first.

## What not to do without checking in

- Don't propose or scaffold a different framework — Flutter is confirmed in
  `AGENTS.md`, this isn't an open decision.
- Don't add a new sign language, avatar signer, or non-FSL dataset without
  explicit confirmation — this is the one rule in this repo that should
  never be worked around for convenience.