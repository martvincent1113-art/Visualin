# Visualin — Filipino Sign Language Translation App

**Tagline:** See language. Speak freely.
**Focus Language:** Filipino Sign Language (FSL)

---

## 1. Overview

Visualin is a mobile application that provides real-time, two-way translation
between **Filipino Sign Language (FSL)** and Filipino/English text and speech.
It is designed to support the Filipino Deaf community in everyday
communication — at home, in school, at work, and in government transactions —
in alignment with the country's legal recognition of FSL.

### Why FSL specifically

FSL is not a dialect of American Sign Language (ASL) or a signed form of
Tagalog — it is its own natural language, with its own grammar, vocabulary,
and regional variation, shaped historically by both indigenous Filipino Deaf
communication and ASL contact.

Under **Republic Act No. 11106 ("The Filipino Sign Language Act"**, signed
30 October 2018), FSL is:

- Declared the **national sign language of the Filipino Deaf**
- The **official sign language of government** in all transactions involving
  the Deaf
- Mandated as the **language of instruction** in Deaf education
- Required as the **official language of legal interpreting** in courts,
  quasi-judicial agencies, police stations, and other tribunals
- Required to have **qualified interpreters** made available in covered
  proceedings, with the Komisyon sa Wikang Filipino (KWF) tasked to set
  national standards and accreditation for FSL interpreting

Visualin's product scope is written around this legal and cultural context —
this is not a generic "sign language app," it is an FSL-first tool built for
the Filipino Deaf community's actual language.

---

## 1.1 Language Policy

- **Sign language:** Filipino Sign Language (FSL) **only**. Visualin does not
  support ASL, BSL, or any other sign language variant — this keeps the app
  scoped, accurate, and aligned with RA 11106 rather than diluted across
  languages that aren't mutually intelligible with FSL.
- **Default UI & output text:** **English**, by default, throughout the app
  (onboarding, buttons, translated captions, TTS voice).
- **Settings toggle:** Users may switch the **default output text language**
  between **English** and **Filipino** in Settings. This only changes the
  *text/speech output* language (i.e., what a translated FSL sign is
  rendered as) — it does **not** add another sign language; FSL remains the
  only signed language in and out of the app, regardless of this setting.

## 1.2 UX refinements (from design review — see docs/design-system.md for
terminology and accessibility standards this section references)

- **Feature naming:** the two core features are always called **"FSL to
  Text"** and **"Text to FSL"** throughout the app — see
  design-system.md's Feature Terminology section. Do not introduce
  alternate names like "Start translating" or "Camera" for the same
  feature.
- **Home hierarchy:** FSL to Text (camera recognition) is the primary CTA
  — it should be visually dominant over Text to FSL, not equal weight,
  since it's the core feature. Replace the "Hello!" header with something
  purpose-oriented, e.g. "What would you like to translate?"
- **Permission re-request flow:** if a user skips the camera-permission
  onboarding slide, then later taps into FSL to Text without having
  granted permission, the app must show a clear in-app prompt explaining
  why camera access is needed and offering to request it — never fail
  silently or show a blank/broken camera screen.
- **Settings structure — Translation section:**
  ```
  Translation
    Sign language
      Filipino Sign Language (FSL)
      Currently, only FSL is supported.

    Output language
      Filipino | ✓ English
      Changes translated text and speech. Sign language remains FSL.
  ```
  This replaces a bare "Filipino Sign Language (FSL) only" heading with
  clear labeling of what each setting actually controls — important for
  first-time users who haven't read the docs explaining the language
  policy.
- **Camera permission copy:** must accurately describe what the
  implementation actually does — verify no video/landmark data is cached
  anywhere (temp files, logs, crash reports) before using language like
  "video is processed for translation and is not saved." If any caching
  exists, fix the copy to match reality, not the other way around. Also
  mention permission can be changed later in Settings, so the request
  feels less final/intimidating.
- **Camera screen state feedback (partial now, full in Phase 2):** the
  camera screen should give the user feedback about hand detection status
  (e.g. hand detected / not detected / move farther from camera) using the
  landmark data already available from Phase 1's pipeline. Full
  recognition-state feedback ("Recognizing sign…" → result with Speak/
  Copy/Save actions) depends on Phase 2's sign classification and should
  be built then, not stubbed with fake states now.
- **Bottom nav labeling:** the fourth tab (currently "Profile") should be
  labeled "Settings" — this app doesn't have meaningful user accounts/
  social identity, so "Settings" more accurately describes what's there
  (language toggle, accessibility controls, etc.).

## 2. Core Features

| Feature | Description |
|---|---|
| **FSL → Text** | Live camera capture of a signer; MediaPipe-based landmark tracking translates FSL signs into Filipino/English text in real time. |
| **Text → FSL** | User types or dictates text; app renders the equivalent FSL signing (video-clip playback and/or fingerspelling for unmatched words). |
| **Text-to-Speech (TTS)** | Optional audio playback of translated text, selectable voice/speed, Filipino and English voice options. |
| **Camera Recognition Mode** | Dedicated live camera screen for continuous signer detection and translation, with on-screen landmark overlay feedback. |
| **History** | Saved log of past translations for reference/review. |
| **Geofencing** | Location-aware features (see Section 5). |
| **Profile / Settings** | Language variant, accessibility, camera, notification, and account preferences. |

