# Elsepin UI polish notes

Read this before applying new design skills or continuing the video-inspired
polish. Current implementation and device evidence are in [CURRENT-WORK](CURRENT-WORK.md).

## Build 73 owner-directed planner/tray changes

The supplied screenshots approve a smaller map tray and removal of its Settings
and More buttons. Main Settings remains a tab; Saved/Joystick default shortcuts
stay, with Speed/Pause still available in shortcut customization. The collapse
handle shares the compact header row and retains drag/interruption handling.
Decorative sizing/text is smaller; actionable targets remain at least 44pt.

Planner order is preview, Stops (each incoming leg edits mode/speed), Whole route,
Summary, then one Options disclosure with indented Behavior, Edit route and Files
& drawing groups. Remove the circled timing explanations, retaining meaningful
errors, walking-path provenance and Start confirmation. Saved/custom paths keep
their geometry for speed edits; active edits require explicit hold confirmation.

Prepared-route map taps must do nothing until X. Recent-route taps open planning,
never start movement. Hybrid's distinct label/road overlay is named Satellite +
labels; keep its stored value. Physical compact/accessibility layout, navigation
interruption and gestures remain phone acceptance checks after native validation.

## Product constraints

Keep the established Elsepin identity, eight themes, thirteen icons, Bloom/Solid
defaults and compact rounded presentation, including accessibility text sizes.
Keep the larger Settings identity card, swipe-revealed search, native navigation,
explicit movement confirmation, cancellation, backup compatibility and honest
provider status. Design advice is not permission to change these decisions.

Use Axiom for native implementation. The installed `unslop` skill supplements
visual review; its web-specific font, grayscale, 32–36px navigation, animation
and logo rules do not replace our native controls, touch targets, chosen colors,
icon artwork or Reduce Motion behavior. Preserve its upstream manual unchanged.
Do not remove options just to satisfy a choice-count rule.

## Sources reviewed — 30 October 2026

Three user-provided MP4s were inspected through sampled frames and local audio
transcription (automatic transcripts can contain recognition errors):

- Cecilia Kim's Nessie motion example, 54.9 seconds: changing numbers, major
  success feedback, loading placeholders, optional shader backgrounds and
  Reduce Motion/Low Power considerations.
- Design transformation roundup, 35.9 seconds: Damir Sokolovsky's dashboard
  example and his forthcoming-at-recording `unslop` skill.
- Motion UI Interface UX examples, 100.9 seconds: discoverable scrolling,
  modal focus, contextual notices, less typing, connected steps and fewer
  simultaneous choices. Its exact percentages and study claims were not
  independently verified and are not universal product requirements.

