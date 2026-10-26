# Visualin Design System v3 (Apple-like, orange + white)

Replaces the Poppins/typography/spacing/icon parts of v2. Brand is **orange and
white**. The Apple feel comes from type, spacing, restraint, glass and motion.
Every value below is a token: define it once in `lib/theme/` and never hardcode
it in widgets.

---

## 1. Colors

| Token | Hex | Use |
|---|---|---|
| `orange` | `#FF6B00` | Brand. Icons, active tab icon, switch track, focus rings, large non-text shapes |
| `orangeStrong` | `#CC4A00` | Any orange that carries text: filled buttons and hero card behind white text, small orange text on white |
| `orangeTint` | `#FF6B00` @ 10% | Chips, icon backgrounds, selected rows |
| `white` | `#FFFFFF` | App background and cards |
| `label` | `#1C1C1E` | Primary text |
| `labelSecondary` | `#6E6E73` | Secondary text |
| `labelTertiary` | `#AEAEB2` | Placeholders, disabled (never for essential info) |
| `separator` | `#E5E5EA` | Hairlines |
| `fill` | `#F4F4F6` | Text fields, pressed states, segmented control track |

**Contrast rule (WCAG 2.1 AA).** White on `#FF6B00` is about 2.9:1 and fails at
every text size. Orange `#FF6B00` text on white also fails. So:
- white text sits only on `orangeStrong` (about 4.6:1, passes),
- orange text on white uses `orangeStrong`,
- `#FF6B00` stays for icons and shapes, always paired with a second cue
  (filled icon, label, position), never color alone.
Verify with a contrast checker and report the measured ratios.

## 2. Typography: Inter (via `google_fonts`)

Inter replaces Poppins. SF Pro must not be bundled (Apple-platform licence).
Large sizes use negative tracking; Flutter `letterSpacing` is in logical px.

| Style | Size / line height | Weight | letterSpacing | Use |
|---|---|---|---|---|
| `largeTitle` | 34 / 41 | 700 | -0.7 | Screen titles (collapse on scroll) |
| `title1` | 28 / 34 | 700 | -0.5 | Home headline |
| `title2` | 22 / 28 | 700 | -0.3 | Hero card title, result text |
| `title3` | 20 / 25 | 600 | -0.2 | Card titles |
| `headline` | 17 / 22 | 600 | -0.2 | Row titles, buttons |
| `body` | 17 / 24 | 400 | -0.2 | Body copy |
| `subhead` | 15 / 20 | 400 | -0.1 | Row subtitles, card subtitles |
| `footnote` | 13 / 18 | 400 | 0 | Helper text under groups |
| `sectionHeader` | 13 / 18 | 600 | +0.3, uppercase | Grouped list headers, `labelSecondary` |
| `caption` | 12 / 16 | 500 | 0 | Chips, tab labels |

Rules: max two weights per screen besides titles; never below 12; all styles
scale with the system text size (no fixed heights that clip at 200%).

## 3. Spacing (4-pt grid)

`4, 8, 12, 16, 20, 24, 32, 40, 48`

| Where | Value |
|---|---|
| Screen side margin | 20 |
| Card inner padding | 20 (hero 24) |
| Gap between cards | 12 |
| Gap between sections | 32 |
| Section header to group | 8 |
| Large title top padding below status bar | 12 |
| List row min height | 52 (touch target ≥ 44) |
| Icon to text in rows | 12 |

## 4. Shape and depth

- Corners: continuous/squircle (`RoundedSuperellipseBorder` if the Flutter
  version has it, else `ContinuousRectangleBorder` with radius × ~2.3 to match).
- Radii: hero card 24, cards 20, buttons 14, settings icon squares 8,
  text fields 12, chips and segmented control full capsule.
- Shadow (cards on white), two layers:
  `0 1 2 rgba(0,0,0,0.04)` and `0 8 24 rgba(0,0,0,0.06)`. No borders on cards.
- Hairlines: 0.5 logical px `separator`, inset to start at the row text.

## 5. Icons: Phosphor (`phosphor_flutter`)

One real icon family everywhere. No Material icons, no generated/illustrated
icons in UI controls (the mascot is for splash, hero card and empty states only).

- Default style **Regular**; **Fill** for selected tab and active states;
  **Duotone** (orange) allowed only on the two Home feature cards.
- Sizes: tab bar 26, list rows 18 inside a 30×30 square, card icons 28,
  toolbar buttons 22 inside a 44×44 hit area.

| Place | Phosphor icon |
|---|---|
| Tab: Home | `house` |
| Tab: Camera (FSL to Text) | `camera` |
| Tab: History | `clock-counter-clockwise` |
| Tab: Settings | `gear-six` |
| FSL to Text card | `hand-waving` |
| Text to FSL card | `keyboard` |
| Close | `x` |
| Flip camera | `camera-rotate` |
| Hand detected chip | `hand-palm` |
| Speak | `speaker-high` |
| Copy | `copy` |
| Save | `bookmark-simple` |
| Sign language row | `hands-clapping` or `hand-waving` |
| Output language row | `translate` |
| Text size | `text-aa` |
| High contrast | `circle-half` |
| Reduced motion | `pause-circle` |
| About / privacy | `info`, `shield-check` |
| Row chevron | `caret-right` |

Verify each name exists in the installed `phosphor_flutter` version; if one is
missing, pick the closest and report it.

## 6. Components

- **Tab bar:** white at ~85% with background blur, top hairline, Fill icon in
  `orange` when selected, labels `caption`; selected label `orangeStrong`.
  No pill behind the active tab.
- **Hero card (FSL to Text):** `orangeStrong` fill, white `title2` + `subhead`,
  mascot on the right, white chevron. Text to FSL is a white card below it.
- **Grouped lists (Settings, History):** white sections on white with the card
  shadow, inset hairlines, icons in `orange` squares with white glyphs.
- **Switch:** `CupertinoSwitch`, active `orange`, row fully tappable.
- **Segmented control:** `CupertinoSlidingSegmentedControl`, English first,
  full width.
- **Camera:** full-bleed preview, close and flip in frosted 44×44 circles,
  status chip in `orangeTint` on glass, result in a bottom sheet with grabber.
- **Buttons:** primary `orangeStrong` fill + white `headline`; secondary
  `orangeTint` fill + `orangeStrong` text; height 50.

## 7. Motion and haptics

- Spring curves (no linear), 250–350 ms; press scale 0.97 on cards.
- Bouncing scroll physics; Cupertino page transitions.
- Light impact haptic on taps of primary actions and on toggles.
- Reduced motion on: no scale, no springs, cross-fades only, no parallax.

## 8. Android stays Android

System back gesture, status bar and navigation bar stay native. Only the
visual style is Apple-like.
