# Session closure and automatic trip recovery — build 68

## Behavior

Ordinary inactive/background transitions retain the existing route/checkpoint
behavior. They do not invoke shutdown or clear the simulated location.

If UIKit delivers `applicationWillTerminate`, Elsepin requests a final checkpoint,
invalidates operation tickets, cancels process route/joystick/monitor work, requests
reminder/activity removal and closes the process command gate. The engine attempts
clear on its existing serial connection. No fresh connection, main-thread wait or
retry loop is created. Queued writes are rejected; an already-running vendor call
cannot be interrupted safely. Checkpoint saving and clear remain best effort.

On reopening, a valid checkpoint restores the route line, saved point, progress,
speed/mode and remaining stops. The saved marker is not a current-device position.
A running trip with recorded automatic intent saved within 24 hours gets one
reconnect attempt after the app is unlocked/foregrounded, pairing exists and Wi-Fi
is available. LocalDevVPN must actually work. The first accepted location command
confirms connection before forward playback; downtime is not travel or stop wait.
A failed attempt leaves the route visible for manual Retry; retry does not silently
resume forward travel. Paused trips, old checkpoints without intent and checkpoints
older than 24 hours wait for manual Resume. Stop/End route/discard/turning recovery
off revoke intent. Selecting another pin cancels pending automatic recovery.

Intent is consumed before connecting and re-armed only by confirmed route checkpoints
or an explicit Continue on a confirmed connection. It is separate from asynchronous
checkpoint writes so a late save cannot undo Pause/Stop. Ordinary saved library
routes are never automatically started. Old backup/checkpoint formats are unchanged.

Before confirmation the UI says saved/waiting/reconnecting, with Cancel reconnect
available during the attempt. An unknown previous location remains explicitly
clearable; real clear errors stay visible. The unfinished-location marker is cleared
only after an accepted clear or proof no coordinate was sent. Without a route, an
abrupt relaunch shows a neutral Previous session ended notice and no active activity.
Website Nearby rules are independent and are not paused by closing Elsepin.

## Limits and source

Apple does not guarantee a termination callback. A process can end before cleanup,
notifications, activities or file/defaults persistence completes. There is no verified
platform guarantee that this bundled DVT engine always clears simulation on process
exit. A saved point can lag behind the last command. Device/provider acceptance is
still required; compilation does not establish it.

- `Locus/App/LocusApp.swift`: main-actor delegate and unlocked/foreground recovery gate.
- `Locus/Engine/SpoofSession.swift`: display restore, single Wi-Fi-triggered attempt,
  producer cancellation, epoch guards, real-error presentation.
- `Locus/Engine/LocationEngine.swift`: serial clear and command gating; never access
  vendor handles from another queue or wait synchronously on MainActor.
- `Shared/SessionLifetime.swift`: locked process gate and legacy `locus.unfinishedSession`.
- `Shared/TripResumePolicy.swift`: durable intent, eligibility and one-attempt claim.
- `Locus/Support/TripRecoveryStore.swift`: checkpoint queue/revisions; immediate intent
  revocation on discard/reset; backup/checkpoint serialization remains unchanged.
- `Tests/SessionLifetimeTests.swift`, `Tests/TripResumePolicyTests.swift`: isolated
  preference suites and deterministic queue/eligibility/relaunch tests; no devices.

Local and native counts are in [current work](CURRENT-WORK.md). Controlled condition
mutations must fail before original code is restored and the full suite rerun.
Follow steps 214–231 of the [ordered walkthrough](TEST-WALKTHROUGH-2.6.1.md) for
route-card layout, Wi-Fi loss, running/paused force-close, reconnect errors, manual
Stop and saved-library preservation. No real accounts or physical phone were used
by automated checks.

## Primary platform references

- [Apple: applicationWillTerminate](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/applicationwillterminate%28_%3A%29) — optional callback and finite cleanup time.
- [Apple: background execution time](https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time) — suspension and limited background tasks.

Read 2 November 2026. Neither guarantees clearing this private simulation service.

Build 68 native validation passed on attempt 3: 600 tests (461 Swift, 104 cloud,
19 Companion, 16 packaging/icon), app/extension compilation and IPA verification,
with zero compiler warnings/errors. The private IPA is hash-verified in Downloads.
Earlier runner-allocation failures and full logs remain recorded in
[CURRENT-WORK](CURRENT-WORK.md). Physical-phone acceptance is still pending.
