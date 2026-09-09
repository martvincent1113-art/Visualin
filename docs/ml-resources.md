# ML Resources — FSL Datasets & Reference Repos

Curated from public GitHub repos, Hugging Face, and Mendeley Data. **Verify
each license before using in a shipped product** — several are academic/
thesis projects without a clear commercial license, and one (FSL-105) is
CC-BY-4.0, which requires attribution.

## FSL datasets (use these before collecting your own)

### FSL-105 — best starting point for dynamic/word-level recognition
- **What:** 105 different FSL signs, ~2,130 four-second video clips (~20
  clips/sign), performed by adult Deaf FSL signers and reviewed by an FSL
  expert. Recorded against a blue background, 640×360. Includes a pre-made
  80/20 train/test split and category labels (10 categories).
- **License:** CC-BY-4.0 (attribution required).
- **Origin:** De La Salle University (Gokongwei College of Engineering),
  funded by the Philippines' Department of Science and Technology. Built
  for Isaiah Jassen Tupal's master's thesis, advised by Melvin K. Cabatuan.
- **Proven baseline:** the thesis extracted joint locations with
  **MediaPipe**, then classified with **Graph Convolutional Networks** and
  **GRU** — the MediaPipe+GRU model hit 100% top-5 accuracy on this dataset.
  This is a strong, already-validated starting architecture — don't
  reinvent this step.
- **Links:**
  - Dataset (Mendeley Data): https://data.mendeley.com/datasets/48y2y99mb9/2
  - Mirror on Hugging Face (via SEACrowd hub): `SEACrowd/fsl_105`
  - Citation: Tupal, I.J.L. & Cabatuan, M.K., "FSL105: The Video Filipino
    Sign Language Sign Database of Introductory 105 FSL Signs."

### FSL Alphabet dataset (static signs)
- **What:** Image dataset covering 24 static FSL alphabet letters (excludes
  J and Z, which are dynamic in FSL).
- **Link:** https://www.kaggle.com/datasets/japorton/fsl-dataset
- **Used by:** `ji-chani/MediaPipe-FSL-Alphabet`,
  `ji-chani/FSLAlphabetRecognition-PHCA` (see below).

## FSL-specific GitHub repos

| Repo | What it does | Relevance |
|---|---|---|
| [`ji-chani/MediaPipe-FSL-Alphabet`](https://github.com/ji-chani/MediaPipe-FSL-Alphabet) | Extracts 21 hand landmarks via **MediaPipe Holistic** for 24 static FSL alphabet letters, classifies with SVM (linear/RBF/poly/sigmoid kernels), 80/20 split. | Closest existing reference for our exact stack (MediaPipe + classifier) on FSL, though limited to static letters. Good for the fingerspelling-recognition sub-feature. |
| [`ji-chani/FSLR-MLPHCA`](https://github.com/ji-chani/FSLR-MLPHCA) | Recognizes **dynamic** FSL gestures using a topology-based method (Persistent Homology Classification Algorithm) instead of a neural net. | Useful as an alternative/lightweight approach to dynamic sign recognition if a full GRU/Transformer pipeline is too heavy for target devices. |
| [`ji-chani/FSLAlphabetRecognition-PHCA`](https://github.com/ji-chani/FSLAlphabetRecognition-PHCA) | Same PHCA method applied to static FSL alphabet; includes full data pipeline (landmark extraction → `.npy` feature files → hyperparameter tuning). | Good example of a clean, reproducible landmark-to-features pipeline to copy the *structure* of. |
| [`Jayveeeee24/iSpeak-Signs`](https://github.com/Jayveeeee24/iSpeak-Signs) | Android app: FSL learning app with static FSL recognition (letters A–Y), FSL dictionary, "word of the day," mini-game. Trained on 800–1000 images/gesture. | Closest existing **full app** analog to Visualin (Android, FSL-focused). Worth reviewing for UX patterns and their dataset collection methodology, even though it's static-only. AGPL-3.0 licensed — check compatibility before reusing code. |
| [`jennieablog/EnglishToSign`](https://github.com/jennieablog/EnglishToSign) | Automatic translation system from **English text → FSL** using the "E-Sign" approach. | Directly relevant to our Text → FSL feature. |
| [`jennieablog/signtyper`](https://github.com/jennieablog/signtyper) | Web app for documenting FSL signs using **HamNoSys** notation, converted to **SiGML**, rendered via the **JASigning** virtual signer system. | Reference for an avatar-based Text → FSL pipeline (Phase 3 territory per our roadmap — not the MVP approach, but useful if we ever move beyond video-clip lookup). |
| [`jennieablog/syntheticfsl`](https://github.com/jennieablog/syntheticfsl) | Companion project: database of FSL handshapes/signs defined parametrically via SiGML for use with JASigning. | Same avatar-synthesis lineage as `signtyper`; useful lexicon reference even if we don't adopt JASigning itself. |

## General MediaPipe sign-recognition reference architectures (not FSL-specific — use for pipeline patterns only, not for FSL sign data)

These are useful to study for **implementation patterns**, not as sources of
FSL training data (they're built on ASL, ISL, or generic gesture data):

- [`gabguerin/Sign-Language-Recognition--MediaPipe-DTW`](https://github.com/gabguerin/Sign-Language-Recognition--MediaPipe-DTW) — MediaPipe landmark extraction + Dynamic Time Warping matching. Good minimal-data-requirement pattern for an early MVP (no training needed, just reference sequences).
- [`barills-diana/Sign-Language-Recognition-Using-Mediapipe`](https://github.com/barills-diana/Sign-Language-Recognition-Using-Mediapipe) — MediaPipe Holistic (hand+pose+face) → LSTM, real-time sequence detection flow. Closest pattern-match to our recommended architecture (Holistic + temporal model).
- [`rabBit64/Sign-language-recognition-with-RNN-and-Mediapipe`](https://github.com/rabBit64/Sign-language-recognition-with-RNN-and-Mediapipe) — MediaPipe hand tracking + RNN, includes a clear data-collection folder convention (one folder per sign label) worth copying.

## Suggested build order using these resources

1. **Fingerspelling (static):** adapt `ji-chani/MediaPipe-FSL-Alphabet`'s
   pipeline (MediaPipe Holistic → 63-dim landmark vector → classifier).
   Fast to get working, gives an early demo-able feature.
2. **Isolated word signs (dynamic):** train on **FSL-105** using the
   MediaPipe+GRU architecture from the source thesis as the baseline;
   compare against a DTW approach (`gabguerin`'s repo) if labeled data for
   a given word is too sparse.
3. **Text → FSL (MVP):** video-clip lookup keyed to the FSL-105 vocabulary
   (or a hand-recorded superset) + fingerspelling fallback — skip avatar
   synthesis for now.
4. **Text → FSL (later phase):** revisit `signtyper`/`syntheticfsl`'s
   HamNoSys → SiGML → JASigning pipeline if avatar rendering becomes a
   priority, with FSL-fluent Deaf reviewers validating output before it
   ships.
