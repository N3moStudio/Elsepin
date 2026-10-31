# Changes since Elsepin 2.6.0

Comparison baseline: public **2.6.0 (59)**, published 27 October 2026,
source `304756f035172d6e8e3406a451ee57c25cd07951`, native run `40460137350`.
Verified against the published release metadata and source diff on 31 October.
The work below is **unreleased 2.6.1**, private builds 60–65; not an announcement
that the public release includes it. See [changelog](../CHANGELOG.md) and
[build history](BUILD-HISTORY.md) for individual build evidence.

## Appearance and Settings
- Retire Abyss; retain eight themes and all thirteen icons. Bloom becomes the
  fresh-install/reset default; old Abyss selections and backups migrate to Bloom.
- Fix the presentation to compact, rounded typography while preserving larger
  accessibility categories. Remove font, text-size and color-mode controls;
  color mode follows the theme. Old backup fields still decode compatibly.
- Offer only Solid (default) and Liquid Glass, in that order. Retired Theme
  Default material values become Solid; explicit Glass choices are preserved.
- Keep the larger identity card, remove its duplicate Appearance row, retain
  Appearance in Settings search, and place surfaces above themes.
- Use an inline Settings title, swipe-revealed search and extra top spacing.
- Improve import/export action styling and footer spacing; open json.site in
  a native Safari sheet. File selection, upload/copy/Paste and import review
  remain explicit; no automatic upload or clipboard access.

## Pairing and setup
- Show pairing progress and the six-digit code in the existing Live Activity
  and expanded Dynamic Island, with notification and in-app fallbacks.
- Respect the activity preference and system authorization. Clear presentation
  on completion/failure/cancel; ignore late callbacks; bound code visibility
  and keep PINs out of logs/backups. This does not alter Apple's PIN validity.
- Give pairing three connected steps, selected-theme backgrounds and existing
  themed action feedback. Remove Pairing help as requested.

## Routes, search and movement
- Show all five draft travel modes in a wrapping grid, with a single column
  at accessibility text sizes.
- Keyboard Search and the general search button show address/business/category
  results rather than automatically choosing one. Cancel/edit discards stale
  replies. The user confirmed keyboard Search works in build 63.
- Use playback acceleration/corner rules, section speeds and stop waits for
  simulated ETA. Cache the estimate; distinguish it from Apple Maps' estimate.
- Pace coordinate writes using successful confirmations and recent latency;
  prevent an immediate catch-up burst after a slow write; reset after jumps.
  This does not force Life360's independently calculated speed.
- Build 63's route-marker hardening did not resolve the reported phone exit.
  Build 64 moves route-touch projection fully into native MapKit, clears stale
  markers across reconnect/navigation and adds opt-in diagnostic breadcrumbs.
  Phone acceptance remains required; the supplied event log is not an iOS stack.
- Build 64 adds Along route/Everywhere draft-stop search with a result map,
  categories, addresses, saved/recent places and path-distance labels. Filter
  off-path matches, deduplicate results, sort along the route and insert the
  selected stop into the existing itinerary before recalculating the preview.
- Searches are explicit, cancellable and bounded to four MapKit requests.
  Long-route sampling/partial failures are disclosed. No Google API dependency.
  Live/custom-path pause stops still use the existing path; hold and edit a
  running trip to plan a detour to a new place.
- Indent expanded Advanced/More options; mark advanced child rows with a subtle
  theme rail. Keep all controls and accessibility sizing.

## Live Activity and Dynamic Island
- Shorten the route layout: bounded elapsed timer, compact distance/ETA and
  progress, optional route name, short update-status text, no duplicated age.
- Preserve stale/disconnected warnings and separate Find My/Life360 freshness
  rows. Do not equate a successful location command with provider verification.
- Reduce optional content at accessibility sizes. Physical layout still needs
  a device check; native compilation alone does not validate every Island size.

## Maintenance and verification
- Update the website catalog source to eight themes and rounded previews.
  This source change is not a deployment.
- Add concise project instructions, code ownership/navigation, UI-preservation
  guidance and handoff documents. Preserve complete skills and necessary tests.
- Add backup/appearance, pairing-code, timing/pacing and route-search regression
  coverage. Retain complete native build logs and artifact receipts privately.
- Split the map view into compiler-friendly boundaries after two failed build
  attempts; retain one state owner. Build 63 subsequently compiled successfully.
- Build 65 removes all three native warnings: modern certificate-chain access
  preserves leaf pins; checked location-delegate isolation preserves main-loop
  callbacks. Its native build passed 565 tests with zero compiler warnings/errors.
  Retain the earlier build logs as historical evidence. No public release.

## Already present in 2.6.0 — not new in this update
Elsepin branding, Prism Jumpgate, thirteen icons, redesigned Settings, manual
update checks, the website, teleport/favorites, joystick, walking/cycling/driving,
route previews, stop durations up to 24 hours, saved places/routes/areas,
selective backups, widgets, Live Activities and experimental cloud checks
already shipped. Find My People remains unsupported. No new promise of
provider speed accuracy, invisible spoofing or universal app compatibility.
