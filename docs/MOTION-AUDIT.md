# Shift motion audit and local control pilots

25 October 2026. Source review against the user-provided **iOS Fluid Interactive
Motion Guide** (27 pages, dated 25 October). This is local development, not an IPA
or release. The guide's examples are reference material, not compiled app code.

## Direction

Keep Shift visually quiet. Motion should explain a response, keep a map or route
in context, or resolve a user's gesture. It should not add screens, auto-start
spoofing, animate every number, or keep the phone rendering while idle.

The first application is the map's main action buttons. The authorized follow-up
adds cancellation and input ownership to the existing tray and joystick, where
interruption matters more than adding bounce. Keep the native stop editor,
navigation, and sheets. No custom animation engine is introduced.

## Observed architecture and boundaries

- `project.yml`: iOS/iPadOS 18.0, Swift language mode 5.0, Xcode 27 project setting;
  app and Live Activity/widget extension. Current version remains 2.5.7 (56).
- `RootView.swift`: native `TabView`, selected tab in `SceneStorage`, a stable map
  with an overlaid control tray, native sheets and a full-screen route planner.
  Changing tray height deliberately does not resize the map's viewport.
- `RoutePlannerSheet.swift`: `NavigationStack`, navigation destinations for search
  and route practice, an item-driven native stop sheet, and explicit draft actions.
- `StopDurationControl.swift`: native time wheels/menu pickers, medium/large native
  sheet detents, a local draft, and Cancel/Done. Only the save callback changes the
  route wait. This already fits the guide's native-first approach.
- `SketchMapView.swift` / `MapHomeView.swift`: MapKit drawing integration with
  explicit stroke rollback on cancellation. Drawing transitions use a local
  Reduce Motion-aware animation. Keep the map's rendering/gesture ownership.
- `ShiftDesign.swift`: shared action/settings button styles. The old action style
  eased both press and release over 0.16 seconds and applied animation around the
  label subtree. A narrowly scoped modifier can animate feedback alone.
- `Package.swift`: Foundation-only reliability tests; SwiftUI is compiled by the
  real app target. Windows source checks cannot validate SwiftUI compilation.

This is a **source-based audit**. No running iPhone/simulator screen, baseline
recording, frame trace, or live accessibility session was available this turn.

## Candidates and priority

| Area / exact owner | Observed behavior or gap | Application of the guide | Status |
| --- | --- | --- | --- |
| Map action buttons: `Locus/Support/ShiftDesign.swift`, `Locus/Features/Map/RootView.swift`, `MapHomeView.swift` | Touch-down was eased along with release. The style's animation could encompass simultaneous label changes. | Immediate touch feedback, a small critically damped release, and animation limited to opacity/scale; preserve native Button activation/cancellation. | First local pilot implemented; native validation pending |
| Tray handle: `BottomControlsView.panelHandle` in `RootView.swift` | Baseline reset ordinary drag state only on `onEnded`/button action; projected travel qualified release but actual travel chose direction, disagreeing after a reversal. | GestureState reset restores the existing anchor on cancel; direction locks once; projected position chooses the nearest anchor. Tap the native handle button to expand/collapse. Layout/visibility/scene changes cancel held input. | Local follow-up implemented; native event delivery and feel pending |
| Joystick: `Locus/Features/Joystick/JoystickPad.swift` | Baseline had normal end/scene/disappearance cleanup, but no gesture-cancel reset and no explicit input gate for the still-mounted hidden expanded pad. | Stop movement before visual return, gate stale input until touch reset, normalize finite vectors, and give each accessibility nudge an ownership token. Cleanup by an idle hidden pad cannot stop the visible pad. | Local follow-up implemented; native event delivery and feel pending |
| Route stop editor: `Locus/Features/Routes/StopDurationControl.swift` | Native modal, wheels, accessible menus at large text sizes, local draft, Cancel and Done. | Keep native scrolling and dismissal. Test cancel/swipe dismiss and focus return; do not add a drag recognizer over the wheels. | Retain existing implementation |
| Route preview and drawing: `RoutePlannerSheet.swift`, `MapHomeView.swift`, `SketchMapView.swift` | Native navigation plus a map drawing overlay; stroke cancellation already restores its prior draft. | Keep a stable map and animate only presentation changes. Consider native source-to-preview zoom only if a future card has a stable matching destination; do not force it across tab changes or route-start actions. | Later, after the first pilot passes |
| App icons: `AppearanceSettingsView.swift`, `ShiftAppearanceController.swift` | Shared icon controller prevents concurrent requests and waits for an active scene before final reconciliation. System icon confirmation can deactivate the app; the earlier reported flicker is not reproduced here. | Preserve tab/navigation and installed-icon state through the system prompt. Record the actual flicker before tuning animation; additional spring effects will not repair a lifecycle problem. | Keep current safeguards; device regression needed |
| Backup review: `BackupImportReviewView.swift`, `LibraryBackupView.swift` | Native lists/disclosure controls and an explicit confirmation path. | Keep selection and data commit independent of animation/dismissal. No bouncing rows, per-item stagger, or decorative zoom for a settings form. | Retain existing implementation |
| `Locus/Features/Map/MapDropPin.swift` | Contains custom scale/drag animations without a Reduce Motion environment value, but no construction site was found in `Locus/`. | Confirm reachability before investing in it; gate motion and review cancel cleanup if it is brought back into use. | Dormant source, not counted as a current-screen fix |