Installed [unslop by Damir Sokolovsky](https://github.com/heydamir/unslop),
CC BY 4.0, from commit `4652254daff586ff4739849395a127b56f7f8cc7` using the skill
installer. The installed directory is `C:/Users/naith/.codex/skills/unslop`.
Existing skills remain intact. Optional upstream snapshot/story scripts were
inspected, not executed. No image service, paid provider or plugin hook added.

## Direction

Product: an iPhone location tool with deliberate manual movement controls.
Character: calm, tactile, precise. World: maps and wayfinding. Visual emphasis:
the selected destination and the next useful action. Signature: connected steps
where a task actually has a sequence. Use the existing theme and component system.

## First local pass

| Before | After | Why |
| --- | --- | --- |
| Pairing instructions mention the Island before opening Settings; four dense paragraphs | Three numbered, connected steps in task order, with short headings | Makes the next action easier to locate without changing the native protocol |
| Pairing sheet paints a system background over the theme canvas | Existing themed screen background shows through | Matches the selected theme |
| Always-visible troubleshooting card | Removed; no Pairing help disclosure | User requested removal after reviewing the connected-steps preview |
| Separate plain capsule pairing actions | Existing `ShiftActionStyle` | Reuses theme shape, press feedback and Reduce Motion behavior |
| Route mode chips scroll horizontally without an indicator | Adaptive grid; a flexible single column at accessibility sizes | Keeps all five choices visible inside the existing Mode & speed disclosure |

Owners: `Locus/Features/Settings/PairOnDeviceView.swift` and
`Locus/Features/Routes/RoutePlannerSheet.swift`. No pairing/session engine,
Live Activity code, stored values, permission requests or imports changed.
The step numbers are instructions, not a fabricated progress/completion meter.

## Ideas deliberately held back

- No always-running shader, looping decoration or artificial loading delay.
- Keep native progress indicators where the result shape is unknown; skeletons
  are not automatically better for pairing or routing.
- Do not animate PINs, coordinates or continuously changing countdowns. Reserve
  number transitions for occasional user-triggered changes if a preview proves useful.
- Existing native dialogs already supply focus/dimming. Existing search,
  saved places and advanced disclosures already reduce typing and choices.

## Validation and next device check

### Build 63 activity follow-up

| Before | After | What this changes |
| --- | --- | --- |
| Large status headline, explanatory line, journey state, progress, distance, route name and repeated age | Route/name and distance/ETA lead; short update-status row; bounded timer and one-line labels | Reduces the stacked height visible in the user's clipped Island screenshot |
| Optional provider status can add multiple multiline blocks | Compact provider rows retain separate status and report age | Keeps Find My/Life360 evidence without implying an update command verified another app |
| Normal text hierarchy can crowd at accessibility sizes | Omit the optional route-name line at accessibility sizes; keep status and route progress | Gives the essential information space without globally reducing accessibility text |

Native compilation passed in run 41174566247. Physical-device screenshots
are still needed for all variants; compilation does not prove layout fits. Pairing code, system Island background, privacy and
stale-state behavior are preserved. No decorative activity animation was added.

57 focused Swift tests passed: pairing activity, route planning, appearance and
backup compatibility. Both changed SwiftUI files passed Swift syntax parsing
on WSL. This does not type-check Apple SDK calls or validate native layout.
The conversational comparison passed browser checks at 320/390/736px and its
action/reset interactions; it is an illustrative mockup, not iPhone evidence.
Local evidence: `.build/video-review/` (ignored, not part of the app).

The subsequently authorized build 62 passed native compilation and all 551 CI
tests on run 41126221099; the exact Downloads IPA passed integrity/package checks.
Three pre-existing warnings remain, with no new UI diagnostics. Still check on
iPhone: all themes, small widths, accessibility sizes,
VoiceOver step order, pairing cancel/retry/background PIN delivery, and each
route mode's existing behavior. The delivered build 61 predates this pass.
No IPA, push, deployment or release was made during the initial polish pass.
The user subsequently requested build 62 in Downloads; its native evidence
is recorded in CURRENT-WORK and BUILD-HISTORY. Publication remains excluded.

## Approved build 67 progress exception

The user approved native ThinkingOrbsKit at three existing request-progress labels.
See [scope, motion gates and device acceptance](NATIVE-PROGRESS.md). This supersedes
the earlier blanket preference for native spinners at those labels only; all other
UI constraints and useful existing feedback remain.

## Route-card collapse — local follow-up

The actual owner screenshot shows the large translucent bottom route card above
the tab bar; the top sent-location banner and floating map controls are separate.
The new chevron button minimizes/expands only the bottom card's optional details.
Pause/Resume and Stop keep their existing actions, guards and accessibility-size
stacking. Current-stop/Continue now, arrival/connection feedback, reroute Cancel
and Retry remain visible. The existing ellipsis menu still exposes Mode & speed.
Route progress and remaining distance remain visible. No app identity, preference,
backup, engine, route-marker or map-coordinate change. One view-local Boolean resets
for new route identity; it does not reset on progress updates, pause or app backgrounding.

Local evidence: 447 model tests and RootView Swift 5 syntax parse passed. Existing
command/menu blocks compare identically to build 67. This does not prove native
SwiftUI type checking, height changes, VoiceOver focus or interruption behavior.
The user's report that route skipping works is specific positive device feedback.

After a separately approved native build, test on the phone:

1. Start a disposable saved test route. Confirm the full card initially appears.
2. Tap its down-chevron. Expect more map space, route progress/distance, Pause,
   Stop and the ellipsis menu; speed/ETA/next-stop details should hide.
3. Let it run briefly. Distance/progress should keep updating without expansion
   or any jump caused by the toggle. Pause and Resume while minimized.
4. Expand and minimize several times. Hold/drag a jump marker and explicitly
   confirm a skip; the same route controls and manual confirmation must work.
5. At a route stop, verify the countdown and Continue now remain available when
   minimized. While rerouting, verify Cancel remains available.
6. Disconnect/reconnect only after reaching a safe test state. The connection
   warning and Retry must remain visible. Resolve any failed clear before continuing.
7. Switch apps/lock and return. The panel should keep its presentation state for
   the same route; a newly started route should open expanded. Progress must survive.
8. Enable Reduce Motion, then Low Power separately: toggling should be instant.
   Check large accessibility text and VoiceOver: named expand/collapse button,
   readable route state, reachable Pause/Resume and Stop. Restore preferences.
9. Tap Stop while minimized and verify the normal clear result. This remains the
   same Stop action, not a separate abbreviated implementation.

No new IPA, push or release was authorized for this follow-up. Build 67 remains
the latest verified binary and does not include the collapse control.

Build 68 includes the route-card collapse above plus an explicitly requested change
in recovery controls: saved/reconnecting presentation, Resume/Cancel recovery, and
Cancel reconnect before a location is confirmed. Existing active-route pause/skip/
Stop handling remains; no map viewport resize. See SESSION-CLOSURE.md and the
ordered walkthrough for current behavior. The earlier local 447-test/no-native
record describes the pre-build collapse patch, not final build 68 validation.
