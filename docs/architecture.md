# Architecture

## 1. Client stack — Flutter (confirmed)

### MediaPipe packages

| Package | Tracks | Platforms | License | Use for |
|---|---|---|---|---|
| [`hand_landmarker`](https://pub.dev/packages/hand_landmarker) | Hands (21 landmarks) | **Android only** | MIT | Primary signal for FSL recognition — start here. JNI bridge, background isolate (non-blocking), bundled model, no manual setup. |
| [`kwon_mediapipe_landmarker`](https://pub.dev/packages/kwon_mediapipe_landmarker) | Face (478 pts) + Pose | Android + iOS | Apache 2.0 | Phase 2: non-manual markers (face) and arm trajectory (pose). Newer package, fewer downloads — vet it before depending on it heavily. |

```yaml
# pubspec.yaml
dependencies:
  camera: ^0.11.0
  hand_landmarker: ^2.2.0
  kwon_mediapipe_landmarker: ^0.0.3   # add when starting Phase 2 (face/pose)
```

**Known constraint:** MediaPipe's Pose Landmarker has **no official iOS
SDK** from Google as of this writing — community packages fill the gap with
varying maturity. Practical implication: **treat Android as the primary MVP
platform**; budget iOS pose/face support as a separate, later milestone
rather than assuming day-one parity.

Reference implementation to read (not a dependency, just useful to study
the JNI bridge pattern): [`IoT-gamer/flutter_mediapipe_hand_tracking`](https://github.com/IoT-gamer/flutter_mediapipe_hand_tracking)
on GitHub — this is the demo project `hand_landmarker` itself was built
from.

### Fallback option (if native packages prove too unstable)

MediaPipe's JS bundle (`@mediapipe/tasks-vision`) running in a WebView via
`flutter_inappwebview` or similar is a fallback path — it runs the full
Hand/Pose/Face Landmarker pipeline via WASM + WebGL, cross-platform, with
sub-15ms latency in reference implementations. Keep the ML pipeline logic
isolated behind a clean Dart interface so swapping the underlying
implementation later doesn't require rewriting the rest of the app.

## 2. Camera pipeline (FSL → Text)

```
Camera frame
   → MediaPipe Tasks (LIVE_STREAM mode):
       HandLandmarker   (21 pts/hand × x,y,z)
       PoseLandmarker   (arm/shoulder trajectory)
       FaceLandmarker   (non-manual markers — Phase 2+)
   → Per-frame landmark vector
   → Normalize (relative to shoulder midpoint, scaled by shoulder width)
   → Rolling buffer (~30–60 frames / 1–2 sec window)
   → Temporal model (see Section 3)
   → Prediction + confidence
   → Voting/smoothing buffer over last N predictions
   → Render as text (Filipino default) + optional TTS
```

**Why `LIVE_STREAM` mode, not `IMAGE` mode:** `IMAGE` mode treats each frame
independently and discards motion context. FSL signs are defined by
movement, handshape change, and path — a single frame is frequently
ambiguous between multiple signs.

**Why normalize before modeling:** raw screen-pixel coordinates encode
"where the signer stood in frame," not the sign itself. Normalizing
position (relative to a body reference point) and scale (relative to a
body-size reference like shoulder width) is required for the model to
generalize across users, camera distances, and phone models.

## 3. Temporal classification model — options, cheapest to most capable

1. **DTW (Dynamic Time Warping)** against reference sequences — no training
   required; good for small MVP vocabularies; handles variable signing
   speed.
2. **Metric-learning + prototype matching** (encoder trained to cluster
   same-sign sequences, classify via cosine similarity to class
   prototypes) — needs fewer labeled samples per class than a full
   classifier; exportable to ONNXRuntime for client-side inference.
3. **GRU / small Transformer encoder** over the landmark sequence — highest
   accuracy; this is the approach validated on the FSL-105 dataset
   (MediaPipe + GRU, 100% top-5 accuracy per the source thesis — see
   `ml-resources.md`). Use this as the default target architecture once
   past the earliest prototyping stage.

## 4. Segmentation (continuous signing) — Phase 2+

Real conversational signing has no pauses between signs. Don't attempt this
before isolated-word recognition is solid. Approaches, in order of effort:
- Movement-energy threshold (low motion = between-sign gap) — simplest.
- Dedicated boundary-detection head trained alongside the classifier.

## 5. Text → FSL rendering

- **MVP:** dictionary lookup → pre-recorded native-signer video clips,
  fingerspelling fallback for unmatched words (names, jargon).
- **Later phase:** avatar-based synthesis (HamNoSys → SiGML → virtual
  signer, e.g. JASigning — see `signtyper`/`syntheticfsl` in
  `ml-resources.md`). Requires FSL-fluent Deaf review before shipping as a
  default experience — don't treat avatar output as launch-ready without
  that review.

## 6. Localization layer

- Filipino is the default locale for **all** UI strings.
- English is a single Settings toggle controlling **output text/speech
  language only** — it must not affect which sign language is recognized
  or rendered (FSL is constant).
- All UI copy routes through the localization layer; no hardcoded strings
  in components (see `AGENTS.md` Section 2 for why this is a hard rule).

## 7. Data handling / privacy

- Camera frames and landmark sequences are biometric-adjacent data —
  don't log or persist raw video/landmark data beyond what's needed for
  on-device inference, unless the user has explicitly opted into
  contributing data (e.g. for model improvement) with clear consent UI.
- History feature (saved translations) stores translated **text**, not
  raw video, unless a future feature explicitly needs otherwise.