---

## 3. Technical Architecture

### 3.1 Camera pipeline (FSL → Text)

- **MediaPipe Tasks**: `HandLandmarker` + `PoseLandmarker` + `FaceLandmarker`
  run in `LIVE_STREAM` mode (not single-image mode — FSL signs are defined by
  motion, not static pose).
- Landmarks are buffered into a rolling temporal window (~1–2 seconds) since
  signs are sequences, not snapshots.
- Coordinates normalized relative to a stable body reference point (e.g.
  shoulder midpoint) and scaled by shoulder width, so recognition isn't
  affected by how close/far the signer is from the camera.
- Temporal classification via a lightweight sequence model (GRU/Transformer
  encoder) or a metric-learning + prototype-matching approach (cosine
  similarity against class prototypes) — the latter is a good MVP choice
  since it needs fewer labeled samples per sign.
- Non-manual markers (facial expression, mouth shape) added in a later phase
  — these carry real grammatical meaning in FSL (e.g. question forms), so
  they shouldn't be treated as cosmetic.

### 3.2 Text → FSL rendering

- **MVP approach:** dictionary lookup of pre-recorded native-signer video
  clips for known FSL vocabulary, with fingerspelling fallback for
  unmatched words (names, jargon, acronyms).
- Avatar/3D animated signing is a possible later phase, but is expensive to
  do well and should not substitute for real signer video without direct
  input from FSL-fluent Deaf collaborators.

### 3.3 Data & dataset considerations

- FSL has **far fewer public labeled datasets** than ASL (which has WLASL,
  How2Sign, MS-ASL, etc.). This is a real constraint, not a minor detail —
  budget time and partnerships for FSL-specific data collection.
- That said, usable FSL-specific resources do exist and should be the
  starting point rather than collecting from zero — see
  [`ml-resources.md`](ml-resources.md) for a curated list (FSL-105 dataset,
  MediaPipe+GRU baseline, static-alphabet datasets, and reference repos for
  both sign recognition and text→FSL rendering).
- Recommended sources/partners to reach out to:
  - Philippine Federation of the Deaf (PFD)
  - Filipino Deaf-led schools (e.g. programs historically linked to the
    Cebu School for the Deaf, De La Salle-College of Saint Benilde's
    School of Deaf Education and Applied Studies)
  - University of the Philippines / Komisyon sa Wikang Filipino, which are
    named under RA 11106 as developing FSL training material standards
- Any dataset collection must involve **Deaf FSL signers as consultants and
  reviewers**, not just as recorded subjects.

---

## 4. Design System Reference

- **Primary colors:** White (#FFFFFF / #FAFAFA background), Orange (#FF6B00
  accent — primary buttons, active states)
- **Text:** Near-black (#1A1A1A) for contrast/readability
- **Style:** Minimal, high-contrast, generous white space, rounded corners
  (16–20px), large legible type (16px+ body text)
- **Accessibility defaults:** adjustable font size, high-contrast mode,
  reduced-motion toggle (some users find persistent animation distracting)

---

## 5. Geofencing Features

Proposed use cases (to be finalized based on product priorities):

1. **Regional sign variant awareness** — FSL itself has regional variation;
   geofencing could surface a note or adjust suggestions based on the user's
   region (e.g. Metro Manila vs. Visayas vs. Mindanao usage differences).
2. **Nearby accessible services** — surface Deaf-friendly or interpreter-
   available locations (government offices, hospitals, PFD chapters) when
   the user is nearby.
3. **Live interpreter request trigger** — near partner institutions (e.g.
   courts, hospitals, LGU offices covered under RA 11106's interpreter
   mandate), offer a shortcut to request a qualified human interpreter.
4. **Offline model management** — auto-download a lightweight offline
   translation model when leaving areas with reliable connectivity.

---

## 6. Standards & Compliance Checklist

- [ ] Legal alignment with **RA 11106** (Filipino Sign Language Act)
- [ ] FSL vocabulary/grammar review by **Deaf-led organizations**, not
      hearing-only consultants
- [ ] **WCAG 2.2** accessibility compliance for app UI
- [ ] Clear, upfront **camera/privacy permissions** explanation (biometric-
      adjacent data — hand/face video — requires explicit, informed consent)
- [ ] Data retention & deletion policy for any recorded video/landmark data
- [ ] Distinct handling of **FSL vs. ASL vs. other sign languages** — never
      conflate them in the product or marketing

---

## 7. Suggested Roadmap

**Phase 1 — MVP**
- Isolated (word-level) FSL sign recognition, limited vocabulary
- Text → FSL via pre-recorded clips + fingerspelling
- TTS output
- Core screens: Welcome, Onboarding, Home, Camera, Profile/Settings

**Phase 2 — Depth**
- Expand FSL vocabulary coverage
- Continuous signing recognition (sign segmentation)
- History with search
- Feedback loop (thumbs up/down on translation accuracy) to improve model

**Phase 3 — Scale**
- Non-manual marker recognition (facial grammar)
- Geofencing features
- Live interpreter partnership integration
- Regional FSL variant support

---

## 8. Open Questions

- Which FSL vocabulary set / regional variant to prioritize first?
- Partnership plan for Deaf community co-design and data collection?
- Monetization model — freemium tier limits vs. what should always be free
  given the accessibility/rights context under RA 11106?