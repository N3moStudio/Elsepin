# Elsepin energy review — 6 November 2026

## Build 73: targeted optional-work reduction

Owner reports much less warmth with build 72, but supplied no controlled power
trace for this pass. The installed Axiom performance/energy/location guidance was
reviewed alongside Apple's current documentation. This is source-level evidence,
not a measured battery improvement or a reason to reduce route-update accuracy.

- `RoutePlanner.setSectionChoice` keeps geometry for speed-only/same-network
  edits and all explicit drawn/GPX paths. A real network change still requests
  matching directions. Section tests preserve unaffected speeds and ETA inputs.
- `RoutePlannerSheet` caches its `MKPolyline` by route identity, so changing speed,
  waits or options does not reallocate it. New route geometry gets a new identity.
- `ElsepinResourceUsage` maps iOS 27's
  [systemPrefersReducedResourceUsage](https://developer.apple.com/documentation/swiftui/environmentvalues/systemprefersreducedresourceusage)
  to optional camera following (at most every two seconds under pressure) and
  pauses decorative loading motion. Older systems keep the existing behavior.
  Thermal limits still take priority. No new polling timer or background work.
- The root already hides map/GPS browsing work while the planner is presented;
  this was verified and preserved, not claimed as a new fix. Location commands,
  connection recovery, route cadence and Stop do not consume the new UI hint.

References: Apple's [SwiftUI performance guidance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance),
[battery guidance](https://developer.apple.com/documentation/xcode/reducing-your-app-s-battery-use)
and [Power Profiler](https://developer.apple.com/documentation/xcode/measuring-your-app-s-power-use-with-power-profiler).
The iOS 27 integration compiled successfully on Xcode 27.1 in private build 73;
optional-camera policy tests passed. Actual CPU/GPU/display power and heat still need a repeatable phone comparison;
do not infer wattage or battery percentages from nominal thermal state or CPU logs.

## Build 72: observed feedback and expanded evidence

The supplied build-71 export contains 43 energy snapshots. Thermal state remained
0 (nominal); usable process CPU samples ranged from 0.7% to 34.4% of one core,
including interaction/route planning. Heat markers were not controlled idle trials.
Those readings do not establish GPU/display power, a leak or a single heat cause.

Build 72 adds current RSS, context-switch counters and the last opened screen to
the existing 30-second foreground samples. MetricKit's OS reports are collected
locally when delivered; no high-rate profiler, server or extra sampling timer is
added. Complete reports up to 256 KiB are encoded across JSONL records with count
and digest identifiers. Oversized/incomplete capture is detectable. Routine touch,
successful probe and periodic energy events use the existing five-second batch;
errors, route stages and explicit heat markers still flush promptly. Sampling
and exports remain opt-in. No measured energy-saving claim is made.

## Build 71 device-feedback follow-up

The owner reports heat shortly after launching build 70. No physical-device
power trace is available, so no single subsystem or battery-saving percentage is
claimed. An optional bounded Groq source review was used for supporting observations;
its suggested heat causes were not treated as measured findings.

- `DeveloperLogObserver` samples process CPU, peak resident memory, thermal state,
  work owners and cumulative location writes every 30 seconds only while the app
  is active and recording. Thermal changes and a **Phone feels warm** marker add
  snapshots. Sampling stops when inactive or logging is off. CPU is percent of
  one core (can exceed 100); peak RSS is not current memory or GPU power.
- Developer endpoint checks and icon failures record stages/durations or native
  error domain/code. They do not log credentials or provisioning-profile contents.
- `BackgroundKeepAlive` avoids repeated demand reconfiguration, allows browsing
  updates to pause, and ends a precise fix when a <=50m fix arrives. Active-session
  background location remains owned by the session.
- Failed pairing-audio startup now deactivates its audio session. Stop completion
  cancels its monitor on both success and failure. Failed clear remains unverified.
- Status clocks stop when there is no timestamp/provider status to age. Route
  cadence and urgent Stop/Live Activity updates remain unchanged.
- Explicit location commands/Stop make a bounded TCP endpoint check. Continuous
  movement reuses it for ten seconds. This extra liveness traffic is a correctness
  tradeoff, not an energy saving, and must be included in device comparison.

Quick evidence: reproduce the warmth, tap **Settings → Diagnostics → Developer
log → Log tools → Phone feels warm**, then export the same developer log. No continuous high-rate
profiling, new server, uploaded telemetry, or training service was added.

## Build 70 source review

Source review, not a power measurement. Windows has no local native Apple toolchain;
Codemagic can compile/test, but cannot measure this owner's physical iPhone battery.
Do not translate pattern counts into battery percentages or a measured health score.

## Energy profile

- Map: `MapHomeView` gates GPS/camera work on visibility and active scene; thermal/Low Power camera intervals already exist.
- Library layers: pin filtering now updates on camera completion/library/visibility events; area polygons are constructed on area edits. Hidden layers leave the map content.
- Movement: the 0.25-second joystick timer exists only during a held gesture and is invalidated on release/stop. Timing is purposeful; do not blindly slow it or add tolerance.
- Location: `BackgroundKeepAlive` reconciles demand and normally uses coarse accuracy. A requested precise fix is bounded. Background location supports an active session.
- Verification: `LocationVerificationController` is an explicit foreground check with cancellation and a 15-second timeout.
- Pairing: `PairOnDeviceService` has a finite worker and cleanup for background task, location and near-silent audio. `SilentAudioKeepAlive.stop` deactivates audio.
- Cloud: helper checks are opt-in, gated by monitoring/session state and a next-check deadline. Push replacement would require signing/server work and change product capabilities.
- Live Activity: `SessionActivityController` coalesces requested state and skips unchanged content. Do not slow urgent Stop/disconnect/pairing updates.
- Storage: recovery checkpoints have a 10-second gate and explicit forced transitions; library writes occur on edits. Diagnostic recording is bounded and optional.
- Background declarations: audio/location have pairing/session owners; `processing` has no BGTaskScheduler registration found. Removing that declaration alone is not demonstrated energy savings.

The search scan is retained in `.build/energy-scan-2026-11-05.log`. Matches were
checked against their owners; expected active-route work is not an idle-work defect.

## What changed

`MapOptionsMenu.swift` owns the small map menu and cached polygon type.
`MapHomeView.swift` owns layer rendering and cached visible pins. Preferences,
backup review and reset reuse the existing infrastructure. No new timers, network
polling, geofencing, location requests, motion effects or runtime dependencies.

## Further candidates — measure before changing

1. Profile a real route with the screen on, then locked, then stopped; isolate the
   map/GPU, session keep-alive and optional cloud contribution before changing cadence.
2. Investigate only if idle drain persists after Stop: confirm location/audio teardown
   and stalled-helper cancellation. Keep recovery, fresh provider status and pairing intact.
3. Profile large libraries and long routes. If layers dominate, consider spatial indexing
   or bounded display simplification; preserve the actual stored outline/route geometry.

Best-fit skills already installed: `axiom-performance` (energy/energy-diag/energy-ref),
`axiom-audit-energy`, `axiom-location`, and `axiom-swiftui` performance guidance.
Load only the relevant guide. No duplicate skill installation is needed and no
upstream skill manuals were edited. Native Instruments/Power Profiler requires a
suitable Mac and a physical device; a CI success is not energy evidence.

Primary reference: [Apple Power Profiler](https://developer.apple.com/documentation/xcode/measuring-your-app-s-power-use-with-power-profiler).
