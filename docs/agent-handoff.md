# Visualin — Agent Handoff (Claude Code + Codex)

You have no chat history. This file is everything you need to continue.
**Read `AGENTS.md` first** (language policy and standing rules). Where this file
and the code disagree about status, trust the code and report the difference.

---

## 1. Project in one paragraph

Visualin is a Flutter (Android-first) capstone app that translates between
Filipino Sign Language (FSL) and English/Filipino text, with optional
text-to-speech. Two features, always named **FSL to Text** (camera recognition)
and **Text to FSL**. Owner: Mart (software engineering student). He pastes your
reports back to a chat assistant, so **end every task with a short, honest
report** (what changed, what you verified, what you could not verify).

## 2. Hard rules (from AGENTS.md, repeated because they matter)

- **FSL only.** No ASL/BSL data, models, charts or flags. ASL repos are pattern
  references only.
- **English is the default UI/output language.** Filipino is an opt-in Settings
  toggle that changes output text/speech only. All UI strings go through the
  localization layer (ARB). No hardcoded copy.
- **Geofencing is out of scope.** Do not add, stub or document it. Remove any
  leftover mentions.
- **Never persist camera frames or landmark data** in the app. History (later)
  stores translated text only.
- Standing a11y rules on every screen: 44x44pt targets, screen-reader labels on
  icon-only controls, no color-alone state, font scaling respected.
- Orange token is `#FF6B00`. Design tokens live in `docs/design-system.md`.
- Do not invent FSL data. Unknown or unsupported sign = say so, never guess.
- Do not stub fake recognition results in the UI.

## 3. Status snapshot (verify before relying on it)

**Built and device-confirmed by Mart:** camera + `hand_landmarker` pipeline
(LIVE_STREAM, CPU delegate, `_isProcessing` gate, correct sensor-to-preview
transform, canonical 21-link topology, restyled overlay, `ResolutionPreset.high`,
front camera default); no crash on closing the camera screen.

**Built, reported by Codex:** Splash, Onboarding (4 slides), Home, Camera,
Settings, stub screens for Text to FSL and History, `shared_preferences`
persistence (`hasOnboarded`, locale), English default / Filipino toggle,
11 passing tests at last report.

**Unknown (Task 0 finds out):**
- UX refinement batch: terminology rename to "FSL to Text", Home hierarchy and
  header, camera-permission re-request flow, Settings "Translation" section,
  switch styling, hand-detection status indicator, nav "Profile" to "Settings",
  accessibility pass, and the camera-caching check for the permission copy.
- Design-system v2 pass (Poppins via `google_fonts`, shadows, 8px scale, outline
  icons, `#FAFAFA` background, 12% orange icon-circle tint).
- 60fps audit.
- Whether docs on disk say English default and whether geofencing text remains.

## 4. Task queue

### Task 0 — Audit and housekeeping (do first, small, either agent)

1. Run `flutter analyze` and `flutter test`; report results.
2. Report, as a table, which UX-batch and design-pass items are present in code
   (check `pubspec.yaml` for `google_fonts`, nav labels, Home header string,
   Settings structure, permission re-request, switch styling, hand-detection
   indicator).
3. Report what you find for the camera-caching question: does the app write any
   video frames or landmark data to temp files, logs, or crash reports? If yes,
   the privacy copy "Video is processed for translation and is not saved" must
   not ship.
4. Docs fixes only: remove all geofencing mentions (README, `product-spec.md`
   Section 5 and roadmap, anything else); make sure `product-spec.md` and
   `design-system.md` say English default; make sure `CLAUDE.md` says English
   default and does not say "Flutter or React Native".
5. Do not change app code in this task except trivial fixes you report.

### Task 1 — FSL-105 recognition pipeline (offline, Python) — Phase 2a

Goal: a trained, exported sign classifier whose input features are exactly what
the on-device pipeline can produce. **Work only inside `ml/`.** This is
independent of the Flutter app, so it can run in parallel with UI work.

**Data**
- FSL-105: https://data.mendeley.com/datasets/48y2y99mb9/2 (also on Hugging Face
  as `SEACrowd/fsl_105`; its loading script may not work with newer `datasets`
  versions, prefer the raw files). 105 signs, about 2,130 four-second clips,
  provided train/test split and labels, CC-BY-4.0.
- If the download needs a browser, stop and ask Mart to download it into
  `ml/data/raw/` (gitignored). Never commit videos or `.npy` files.
- Check and report whether the provided split is signer-independent. If signer
  IDs are not available, say so. A signer-dependent split overstates accuracy.

**Layout**
```
ml/
  README.md              one command per stage, exact versions
  requirements.txt       pin versions; pick a Python version supported by BOTH
                         mediapipe and tensorflow (verify before installing)
  src/extract_landmarks.py
  src/features.py        normalization + windowing (single source of truth)
  src/train.py
  src/evaluate.py
  src/export_tflite.py
  data/                  gitignored
  export/                model, label map, golden vectors
```
Windows/PowerShell is the dev environment: use a venv (`py -m venv .venv`).

**Feature contract (decide, document in `ml/README.md`, and keep stable)**
- Variant A (must match the app today): two hands x 21 landmarks x (x, y, z)
  = 126 values per frame, plus a per-hand "present" mask. Missing hand = zeros
  plus mask 0.
- Variant B (offline experiment only): A plus MediaPipe Pose upper-body points.
  Purpose: measure how much body-relative position helps, to decide whether to
  bring in `kwon_mediapipe_landmarker` earlier. Report the accuracy gap.
