# Map and route interaction blueprint

Baseline: clean local `codex/pins-search-69`, commit `073f8f4`, following the
privately validated build 77. That build removed the saved-pin annotation's
required environment-object lookup identified in the build-76 crash report.
Its 652 automated checks do not establish phone acceptance of this new work.

## Assessment and fixes

| Report | Source evidence | Target behavior |
| --- | --- | --- |
| Pin names unavailable during a route | `MapHomeView` returned before setting the selected pin whenever placement was forbidden. | Tap reveals/hides the name. An active or prepared route, its position and its destination remain unchanged. |
| Dropped-pin collapse hides text without useful space saving | `RootView` enabled collapse for pin previews and held sessions; the handle itself keeps a minimum height. | No collapse button/gesture for these already compact states. Keep substantial route-preview and joystick controls collapsible; retain the separate active-route panel behavior. |
| Route smoothing shown in joystick mode | `MovementSpeedControl` showed the toggle without a journey; the joystick engine never reads route smoothing. Changing it could instead change the future-route default. | Show route smoothing only with a journey. Explain joystick speed proportional to stick displacement; release stops movement input. Do not introduce coasting or change movement physics. |
| Stay here opens destination search | Destination editing and an automatic-style arrival picker share a compound List row. The physical misrouting is reported, not reproduced locally. | Explicit menu picker and plain destination button isolate the controls. Arrival changes do not navigate or replace a destination. |
| Add stop opens a pause screen | Explicit branch chose `AddPathStopSheet` for a live journey or stored nonautomatic path. | Add stop consistently opens place search. Move exact-path pauses to the adjacent options menu with the name Pause on this path. |

## Related risks checked

- **Saved/drawn geometry:** `addWaypoint` switches from the stored path to new
  directions. Require Recalculate route versus Keep current path after selecting
  a place; no mutation before the choice. Apply the same protection to replacing
  a stop or changing an endpoint on a stored path.
- **Live editing:** first use the existing Hold location and edit confirmation.
  Only after travel ends, open stop search. Cancel preserves the running route;
  editing never automatically restarts it. Exact-path pauses retain their existing
  ahead-of-current-position checks.
- **Limits:** directions allow eight intermediate places; path pauses allow twenty.
  Keep these separate so hitting the directions limit does not silently send the
  user into another editor. A stored path with more than eight stops cannot be
  converted through this search flow.
- **Stale choices:** queued changes verify that the planner remains open, no journey
  is active, no calculation is running and the selected route still matches.
- **Annotation safety:** keep build 77's explicit pin presentation values. No new
  environment object in MapKit-hosted annotation content. Accessibility describes
  label-only taps accurately while a route is staged/running.
- **Collapse cancellation:** preserve interrupted-drag cleanup. A noncollapsible
  panel cannot inherit disabled hit testing from an earlier collapsed state.

## Implementation boundaries

Use the existing themes, sizes, surface treatment, navigation and stop editors.
No redesign, data migration, library deletion, demo-data change, credential change,
new poller, or change to connection/Stop/clear confirmation. No public release.
Only inspect adjacent interaction paths; do not claim an exhaustive whole-app audit.

Code: `MapHomeView.swift`, `SavedPinMapIcon.swift`, `RootView.swift`,
`RoutePlannerSheet.swift`, `TravelControls.swift`, and the portable
`MapPinPlacement` rules in `Shared/RouteLegEditing.swift`.

## Validation and next checkpoint

- Local identity/appearance checks and all 17 Python resource/packaging tests pass.
- All seven changed Swift files parse with the Swift grammar. This is not native
  compilation or runtime UI evidence.
- Added a Swift test covering saved-pin selection for active/prepared/idle routes
  and drawing/adjustment states. Swift is unavailable locally, so execution of this
  test and the existing Swift suite requires the cloud Mac.
- Native build and physical tap/gesture acceptance remain pending. No new IPA was
  built, source pushed, or release published for this local review.
- Local Python had lost its standard library. A signed Python Software Foundation
  embedded runtime under ignored `.build/python-3.13.7/` ran the checks; system
  configuration was not modified.

Focused phone acceptance after the next validated build:
1. During a short route and then its preview, tap a saved pin: name appears, path
   and selected destination remain. Idle tapping still prepares the pin.
2. Drop a pin, then hold a location: neither compact tray has a collapse arrow.
   Joystick and route-preview controls still expand/collapse and recover from an
   interrupted touch.
3. Destination Stay here opens only the arrival menu. Add stop opens search on a
   new route and a demo/saved path; cancel recalculation keeps the old geometry.
   Pause on this path opens the duration/path editor. Live edits require Hold.
4. Joystick speed controls show no route-smoothing toggle; release stops input.
   A real route still exposes its own smoothing toggle without changing defaults.

Undo only this workstream's tracked diff after reviewing it; do not revert build
77 or use a whole-working-tree reset. The blueprint and handoff identify the scope.
