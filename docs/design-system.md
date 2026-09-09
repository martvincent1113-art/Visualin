# Design System — Visualin

This document is the source of truth for Visualin’s UI. It aims for a clean,
native-feeling mobile experience while retaining the orange Visualin identity.

## Language and terminology

- The signed language is always **Filipino Sign Language (FSL)**. The output
  language choice never changes the sign language.
- Use **FSL to Text** and **Text to FSL** everywhere those features are named.
- English is the default locale. Filipino copy must come from the localization
  layer; do not hardcode it in widgets.

## Colors

| Token | Value | Use |
| --- | --- | --- |
| Primary orange | `#FF6B0A` | Selected state, primary action, important icon |
| Orange tint | `#FFF0E8` | Selected-icon and icon-circle backgrounds |
| App background | `#F5F5F7` | Screen background |
| Surface | `#FFFFFF` | Cards, grouped settings, tab bar |
| Primary text | `#1C1C1E` | Headings and body copy |
| Secondary text | `#6E6E73` | Supporting copy, timestamps, inactive icons |
| Divider | `#E5E5EA` | Borders and separators |
| Inactive | `#AEAEB2` | Inactive tab icons and switch tracks |

Orange is the single accent. Do not introduce a second status color: pair
orange with an icon and text when communicating recognition state.

## Typography

- Use the platform system font. On iOS this is SF Pro when available.
- Page title: 34px, Bold (700).
- Main section title: 26px, Bold (700).
- Card title: 19px, SemiBold (600).
- Body and helper text: 15–16px, Regular (400).
- Tab labels: 11–13px, Medium (500); selected labels are SemiBold.
- Do not use extra-bold text outside the splash wordmark. Respect both system
  text scaling and Visualin’s in-app text-size preference.

## Layout and surfaces

- Screen padding: 24px horizontally.
- Major section gaps: 32px.
- Card/group padding: 20px; title-to-helper gap: 4px.
- Standard stacked-card gap: 16px.
- Card radius: 22px. Button radius: 16px.
- Use white cards on the light-gray background with a light `#E5E5EA` border.
  Avoid strong elevation and do not treat every card as a floating button.

## Icons and navigation

- Use outline-style icons with a consistent visual weight.
- Icon-only actions require tooltips or semantic labels and have at least a
  44×44pt hit area.
- Bottom navigation has four equal-width items: Home, FSL to Text, History,
  and Settings. It is a normal white bar with a subtle top divider — never a
  floating camera action.
- Icons are 24–26px. The active icon has an orange tint background; the icon
  and text are orange. Inactive items are gray. Selection is communicated by
  color, background shape, and label weight.

## Screen patterns

### Home

- Keep “Visualin” small in the top bar and omit the duplicate Settings action.
- Use equal-height FSL to Text and Text to FSL cards with a tinted icon square
  and gray chevron.
- The Recent translations empty state includes both an icon and a supporting
  sentence.

### Onboarding

- Give each page a concise title and one supporting sentence.
- Keep the icon and copy in the upper-middle of the screen; page indicators
  sit immediately above the fixed bottom action.
- Explain camera access before requesting it. State that video is not saved
  only if the implementation continues not to save video.

### Settings

- Use the page background for the header and white grouped cards below it.
- The Language group must explicitly state that only FSL is supported and
  that the output text/speech setting does not change FSL.
- Accessibility rows provide a title, supporting description, and full-row
  touch target. Text size, high contrast, and reduced motion must affect the
  app rather than being decorative controls.
- Switches use orange when on and neutral gray when off.

### FSL to Text camera

- Keep controls outside the preview where possible.
- Use a rounded camera preview that leaves room for a result panel below it.
- Detection guidance must include a text label, not color alone: for example,
  “No hand detected” and “Move your hands inside the frame.”
- The result panel shows output language, confidence state, and Speak/Copy/
  Save controls. Until a verified FSL classifier is integrated, it must not
  display an invented translation or confidence value.

## Accessibility and motion

- Minimum target: 44×44pt for every interactive control.
- All status communication has a text or icon counterpart to color.
- Respect system text scaling and provide Visualin’s persistent text-size
  preference.
- High contrast and reduced motion apply app-wide. Reduced motion eliminates
  page/splash animations rather than merely slowing them down.
- Provide screen-reader labels for icon-only controls and live-region text for
  changing camera detection feedback.