- Inspect what the Flutter `hand_landmarker` plugin actually returns (coordinate
  space, handedness, z meaning) and make the Python extraction match it. Do not
  assume Python and Dart return the same convention.
- Mirroring: the front camera preview is mirrored. Choose one convention (for
  example, feed the classifier un-mirrored coordinates, or canonicalize
  handedness) and document it. Add mirror augmentation if signers' handedness
  varies.
- Normalization: translate relative to a stable reference (wrist or a body
  reference), scale by a size reference. Raw image coordinates are not allowed
  as the only features.
- Windowing: resample each clip to a fixed length T. Try T in {32, 48, 64} and
  report which wins.

**Model and training**
- Start small: 1-2 GRU layers (about 64-128 units), dropout, softmax over 105
  classes. Keras/TensorFlow.
- Augment: small rotation/scale/translation of landmarks, noise, time-warp,
  random dropped frames. Landmarks are background-independent, but detection
  quality on a phone in a normal room is the real risk (FSL-105 was filmed on a
  blue background at 640x360).
- Report top-1 and top-5 on the provided test split, per-class accuracy, and a
  confusion matrix image. State clearly that the source thesis's 100% top-5
  figure has not been reproduced unless you reproduce it.

**Export**
- Convert to TFLite. GRU conversion can need fixed shapes or extra ops; try it
  early, before heavy tuning. If TFLite conversion proves painful, export raw
  weights to JSON as a fallback (see Task 2, option C).
- Verify the TFLite model against the Keras model on at least 20 sequences
  (max absolute difference under 1e-3 for float32) and report it.
- Write `export/label_map.json` and `export/signs.json` with fields
  `id`, `en`, `fil`. Use the dataset's labels for `en`. **Leave `fil` null until
  a Filipino-fluent reviewer confirms it. Do not machine-translate silently.**
- Write golden test vectors (`export/golden/`): a few input feature sequences and
  the expected output probabilities, for Dart-side tests in Task 2.
- Add FSL-105 attribution to a `NOTICE`/credits file (CC-BY-4.0 requires it).
  Citation: Tupal and Cabatuan, "FSL105: The Video Filipino Sign Language Sign
  Database of Introductory 105 FSL Signs."

**Done when:** the pipeline reproduces from `ml/README.md`, the report lists
numbers for Variants A and B, TFLite parity is verified, golden vectors exist,
and no raw data is committed.

### Task 2 — On-device integration (after Task 1 passes; Flutter)

1. **Spike first on a branch:** confirm a TFLite runtime coexists with
   `hand_landmarker`. `tflite_flutter` was recommended but never checked
   against the TFLite/MediaPipe native libraries bundled in `hand_landmarker`.
   Options if it conflicts:
   - A: another Flutter TFLite plugin that passes the spike,
   - B: a small platform-channel wrapper over the Android TFLite library,
   - C: run the small GRU as a pure-Dart forward pass using exported weights.
2. Dart feature extraction must reproduce the Python features exactly. Prove it
   with a test that feeds the golden input vectors and compares outputs.
3. Add a rolling frame buffer, a voting/smoothing window, and a confidence
   threshold. Below threshold shows "No sign recognized", never a guess.
4. Replace the "Recognition is coming soon" placeholder with real output.
   Recognition states ("Recognizing...", result with Speak/Copy/Save) only now
   become allowed. Output text honors the English/Filipino toggle; if a sign's
   `fil` is null, fall back to English and mark it.
5. Keep the `_isProcessing` gate and the camera lifecycle fixes intact. Re-run
   the close-screen crash check and the logcat check for the native tensor
   error after integration.

### Task A — UI polish (Codex lane, parallel to Task 1)

Only items Task 0 shows are missing: design-system v2 pass (show the Home screen
result before repainting everything), onboarding supporting sentence per slide,
then the 60fps audit using DevTools in profile mode. Do not touch the camera
detection/overlay logic without a measured problem.

### Later (do not start yet)

`flutter_tts` output; `drift` history (text only; fields: text, direction,
output language, timestamp, favorite); Recent Translations UI; Text to FSL MVP
(word-to-clip lookup with `video_player` plus fingerspelling fallback);
`kwon_mediapipe_landmarker` for face/pose if Variant B justifies it.

## 5. Working agreement for two agents

- Suggested split: **Claude Code takes Task 1 (`ml/`)**, **Codex takes Task 0
  then Task A (Flutter)**. Do not edit each other's directories.
- Use separate git branches (for example `ml/fsl105-pipeline` and
  `ui/design-pass`). If the project is not a git repo yet, ask Mart before
  running `git init`. Do not push or rewrite history.
- Ask before adding any dependency not named in this file or `AGENTS.md`.
- Windows paths and PowerShell syntax in any command you give Mart.

## 6. Known risks to keep honest about

- Phone-camera accuracy will probably be below dataset accuracy (background,
  lighting, signers, 105-sign vocabulary only).
- Isolated signs only. Continuous signing needs segmentation and is out of
  scope for now.
- Mart is not assumed to be an FSL signer. Real-world validation needs an
  FSL-fluent person. Do not have anyone "test" by guessing signs.
- No Deaf-community review yet. Treat all vocabulary and any Filipino glosses
  as unverified until reviewed.
- `Jayveeeee24/iSpeak-Signs` is AGPL-3.0: UX reference only.
