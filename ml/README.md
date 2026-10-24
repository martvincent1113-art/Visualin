# Visualin ML: FSL-105 recognition pipeline (Task 1)

Offline Python pipeline that trains an isolated-sign classifier on FSL-105 and
exports a TFLite model whose **input features are exactly what the app's
`hand_landmarker` pipeline can produce**. Everything here lives in `ml/`; the
Flutter app is untouched.

> Sign language is **FSL only**. This pipeline uses FSL-105 (105 Filipino Sign
> Language signs). No ASL/BSL data, models or charts are used anywhere.

## 1. What the Flutter plugin actually returns

Read from `lib/services/landmark_service.dart` and the plugin source
(`hand_landmarker-2.2.0`, `MyHandLandmarker.kt`, `hand_landmarker.dart`):

| Question | Answer |
|---|---|
| What comes back per hand | 21 `Landmark(x, y, z)`; **only** MediaPipe's normalized *image* landmarks (`result.landmarks()`). |
| Handedness (left/right) | **Not returned.** The Kotlin wrapper drops `result.handedness()`. |
| Confidence / presence score | **Not returned.** |
| World (metric) landmarks | **Not returned.** |
| Hand count and order | 0 to 2 hands (`numHands: 2`), **arbitrary order**. |
| `x`, `y` | Normalized to [0, 1] by the image width / height (not square). |
| `z` | Depth relative to the wrist (wrist ~ 0), roughly the same scale as `x` (width-relative). Smaller = closer to the camera. |
| Running mode | `IMAGE` (stateless per frame, **no tracking** between frames, so no temporal smoothing from MediaPipe). |
| Model / library | `hand_landmarker.task` (7.8 MB, bundled in the plugin), `com.google.mediapipe:tasks-vision:0.10.26.1`. |
| App settings | `numHands 2`, `minHandDetectionConfidence 0.7`, CPU delegate; presence / tracking confidence left at default 0.5. |
| Frame path | YUV_420_888 -> NV21 -> JPEG (quality 100) -> Bitmap -> `ImageProcessingOptions.rotationDegrees = sensorOrientation`. |
| Mirroring | **None in the data.** Front-camera mirroring is applied only when the app draws the preview/overlay (`CameraOverlayTransform.mirrorHorizontally`). |

### Coordinate space (needs a device check)

`CameraOverlayTransform` treats the returned points as **sensor-frame**
coordinates and rotates them by `(sensorOrientation ± deviceRotation)` before
drawing (this overlay is device-confirmed per the handoff). So to get the
upright frame that the dataset videos are in, the Dart extractor must apply the
same rotation **without** the front-camera mirror. Python never sees this issue
because decoded videos are already upright. **I could not verify this on a
device.** Task 2 must log a few frames with a hand held at a known screen
position and confirm the upright mapping before trusting any recognition result.

## 2. Feature contract (stable: change = retrain + re-export + Dart update)

The single source of truth is `src/features.py`. Pipeline per clip or live
buffer of `F` frames:

1. **Convention.** Coordinates are in the *upright, un-mirrored* camera frame
   (what a normal video of a signer facing the camera looks like, which is also
   what FSL-105 clips are). The front-camera preview mirror is display-only and
   must **not** be applied to classifier input. The signer's right hand appears
   on the image's left.
2. **Resample to `T` frames** by nearest index: `idx[i] = floor((i + 0.5) * F / T)`,
   clamped to `F - 1`. `T` is one of 32 / 48 / 64 (chosen by validation, see
   section 5). If `F < T` frames repeat.
3. **Metric space.** `X = x * W`, `Y = y * H`, `Z = z * W` where `W x H` is the
   upright frame size in pixels. This removes the width/height anisotropy so a
   portrait phone and the 640x360 dataset produce the same hand geometry.
