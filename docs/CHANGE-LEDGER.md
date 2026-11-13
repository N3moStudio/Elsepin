# Elsepin Change Ledger

## Build 80 validated and delivered - 12 November 2026

GitHub run 43376928555 succeeded at 6a1a29c: 686 checks passed (547 Swift,
104 cloud, 18 Companion, 17 resources; one Windows-only case skipped).
Native app/extension compiled with zero compiler warnings/errors. Both bundles
are 2.6.1 (80); arm64, entitlements, icons, helpers and notices verified.
Delivered Elsepin 2.6.1 build 80.ipa to the usual Desktop IPA folder, replacing
build 79. Logs/receipt: .build/artifacts/github-43376928555/.
No release published. Physical-device acceptance remains pending. Earlier
not-built/pending-native notes below are superseded by this result.


Updated through **12 November 2026** (America/Los_Angeles). Elsepin 2.6.0 (59)
is the last recorded public release. Earlier entries retain their original validation context.

See [the public build register](BUILD-HISTORY.md) for dates, outcomes and all recorded 2.5.x/2.6.0 native runs.

## Build 80 preparation - regressions (12 November 2026)

The [review record](BUILD-80-REVIEW.md) maps the planner/pin/search fixes and
bounded adjacent audit. Build number 80 is reserved, not built. User will request
the next build; no release authorized. Existing backups, demo separation,
confirmed location writes, widget confirmation and exact saved paths are retained.
See [changelog](../CHANGELOG.md#build-80---planner-and-pin-regression-fixes-not-built-yet).

## Build 79 - post-78 integration (12 November 2026)

Implemented the authorized library/pin/area and route changes listed in the
[changelog](../CHANGELOG.md#build-79---library-pin-and-route-refinements-unpublished-test-build).
New shared rules cover Redo history, row hit testing, emoji validation and bounded
next-route timing. Pin backup additions are optional; all existing storage IDs
and compatibility identifiers are retained. Next-route automatic consent is
explicit, one-shot and not persisted. No release or billing change authorized.
Final source `9d64110`, GitHub run `43356906705`: 665 checks passed, zero compiler
warnings/errors, both bundles/package verified, and build 79 delivered to the
usual IPA folder replacing only build 78. See [current evidence](CURRENT-WORK.md)
and [build history](BUILD-HISTORY.md) for every attempt. Phone acceptance remains
pending. Individual local-only notes below describe earlier stages of this work.

## Build 78 interaction fixes (12 November 2026)

- Show saved-pin names during active/prepared routes without moving the destination.
- Remove redundant collapse from dropped-pin and held-location trays.
- Keep route smoothing out of joystick controls; clarify stick-controlled speed.
- Make arrival an explicit menu and separate Add stop search from exact-path pauses.
- Confirm recalculation before replacing saved/drawn geometry; preserve live-edit Hold.
- GitHub run 43348423568 passed 653 checks and native compilation without compiler
  warnings/errors. Test IPA delivered; no release. Phone acceptance remains separate.

## Build 77 - saved-pin annotation crash fix (8 November 2026)

The supplied developer export contains an iOS crash report for build 76 at the
Demo Garden Walk start. Its Locus UUID matches the delivered binary exactly.
Exception type 6 / SIGTRAP (5) has Swift/SwiftUI frames above
`SavedPinMapIcon.body` and its Button label, called during MapKit annotation layout.
The log records three accepted location writes before exit. This is a recorded
runtime trap, not a Jetsam report; the last sample was 380.8 MiB footprint with
6275.2 MiB advisory headroom. It does not establish all other exits have this cause.

Removed the annotation's required EnvironmentObject lookup. MapHomeView now passes
pin size and label background explicitly. This preserves pin size, themes, labels,
selection, favorites and explicit Teleport confirmation while avoiding a missing
settings object in separately hosted/recycled annotation views. No persistence or
connection behavior changed. Original report/extraction stays in ignored
`.build/incident-76/`; exact binary symbols resolved the two app frames at offsets
2979876 and 2977904. Codemagic `6af170c877f10fa3b05d9e17` passed all 652 checks (513 Swift, 104 cloud,
18 Companion, 17 packaging; one Windows-only helper case skipped on Mac).
Source `035a8468291078e4d59b57e85fe511a19c830f78`; native app/extension built with
zero compiler warnings/errors. Verified both bundles 2.6.1 (77), arm64/SDK 27.1,
compatibility IDs/entitlements, 13 icons and bundled helpers. Delivered only
`Elsepin 2.6.1 build 77.ipa` (18,839,322 bytes) to the usual Desktop IPA folder,
replacing build 76. Code is local and on both private remotes. No release or main
merge. Phone acceptance pending: start Demo Garden Walk and zoom/select a saved pin.

## Build 76 - Dev Mode, sweep selection and map hardening (8 November 2026)

Private build 76 compiled and was delivered; 652 checks passed, with zero compiler
warnings/errors. Phone acceptance remains pending. Owner reports build 75 still exits on satellite
zoom and sometimes saving/zooming around a pin; no new incident export is present
in Downloads. Owner currently reports no noticeable heat. These are device reports,
not a confirmed crash cause or a measured energy result. No release is authorized.

- Advanced & experimental -> Testing tools has Dev Mode. Demo library and ordinary
  preferences use a separate defaults domain/file directory. Original library files
  are never replaced. Stop/finish the session and recovery before switching; pending
  saves finish first. Recreate drafts, reject stale library/import callbacks, refresh
  widget snapshots, and reset demo edits on the next activation. Pairing, connected
  accounts, security/icon settings, clear-state evidence and diagnostics stay global.
- Fixtures include eight pins, six walk/run/cycle/e-bike/drive/mixed routes, second
  and two-hour waits, folders, two areas, route history/recents and ten deleted items.
  Synthetic paths are not verified roads. Real connection, cloud helper/signing
  requirements and explicit Start/Teleport confirmation still apply.
- Recently Deleted: drag the selection-circle gutter to select/deselect a contiguous
  range, including fast/reversed gestures. Scroll normally elsewhere. Preserve
  individual taps, accessibility actions, cancellation cleanup and deletion review.
- Save a pin's full metadata with one publication/write. Delay native tap-coordinate
  projection until a tap succeeds (not the first finger of a pinch). Pause covered
  map callbacks and filter pin-editor annotations by the viewport. These remove
  concrete churn/hazards but do not establish that the reported crash is resolved.
- Opt-in diagnostics add current/peak memory footprint and advisory memory headroom;
  map snapshots are rate limited to five seconds. No new polling loop. Numeric touch
  formatting rejects nonfinite/out-of-range inputs instead of trapping.

Validation: Codemagic `6af16be955fc448af77585cd`, source `1e7b5dc`, passed 513 Swift,
104 cloud, 18 Companion and 17 packaging/resource tests. One Windows-only helper
test was skipped on Mac and excluded. The native app/extension and unsigned IPA
were verified as 2.6.1 (76), arm64, SDK 27.1. New tests cover workspace isolation,
failed seeds, fixture round-trips, drag ranges and diagnostic values. The first
native attempt's compiler complexity error and two concurrency warnings were fixed
before the successful rebuild. No release or deployment; phone crash acceptance pending.

## GitHub source sync and blocked Actions attempt - 7 November

Owner reported account reinstatement and authorized source sync plus a GitHub
build attempt. Private repository access verified; fast-forwarded the existing
test branch from `ea41165` to `bdbc5da`, with no main change. Run `42448203209`
was rejected before execution by GitHub's failed-payment/spending-limit check.
Account access works; Actions availability is still blocked. Preserved GitLab,
Codemagic, push defaults and verified build 75 delivery. No code changes, billing
changes, release, deployment or cancellation of another build. Updated stale
account-suspension guidance so future chats can use GitHub source access without
mistaking it for restored build allowance.

## Build 75 - feedback follow-up and private delivery, 7 November

Five owner screenshots show a lingering native search control after route-label
editing and corrupt import separators. The owner also reports map zoom-out exits,
a lost preview after Start without VPN, and asks for scoped smoothing and swipes.
RouteSearchField owns its field/focus within each search editor. Place labels are
explicitly route-only. SpoofSession keeps a matching prepared-route confirmation
until the first accepted write; a definite pre-write failure restores its preview,
while uncertain/previous writes still require clearing. Route smoothing is separate
from the persisted default and survives saved/recovered/recalculated trips.

Native pin recognizers no longer retain SwiftUI converter closures; recognizer
configuration stays stable during holds. MapViewportSafety rejects invalid camera
values and projected markers reject non-finite points. Settled viewport/style and
route-start events use the existing opt-in capped log. These are defensive changes:
the new crash incident is not yet available; the only local export is November 5.

Library/Favorites swipes preserve trash/confirmation and active-route guards.
Import Overview describes only selected new items and current-to-applied settings,
grouped by category. Legacy glassPanel compares with the effective current surface.
No backup schema/version or identifier changes; the prebuild encoding guard now
rejects corrupted middle-dot/NBSP sequences as well as prior punctuation patterns.

Local Python, identity/assets, diff and 20-file Swift syntax checks passed first.
Owner then requested the IPA. Private run `6aeffac04ed44a8f85aaa7c7` at `39f124f`
passed tests/native compilation but exposed one ImplicitStrongCapture warning.
An explicit weak planner capture plus captured route ID removed that warning.
Final run `6aeffd199b54af17623a586e` at `fc3887a` passed 640 checks (501 Swift,
104 cloud, 18 Companion, 17 packaging) and native app/extension compilation with
zero compiler warnings/errors. One Mac-inapplicable Windows helper skip is excluded.
Complete original logs and successful receipt remain under `.build/artifacts/`.
Both bundles verified as 2.6.1 (75), arm64, SDK 27.1; package identities, groups,
resources and helpers passed. Delivered only the 18,767,708-byte IPA to the Desktop
project folder after verification and removed only Elsepin build 74 there. Updated
private GitLab; no public release/deployment. Device zoom-crash resolution and UI
acceptance remain pending. [Current checks](TESTING.md).

## 2.6.1 (74) - planner organization and navigation - unreleased

Owner requested explicit keep/recalculate choice for network changes, fewer cards,
endpoint-based arrival/naming, full-screen stop selection and native back swipes.
Remove the redundant planning controls and notes; keep move-on-map and all active
movement safeguards. Shared editor navigation no longer hides native Back.
Full-map selection unwinds before itinerary edits; exact-path pauses remain on
the original geometry. Source/backup identifiers and optional energy policy stay.
Tests cover cross-network path choice and unchanged movement-section boundaries.
Private run `6aeebd6324e1ec23755711eb` at `b66aad4` passed 634 checks (495 Swift,
104 cloud, 18 Companion, 17 packaging) and native app/extension compilation,
zero compiler warnings/errors. Both bundles and resources passed IPA inspection.
Delivered only build 74 after verification, replacing 73 in the Desktop folder.
The earlier `8bc1200` run also passed but was not delivered; final review added
surface-respecting expand buttons, removed duplicate Cancel controls and retained
older saved-path stop limits. Both runs' complete logs remain internal. No public
publication; phone gesture/layout acceptance is pending.

## 2.6.1 (73) - editable legs, staged-route protection and compact planning - unreleased

Owner supplied six screenshots and reported per-leg editing was inaccessible,
map taps destroyed ready routes, planned routes were missing from Recents and
the tray/planner were too bulky. Direct leg controls now preserve unaffected
speeds/path sections, use deferred navigation handoff and respect active-route
hold confirmation. Previewed routes enter local opt-in history; taps reopen the
snapshot without starting movement. The explicit X owns staged-route dismissal.

Retire the tray Settings/More affordances; keep Settings tab and existing features
under compact planner groups. Remove the selected timing prose. Hybrid is renamed
Satellite + labels rather than removing a distinct map layer. Compatibility tests
retain old backup, shortcut and travel-section fields. Remove only unreachable
UI/state from this scope; retain vendor resources, notices and historical evidence.

Use the installed Axiom performance/location and Apple Design guidance. Follow
Apple's iOS 27 reduced-resource signal only for optional visual work; cache preview
geometry and avoid new direction requests for speed-only changes. No extra polling
or high-rate diagnostic capture. Private Codemagic run `6aee4fc824e1ec237556f9c4`
passed at `567e6c5`: 631 checks (492 Swift, 104 cloud, 18 Companion, 17 packaging),
native app/extension and IPA inspection, zero compiler warnings/errors. The single
Windows-only helper skip is excluded. Delivered build 73 after verification and
removed only the older Elsepin IPA from the delivery folder. Full logs and receipt
are preserved internally. No public release; phone UI/heat acceptance is pending.

## 2.6.1 (72) - connection, route handoff and diagnostic follow-up - unreleased

Build-71 device evidence and fixes are summarized in CURRENT-WORK.md and
ENERGY-REVIEW.md. No OS crash stack was supplied, so the reported Add Stop exit
remains a device-retest item after focused navigation/timeline corrections.
Fresh explicit handshakes, a shorter endpoint failure bound, accurate durable
write markers, directions deadlines, Live Activity age labels and expanded local
MetricKit/CPU/memory/screen/route diagnostics are implemented. Existing visual,
Recently Deleted, backup and manual-confirmation behavior is preserved.
Private Codemagic run `6aed7105ab17f8deb75355d1`, source `50467da`, passed
620 automated checks (481 Swift, 104 cloud, 18 Companion, 17 packaging), native
app/extension compilation and IPA verification with zero compiler warnings/errors.
The Mac's Windows-only helper skip is not counted as a pass. Delivered only build
72 to the Desktop project IPA folder, replacing build 71 after verification.
Device route/VPN behavior and heat remain unverified; App Group signing remains
necessary for saved-location widgets. Full run evidence: BUILD-HISTORY.md.
No publication or deployment.

## 2.6.1 (71) - owner feedback and bounded diagnostics - unreleased

- Owner installed with FlareStore, confirmed LocalDevVPN is the connection in use.
- Endpoint liveness checks and honest pending/failed session labels; compact Stop
  retains its in-flight lock even when the evidence deadline expires.
- Saved-pin tap selects a preview; instant pin/route stars and adjustable saved-pin
  size preserve library identities, metadata and old backup imports.
- Compact deleted-item selection bar, two-column map actions at ordinary text sizes,
  corrected UTF-8 text with a regression guard, signer capability/error diagnostics.
- Foreground-only 30-second CPU/peak memory/thermal/resource snapshots, heat marker,
  precise-fix early completion and failed audio/session-monitor cleanup.
- Private Codemagic run `6aed1ad9ab17f8deb753426c`, source `14d2050`, passed:
  615 checks, zero compiler warnings/errors, app/extension and IPA verification.
  Delivered only build 71 to the Desktop project IPA folder, replacing build 70.
  Device, FlareStore and heat acceptance remain pending. No public release or
  changes to other apps. Full run/failure evidence is in BUILD-HISTORY.md.

## 2.6.1 (70) - map layers and rendering work - private build

- Reuse the layers button for Map options: Pins, Areas, and all three map styles.
- Draw saved area outlines on the main map; remember each layer independently.
- Keep selected destinations visible, preserve tap-only pin labels and route controls.
- Cache visible pins and polygon geometry instead of rebuilding on route ticks.
- Preserve old backups through optional flags; support selective import and reset.
- Record source-level battery findings in [energy review](ENERGY-REVIEW.md).
- Source commit `19c530b` was initially blocked by GitHub suspension. The owner
  resumed private GitLab hosting in the existing folder and authorized Codemagic
  M2/Xcode 27.1. Run `6aeceff2ab17f8deb7533589` passed at `0e098f2`: 611 distinct
  tests, zero compiler warnings/errors, both app/extension and IPA inspection passed.
- Read-only Elsepin-specific builder key, private GitLab source, no CI/Pages,
  no paid billing, browser/desktop control, public release or deployment.
- Delivered only build 70 to the Desktop project IPA folder, verified before
  replacing build 69. Other apps unchanged; device and battery acceptance pending.

## 2.6.1 (69) — Pins, Favorites, map search and energy — unreleased

- Separate permanent Pins from favorite Pins/Routes, with optional starring, map
  symbols and tap-only name bubbles. Preserve folders and all pins in widgets,
  backups and deletion/restore. Historical defaults and formats remain readable.
- Recent route snapshots share history privacy controls; recent pin/route actions
  can plan or name/save, and only a pin offers Teleport preparation.
- Area search moves the drawing camera without altering corners; Home search
  removes Saved places and calls the selected map point Currently dropped pin.
- General/category search uses bounded native requests and one fallback. Active
  route search browses/saves results without redirecting travel; draft stop
  searches still rebuild a preview and now show partial results sooner.
- Cycling fallback requires explicit walking-path choice. Battery work limits
  idle wait wakeups, cancels obsolete search/directions, limits pins to the map
  viewport and slows optional camera updates during thermal pressure.
- Review preserved actual wait duration, interruption wakeups, movement cadence,
  Stop, privacy, compatibility, themes, icons and recovery timing.
- Add a manual personal Codemagic M2/Xcode 27.1 build alternative after GitHub's
  account quota blocked the native runner. Preserve every test and original log;
  verify stderr/failure-status capture with an intentional exit-23 check.
- Fix the library-only backup fixture without weakening production validation,
  make its unrelated incident-test teardown Sendable-safe, and convert the
  MapKit fallback error code to the Int required by NSError.
- Codemagic run `6aec1824004ce28f20ee09d4` at `8b155ec` passed the native app and
  extension build with zero compiler warnings/errors. All 609 distinct tests
  passed across the Mac and the Windows-specific helper check. Verified build 69
  is in Downloads; full evidence is in BUILD-HISTORY. No release or deployment.

## 2.6.1 (68) — compact route card and automatic trip recovery — private test build

- Collapse/expand the active-route card while retaining progress, remaining distance,
  Pause/Resume, Stop and actionable warnings. New routes open expanded.
- Restore an interrupted route and its saved position on launch. A remembered running
  trip saved within 24 hours gets one reconnect attempt in an unlocked foreground,
  once Wi-Fi and pairing are available. LocalDevVPN must work. Travel resumes only
  after the saved point is accepted; downtime is not added to distance or stop waits.
- Paused trips, legacy checkpoints without recorded intent, older checkpoints and
  failed reconnects require manual Resume/Retry. Stop/End route, discard and disabling
  recovery revoke automatic intent. No background polling/reconnect loop was added.
- On a delivered UIKit termination callback, preserve the checkpoint, cancel process
  workers, close the engine command gate and attempt a clear on the existing serial
  connection. Normal backgrounding remains unchanged. iOS can terminate without
  this callback; clearing/activity removal cannot be guaranteed after force-kill.
- Show saved/reconnecting state without claiming active spoofing. Preserve genuine
  errors and explicit clearing when the device state remains unknown. A successful
  clear alone, or proof no location was sent, clears the legacy unfinished marker.
- Preserve compatibility IDs, backup formats, themes and bundled helper exports.
  Build 67 is retained. No public release, deployment or public asset changes.
- Native run 41526208045, attempt 3, passed all 600 tests (461 Swift, 104 cloud,
  19 Companion, 16 packaging/icon), app/extension compilation and IPA verification,
  with zero compiler warnings/errors. The private build 68 IPA is hash-verified in
  Downloads. Earlier runner-allocation failures remain recorded in CURRENT-WORK.
  Physical-phone acceptance remains pending; the release stays unpublished.

## 2.6.1 (67) — native request progress — unpublished

- Add native 20-point Thinking Orbs beside existing place search, route-stop search
  and explicit cloud Test connection labels. Indicators follow existing requests;
  cancellation, errors, results and manual movement controls are unchanged.
- Keep progress static for Reduce Motion, Low Power Mode, inactive scenes and
  disappeared views. Labels remain readable and announced once by VoiceOver;
  existing typography, themes and accessibility text sizing are retained.
- Pin the reviewed MIT-licensed ThinkingOrbsKit revision to the app target only;
  retain its notice. No web bridge, AI service, new permissions or polling.
- Include the separately reviewed removal of 264 unused production Swift lines.
  Existing tests were retained; four motion-policy regression tests were added.
- Native run 41518500417 passed 586 tests, app/extension compilation and IPA
  validation with zero compiler warnings/errors. Build 67 is verified in Downloads.
  No public release or website deployment.

## Local dead-code cleanup — 2 November 2026

Base `60f084e`; no commit or upload. [Review and rollback](CLEANUP-AND-ORBS-REVIEW.md)
records reference evidence, 264 production Swift lines removed (zero test changes),
443+16 passing checks, native-build limitation and unchanged build 66 checksum.
No runtime feature or deployment change; optional tool/dependency approvals remain pending.

## 2.6.1 (66) — incident diagnostics and experimental audit — 1 November 2026

- Added bounded incident export around explicit problem markers; the full JSONL export,
  opt-in capture and 48-hour retention remain unchanged. Route attempts link preview,
  manual jump, Undo, retry and actual write outcomes without changing movement gates.
- Fixed shared Nearby/spoof-check polling and Nearby-only authentication readiness.
  Corrected helper export runtime pin and standalone setup guides.
- Anonymous public IPA access and both embedded helper packages verified. Public
  docs/assets intentionally untouched; People remains unavailable.
- 443 Swift, 104 cloud, 19 companion and 16 packaging/icon tests passed locally;
  freshly extracted helper ZIPs independently pass. Native run `41396515177`
  passed all 582 tests, app/extension compilation and packaging with zero compiler
  warnings/errors. Source `7bdf1a5f8051ccc94d38420fb45ee3d24236c6d9`.
- Downloads IPA: 18,444,793 bytes; SHA-256
  `aadde4ce1d7277d4ca182a8d2c8bbd2fb6b03dac63528f19ae08ec7c7d1ebc22`.
  Original logs/receipt retained in `.build/artifacts/41396515177/`; earlier IPAs retained.
  Delivered offline 216-step checklist, expected import values, six fixtures and both helpers.
- Ordered owner walkthrough and experimental audit are linked in CURRENT-WORK.
  No public release or deployment. Physical-phone/provider acceptance still required.

## 2.6.1 (65) — native warning cleanup — 31 October 2026

- Replace deprecated certificate access in the Windows companion and self-hosted
  cloud helper delegates with `SecTrustCopyCertificateChain(...).first`. Retain
  leaf SHA-256 pinning, host checks, rejected redirects and managed-HTTPS system
  trust handling. No broader trust exception or credential change.
- Mark the MainActor-created location manager's legacy delegate conformance with
  checked `@preconcurrency`. Core Location delivers on its creation run loop;
  preserve synchronous fresh-fix handling, cancellation and foreground-only checks.
- Increment both target build numbers to 65 so native validation is distinguishable
  from the user's ongoing build 64 route-crash test. UI and route code are unchanged.
- Native run 41213887689 passed 565 tests and app/extension compilation with
  zero compiler warnings/errors. The private IPA artifact passed integrity,
  identity, icon/resource and hash checks. Build 64 in Downloads is unchanged;
  no new Downloads/Drive delivery or release publication. Device checks remain pending.

## 2.6.1 (64) — route interaction and stop discovery — 30 October 2026

- Replace route-marker touch callbacks' SwiftUI map conversions with native
  MapKit projection. Keep a weak map reference for marker drags; discard stale
  marker state on disconnection/retry, backgrounding or route replacement.
  Hold/drag remains preview-only; Teleport is still an explicit confirmation.
- User-confirmed in build 63: keyboard Search works; route holding still exits
  the app. A supplied optional developer log records successful location writes,
  then `route_marker_hold_began`, followed by a new process. No jump was recorded.
  This identifies the interaction boundary, not the exact iOS exception or a
  verified fix. The supplied log does not include a retry attempt.
- Add draft-stop search with Along route/Everywhere scopes, route/result map,
  Coffee/Food/Groceries/Parks shortcuts, saved/recent places, addresses and
  distance from the path. Filter and deduplicate actual coordinates; order
  along-route matches and insert the chosen stop into the existing itinerary.
  Rebuild the preview without starting movement. Live-path pause stops retain
  their existing behavior; use Hold location and edit for a new destination detour.
- Bound explicit MapKit searches to four cancellable requests; reject stale
  results and disclose incomplete/long-route sampling. Distance from the path
  is not a claimed detour time. No Google dependency, key or background polling.
- Indent expanded Advanced/More options and give advanced child rows a subtle
  theme-colored rail. Keep native controls, accessibility and all existing options.
- Five portable corridor tests cover bent routes, invalid coordinates, bounded
  regions, long routes, date-line geometry, stop insertion and deduplication.
  Native validation passed: 565 tests, app/extension compilation and verified
  Downloads delivery in run 41176847512. Three existing warnings remain;
  phone acceptance is pending. Release remains unpublished.

## Route/search follow-up: 2.6.1 (63) — 30 October 2026

[Run 41174566247](https://github.com/N3moStudio/Elsepin/actions/runs/41174566247) passed at
source `f1ed08d91efbf7bfaf506d88b8fcc5bf358b4dd3`: 431 Swift tests, 14 packaging/icon tests,
19 Companion tests and 96 cloud-helper tests (560 total), native app/extension
compilation, signing and package checks. Both bundles are 2.6.1 (63), SDK 27.1.
Thirteen icons, compatibility identities, resources, ZIP integrity and GitHub's
SHA-256 were checked. Three existing certificate/delegate warnings remain;
no new warnings. The two earlier native attempts failed on Swift expression
complexity and produced no IPA; their complete logs are preserved.

Downloads: `C:/Users/naith/Downloads/Elsepin 2.6.1 build 63.ipa`
(18,306,911 bytes), SHA-256 `a544b5f7060d5c23b3099861dd880cc25af8a9537a9cff59228fe3c43b96dae5`.
Complete logs and receipt: `.build/artifacts/41174566247/`.
The actual phone crashes, Live Activity layout and Life360 MPH still require
device/provider retesting. Release remains an unpublished draft with zero assets.
The earlier Drive copy is unchanged.


Owners: RoutePlaceSearchSheet (general results/selection and request lifecycle),
MapHomeView (native hold coordinates, matching index, interruption),
RouteTiming + RouteBuilder + SpoofSession (cached moving-time estimates),
RoutePlannerSheet (simulated versus Apple time), LocusLiveActivity (bounded rows).
Compatibility: no data format, engine protocol, bundle/group/default key or
pairing-code lifecycle change. General search never sends a movement command.
Timing tests cover units, playback comparison, waits/seeks, sections, long
straight paths and cache invalidation. No crash report is available; phone
termination and layout acceptance remain unverified. See CURRENT-WORK for status.
Follow-up: `Shared/TripFeatures.swift` and `PrecisionControlsTests.swift` add
confirmation-aware update pacing, retain suspension/jump resets and test short
latency, slow-to-fast response transitions and reset behavior. No remote speed
field is injected or Life360 reading guaranteed. Native attempt 41173992580
failed after 557 passing tests on map-view type-check complexity; its raw logs
are retained and the closure was extracted before retry.

## Private UI IPA: 2.6.1 (62) — 30 October 2026

User authorized a private native build and Downloads delivery, excluding release
publication. Run `41126221099` passed at `a213d8b37a87759b0db719a9caa2ba571427330e`:
551 tests, native app/extension compilation, signature checks and packaging.
Artifact `13010842478` was downloaded and independently checked for integrity,
both bundle versions/identities, SDK metadata, resources and thirteen icons.
Downloads: `Elsepin 2.6.1 build 62.ipa`; SHA-256
`4d3ccac5a529b957a3ab2eb945747e2eae65d31b9c3837e6a7b8840d6f491d05`.
Three pre-existing certificate/delegate warnings remain; no new UI warnings.
Release 2.6.1 remains a draft with no assets. Device checks are in TESTING.md;
complete original logs and receipt are in `.build/artifacts/41126221099/`.

## Video-inspired UI polish — local, unbuilt — 30 October 2026

Reviewed all three supplied videos through sampled visuals and local transcripts.
Installed Damir Sokolovsky's `unslop` alongside existing skills, keeping its
original guidance/credit and the project's native constraints. [UI-POLISH](UI-POLISH.md)
records provenance, before/after decisions, exclusions and device acceptance.
Changed only pairing-sheet presentation and draft route-mode layout; engines,
Dynamic Island ownership, stored values, imports and manual confirmation remain.
57 focused tests and both Swift syntax checks passed. Responsive mockup checks
passed at 320/390/736px; native layout/compilation remain unverified for this pass.
No push, IPA, release, deployment or API-key use. Delivered build 61 is unchanged.
Preview feedback: retain Connected steps, remove the Pairing help section entirely.

## 2.6.0 (59) — Elsepin development — 26 October 2026

- Rebrand the regular app, setup/pairing prompts, notifications, Live Activities, helper downloads and backup filenames to Elsepin. Use Prism Jumpgate as the primary icon; retain all thirteen icon options and nine themes.
- Give Ion its dark olive canvas, solid panels and citron actions. Apply theme defaults for color mode, surfaces, font design and relative text size, with independent persistent overrides and a reset-to-theme control. Keep accessibility text sizes and Reduce Transparency respected.
- Replace translucent app-owned navigation/control surfaces when Solid is selected; keep one map and session alive during appearance changes. System-owned menus retain system behavior.
- Refresh Settings with an appearance card and clearer groups. Add Software updates and a manual stable-release check with progress, empty/error feedback, cancellation guards and server-requested cooldowns. Automatic checks remain foreground-only and once daily.
- Back up/review/import the new appearance settings individually, preserving older library files. Preserve existing bundle IDs, defaults, keychain services and widget links to protect upgrades.
- Add a responsive static website with nine interactive theme previews, thirteen icon choices, setup/privacy pages and no tracking or keep-alive requirement. Build assets from an explicit allowlist and reject stale unexpected output.
- Establish private Elsepin development and a public Elsepin-Releases download/help endpoint. Preserve inherited notices and accurately scope restrictions to identified new original files. Catalog dependencies and compatibility traps in the Product Atlas.
- Branding follow-up: remove the old product name from the incomplete-backup message and exported diagnostic-log description. Keep old backup formats, storage keys and notification IDs compatible. The public update endpoint returns no official release until one is published. Follow-up validation: 32 backup-import and diagnostic-log tests passed on WSL; no native rebuild or IPA. The first test invocation had a shell-quoting error; rerunning the existing compiled tests with direct argument passing passed.
- Validation: [private Mac run 40442493014](https://github.com/N3moStudio/Elsepin/actions/runs/40442493014) passed 533 automated tests (404 shared Swift, 14 packaging/icon, 19 Windows-helper, 96 cloud-helper) and native app/extension compilation at b5f5b24. Website phone-frame checks at 320/375/430/768 pixels showed no horizontal overflow; all preview images loaded. The static website is live at https://elsepin.onrender.com. Device appearance, provider, battery and accessibility acceptance remain pending. No new IPA or GitHub release.


The release log and source map for this fork. Update this ledger and
[CHANGELOG.md](../CHANGELOG.md) for every version/build; record failed or repaired
build attempts under the same entry without presenting an earlier success as a
later build's result. Dates use America/Los_Angeles. Commit descriptions should
name the behavior changed and the affected area.

### Documentation, workflow and build-record follow-up — 26 October 2026

- Refine the public README to a visual route banner, short feature list and prominent website/release links. Remove the development notice and long explanations; preserve the full changelog, build records and guides. No release is created by this presentation change.

- Refresh the public README with the app introduction, Prism Jumpgate artwork, feature groups, all nine themes/thirteen icons, setup, honest release status, optional-provider limits and support links.
- Preserve the entire earlier changelog and publish a synchronized public copy plus a build register. Record the two failed Elsepin attempts and their fixes, rather than reporting only the successful run.
- Run `40441280998` (`a863660`) failed during appearance initialization; `ea91bd2` fixes initialization ordering. Run `40441622492` then failed the icon-resource check because XcodeGen uses grouped paths; `b5f5b24` fixes that validation. Run `40442493014` passed 533 tests and native app/extension compilation. No IPA was packaged by any of these three runs.
- Simplify the manual workflow to **Build Elsepin IPA**: remove the packaging checkbox and validation-only artifact; keep automatic tests, identity/resource checks and one downloadable IPA for future runs. Update the maintainer build guide.
- Retain private application development and public downloads/help. This documentation/workflow update creates no IPA, tag or release and does not change app behavior. Previous successful native validation applies to its recorded source, not to an unrun future workflow.


## 2.5.8 / build 58 — official promotion (26 October 2026)

The maintainer tested the candidate and reported, "New app works beautifully! Make a full release as well!" This approves official publication of the exact existing build-58 IPA. It is general iPhone acceptance, not a claim that every provider, background, accessibility or battery scenario was tested.

- Reuse the inspected IPA from [Mac run 40414605689](https://github.com/N3moStudio/Shift/actions/runs/40414605689); no rebuild or executable/helper source change. Tested implementation commit: `4136e32e28f04858be41560bb1c7117de7f73732`.
- 526 passing tests (397 Swift, 14 packaging/icon, 19 Windows helper, 96 cloud helper), Xcode 27.1, both targets 2.5.8 (58), stable channel. Full artifact checks are recorded in the candidate entry below.
- Release asset: `Shift.2.5.8.ipa`, 18,140,782 bytes, SHA-256 `62e73269cccfcaf0da9bfa855768038f75145ae9b060ff9860ee58a916e62a08`. The existing draft asset digest and the Downloads copy were reverified before promotion.
- Publish [v2.5.8](https://github.com/N3moStudio/Shift/releases/tag/v2.5.8) as official Latest, with complete notes. Bring the tested changes into main; the release tag includes documentation-only promotion updates.
- Update README, changelog, release notes and build/update guidance. No hosted service deployment, new plan restriction or Veypax change. Find My People remains unavailable; cloud/Nearby integrations remain experimental.

## 2.5.8 / build 58 — release candidate (26 October 2026)

Requested: build a new IPA for device testing and prepare the release draft while it builds. Upload the complete implementation to `codex/shift-2.5.8-rc`; leave main and the published release unchanged until acceptance. Both targets use build 58. The binary uses stable update-channel metadata as a candidate for the eventual official release; this does not publish it or mark device testing complete.

Included: the appearance expansion below and all full-Shift 2.5.8 development changes. Release notes are drafted in `docs/releases/2.5.8.md`, with an iPhone checklist in `docs/releases/2.5.8-TESTING.md`. Find My People remains unavailable and cloud/Nearby providers remain experimental.

Validation — PASS:

- [Mac run 40414605689](https://github.com/N3moStudio/Shift/actions/runs/40414605689), attempt 1, source `4136e32e28f04858be41560bb1c7117de7f73732`; the uploaded source tree exactly matched the prepared local index before dispatch.
- 26 October 2026, 3:43–3:47 PM America/Los_Angeles; workflow 4m 9s, job 4m 3s. Xcode 27.1 (27A9275), iPhoneOS 27.1 SDK, arm64 app and widget/Live Activity extension, minimum iOS 18.
- All 526 tests passed: 397 Swift, 14 packaging/icon, 19 Windows-helper and 96 cloud-helper tests. Native compilation, strict signature/package verification and upload succeeded. No failed attempt or repair build.
- Artifact `12693729747`, 18,140,782 bytes; saved as `Shift 2.5.8 (58) - Test.ipa` in Downloads, preserving the older build-57 IPA.
- SHA-256 matches GitHub: `62e73269cccfcaf0da9bfa855768038f75145ae9b060ff9860ee58a916e62a08`.
- Independently verified ZIP integrity, both targets 2.5.8 (58), stable channel, existing bundle IDs/URL scheme/app group, Live Activities, all 13 icon declarations, SDK metadata, license notices and byte-for-byte matching helper archives.
- Existing certificate-API deprecation and Swift 6 delegate-isolation warnings remain, along with the checkout action's Node runtime migration warning. These are not new appearance-build failures. Physical iPhone/provider, automatic Home Screen treatments, gesture/accessibility and measured battery acceptance remain pending.
- Release notes are saved as an unpublished GitHub draft. Only documentation changes follow the tested source; publication and any main merge wait for device acceptance.

Publication is conditional on the maintainer's device test. No GitHub release is published and no cloud helper is deployed by this preparation.

## Appearance expansion — 26 October 2026 — local, unreleased

The maintainer approved adding all six proposed themes and four icon studies as options. Baseline: `main` at `c0e785cd3961fe5ae697e094a69b4a514451c06b`. The app stays Shift; no rebrand/name choice, plan restriction or unrelated feature proposal is implemented.

- Themes: Ion, Ember, Abyss, Bloom, Blueprint and Titanium, alongside Glacier, Afterhours and Porcelain. Each has a light and dark palette. The previous style remains selected; appearance keys and defaults are unchanged.
- Icons: A1 Ion Jumpgate, A2 Titanium Jumpgate, A3 Prism Jumpgate and B1 Ember Switchpath. Four additions plus the nine original choices; Glacier remains the primary icon. The new grid sits above the original groups and supports wrapping labels/Dynamic Type. A pending icon change disables competing taps and retains the existing lifecycle guard.
- Shared colors and simplified marks cover app, widgets and Live Activities. No new timer, polling, animated icon finish or background service. Notifications retain the Shift name. Manual Start/Teleport confirmation is unchanged.
- Catalog: `Shared/ShiftAppearance.swift`, `Shared/ShiftBrandViews.swift`, `Shared/Personalization.swift`, `Locus/Features/Settings/AppearanceSettingsView.swift`, icon catalogs/previews, `project.yml` and `Locus.xcodeproj/project.pbxproj`. Original approved art, prompts and digests live under `Brand/AppearanceIcons/`; deterministic exports use `scripts/prepare_approved_icons.py`.
- Production route: complete approved RGB artwork resized to 1024px opaque sRGB catalogs and 256px Settings thumbnails. No Icon Composer reconstruction or material redesign. iOS automatically treats dark/tinted appearances for the additions, following [Apple's asset-catalog workflow](https://developer.apple.com/documentation/xcode/configuring-your-app-icon). Original explicit variants remain intact.
- Validation: Swift 6.4 on local WSL/Linux, **397 logic tests passed**; **14 packaging/appearance tests passed** on Windows. Coverage includes all theme/icon combinations through widget serialization, unchanged old names/defaults, no nonexistent new finish combinations and 4.5:1 contrast for the tested foreground/background pairs in all 18 palettes. All four 1024px PNGs passed static size/profile/opacity preflight; all 13 choices and 31 supplied icon images passed resource checks.
- Limits: syntax/source/package evidence is not native iOS compilation or physical-device validation. Home Screen automatic treatments, icon switching, VoiceOver, large-text layout and device battery behavior need acceptance on iOS. No current build/IPA or release is claimed.

Distribution: local working changes only. Version remains 2.5.8 (57), channel prerelease. No commit, push, tag, GitHub release or deployment. Published v2.5.7 and Veypax are unchanged.

## Main consolidation — 26 October 2026 — no release

The maintainer requested bringing the latest full Shift development into `main` and deleting the two old branches. Baseline: `codex/shift-2.5.8-test` at `57e007863344ec11b3173d0f84d1e3b7a608ad6f`; existing main/tag v2.5.7 at `d4126c78ca81b693ebed1b13a53c18c08853c8ac`. The merge preview had no conflicts and its source tree matched the full test branch.

Included: all application/helper improvements in build 57, plus durable `main` guide links and current source/build documentation. The helper archive is regenerated from its explicit source manifest. Branding changes, commercial-edition restrictions and unfinished People research are excluded. Find My People remains unavailable.

Before cleanup, the 65 unfinished local files were archived with per-file SHA-256 verification and a full Git-history recovery bundle. The original experimental working folder and private state are preserved locally. Branch deletion removes obsolete branch labels; it does not publish the archived research.

Validation: [Mac run 40398031406](https://github.com/N3moStudio/Shift/actions/runs/40398031406) passed on 26 October 2026 for source `6e0244add7e987242ee144e40ce508fa26f7f225`, using Xcode 27.1. All 524 tests passed (395 Swift, 14 packaging/icon, 19 Windows-helper and 96 cloud-helper tests); identity, appearance and source-only archive checks passed, and the iOS app/extension compiled successfully. IPA packaging and upload were disabled. Only this validation record and its changelog entry changed afterward. Existing certificate-API deprecation and Swift 6 delegate-isolation warnings remain; the workflow also reports the checkout action Node runtime migration warning. Physical iPhone/provider, gesture/accessibility and battery acceptance still require device checks.

Distribution: no new release, tag, downloadable IPA or Render deployment. Source remains 2.5.8 (57) with the prerelease channel. Official Latest remains v2.5.7. Future development uses `main`; a release requires a separate explicit decision.

## 2.5.8 / build 57 — requested test IPA (25 October 2026)

The maintainer explicitly authorized uploading the app/helper changes to
`codex/shift-2.5.8-test` and building an IPA. Source baseline: `7e3a720`.
Main and official v2.5.7 stay unchanged. No new release/tag or Render deployment.
People research and unrelated prototypes remain local and are excluded.

Included: the cloud/Nearby work and motion fixes cataloged below; the reset and
Recently Deleted improvements already on the development branch; version/channel
metadata; a matching helper archive; and setup links pointing to this test branch.
The build script now rejects concurrent xcodebuild work instead of interrupting it.

Preflight evidence: 395 Swift logic tests, 96 cloud tests on Windows and Linux,
14 packaging/appearance tests, 19 Windows-helper tests, and the documented
browser layout checks. The uploaded source tree matched the prepared index
exactly before the build.

### Native build and downloaded artifact — PASS

- Source commit: `470aa3163c3e8a4eb91badb9659e725fd2fe64fe`.
- Source tree: `49005e796691a9e47bb6d62e355e0fe1f2a2378c`.
- [Mac run 40259930059](https://github.com/N3moStudio/Shift/actions/runs/40259930059),
  attempt 1: success, 25 October 2026, 7:36–7:42 PM America/Los_Angeles.
  Workflow duration 5m 42s; build job 5m 36s. Xcode 27.1, iPhoneOS 27.1 SDK,
  arm64 app and widget/Live Activity extension, minimum iOS 18.
- 524 passing tests: 395 Swift, 14 packaging/appearance, 19 Windows helper and
  96 cloud helper. Native compilation, signature/package validation and upload
  succeeded. No repair/rebuild was required.
- Artifact `12623778973`: `Shift 2.5.8.ipa`, 9,394,622 bytes. Downloaded to the
  maintainer's Downloads folder; ZIP integrity and the GitHub digest both match.
- SHA-256: `6ff4810cdab58e37e92aa3e848e34c834206ef825ebe2461abc20eb37c2afb5c`.
- Independently verified app/extension 2.5.8 (57), prerelease channel, unchanged
  bundle identities, Live Activities, 9 icon choices, SDK metadata, license
  notices and byte-for-byte matching Windows/cloud helper archives.
- Saved a short setup/test checklist and the matching cloud helper beside the
  IPA. Full reusable instructions are in [CLOUD-GUIDE.md](CLOUD-GUIDE.md).
- Existing non-blocking warnings remain: legacy certificate access in the two
  check clients, Swift 6 isolation diagnostics for LocationVerificationController
  while the project uses Swift 5 mode, and checkout@v4's Node runtime deprecation.
  This build is successful, not warning-free.
- Main and v2.5.7 still point to `d4126c78ca81b693ebed1b13a53c18c08853c8ac`.
  This documentation-only result entry follows the tested commit; no executable
  source or bundled guide is changed by the follow-up. No release or deployment.

Live Apple/Life360 sign-in, actual iPhone Web Push and touch/accessibility behavior
remain device acceptance checks even after a successful native build.

## Local development — cloud setup and Nearby alerts — 25 October 2026

**Status:** implemented locally for testing; version remains 2.5.7 (56). No native
IPA, commit, push, deployment or release. Earlier People research and motion work
remain intact. Provider/notification acceptance is not established by fixtures.

| Owner | Change |
| --- | --- |
| `Locus/Features/Settings/RemoteFindMyView.swift`, `FindMyChecksView.swift` | Remove long/collapsible cloud tutorials and uptime instructions; keep actionable status, switches, connection controls and one GitHub setup guide under Advanced. Nearby opens the helper website. Native list/navigation/button behavior stays intact. |
| `Locus/Support/RemoteFindMyController.swift` | Decode optional `nearby` support on explicit Test connection; reset on pair/unpair. Older helpers hide the new entry rather than opening a nonexistent path. No timer or native push changes. |
| `CloudFindMy/render_server.py`, `web_ui.py`, `static/style.css` | Compact reusable connection screens and separate Nearby dashboard/editor; keep existing auth/phone API. Add scoped same-origin script/worker policy and CSRF checks for notification actions. Responsive layouts, scalable fonts, visible keyboard focus, dark mode and Reduce Motion. |
| `CloudFindMy/nearby.py` | Bounded provider-independent place rules; valid coordinates/radius/duration, spherical distance, accuracy margin, two distinct observations after a baseline, stale/out-of-order/gap handling, once/fixed/escalating reminders, manual acknowledgement/pause/resume/delete. Authenticated encrypted atomic storage; restored rules always pause. |
| `CloudFindMy/nearby_web.py`, `web_life360.py` | Authorized source selection and independent minute-based cloud polling; Circle members do not replace the own-profile checker. Reject unlisted/mismatched/revoked member reports. Serialize provider access and discard late results after account changes or pause. No provider calls from health/page views. |
| `CloudFindMy/web_push.py`, `static/nearby.js`, `static/sw.js`, requirements | Opt-in Home Screen Web Push, test/unsubscribe, maximum five receivers, encrypted per-helper VAPID material, fixed delivery-service allowlist, no redirects, bounded requests/TTL, expired subscription cleanup, no service-worker caching of account pages. Dependency `pywebpush==2.5.0`; no native app dependency or entitlement changes. |
| `docs/CLOUD-GUIDE.md`, `CloudFindMy/RENDER-SETUP.txt` | Generic full setup, privacy, free-hosting limits, real test checklist and scope. New GitHub link remains unpublished until authorized publication. Guide is also in the source helper archive. |
| `scripts/package_helpers.py`, source helper zip | Explicit allowlist extended for the new source, assets, guide and tests. No private state, research connector or account credentials included. |

### Motion application

| Before | After | What this changes |
| --- | --- | --- |
| Long cloud help sections inside settings | Native settings rows plus an Advanced guide link | The app's setup page is shorter without a new navigation pattern. |
| Helper connection page mixes setup paragraphs and controls | Short cards and an external guide; separate place editor | Users see the next action without scrolling through a tutorial. |
| No shared web press treatment | Immediate `:active` feedback; 180 ms ease-out release limited to opacity/scale; Reduce Motion removes scale/transition | Buttons respond immediately and clear automatically when a press ends or is canceled. |

The supplied iOS Fluid Interactive Motion PDF was rechecked via its extracted
text and accessibility-page rendering. Native SwiftUI navigation and controls
retain their built-in interruption behavior. No custom gestures or per-frame
work were added. Battery/frame-rate improvements are not measured.

### Verification

- PASS: 96 cloud tests on Windows Python 3.12 and Linux/WSL ARM64, including 34
  new tests for rules, encrypted restart state, identities/sharing, CSRF/auth,
  push encryption/redirect handling, independent polling and cancellation.
- PASS: browser render/interaction checks at 320, 390, 768 and 1280 px; light/dark,
  Reduce Motion, 200% root text, no horizontal overflow or browser errors, empty
  state, unsupported push environment and separate editor. Headless Edge is not
  iPhone Safari/VoiceOver validation. Fictional preview data only.
- PASS: Swift syntax parse of the three changed Swift files. This is not native
  SDK compilation or type checking.
- PASS: existing 14 packaging/appearance tests, app identities and icon checks.
- PASS: helper archives verified against explicit source manifests (13 Windows,
  26 cloud entries, including the guide). No research/private files included.
- NOT RUN: live Apple/Life360 account acceptance; signed-iPhone Web Push receipt,
  background/Focus behavior; native iOS build; VoiceOver/device motion or battery
  profiling; public deployment, new IPA or release.

Local evidence: `.build/nearby-review/` (test logs, browser script and fictional
screenshots; ignored). Source-only payload can be reviewed without credentials.

### Scope and operational limits

The first implementation handles **fixed circular places** and enter/leave.
Moving real-me anchors, imported polygons, dwell rules and Find My People are not
included. The nearby website is the management/acknowledgement surface, with a
small entry in Shift. Direct native IPA push remains separate from Web Push.
One-hour monitoring is the default; Until I pause is an explicit choice.

Free Render can sleep, restart and erase local storage; no 24/7 or persistence
guarantee is claimed. If encrypted storage survives, rules/acknowledgements are
restored paused. Provider passwords stay memory-only. Acknowledgement prevents
new sends but cannot retract a push already accepted by the delivery service.

## Distribution policy

- Development work stays on `codex/shift-2.5.0` until explicitly promoted.
- Collect small fixes on the development branch; do not automatically build or
  publish a prerelease for each small fix. Use appropriate source checks, then
  make a distributable IPA when the user requests a release/device test or approves
  a batch for testing.
- Test releases are prereleases and must not replace the stable Latest release.
- On 24 October 2026 the maintainer explicitly approved promoting 2.5.4 to
  official. Build 53 embeds the stable channel; publish numeric tag `v2.5.4`
  as Latest and promote its source to `main` after validation.
- A new release includes version/build, exact changes, tested commit, workflow,
  validation, remaining device checks, installation notes and IPA checksum.
- Repository check on 23 October 2026: only the maintainer's **v2.4.4** release
  existed. Builds 48 and 49 were Actions artifacts, not published releases.

## Unreleased — tray and joystick interruption fixes (25 October 2026)

Continue the authorized local motion work on `codex/shift-2.5.0`, based on
`c42cd30` plus the earlier uncommitted button pilot. Keep 2.5.7 (56), existing
manual movement confirmation, session engine, navigation, identities and signing.
No Find My experiment or cloud configuration was changed in this follow-up.

| Files | Exact change |
| --- | --- |
| `Shared/ControlInteraction.swift`, `Tests/ControlInteractionTests.swift` | Small Foundation-only touch lifecycle, tray direction/release rules, finite joystick vector normalization and nudge ownership; 16 behavior tests |
| `Locus/Features/Map/RootView.swift` | GestureState cancellation rollback; lock handle axis; settle toward projected nearest anchor instead of picking direction from the older translation; gate interrupted touch updates; native 44-point expand/collapse button; cancel on visibility, size, scene and Reduce Motion changes; explicitly enable only the visible joystick |
| `Locus/Features/Joystick/JoystickPad.swift` | Stop movement before visual return on end/cancel; reject held input after interruption; direct unanimated finger tracking; damping fraction 1 return; live Reduce Motion, visibility and geometry cleanup; invalidate superseded accessibility nudges; inactive/hidden pad cleanup does not zero another pad's movement |
| `Locus.xcodeproj/project.pbxproj` | Register the shared rules in app/extension, matching `project.yml`'s existing Shared source inclusion; no settings/dependency changes |
| Motion audit, app map, changelog and this ledger | Exact behavior, local evidence, native acceptance gaps and rollback scope |

PASS: baseline 379 and updated **395 XCTest tests**, zero failures, using Swift
6.4 in local Ubuntu 24.04/WSL (ARM64). Logs:
`.build/motion-review/baseline-swift-tests.log` and
`.build/motion-review/control-swift-tests.log`; scratch build outside the checkout
at `/tmp/shift-control-qa`. This local toolchain was discovered during the
follow-up; the earlier Windows-only toolchain statement does not apply to WSL.
PASS: Swift frontend syntax parsing of the two changed views and shared rules;
14 existing packaging/appearance tests; identity and nine-icon/27-image checks;
diff whitespace check and source-registration review.

NOT RUN: native iOS/SwiftUI type checking or app build; device/simulator touch
event ordering and Button/drag arbitration; arbitrary tray re-grab during settle;
VoiceOver, Reduce Motion, rotation and size-class acceptance on hardware; frame,
power or hitch measurement. Linux unit tests exercise the shared rules, not iOS
gesture delivery. Full presentation-position/velocity continuity is not claimed.
The device checklist is in [MOTION-AUDIT.md](MOTION-AUDIT.md).

No new timer, frame loop, background service, version, artifact, remote CI,
commit, push, release or deployment. Existing uncommitted work is preserved.

## Unreleased — map button motion pilot (25 October 2026)

Apply the user-provided 27-page fluid-motion guide to Shift with a small native
control pilot. Source baseline: `c42cd30` on `codex/shift-2.5.0`; prior uncommitted
Find My research and documentation remain intact. No running iPhone baseline was
available, and no new commit or version was created.

| Files | Exact change |
| --- | --- |
| `Locus/Support/ShiftDesign.swift` | Add default-off `immediatePress` option to `ShiftActionStyle`; immediate pressed opacity/scale, scoped spring release (response 0.24, damping 1), Reduce Motion and disabled gates, existing legacy branch retained |
| `Locus/Features/Map/RootView.swift` | Opt in Pause/Resume, interrupted-trip recovery, Teleport/Start at pin, Stop spoofing and prepared Start route; action closures and session guards unchanged |
| `Locus/Features/Map/MapHomeView.swift` | Opt in Review route after drawing; readiness/point-count checks unchanged |
| `docs/MOTION-AUDIT.md`, app map and changelog | Source inventory, next priorities, exact pilot contract, before/after device matrix, evidence limits and targeted rollback |

PASS: 14 existing Python packaging/appearance tests; app/extension/URL/group
identity check; nine icon choices and 27 native appearance images; diff whitespace
check. These source checks do not validate SwiftUI compilation or motion feel.
NOT RUN: SwiftUI/native build, Swift reliability tests, recordings, iPhone/iPad
interaction, live Reduce Motion changes, VoiceOver/large-text/RTL acceptance,
60 Hz/ProMotion or battery measurements. That first pilot used Windows source
checks only; local WSL Swift was found in the follow-up above. Native compilation and the documented device matrix remain acceptance
gates before expanding the pilot. No synthetic timing benchmark is presented as
on-device evidence; no implementation-mirroring tests were added.

No runtime dependency, timer, custom recognizer, background work, data migration,
confirmation rule, app identity or deployment target changed. No IPA, remote CI,
commit, push, release or deployment. Official 2.5.7 (56) remains unchanged. The
Find My People experiment was not changed by this motion work.

## Unreleased — reset controls and bulk deletion (25 October 2026)

Development source only. No version/build increment, IPA, tag or release for this
batch. Official 2.5.7 and main remain the released code. See
[reset behavior and device checks](RESET-AND-RECENTLY-DELETED.md).

| Files | Responsibility / exact change |
| --- | --- |
| `Shared/AppResetRules.swift`, `Locus/Support/AppResetController.swift` | Three reset scopes, explicit owned preference keys, idle/worker gates, ordered failure reporting, pairing/setup last |
| `AppResetSection.swift`, `ConnectionDetailsView.swift`, `Shared/Personalization.swift` | Advanced settings entry, two wipe choices, destructive review, Cancel and reset search aliases |
| `LocusApp.swift`, `RootView.swift`, `AppPrivacyController.swift` | Disable interaction/imports during reset, authenticate protected-app resets, rebuild drafts, preserve mandatory manual widget confirmation |
| `SpoofSession.swift`, `PairOnDeviceService.swift`, `LocationEngine.swift`, `SessionPreferences.swift`, `ShiftAppearanceController.swift` | Clear in-memory library/settings, track actual native pairing worker lifetime, await installed default icon |
| `TripLibrary.swift`, `TripRecoveryStore.swift`, `DeveloperLogStore.swift`, `ReliabilityRecorder.swift`, `RecentlyDeletedStore.swift` | Explicit local storage deletion with errors; drain queued recovery/log writes; allow confirmed wipe of unreadable library files |
| `CompanionClient.swift`, `RemoteFindMyController.swift`, `HomeWidgetPublisher.swift`, `StableReleaseUpdates.swift`, `AppUpdateController.swift` | Remove only app-owned helper Keychain entries; clear shared widget catalog; discard obsolete update responses after wipe |
| `Shared/DeletedLibraryItem.swift`, `RecentlyDeletedView.swift` | Mixed-type multi-selection, immutable confirmation scope, stale/expiry checks, one atomic save and retryable failure |
| `AppResetTests.swift`, `DeletedItemsSelectionTests.swift`, `DeveloperLogTests.swift`, `StableReleaseUpdatesTests.swift` | Scope preservation, idle guards, ordered failures, native-worker gate, selection/atomic failure cases, pending writes and late responses |

Validation: [Mac run 40222489196](https://github.com/N3moStudio/Shift/actions/runs/40222489196),
job 121256869769, tested commit `2c553bc73411f6c905af500b59391f4a036e281a`,
passed all **474 tests** (379 Swift, 14 packaging/icon, 19 Windows helper, 62 cloud
helper). Xcode 27.1 (27A9275) compiled the app and widget extension successfully;
the job took 4m 17s and native compilation 2m 22s. `package_ipa` was off, and
both IPA packaging/upload steps were skipped. No new artifact or release.

Local WSL Swift tests also passed 379/379 with no warnings after the test's actor
annotation was corrected. Identity, all nine icons, helper archive integrity and
whitespace checks passed. Source catalog refreshed: 311 files, 156 Swift files.
The remaining native warnings are the existing certificate API deprecations,
location-delegate actor-isolation warning and checkout action's Node 20 notice.
No user/device data or pairing was wiped during implementation/tests. Physical
iPhone reset/authentication/pairing/icon acceptance remains pending, as listed in
the device checklist. Subsequent commits only record this validation evidence.

## 2.5.7 / build 56 — official release (25 October 2026)

The maintainer explicitly requested a full official release of this batch and
all prior test-only backup improvements. Both targets use 2.5.7 (56); the app
channel is stable. Publish numeric tag v2.5.7 as Latest after native validation,
with the tested implementation promoted to main and exact IPA attached.

The maintainer's widget rule is mandatory: widget taps only prepare a pin/route;
they never send a location or start/stop a session, even if spoofing is already
active. The new per-instance Location shortcut widget resolves a current saved
place or route start by ID, without falling back to another location if deleted.
The app's existing unlock/setup gates still apply. Teleport/Start remains a
separate explicit in-app action. The older widget kinds and links are retained.

| Files | Responsibility / exact change |
| --- | --- |
| `Shared/BackupImportReview.swift`, `Locus/Features/Settings/BackupImportReviewView.swift` | Actual differences in overview; changed settings first; apply-time settings/session guard; library-only imports while active |
| `LibraryBackupView.swift`, `LibraryBackupInput.swift`, `SettingsView.swift`, `ConnectionDetailsView.swift` | Shorter import UI, Everything-first exports, json.site link, removal of host-specific and redundant help |
| `Shared/NamedArea.swift`, `Shared/LibraryBackup.swift`, `Locus/Engine/SpoofSession.swift` | Interior-overlap detection and persistence/import validation; shared borders and same-name pieces; legacy preservation |
| `NamedAreasView.swift`, `PathEditorSheet.swift`, `SketchMapView.swift` | Cached gray reference outlines/labels, edit-map context and actionable overlap errors without resetting the camera |
| `Shared/WidgetLibrary.swift`, `HomeWidgetPublisher.swift` | Bounded shared name/ID catalog, backward-compatible snapshots, independent target resolution and event-driven refresh |
| `LocusActivity/LocusHomeWidgets.swift`, `LocusLiveActivity.swift`, `RootView.swift`, `HomeWidgetsSettingsView.swift` | Native configurable widget, searchable saved targets, preview-only route-start link and manual-start instructions |
| `Tests/AreaOverlapTests.swift`, `WidgetLocationTests.swift`, `BackupImportReviewTests.swift` | Geometry, legacy/current selection, missing targets, no command calls from widget handler, session gates and sorted differences |
| `project.yml`, checked-in Xcode project, release/readme/build/backup/widget guides, source map and ledger | Stable build metadata, comprehensive public changes and release provenance |

Local testing caught and repaired a date-line projection bug: each polygon must
be unwrapped around its own first vertex before comparing, so a distant area
cannot appear to span Greenwich. All later validation must use that corrected
implementation. All 360 local Swift tests passed after the repair. App identity,
appearance and whitespace checks also passed locally.

Release validation:
- Tested commit: `2cacea4f3ca568312f5e266781decdb9bb2e6371` on `codex/shift-2.5.0`.
- Mac run [40215371297](https://github.com/N3moStudio/Shift/actions/runs/40215371297),
  job `121235253700`, completed successfully in **5m 14s** (job **5m 8s**).
- **455 tests passed**: 360 Swift, 14 packaging/icon, 19 Windows helper and 62
  cloud helper tests. Xcode **27.1 (27A9275)** compiled the app and widget extension.
- Downloaded `Shift 2.5.7.ipa`: **9,244,137 bytes**. ZIP integrity, all nine icon
  choices, iOS SDK 27.1 links, independent bundle IDs, both targets' **2.5.7 (56)**
  metadata and the **stable** channel were verified. Binary markers include the
  import overview, required manual Teleport notice and new ShiftLocation widget.
- SHA-256: `17982b0862722b0d02b4e0097f199959a1c285de798114067312b35908f3b468`.
  It matches Actions artifact **12608095025** exactly.
- Existing certificate API deprecations and the LocationVerificationController
  actor-isolation warning remain; checkout also reports its Node 20 deprecation.
  No new widget/area/import compiler warning or error was reported.
- Distribution: official numeric tag **v2.5.7**, stable Latest release, with the
  exact tested IPA. Promote the implementation to main; only release-evidence
  documentation changes follow the tested commit. No extra prerelease is created.

Actual iPhone widget configuration, active-session manual confirmation, map
rendering and Files/Paste acceptance remain device checks.

## 2.5.6 / build 55 — selective import test IPA (25 October 2026)

Requested by the maintainer: one importer analyzes a settings-only, library-only
or combined file, previews each change, and lets the user check individual items.
The Settings destination is now **Import & export** (old search keywords still work).
The review separates Settings, Routes, Saved Places and Named Areas into expandable
groups. Settings start unchecked; new library items start selected. Same settings
and existing library identities are labeled and disabled. No overwrite of local
routes, names or boundaries is introduced. Speeds retain internal MPH meaning
even when only a preset, without its display unit, is selected.

Export offers Settings only, Routes/places/areas, or Everything. The v1/v2 format,
legacy optional-field behavior and file/Paste protections are preserved. Capacity
is checked for the selected subset. A confirmation snapshot detects changes to
the live library/preferences before commit. Route-file saves happen before
preference writes; a route-save failure leaves settings unchanged. This is not
a claim of a single atomic transaction across the separate persistence stores.

| Files | Responsibility |
| --- | --- |
| `Shared/BackupImportReview.swift` | Typed 25-setting diff, item selection, keep-current identity rules, selected-subset capacity and merged preferences |
| `Locus/Features/Settings/BackupImportReviewView.swift` | Expandable review, per-item checks, current/imported values, summary, final confirmation and stale-context guard |
| `Locus/Features/Settings/LibraryBackupView.swift`, `Shared/Personalization.swift` | File/Paste entry, renamed destination/search, separate/combined exports, persistent selection and LiveContainer help |
| `Tests/BackupImportReviewTests.swift` | Exact sample reading, independent selections, unchecked-field preservation, legacy defaults, duplicates, capacity and confirmation context |
| `docs/Shift-Settings-Test.json`, `docs/Shift-Routes-Areas-Test.json`, `docs/IMPORT-TEST-CHECKLIST.md` | Separate safe test samples and exact values/device acceptance steps |
| `project.yml`, `Locus.xcodeproj/project.pbxproj` | Version 2.5.6 (55), prerelease channel, source registration |

Local validation: all 347 Swift tests passed, including 11 new review tests.
The first new-test attempt caught an incorrect expected difference count
(19 versus 20); the expectation was corrected before distribution. App identity
and all 9 icon choices passed source checks. Uploaded Swift line endings were
normalized to the repository policy before the build; the local index matched
the remote tested tree exactly.

Build 55: [run 40211268590](https://github.com/N3moStudio/Shift/actions/runs/40211268590)
tested commit `e3518c5be29bc2bdd5f317b6904462ac98ab0ecb`. **442 tests passed**
(347 Swift, 14 packaging/icon, 19 Windows-helper, 62 cloud-helper), followed by
native app + Live Activity extension compilation and IPA packaging with
Xcode 27.1 (27A9275). Total 3m 31s; job 3m 26s. Existing certificate API and
location-delegate isolation warnings remain in unchanged sources. The workflow
also reports the existing checkout action's Node 20 deprecation. No warning was
reported for the new import review sources.

The inspected IPA is 9,200,702 bytes, SHA256
`f6a65cc9a28cdf5615f4626244f59320abe8252b4617dc783da2bc1277d0e6c2`,
matching GitHub artifact `12606315849`. Both targets are 2.5.6 (55),
the app channel is prerelease, all 9 icon choices pass inspection, and the
compiled review/Paste/LiveContainer strings are present. Delivered to Downloads
as `Shift 2.5.6 Test Build 55.ipa`, alongside the two separate test JSONs and
`Shift-2.5.6-Import-Checklist.md`. This follow-up records evidence and only changes
documentation; executable sources remain identical to the tested commit.

No new release or tag was created. Verified Latest remains official `v2.5.4`
and main remains `b5917348e44e973ae384790c9baeeb55723c8158`.
iPhone/LiveContainer file-provider behavior, checkbox accessibility, navigation
and actual persistence after relaunch require device acceptance; they are not
inferred from model tests, native compilation or packaged UI strings.

## 2.5.5 / build 54 — requested test IPA (25 October 2026)

The maintainer requested a downloadable IPA and sample JSON after the source-only
validation below. Both targets are now 2.5.5 (54), with the app release channel
set to `prerelease`. This build is an Actions artifact, not a new GitHub release;
official `v2.5.4` and `main` stay unchanged. `project.yml` and the checked-in Xcode
project own this metadata; README, build/backup guides and the app map distinguish
the test build from the official release.

`docs/Shift-Import-Test.json` contains two labeled test places and one
drawn route, with 15-second and 90-second stops. After the build completed, the
maintainer requested settings too; the revised sample includes every supported
backup preference and the backup guide lists their exact expected values. A new
regression in `Tests/BackupImportReaderTests.swift` checks this exact sample via
file and Paste readers, route/stop preservation and duplicate-free reimport. The
post-build revision also compares all imported preferences to explicit expected
values and confirms settings can be deselected.
The sample is also copied to Downloads for the requested phone test.

Local sample validation initially caught an incorrectly encoded route-source enum
(string instead of the existing keyed Codable representation). The sample was
corrected before distribution; app decoding rules were unchanged.

Build 54 validation: [run 40208929771](https://github.com/N3moStudio/Shift/actions/runs/40208929771)
tested commit `59f490048d7ea77983a13f679eff37f1c3c4d176` and passed **431 tests**
(336 Swift, 14 packaging/icon, 19 Windows-helper, 62 cloud-helper), native app +
Live Activity extension compilation, signing/package checks and IPA inspection
with Xcode 27.1. Total 2m 36s; job 2m 31s. Existing certificate/delegate warnings
remain in unchanged files, as documented below.

The downloaded IPA is 9,118,148 bytes, SHA256
`4e343981901827746db384a2e90e1b96e31a6a4b40abe3b8ac0d5768e8f53104`, matching
GitHub artifact `12604763595`. Both targets are 2.5.5 (54), the app channel is
`prerelease`, all 9 icon choices pass inspection, and the compiled backup UI is
present. It is saved as `Shift 2.5.5 Test Build 54.ipa` in Downloads. No release
or tag was created; stable Latest/main remain unchanged.

The full-settings sample was updated after this IPA was built. All 11 local
backup-reader tests passed again, including exact preference values. Only the
sample, its test and documentation changed after the tested commit; executable
app/extension sources are identical. No second IPA build was needed. Signed
iPhone/LiveContainer acceptance is still a separate check.

### Initial source-only work — backup import (24 October 2026)

At this initial stage no version/build was assigned and no IPA/release was
published. Official `v2.5.4` and `main` retained build 53. Development work adds file-data selection and
a native Paste backup text action, with shared validation, guarded presentation,
off-main-thread coordinated reads, preserved previews and LiveContainer guidance.

| Files | Responsibility |
| --- | --- |
| `Shared/BackupImportReader.swift` | Bounded file/text reading, content validation, immutable worker result and late-result/cancel protection |
| `Locus/Support/LibraryBackupInput.swift` | Screen-owned picker, scoped access, worker lifecycle, exactly-once callbacks and no synthetic teardown cancellation |
| `Locus/Features/Settings/LibraryBackupView.swift` | File/Paste choices, shared preview and existing merge confirmation, LiveContainer help |
| `Tests/BackupImportReaderTests.swift` | Ten regressions covering old/current backups, exact routes, duplicates, malformed input, file/text caps, original preservation and cancellation |
| `Locus.xcodeproj/project.pbxproj` | Register the two new source files in their proper targets |
| `.github/workflows/build-ipa.yml`, `docs/BUILDING.md` | Default to tests/native compilation; package an IPA only when explicitly selected |
| `docs/BACKUPS.md`, `SETUP.md`, `README.md`, `docs/APP-MAP.md`, `CHANGELOG.md`, this ledger | Current workaround, upcoming feature instructions, ownership and unreleased status |

Validation: local Swift suite passed 335 tests. The first local attempt caught a
new test fixture assigning an immutable coordinate; replacing the whole point
fixed the fixture. [Mac run 40167635354](https://github.com/N3moStudio/Shift/actions/runs/40167635354)
tested commit `96fb68df7bc8d44396a192f5e858c452fdcab049`: 430 tests passed
(335 Swift, 14 packaging/icon, 19 Windows-helper and 62 cloud-helper), followed
by successful native app + Live Activity extension compilation with Xcode 27.1.
Total run: 4m 56s; job: 4m 50s. IPA packaging/upload were explicitly skipped and
the run has zero artifacts. Documentation-only follow-ups record this evidence;
they do not change the tested executable sources. Existing certificate API
deprecations and location-delegate isolation warnings remain in unchanged files;
no warning was reported for the new backup sources. LiveContainer/iPhone UI
acceptance remains pending and is not inferred from automated tests.

## Build register

| Version / build | Date | Changes | Validation / distribution |
| --- | --- | --- | --- |
| 2.5.0 / 48 | 22 Oct 2026 | Seconds-based stops; mph/km/h with exact conversions; separate Shift app/extension IDs and app group; notification routing; pairing validation; logging opt-in; Library empty states and About accessibility | [Run 39913718958](https://github.com/N3moStudio/Shift/actions/runs/39913718958), commit `9525f0916ee7a99d3e85a2eb75c351049404db8b`: 373 tests passed (290 Swift, 14 packaging, 19 Windows, 50 cloud); app + extension + packaged IPA passed. Actions artifact only. |
| 2.5.1 / 49 | 23 Oct 2026 | Compact active-route controls; numbered planner; wait presets / Apply to all; preview scrubbing / stop jumps; deferred icon preferences and restored tab | [Run 39986538008](https://github.com/N3moStudio/Shift/actions/runs/39986538008), commit `275eb1791ed6d18df049e8f3852eff6370d41bd6`: 377 tests passed (294 Swift, 14 packaging, 19 Windows, 50 cloud); app + extension + packaged IPA passed. User confirmed installation; icon smoothness and full device matrix remain unverified. Actions artifact only. |
| 2.5.2 / 50 | 23 Oct 2026 | Hours/minutes/seconds up to 24 hours throughout route waits; long-duration display; validation and persistence coverage; maintained source/change map and verification guidance | [Run 40052908812](https://github.com/N3moStudio/Shift/actions/runs/40052908812), commit `b451c9d2362eed965a4f591ece96609d019b74da`: 384 tests passed (301 Swift, 14 packaging, 19 Windows, 50 cloud); Xcode 27.1 app + extension + packaged IPA passed in 3m 23s. Prerelease `v2.5.2-beta.1`; device acceptance pending. |
| 2.5.3 / 51 | 23 Oct 2026 | Cloud Life360 alongside Find My; one Live Activity with separate service statuses and visibility; clearer cloud recovery; free uptime setup | [Run 40066390461](https://github.com/N3moStudio/Shift/actions/runs/40066390461), commit `fe62fb4e11493fff14fdc663ba0f2bbb1e6da579`: 402 tests passed (307 Swift, 14 packaging/icon, 19 Windows, 62 cloud); Xcode 27.1 app + extension + packaged IPA passed in 2m 33s. Prerelease `v2.5.3-beta.1`; real provider sign-in and device acceptance pending. |
| 2.5.4 / 52 | 24 Oct 2026 | Official-only daily GitHub update check; dismissible Settings card; exact release links; cached conditional requests and beta-to-stable comparison | [Run 40152801782](https://github.com/N3moStudio/Shift/actions/runs/40152801782), commit `b1abc21a5ac6a1c63b3717b3f39a8a04b8876365`: 420 tests passed (325 Swift, 14 packaging/icon, 19 Windows, 62 cloud); Xcode 27.1 app + extension + packaged IPA passed in 2m 51s (job 2m 45s). Prerelease `v2.5.4-beta.1`; device layout/VoiceOver and energy measurement pending. |
| 2.5.4 / 53 | 24 Oct 2026 | Official promotion of build 52 feature set; stable embedded update channel; updated release policy and public documentation | [Run 40153593002](https://github.com/N3moStudio/Shift/actions/runs/40153593002), commit `6af7c117af4cd4bb6ef97a6cf158c7d99819aae6`: 420 tests passed (325 Swift, 14 packaging/icon, 19 Windows, 62 cloud); Xcode 27.1 app + extension + IPA passed in 2m 51s (job 2m 47s). Official `v2.5.4`, Latest; no feature-logic changes from beta 52. |
| 2.5.5 / 54 | 25 Oct 2026 | File/Paste backup import, guarded picker, bounded reads, LiveContainer guidance, detailed sample JSON | [Run 40208929771](https://github.com/N3moStudio/Shift/actions/runs/40208929771), commit `59f490048d7ea77983a13f679eff37f1c3c4d176`: 431 tests, app + extension + IPA passed; Actions artifact only, prerelease channel; no GitHub release. |
| 2.5.6 / 55 | 25 Oct 2026 | Per-setting before/after review; independent routes/places/areas selection; separate exports and test files; keep-current and confirmation guards | [Run 40211268590](https://github.com/N3moStudio/Shift/actions/runs/40211268590), commit `e3518c5be29bc2bdd5f317b6904462ac98ab0ecb`: 442 tests, app + extension + IPA passed; Actions artifact only, no GitHub release. |

Build 48 IPA SHA256: `48db5d6715a90dc5f31551653f0f09020f3de6ae71948a0948e0f0a876827848`.
Build 49 IPA SHA256: `e9e6741540732baa2a6def85a9bb3497d8f8f3c48c32f4306e7722a5174be23e`.
Build 50 IPA SHA256: `28a918c6b78f244966a8761e61800d9ef2d1f767c3f74ab5755946880f8ac916`
(8,958,279 bytes). The release source includes documentation-only follow-ups
recording this result and build 49's earlier attempt; executable sources match
the tested commit above.

### Build 49 attempts

- 09:21 PDT: [run 39986065262](https://github.com/N3moStudio/Shift/actions/runs/39986065262),
  commit `eeec785f480badc5e81d4b3066bc733c9ff2a12c`, succeeded in 2m 44s.
  Initial interface build; IPA SHA256
  `fd400d8842c27ac668fba2b3fa36ed26e14e081ddb6f7b6184b278e020b11470`.
- 09:24 PDT: [run 39986538008](https://github.com/N3moStudio/Shift/actions/runs/39986538008),
  commit `275eb1791ed6d18df049e8f3852eff6370d41bd6`, succeeded in 2m 58s.
  Follow-up in `RouteEditorViews.swift` and `RoutePlannerSheet.swift`: name the
  orange preview dot accurately for accessibility, direct reordering help to the
  route timeline, and explain retained section settings on saved paths. This is
  the build 49 IPA delivered to the user. No additional version number was assigned.

### Build 51 attempts

- 22:22 PDT: [run 40066022555](https://github.com/N3moStudio/Shift/actions/runs/40066022555),
  commit `8611c80f80df895688f0365b003debbef003cf7f`, succeeded in 2m 39s.
  Initial cloud/dual-provider activity build: 402 tests passed (307 Swift,
  14 packaging/icon, 19 Windows-helper, 62 cloud-helper), then Xcode 27.1
  compiled the app and extension and packaged the IPA. Artifact: 9,008,015 bytes;
  SHA256 `2f478350807aeada584b34363d6eef6ba8296ab734ec53328e332c69f261d645`.
- 22:28 PDT: [run 40066390461](https://github.com/N3moStudio/Shift/actions/runs/40066390461),
  commit `fe62fb4e11493fff14fdc663ba0f2bbb1e6da579`, succeeded in 2m 33s.
  The same 402 tests passed; Xcode 27.1 built the app/extension and the final IPA
  passed packaging checks. Downloaded IPA: 9,012,586 bytes; SHA256
  `dcd0bfb046019014acca9140bcc6464068abcd639f5089faed308a915a53507b`.
  Both app and extension identify as version 2.5.3, build 51.
  Follow-up in `LocusActivity/LocusLiveActivity.swift`: one compact status/age
  row per service in the expanded Island, and the command timer appears only
  in its existing top corner. Full descriptions remain on the Lock Screen and
  in accessibility labels. This is the IPA delivered in prerelease
  `v2.5.3-beta.1`. The release source adds documentation-only result updates;
  executable and bundled helper sources remain identical to the tested commit.

### Build 52 attempt

- 24 October 2026, 19:00 PDT: [run 40152801782](https://github.com/N3moStudio/Shift/actions/runs/40152801782),
  commit `b1abc21a5ac6a1c63b3717b3f39a8a04b8876365`, succeeded in 2m 51s
  (build job 2m 45s). All 420 tests passed: 325 Swift, 14 packaging/icon,
  19 Windows-helper and 62 cloud-helper. Xcode 27.1 compiled the app and
  extension; packaging and identity checks passed. The 325-test Swift suite
  also passed locally before upload, including 18 new update regressions.
- Downloaded IPA: 9,079,398 bytes. SHA256
  `e09603f60d3c490f2ddb22edbfd81a0dd80aead0881db59c1250045834fcb1de`,
  matching the Actions artifact digest. ZIP integrity passed; app and extension
  both identify as 2.5.4 (52), and the app's resolved release channel is
  `prerelease`. Bundle IDs remain `com.n3mostudio.shift` and
  `com.n3mostudio.shift.activity`.
- Prerelease `v2.5.4-beta.1` includes documentation-only validation updates
  after the tested commit. Executable sources and bundled helpers match that
  commit. Stable `v2.4.4` remains Latest. No update card is expected for this
  beta while the official feed remains older. Physical-iPhone layout,
  VoiceOver and energy measurements are still acceptance checks; no zero-energy
  or measured battery-saving claim is made.

### Build 53 official promotion

- 24 October 2026, 19:12 PDT: [run 40153593002](https://github.com/N3moStudio/Shift/actions/runs/40153593002),
  tested commit `6af7c117af4cd4bb6ef97a6cf158c7d99819aae6`.
  All 420 tests passed (325 Swift, 14 packaging/icon, 19 Windows-helper,
  62 cloud-helper); Xcode 27.1 built both targets and packaged the IPA.
  Total duration 2m 51s; build job 2m 47s.
- Downloaded and verified IPA: 9,079,399 bytes. SHA256
  `6efa0a1aa3179e61cb29d126e7c77ef2517486c22c2fcb69255b9dcf0e371853`,
  matching the Actions artifact. ZIP integrity passed, both target versions are
  2.5.4 (53), and the compiled app embeds `ShiftReleaseChannel = stable`.
- Only channel/build metadata changed from beta 52; feature logic and bundled
  helpers are identical. Source promotion to `main` and tag `v2.5.4` include
  documentation-only validation follow-ups after the tested commit. The official
  release includes the complete build 48–52 change history, migration instructions
  and this build's validation. Beta tags remain historical prereleases.
- Exact changes for this promotion: `project.yml` and the checked-in Xcode
  project set stable/53; `README.md`, `CHANGELOG.md`, `docs/APP-MAP.md`,
  `BUILDING.md`, `UPDATES.md` and this ledger record official distribution and
  the maintainer's policy to collect small fixes before requesting another IPA.
  Physical-iPhone/provider acceptance and measured energy usage remain pending.

## 2.5.2 change inventory

| Files | Exact responsibility / change |
| --- | --- |
| `Shared/SpeedUnit.swift` | One 0–86,400-second range, validation, component editing and h/m/s formatting. Aggregate totals do not inherit the per-stop cap. |
| `Shared/TripFeatures.swift`, `Shared/RouteLifecycle.swift` | Saved-route and live-insertion validation use the same duration rule. |
| `Locus/Engine/RoutePlanner.swift` | Draft edits, all-stop edits, added path stops and place edits retain waits through 24 hours. |
| `Locus/Features/Routes/StopDurationControl.swift` | Three labeled time wheels, accessibility menus, six presets, 24-hour boundary, pause explanation; existing cancelable sheet and Apply to all retained. |
| `Locus/Features/Routes/RoutePlannerSheet.swift`, `RouteEditorViews.swift`, `TripViews.swift` | Readable route-total, rehearsal and active-stop countdowns. |
| `Tests/SpeedUnitTests.swift`, `RouteLifecycleTests.swift`, `TripFeaturesTests.swift`, `LibraryBackupTests.swift`, `RouteEditingTests.swift` | Seven new regression tests: all selectable seconds; component edits; labels/totals; live insertion; countdown/recovery/save; backup bounds; preview pause/seek. Update two old one-hour assertions. |
| `project.yml`, `Locus.xcodeproj/project.pbxproj` | App and extension version 2.5.2, build 50. Identities unchanged. |
| `README.md`, `CHANGELOG.md`, `docs/TESTING-2.5.md` | Current feature description, dated history and concrete device checklist. |
| `docs/APP-MAP.md`, `docs/VERIFICATION.md`, this ledger | Maintained ownership map, existing verification capabilities and explicitly proposed improvements. |

No rebrand, new helper deployment, Life360 Island integration or monitoring
subscription is included in build 50. Existing preferences, saved seconds,
bundle IDs, helper credentials and migration behavior stay compatible with 2.5.x.
Older versions may reject backups containing stops longer than one hour.

See [App map](APP-MAP.md) for the broader catalog and [device checks](TESTING-2.5.md)
for what an automated build does not prove.

## 2.5.3 change inventory

| Files | Exact responsibility / change |
| --- | --- |
| `CloudFindMy/web_life360.py`, `render_server.py`, `requirements.txt` | Async memory-only Life360 observer adapter; protected browser setup, independent provider stores/polling; optional response/capability fields; legacy Apple clients remain valid |
| `CloudFindMy/test_life360.py`, `test_render.py` | Twelve new tests for consent/auth/CSRF, report time, selected profile, provider isolation, lease expiry, stop races, readiness and pinned-library API; extend existing status expectations |
| `Shared/RemoteFindMy.swift`, `CloudServiceChecks.swift` | Optional provider-validated Life360 response; local/cloud verdict agreement, independent freshness, source language and transport error mapping |
| `Locus/Support/RemoteFindMyController.swift`, `CompanionClient.swift` | Per-service cloud consent, old-helper handling, independent evidence and Life360 warnings; existing Windows reports also reach the activity |
| `LocusActivity/LocusLiveActivity.swift`, `Shared/SessionPresentation.swift`, `Locus/Engine/SessionActivityController.swift`, `SpoofSession.swift` | One activity containing both services, separate compact icons and ages; one compact row per service and one command timer in expanded Island; clear both when ending |
| `Locus/Support/SessionPreferences.swift`, `Locus/App/LocusApp.swift`, `Shared/LibraryBackup.swift` | Persist visibility, refresh immediately, optional backup fields without copying service consent or secrets |
| `Locus/Features/Settings/RemoteFindMyView.swift`, `FindMyChecksView.swift`, `ConnectionDetailsView.swift`, `SessionSettingsSections.swift`, `Shared/Personalization.swift` | Find My & Life360 entry, readiness/errors, checking versus visibility, uptime URL sharing and free setup |
| `Tests/CloudServiceChecksTests.swift` | Six tests for compatibility, isolated failures/freshness, local evidence, provider identity, bounded activity payload and errors |
| `scripts/package_helpers.py`, `Locus/Resources/Elsepin-FindMy-Cloud.zip` | Deterministic source-only cloud download includes Life360 adapter/tests |
| `project.yml`, `Locus.xcodeproj/project.pbxproj` | App/extension 2.5.3 build 51; shared service model in both targets |
| `README.md`, `CHANGELOG.md`, cloud setup/checklist, `docs/APP-MAP.md`, `TESTING-2.5.md`, `VERIFICATION.md`, this ledger | Current capabilities, helper upgrade, limits, ownership and acceptance checks |
| `docs/BATTERY-OPTIONS.md` | Twelve proposals for approval only; no battery optimization implementation |

External Apple/Life360 login and physical-iPhone Island/background behavior are
not claimed as verified by unit tests. No cloud account was provisioned or paid
plan selected. Deploy the updated helper separately and sign in to each provider.


## 2.5.4 change inventory

| Files | Exact responsibility / change |
| --- | --- |
| `Shared/StableReleaseUpdates.swift` | Numeric stable versions, strict release URL validation, persisted 24-hour attempt/cache/dismissal/rate-limit state, one in-flight anonymous conditional request and cancellation |
| `Locus/Support/AppUpdateController.swift`, `Locus/App/LocusApp.swift` | App-owned update state and a cancelable foreground-only check; no new timer or background mode |
| `Locus/Features/Settings/AppUpdateNotice.swift`, `SettingsView.swift` | Native dismissible notice, exact More info link, retained About details, accessible controls and Settings appearance check |
| `Shared/Personalization.swift` | Updates/official release search aliases lead to About Shift |
| `Locus/Resources/Info.plist`, `project.yml`, `Locus.xcodeproj/project.pbxproj` | Explicit app release channel; app/extension 2.5.4 build 52; new source membership |
| `Tests/StableReleaseUpdatesTests.swift` | Update detection, persistence, daily limits, cancellation/races, conditional cache, error/retry, URL safety and search regressions |
| `README.md`, `CHANGELOG.md`, `docs/APP-MAP.md`, `BUILDING.md`, `UPDATES.md`, `TESTING-2.5.md`, this ledger | Behavior, ownership, stable publication checklist, current build record and device acceptance |

No cloud deployment, helper behavior change, automatic installation or other
battery proposal is included. Physical-iPhone layout and energy measurement remain
separate acceptance checks.


## 27 October 2026 — Elsepin 2.6.0 official publication

Publish the user-supplied Downloads IPA unchanged. Successful source/build: `304756f` / `40460137350`. App and extension are 2.6.0 (59); Prism Jumpgate primary. SHA-256 matches GitHub artifact: `c8cb9197d1b856bcd90a9de7d29311f82411eddd7b825a5d32a2080747156d22`. Release notes cover changes since Shift 2.5.8. Device/provider claims remain separate.

## 28 October 2026 — 2.6.1 appearance draft

Applied the now-authorized Elsepin Bloom/compact/rounded/surface-only changes, retaining icons and legacy backup decoding. Corrected old test expectations for retired color mode and a search alias collision. Final 410 Swift and 14 Python tests pass; identity/appearance/helper checks and website generation pass. Native iOS compilation pending: no IPA workflow started. Updated project.yml to 2.6.1 (60), navigation map, handoff, changelog and unpublished release draft. No release publication or site deployment.

## 28 October 2026 — Authorized native validation and private IPA

Run 40826806154 passed on source 506923c. Both app and extension report 2.6.1 (60); local IPA checks passed for all 13 icons and linked SDK 27.1. Artifact digest matched SHA-256 3e72bc2646e112e9664d586e60332bc4341e2ff08aa9370d26b9628f43fba547. Saved to Downloads and uploaded to Google Drive with no sharing changes. Release remains an unpublished draft with no assets. Device acceptance remains pending.

## 29 October 2026 — Settings search spacing and explicit surfaces (61)

Address screenshot feedback with compact Settings title, native automatic search drawer and top scroll margin; search is intentionally not always visible. Remove Theme default choice/reset button, default to Solid, migrate legacy theme values to Solid, preserve Glass. Added migration/round-trip tests: 414 Swift and 14 Python pass. Updated project build to 61 to distinguish from delivered IPA 60. No native build, IPA, publication or deployment; on-device scrolling still needs validation.

## 30 October 2026 — Focused Settings/import polish (build 61)
Applied complementary design guidance without changing palettes, defaults, identity, serialization or movement behavior. Compact Appearance summary replaces the slogan and duplicate row; surface picker moves above themes. Import/export actions share Settings icons; JSON help moves to the footer and opens a native Safari sheet with explicit Done/Paste/review. No automatic web upload, JS bridge or clipboard reading.
60 targeted Swift tests passed; changed UI sources passed syntax parsing. No iOS SDK type-check or device test; detailed acceptance is in TESTING.md. No IPA, release publication or deployment. Full 414/14 results from 29 October remain earlier evidence, not repeated claims.

## 30 October 2026 — Pairing code in the existing Live Activity (build 61)
PairOnDeviceService starts setup presentation synchronously while foregrounded and sends progress/PIN callbacks to the existing extension, retaining notification/in-app fallbacks. Shared SessionActivitySelection prevents idle-session updates from dismissing setup. One serial controller reuses a live container and drops superseded writes after suspension. No push registration or new polling/network service.
Optional SessionSnapshot.pairing preserves older activity decoding. PINs are six ASCII digits, never logged/exported, privacy-sensitive and hidden when stale/expired. One cancellable five-minute sleep per stage bounds presentation, with stale-date fallback; this is not a native-protocol validity claim. Success/failure/cancel clears the activity and PIN notification. Per-attempt callback boxes disconnect old callbacks; the worker gate remains busy until native work actually returns.
All 422 portable Swift tests passed (eight new pairing tests), with native-source syntax checks. No native SDK/device result claimed, and no IPA/publication/deployment. Settings comparison is a local chat mockup; theme/icon choices remain intact.

## 30 October 2026 — Final Settings comparison choice
User chose the compact overall Settings layout but retained the original larger identity card. Restored its 70-point icon, “MAKE IT YOURS” caption, title2 “Your space. Your way.” heading and original card spacing; theme/surface subtitle remains live. Keep the duplicate Appearance row removed, search spacing unchanged, and all theme/icon options. Updated the handoff/map/release draft to prevent future polish from undoing this choice. Swift syntax parsing and diff checks passed; no model changes, new tests, native build, IPA or publication.

## 30 October 2026 — Authorized build 61 IPA delivery, unpublished
Built source e7065f27ac863199b5d9a26ddcebe596a8154cc6 in native run 41103527856. All 551 tests passed (422 Swift, 14 packaging/icon, 19 Companion, 96 cloud), and app/extension Release compilation and package/signature checks succeeded. Recorded the three existing trust/delegate warnings in BUILD-HISTORY.md, retaining complete original logs under .build/artifacts/41103527856/.
Downloaded artifact 13000346208, verified both bundles 2.6.1 (61)/SDK 27.1, all 13 icons, required resources and SHA-256 against GitHub, then copied the exact bytes to Downloads/Elsepin 2.6.1 build 61.ipa. Digest 59031619b950c09b915b9b70ca7a29501dbef3cf2df321356f7098740fe91cbc, 18,258,461 bytes. No public asset, release or deployment; old Drive IPA remains build 60. Device pairing, Island/UI behavior and battery are still acceptance checks.

## Connection-check follow-up (local, after build 78)

The TCP liveness cache previously lasted 10 seconds regardless of a shorter
selected check interval. It now respects 3-10 seconds (preserving the existing
10-second maximum) and invalidates on foreground entry without tearing down a
working route's developer connection. No new timer or idle network loop added.
Explicit movement/Stop still require fresh connections; accepted writes still do
not prove Find My/Life360 ingestion. Foreground invalidation affects the next
write, not a write already in flight, and cannot guarantee instant VPN detection.
Added two Swift regression tests for interval boundaries and invalid timing.
Local diff checks passed. Three changed Swift files parse cleanly; LocationEngine
has the same three parser limitations as HEAD, with no new parser errors. No local
Swift/Xcode is installed: native compile, Swift test execution and phone validation
remain pending. No IPA build, push or release requested/performed for this follow-up.

## Drag-selection alignment follow-up (local, after build 78)

Recently Deleted now measures both finger and row frames in global coordinates,
avoiding named-space resolution across List cell hosting roots. Shared
SelectionRowHitTest prefers the row containing the touch, then the nearest edge
in a separator gap; variable-height rows no longer lose to a closer neighbor's
center. Existing reversible range selection, cancellation, tap/VoiceOver controls,
scrolling outside the circle gutter and deletion confirmation are preserved.
Repository scan found this is the only drag-to-select list; map/joystick/tray drags
are not bulk selection and were left alone. Three geometry regression tests added.
Swift syntax checks passed for the three affected files and diff checks passed.
No native Swift tests/compiler or phone gesture validation run yet; no build,
push or release. Next device check: drag down/up across circles before and after
scrolling, reverse direction, release/restart and confirm Delete count matches.