## Pilot behavior contract

The existing `ShiftActionStyle` has an opt-in `immediatePress` value, default false.
Six map call sites opt in: Pause/Resume, interrupted-trip recovery, Teleport/Start
at a pin, Stop spoofing, Start route, and Review route after drawing. Other uses
keep their existing behavior until this pilot is accepted.

| Situation | Requested behavior |
| --- | --- |
| Resting | Existing layout, shape, colors, typography and 48-point minimum height |
| Enabled touch-down | Immediately show the existing 0.78 opacity / 0.975 scale feedback; no ease-in delay |
| Release / canceled press | Return visual feedback through a spring with response 0.24 and damping fraction 1; this response value is not a measured completion time or frame-rate claim |
| Disabled | Existing 0.40 opacity, no pressed scale; disabled transition is not delayed by the pilot |
| Reduce Motion enabled | No scale or release spring; opacity still acknowledges a press. Read the environment on view updates; device-test changes during a press/settle |
| Activate | The existing native Button action and its existing permission/session checks run normally; no animation completion controls execution |
| Repeated touch / leaving the button | Native Button owns tracking and whether a release activates; no custom recognizer, timer, task, persistence or extra haptic |

Only opacity/scale modifiers use the new scoped animation. The existing action
closures, labels, confirmation rules and route/session calculations are untouched.
This is not a general draggable-card implementation and makes no arbitrary
mid-spring re-grab continuity claim.

## Button pilot verification record

| Check | Result / evidence |
| --- | --- |
| PDF review | PASS: extracted source; reviewed mechanics/native examples, accessibility and rollout criteria; visually rendered the accessibility page |
| API/deployment review | PASS: Apple's scoped-animation declaration is iOS 17+, below this app's existing 18.0 target; spring/transaction APIs are already compatible. No target or dependency change |
| Source diff / whitespace | PASS: three Swift files, feedback/style opt-ins only; `git diff --check` passed |
| App identities | PASS: `python scripts/check_app_identity.py` |
| Appearance resources | PASS: `python scripts/check_appearance.py`; 9 icon choices / 27 native appearance images |
| Existing packaging/appearance tests | PASS: 14 tests, `python -m unittest discover -s scripts/tests -p 'test_*.py' -q` |
| SwiftUI compilation / Swift unit suite | NOT RUN during the first button pilot. The follow-up below found local WSL Swift for Foundation tests; native SwiftUI compilation is still unavailable. No remote build initiated |
| Before/after device recordings | NOT RUN |
| Reduce Motion / VoiceOver / Switch Control / maximum Dynamic Type / RTL | NOT RUN on an Apple device; preserving native controls is not proof of runtime accessibility |
| 60 Hz / ProMotion / power and hitch measurements | NOT RUN; no performance or battery numbers claimed |
| Push/release/IPA/deployment | NOT RUN; existing no-push/no-release instruction retained |

No new unit tests were added for a reversible visual modifier. Source-string tests
would only mirror its implementation and would not establish correct feel,
gesture cancellation, or SwiftUI type checking. The existing checks above protect
packaging/identity resources; they do not test the motion.

## Tray and joystick follow-up