4. **Slot the hands** (the plugin gives no handedness):
   - two hands in a frame: smaller wrist `X` -> slot 0, the other -> slot 1;
   - one hand: compared to a *divider*: the mean wrist-`X` midpoint over the
     window's two-hand frames, else `W / 2`. If the window never has two hands
     at once, all single-hand frames use the window-mean wrist `X`, so the slot
     cannot flip in the middle of a sign.
5. **Variant A normalization** (window level, so a single hand moving through
   space keeps its motion): `ref` = mean wrist `(X, Y)` over all present hands in
   the window; `s` = mean 2D distance wrist(0) -> middle-finger MCP(9) over
   present hands (guard: `s <= 1e-6` -> `1`). Then
   `x' = (X - ref_x) / s`, `y' = (Y - ref_y) / s`, `z' = Z / s`.
6. **Missing hand** = 21x3 zeros in that slot and the present flag `0`. A window
   with no hand at all is entirely zero.

**Variant A (what the app can produce today):** per frame
`[slot0: 21x(x',y',z')] [slot1: 21x(x',y',z')] [present0, present1]` ->
`2*21*3 + 2 = 128` floats (126 coordinates + 2-value mask). Input tensor
`(1, T, 128)` float32.

**Variant B (offline experiment only):** Variant A's layout, but hand
coordinates are normalized to the body: `ref` = mean shoulder midpoint, `s` =
mean shoulder width over the window (frames with both shoulder visibilities
>= 0.5; if none, falls back to A's rule). Plus MediaPipe Pose points
`nose, shoulders, elbows, wrists` (indices 0, 11, 12, 13, 14, 15, 16) as
`7x(x',y',z')` = 21 floats and one pose-present flag -> `128 + 21 + 1 = 150`.
Pose comes from `pose_landmarker_full.task`; the app has no pose pipeline yet.

**Mirror handling.** Training uses mirror augmentation (x -> W - x, then
re-slot, left/right pose points swapped) with probability 0.3 so left-handed
signers are covered. Inference never mirrors.

**Unverified assumption:** FSL-105 and a phone differ in frame rate (60 fps
vs. ~10-15 fps detections). The model sees `T` samples spread across the whole
clip/buffer, so the on-device buffer must span a similar duration (about 4 s).
Sign segmentation is out of scope.

## 3. Setup (Windows / PowerShell)

Python **3.12** (the installed 3.13 is not used: pins below were verified on
3.12). From the repo root:

```powershell
cd ml
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Pins (see `requirements.txt` for the full list): `mediapipe==0.10.21`,
`tensorflow==2.19.1`, `numpy==1.26.4`, `opencv-python-headless==4.11.0.86`.
`mediapipe 0.10.30` was tried first because it is closer to the Android
`0.10.26.1`, but its Tasks API fails to load on Windows
(`function 'free' not found`), and `0.10.26` is not published for 3.12/Windows.
The `.task` model files are identical to the app's, so the version gap only
affects the surrounding graph code; this is an unverified risk, see section 7.

## 4. Run it (one command per stage)

```powershell
# 0. data -> ml/data/raw (gitignored). Direct download, no browser needed:
#    https://data.mendeley.com/datasets/48y2y99mb9/2  (clips.zip 379 MB, sha256 c048c082...5748463)
#    unzip clips.zip into ml\data\raw so clips\<sign id>\<n>.MOV exist, next to train.csv / test.csv / labels.csv

# 1. landmarks (hands + pose) -> ml\data\landmarks\*.npz (~40 min, 6 workers, every 4th frame = 15 fps)
.\.venv\Scripts\python.exe src\extract_landmarks.py --stride 4 --workers 6

# 2. feature-contract tests
.\.venv\Scripts\python.exe -m pytest tests -q

# 3. T sweep + 3 seeds at the best T, Variants A and B -> reports\results.json (about 1.5 h on CPU)
.\.venv\Scripts\python.exe src\sweep.py

# 4. (single run) .\.venv\Scripts\python.exe src\train.py --variant A --t 48 --seed 0
#    (re-evaluate) .\.venv\Scripts\python.exe src\evaluate.py --run runs\A_T48_s0 --split test

# 5. export the best Variant A run -> export\ (model.tflite, labels, golden vectors, parity.json)
.\.venv\Scripts\python.exe src\export_tflite.py --run runs\<best A run>
```

The models `hand_landmarker.task` (copied from the Flutter plugin's assets in the
pub cache) and `pose_landmarker_full.task` (downloaded from Google's MediaPipe
model bucket) go to `ml/models/` automatically.

## 5. Results

All numbers come from `reports/results.json` (regenerate with `src/sweep.py`).
Train 1,389 clips, validation 315 (carved from the provided train set, stratified
by sign), **test 426 (the provided test split, read only after T was chosen on
validation)**. Model: 2 stacked GRU layers x 96 units, dropout 0.3 / 0.4,
softmax over 105 signs, Adam + cosine decay, 120 epochs, augmentation as in
`src/augment.py`. Landmarks extracted at 15 fps (every 4th frame of 60 fps clips).

### T sweep (1 seed each, accuracy top-1)

| Variant | T | Val | Test |
|---|---|---|---|
| A | 32 | **0.829** | 0.829 |
| A | 48 | 0.819 | 0.796 |
| A | 64 | 0.822 | 0.829 |
| B | 32 | 0.803 | 0.824 |
| B | 48 | **0.819** | 0.845 |
| B | 64 | 0.787 | 0.793 |

T is chosen by validation: **A -> 32, B -> 48**. The differences between T values
(about 1-3 points) are the same size as the seed-to-seed spread below, so the
choice of T is not a strong result.

### Variant A vs Variant B (3 seeds at each variant's best T)

| | Test top-1 | Test top-5 | Val top-1 |
|---|---|---|---|
| **A** (hands only, T=32) | **82.8% +/- 2.4** (82.9, 85.7, 79.8) | 97.3% +/- 0.1 | 82.7% +/- 1.6 |
| **B** (+ pose, T=48) | 81.1% +/- 2.6 (84.5, 78.2, 80.8) | 97.3% +/- 0.5 | 81.9% +/- 0.3 |
| **Gap B - A** | **-1.6 points (not significant)** | 0.0 | -0.8 |

**Conclusion: adding upper-body pose and body-relative normalization did not
help on FSL-105.** The gap is smaller than the seed spread (+/- 2.4 to 2.6) and
has the wrong sign. This is not evidence that body position never matters: the
dataset is a fixed camera, one plain backdrop and consistent framing, so the
window-level hand normalization of Variant A already captures most of the
position information. Phone footage with variable framing may behave
differently. Recommendation from this data alone: **do not bring in
`kwon_mediapipe_landmarker` earlier on accuracy grounds**; revisit if
phone-camera testing shows position errors. Variant B also needs a pose model
the app does not have, and pose was detected in ~100% of dataset frames, which
will not hold on a phone.

### Shipped model (Variant A, `A_T32_s1`, chosen by best validation score)

- Test top-1 **85.7%**, top-5 **97.4%** (426 clips); the exported
  `model.tflite` gives the same 85.7% on the whole test set.
- This is the best of three seeds (the 3-seed mean is 82.8%). Quote the mean as
  the expectation, not 85.7%.
- Per-class (`reports/per_class_variant_A.csv`): mean 85.9%, 68 of 105 signs
  at 100%, 13 at or below 50%. Weakest: EIGHT 0%, BLUE 0%, MARCH / BLIND / JUNE /
  SEPTEMBER 25%, DECEMBER 40%. Months are over-represented among the failures,
  which fits signs that differ in small handshape or movement details.
- Confusion matrix: `reports/confusion_variant_A.png`.
- The shipped run's best epoch was the last one (120), so it was still improving
  when training stopped. More epochs may help; not tried.

### The thesis figure was not reproduced

The source thesis's reported **100% top-5** was **not reproduced**. This
pipeline reaches 97.3% top-5 (mean) on the provided test split, and its top-1
is 82.8% (mean). Different features (this pipeline cannot use handedness),
frame rate, model and split handling all differ, and I did not try to replicate
their exact setup.

## 6. Signer independence (important)

**The provided split is probably not signer-independent, and I cannot prove
either way.** FSL-105 ships no signer IDs. What the files show: `train.csv` and
`test.csv` are a random clip-level split (every sign has 14-17 train and 4-5 test
clips, all clip numbers 0-21 appear in both, with similar proportions, and no
path appears in both). If one signer recorded several clips per sign, those
clips sit on both sides of the split. A signer-dependent split overstates
accuracy on new people. My own validation split is also stratified by sign only,
for the same reason, so model selection (T, early stopping) is optimistic too.
**Treat 82.8% as an upper bound for unseen signers**, and real phone accuracy as
lower still (see section 7). A proper test needs recordings of new signers.

## 7. What I could not verify

- **The on-device coordinate frame.** Whether `hand_landmarker` returns
  sensor-frame or upright coordinates when `rotationDegrees` is passed. The
  app's overlay code implies sensor-frame; I did not test on a device.
- **Python vs. Android MediaPipe parity.** Same `.task` hand model and the
  same settings, but Python runs `mediapipe 0.10.21` while the app bundles
  `tasks-vision 0.10.26.1`, and the Python frames are decoded by OpenCV rather
  than the camera's YUV path. Landmarks may differ slightly; the model has not
  been run on landmarks produced by the app.
- **Phone-camera accuracy.** FSL-105 is a blue backdrop at 640x360. Nothing here
  measures lighting, backgrounds, distance, or new signers.
- **Frame rate and window length** on the device (the model expects a ~4 s
  buffer resampled to T=32) and any sign segmentation.
- **The exported model inside Flutter.** TFLite-vs-Keras parity is verified in
  Python only (max abs diff 5.4e-7 on 40 real validation sequences). Whether the
  Flutter TFLite plugin loads it is Task 2's spike.
- **Filipino glosses.** `signs.json` has `fil: null` everywhere on purpose. English
  labels are the dataset's own and have not been reviewed by an FSL-fluent
  reviewer; treat all vocabulary as unverified.
- Only one data split and seeds 0-2 were run; no confidence intervals beyond
  the seed spread.

## 8. Export contents (`ml/export/`)

| File | Purpose |
|---|---|
| `model.tflite` | float32, input `(1, 32, 128)`, output `(1, 105)`, 716 KB. Pure feed-forward graph: `ADD, FULLY_CONNECTED, LOGISTIC, MUL, PACK, RESHAPE, SOFTMAX, SPLIT, STRIDED_SLICE, SUB, TANH, UNPACK` (no Flex ops, no stateful variable ops) |
| `feature_spec.json` | T, feature dimension, layout, constants for the Dart side |
| `label_map.json` | id -> English label (dataset labels) |
| `signs.json` | `id`, `en`, `fil` (null until reviewed), `category` |
| `parity.json` | Keras vs TFLite agreement and TFLite test accuracy |
| `golden/*.json` | 5 **synthetic** cases (two hands, right only, left only, mixed, dropouts): raw plugin-style frames -> expected features -> expected probabilities (Keras and TFLite) |

Golden inputs are synthetic by design: `AGENTS.md` forbids committing landmark
data of real people, and a synthetic skeleton is enough to prove the Dart
feature code and model produce identical numbers. They do not test recognition
quality. Suggested Dart tolerances: features 1e-4 (Python is float32), model
probabilities 1e-3.

The TFLite conversion first produced `VAR_HANDLE` / `CALL_ONCE` stateful ops
(from Keras's dropout seed state). `export_tflite.py` now exports a dropout-free
copy with frozen weights, verified identical to the trained model before
conversion.

## 9. Tests

```powershell
.\.venv\Scripts\python.exe -m pytest tests -q
```

14 tests check the contract: resampling, mask semantics, translation / scale /
aspect-ratio invariance, hand-order independence, mirror round trip and
single-hand slotting. They define behaviour the Dart port must also satisfy.

