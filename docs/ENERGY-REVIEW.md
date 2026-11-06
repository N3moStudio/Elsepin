# Elsepin energy review — 5 November 2026

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