The scope stays within the existing controls. `Shared/ControlInteraction.swift`
holds the small testable touch, projection, vector and nudge-ownership rules. The
SwiftUI views own event delivery and visual state; `SpoofSession` remains the
movement owner and already invalidates its joystick timer on a zero vector.

| Event | Behavior |
| --- | --- |
| Tray touch | Existing local 12-point drag threshold; lock vertical versus sideways at recognition, track without inherited animation, keep the map viewport fixed |
| Tray release | Project the expanded fraction using predicted end displacement and current detail height, then choose the nearest anchor; exact midpoint preserves the current anchor. A short release returns; reversing direction before release can change the target |
| Tray cancellation | GestureState reset clears offset and returns to the existing committed open/compact anchor, without committing a new state |
| Tray button | Same capsule/chevron appearance and 44-point target; native tap and accessibility activation now expand or collapse. A local high-priority drag handles movement; verify no duplicate tap on device |
| Joystick touch/re-grab | Measure position against the stationary base, clamp the vector, and directly update thumb and input without inherited animation. A new touch supersedes any old nudge |
| Joystick release/cancellation | Send zero to the session immediately, cancel any owned nudge, then return the thumb (response 0.25, damping 1). Movement never waits for a visual completion |
| Interruption | Inactive scene, hidden tab, app lock, planner/session/movement/recovery presentation, view disappearance, changed joystick frame/radius or tray width/content height cancel relevant held input; old updates are ignored until gesture reset. Opening an unobscured map again does not resume movement |
| Expanded versus compact pad | Only the visible pad accepts input. An idle pad's geometry/disappearance cleanup does not send a stop belonging to the other pad |
| Accessibility | Keep native directional buttons and the 250 ms nudge. Stop, a newer nudge or a new touch invalidates older completion tokens; a delayed reset cannot cancel a newer nudge |
| Reduce Motion | Return without a spatial spring; a live change safely ends held input and snaps transient offsets. No new settings or motion choices |

No display link, polling, background task, new timer, dependency, persistence,
teleport/start action or session engine change is added. The existing short
accessibility Task is retained and explicitly canceled. Geometry is observed
through SwiftUI callbacks, not sampled in a loop. Expected battery impact is
small; stopping a canceled joystick avoids leaving its movement timer active.
No battery savings or frame-rate improvement has been measured.

This remains a SwiftUI target-based tray animation, not a presentation-position
spring engine. Arbitrary mid-settle re-grabs can still require refinement after
device recording. Do not claim exact velocity continuity or prove gesture event
ordering from a unit test. Keep the current 0.32-second tray animation setting.

### Follow-up evidence

| Check | Result / evidence |
| --- | --- |
| Baseline Swift tests | PASS: 379 XCTest tests, zero failures, local Swift 6.4 / Ubuntu 24.04 WSL ARM64 |
| Updated Swift tests | PASS: 395 tests, zero failures, including 16 new behavior cases in `Tests/ControlInteractionTests.swift` |
| Syntax parsing | PASS: Swift frontend parse for `RootView.swift`, `JoystickPad.swift` and the shared rules. This is not native SDK type checking |
| Project source registration | PASS: shared file registered in the checked-in app and extension; existing `project.yml` already includes all Shared files |
| Packaging/appearance tests | PASS: 14 existing tests; identity check and 9 icon choices / 27 images pass |
| Diff whitespace | PASS |
| SwiftUI/native build, gesture/button arbitration, accessibility, recordings, power/performance | NOT RUN; needs Mac/iPhone testing |

Local logs are `.build/motion-review/baseline-swift-tests.log`,
`control-swift-tests.log` and `control-syntax.log`. The 16 tests cover interrupted
and fresh touches, cancellation without release, sideways ownership, resize
blocking, reversed and small releases, invalid geometry/vectors, superseded
nudges, delayed reset and idle hidden-pad ownership. No source-string tests or
synthetic timing measurements stand in for native interaction.

## Native acceptance and recording plan

On the next explicitly requested build, compile the real `Locus` scheme and its
extension with the existing project/workflow. Use a source baseline with the six
opt-ins absent, then the same build configuration with them enabled. Record device,
OS, refresh-rate capability, build mode and Reduce Motion setting for each clip.

1. Record the same map location and idle prepared route before/after. Press, hold,
   slide off, slide back, release outside, tap rapidly, and re-press during release.
   Expected: feedback is immediate, canceled presses cause no action, no duplicate
   route start or teleport, and no map/label layout jump.
