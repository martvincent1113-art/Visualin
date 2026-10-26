# Visualin — Agent Handoff (Claude Code + Codex)

You have no chat history. This file is everything you need to continue.
**Read `AGENTS.md` first**, then `docs/design-system-v3.md` for any UI work.
Where this file and the code disagree about status, trust the code and report
the difference.

---

## 1. Project in one paragraph

Visualin is a Flutter (Android-first) capstone app that translates between
Filipino Sign Language (FSL) and English/Filipino text, with optional
text-to-speech. Two features, always named **FSL to Text** (camera recognition)
and **Text to FSL**. Owner: Mart (software engineering student). He pastes your
reports back to a chat assistant, so **end every task with a short, honest
report** (what changed, what you verified, what you could not verify).

## 2. Hard rules

- **FSL only.** No ASL/BSL data, models, charts or flags. ASL repos are pattern
  references only.
- **English is the default UI/output language.** Filipino is an opt-in Settings
  toggle that changes output text/speech only. All UI strings go through ARB.
- **Geofencing is out of scope.** Do not add, stub or document it.
- **Never persist camera frames or landmark data** in the app. History stores
  translated text only.
- A11y on every screen: 44x44 targets, screen-reader labels on icon-only
  controls, no color-alone state, text scaling respected.
- **Design source of truth: `docs/design-system-v3.md`** (orange `#FF6B00` +
  white brand, Inter, Phosphor icons, `#CC4A00` behind/for text). Design skills
  may review and suggest, but must not replace its colors, fonts or tokens.
- Do not invent FSL data. Unknown or unsupported sign = say so, never guess.
- No fake recognition results in the UI.
- Do not touch the `_isProcessing` gate or camera lifecycle fixes without a
  measured problem.
- Ask before adding any dependency not named here, in `AGENTS.md` or in v3.
- Never push unless Mart's prompt says to. Never rewrite history.

## 3. Status snapshot (verify before relying on it)

- **Camera + `hand_landmarker` pipeline:** built and device-confirmed.
- **Screens:** Splash, Onboarding, Home, Camera (FSL to Text), History stub,
  Settings, Text to FSL stub. UX refinement batch is on `ui/ux-refinement`.
- **Task 0 (audit + docs fixes):** Codex reported it done and pushed on
  `ui/ux-refinement`. Its report (audit table, camera-caching finding) was not
  reviewed yet. Re-verify.
- **Task 1 (FSL-105 pipeline):** done on local branch `ml/fsl105-pipeline`
  (commits `9327977`, `8adfd9d`), not pushed. Results: Variant A (hands only,
  T=32) 82.8% ± 2.4 top-1, 97.3% top-5 (mean of 3 seeds); Variant B (hands +
  pose) did not help. Split is random per clip, no signer IDs. Golden vectors
  in `ml/export/golden/` are synthetic. Mediapipe 0.10.21 in Python vs
  0.10.26.1 in the app.
- **Design-system v3 pass:** not started.
- **Task 2 (on-device recognition):** not started.

## 4. Task queue (in this order)

### Task A1 — Design v3: tokens, Home, Settings
Branch `ui/apple-pass` from `ui/ux-refinement`. Implement v3 tokens in
`lib/theme/`, add `phosphor_flutter` (approved), replace icons per the v3 table,
restyle Home and Settings only. Report screenshots and measured contrast
ratios. Stop for Mart's OK.

### Task 2a — On-device inference foundations (no UI)
Branch `ml/task2-integration` from `ml/fsl105-pipeline`.
1. **Spike:** add a TFLite runtime and confirm it coexists with
   `hand_landmarker` on Android (build, run on device, load the exported model,
   run one inference, check logcat for native errors and the tensor-writes
   error). If it conflicts, try in order: another TFLite plugin, a small
   platform-channel wrapper over Android TFLite, a pure-Dart GRU forward pass
   from exported weights.
2. **Dart feature extraction** mirroring `ml/src/features.py` exactly, tested
   against the golden vectors.
3. **Coordinate-frame check on device:** prove the Dart pipeline converts phone
   frames (portrait, rotated, front-camera mirrored, different aspect ratio from
   640x360) into the frame the model was trained on. Add a test and describe
   the handling.

### Task A2 — Design v3: remaining screens
On `ui/apple-pass` after Mart's OK: Camera (full-bleed preview, frosted 44x44
close/flip, result bottom sheet; update the overlay transform for the crop and
add a test), History (inset grouped list, mascot empty state), Splash (mascot
on transparent background), Onboarding, motion and haptics (Reduced motion
respected).

### Task 2b — Sign segmentation and recognition UI
After 2a passes and A2 is merged. Branch from the merged result.
- **Segmentation state machine:** Ready -> Signing -> Ended -> Recognizing ->
  Result / No sign -> Ready. Start = hands appear and wrist motion exceeds a
  threshold (keep ~0.3 s pre-roll). End = hands leave the frame or drop, or
  stay still ~0.6 s. Classify each segment **once**, resampled to T=32 exactly
  like training.
- **No duplicates / no guesses:** confidence threshold plus top-2 margin; below
  it show "No sign recognized". A repeated identical sign counts only after a
  return to rest.
- **Manual mode:** tap, 3-2-1 countdown, auto-stop at rest.
- All thresholds are named constants; report the values tuned on device.
- Replace "Recognition is coming soon" with real output. Result shows
  Speak/Copy/Save. Output honors the English/Filipino toggle; if a sign's `fil`
  is null, fall back to English and mark it.
- State shown with text + icon, never color alone.

### Later (do not start)
- `flutter_tts`, `drift` history (text only: text, direction, output language,
  timestamp, favorite), Recent Translations UI.
- **Text to FSL MVP:** dictionary keyed by **sign ID** (many English/Filipino
  words -> one sign ID -> one clip; Tagalog input treated as Filipino; every
  word-to-sign link confirmed by an FSL signer), phrase match before word
  match, play clips in order with `video_player`, fingerspell unknown words.
  Note in the paper: word-by-word order is signed English/Filipino, not full
  FSL grammar.
- **Task 3 — Blender sign animations:** record FSL signs, capture hands with
  MediaPipe, drive a Rigify rig, render one short video per sign. Every
  animation reviewed by an FSL signer. Hands-only avatars cannot show facial
  grammar; state that limitation.

## 5. Testing tools (use them; report what you verified on device)

- **Dart MCP server** (`dart mcp-server`): run tests, read runtime errors,
  inspect the widget tree, hot reload.
- **Maestro** for on-device UI flows, targeting widgets by semantics labels.
  Prefer the CLI (`maestro test`) over the Maestro MCP for long sessions.
- Before every report: `flutter analyze`, `flutter test`, launch on the
  connected phone, check runtime errors, walk changed screens with a Maestro
  flow, then run `/ponytail-review` and include its findings.
- You cannot sign in front of the camera. Never claim recognition works on
  real signing; say it needs an FSL signer.

## 6. Known risks to keep honest about

- Phone-camera accuracy will likely be below the 82.8% offline figure
  (background, lighting, new signers, random split).
- Isolated signs only. 105-sign vocabulary only.
- Hands are slotted by image position (plugin gives no handedness); crossing
  hands can swap.
- No Deaf-community review yet. All vocabulary and Filipino glosses unverified.
- `Jayveeeee24/iSpeak-Signs` is AGPL-3.0: UX reference only.
- Verify the FSL-105 citation in `ml/NOTICE.md` against the dataset page.
