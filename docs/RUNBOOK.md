# Visualin Runbook (Claude Code)

Run the steps in order. Send **one prompt at a time**, wait for Claude Code's
report, paste it to the chat assistant, then continue. Do not merge prompts
into one: each one ends with a stop-and-report on purpose.

---

## Step 0 — Manual setup (you, once)

1. Save files into `Desktop\Visualin\docs\`:
   - `agent-handoff.md` (replace the old one)
   - `design-system-v3.md`
2. Add these lines to `AGENTS.md`:
   ```
   Current task queue and project status: docs/agent-handoff.md
   Design source of truth: docs/design-system-v3.md. Design skills may review
   and suggest, but must not replace its colors, fonts or tokens.
   ```
3. Check versions in PowerShell:
   ```powershell
   flutter --version   # Dart 3.9+ needed for the Dart MCP server
   node --version      # needed for the Apple Design skill
   ```
4. Install in Claude Code (type inside a Claude Code session):
   ```
   /plugin marketplace add DietrichGebert/ponytail
   /plugin install ponytail@ponytail
   ```
   Then in PowerShell, from `Desktop\Visualin`:
   ```powershell
   npx skills add dickwu/apple-design-skill -a claude-code
   claude mcp add dart -- dart mcp-server
   ```
5. Maestro (optional now, needed by Step 4): install per the official Maestro
   docs for Windows, then `maestro --version`.
6. Phone: plug in, approve **USB debugging**, check `flutter devices`.
7. Restart Claude Code so the plugin, skill and MCP server load.

---

## Step 1 — Verify, commit docs, push ML branch

```
Read AGENTS.md, docs/agent-handoff.md and docs/design-system-v3.md.
On branch ui/ux-refinement:
1. Verify Task 0: run flutter analyze and flutter test. Produce the audit
   table (which UX-batch items exist in code) and the camera-caching finding
   (does the app write frames or landmarks to temp files, logs or crash
   reports?). Confirm docs have no geofencing and say English default.
2. Commit the updated docs/agent-handoff.md, docs/design-system-v3.md and
   AGENTS.md lines.
3. Push ui/ux-refinement and ml/fsl105-pipeline.
Do not change app code. Run /ponytail-review on your changes. Stop and
report.
```

## Step 2 — Design v3: Home + Settings (Task A1)

```
Do Task A1 from docs/agent-handoff.md on a new branch ui/apple-pass from
ui/ux-refinement. Follow docs/design-system-v3.md exactly. Use the Apple
Design skill to review the result against HIG, but keep v3 tokens. Verify
on the connected phone via the Dart MCP server (runtime errors, widget
tree). Report screenshots of Home and Settings, measured contrast ratios,
and any Phosphor icon names that didn't exist. Run /ponytail-review. Stop
and wait for my OK. Do not push.
```

## Step 3 — On-device inference foundations (Task 2a)

```
Do Task 2a from docs/agent-handoff.md on a new branch ml/task2-integration
from ml/fsl105-pipeline: TFLite spike on the phone, Dart feature extraction
tested against the golden vectors, and the coordinate-frame check with a
test. No UI changes. Keep the _isProcessing gate and camera lifecycle fixes
intact; re-check logcat for native errors. Ask before adding dependencies.
Run /ponytail-review. Stop and report. Do not push.
```

## Step 4 — Design v3: remaining screens (Task A2)

Only after you approved Step 2.

```
Do Task A2 from docs/agent-handoff.md on ui/apple-pass. Camera: full-bleed
preview, frosted close/flip, result bottom sheet; update the overlay
transform for the crop and add a test, then confirm on the phone that the
skeleton sits on the fingers. Write a Maestro flow that walks Splash,
Onboarding, Home, Camera, History and Settings using semantics labels and
run it with maestro test. Run /ponytail-review. Stop and report with
screenshots. Do not push.
```

## Step 5 — Merge

```
Merge ui/apple-pass and ml/task2-integration into a new branch
integration/recognition from ui/ux-refinement. Resolve conflicts, run
flutter analyze, flutter test and the Maestro flow on the phone. Stop and
report. Do not push.
```

## Step 6 — Segmentation + recognition UI (Task 2b)

```
Do Task 2b from docs/agent-handoff.md on integration/recognition.
Implement the segmentation state machine, single classification per
segment, confidence + top-2 gate, repeat-after-rest rule, and manual mode.
Thresholds as named constants. Replace the placeholder with real output
(Speak/Copy/Save, English/Filipino toggle with null-fil fallback). You
cannot sign in front of the camera: verify the state machine with tests
and a recorded landmark sequence, and list exactly what needs a human FSL
signer to verify. Run /ponytail-review. Stop and report. Do not push.
```

## Step 7 — You test with a signer

Ask an FSL signer to perform several of the 105 signs in a normal room. Note
which were recognized, missed or wrong. Paste the results to the chat
assistant; thresholds get tuned from that.

---

## Later (no prompts yet)
TTS, history with drift, Text to FSL MVP, Blender animations (Task 3).