2. Check disabled Start/Review and busy transitions. Do not start real movement just
   to inspect a press; cancel outside first and use an authorized controlled session
   for actual Start/Pause/Resume/Stop checks. Widget preparation must still wait for
   the existing manual Start/Teleport action.
3. Toggle Reduce Motion while idle, held and settling. Expected: no spatial press
   feedback when enabled, a coherent resting state, and no stale action/completion.
   Verify this live; the source gate alone cannot prove interruption behavior.
4. Use VoiceOver, largest Dynamic Type, RTL, keyboard/Switch Control where available.
   Expected: existing labels, focus and activation semantics; no clipped button or
   inaccessible action. Background/foreground while held and open/dismiss the
   system icon prompt to check stale pressed states and tab preservation.
5. Capture optimized-device traces on 60 Hz and ProMotion hardware when available.
   Look for repeatable new hitches, layout invalidation and idle work. Compare to
   baseline rather than declaring a frame rate from the spring response value.

6. With the tray expanded and compact, drag halfway then open Control Center,
   background the app, rotate/resize, switch tabs or present an editor. Expected:
   no stranded height or disabled details; cancellation preserves the old anchor.
   Drag sideways then curve vertically; it must not acquire tray ownership. Test
   short releases, reversed flicks and rapid re-grabs during settling. Record any
   presentation jump before changing the animator.
7. In an authorized active session, hold the joystick, then perform the same
   interruptions, collapse/expand using another touch, and change Reduce Motion.
   Expected: movement stops promptly; returning or holding the old finger does
   not restart it; a fresh touch works. Check both compact and expanded pads.
8. With VoiceOver, issue two directions quickly, Stop, then another direction.
   Expected: an older 250 ms completion cannot stop newer input. Test the native
   tray button in both states with VoiceOver/keyboard, plus tap versus pan on
   hardware: one action per tap and no extra toggle after a recognized drag.

Do not expand the opt-in to settings/library screens or introduce a custom tray
animator until native compilation and the relevant device matrix pass.

## Rollback and references

Remove `immediatePress: true` from the six map call sites to restore their previous
style. The option defaults false; no data migration or reset is involved. Delete
the optional branch/property afterward if retiring the pilot. Revert only these
motion edits, preserving unrelated local Find My/reset/backup work and ledger history.

For the interruption follow-up, revert only its `RootView`/`JoystickPad` edits,
shared rules/tests and source registrations. Preserve the earlier button opt-ins
and unrelated changes. No migration is needed. Keep both pads' input gates and
the cancellation fixes together if retaining any of this follow-up.

- User guide: pages 5-6 (audit/native API choice), 9-13 (state and SwiftUI limits),
  20-25 (gesture ownership, accessibility, measurement, acceptance and rollout).
- [Apple scoped animation](https://developer.apple.com/documentation/swiftui/view/animation(_:body:)):
  apply animation only to the modifiers in the closure.
- [Apple spring parameters](https://developer.apple.com/documentation/swiftui/animation/spring(response:dampingfraction:blendduration:)):
  response is an approximate spring parameter, not a measured end-to-end duration.
- [Apple GestureState](https://developer.apple.com/documentation/swiftui/gesturestate):
  gesture-owned temporary state resets when its gesture becomes inactive.
- Existing installed skills used: PDF; Axiom SwiftUI with animation reference;
  Axiom Accessibility with Reduce Motion guidance. No skills, hooks or runtime
  libraries were installed or updated for this work.
- Follow-up guidance: Axiom SwiftUI gestures, UIKit bridging evaluation (no new
  UIKit bridge was adopted), Concurrency task ownership, and Testing's pure-logic
  package approach. Existing XCTest conventions were retained.

## Cloud setup and Nearby follow-up

The 25 October cloud/nearby change keeps native SwiftUI list and navigation
behavior. Tutorial text moves to `docs/CLOUD-GUIDE.md`; the web dashboard and
place editor use semantic native forms, no custom gestures and no frontend
framework. Web press feedback is immediate; a local 180 ms release is limited to
opacity/scale. Live Reduce Motion removes spatial feedback. Browser checks cover
light/dark, 320–1280 px, 200% text and native form controls; real
iPhone feel, VoiceOver and battery profiling remain untested. See the Change
Ledger for exact test evidence and limitations.
