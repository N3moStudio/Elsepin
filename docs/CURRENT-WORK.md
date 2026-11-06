# Elsepin current handoff

Updated 6 November 2026. Read AGENTS.md, inspect Git status, preserve newer work.

## 2.6.1 (73) - route legs, recents and compact controls - privately validated/delivered

Each incoming stop/destination leg now opens its own movement editor directly,
including saved/drawn/GPX paths. Speed changes and switches on the same route
network preserve geometry; automatic network changes recalculate directions.
`Shared/RouteLegEditing.swift` preserves untouched sections, validates interval
coverage/limits and handles co-located stops. Active travel requires the existing
explicit hold-and-edit confirmation. No selection starts movement automatically.

Prepared routes ignore map pin taps until their explicit X. Valid planned routes
enter existing opt-in Recents before Start; tapping one opens its exact snapshot
in the planner. Stable history IDs prevent repeated edits creating duplicates.
The tray removes Settings/More and uses smaller header/inline shortcuts with 44pt
targets. Settings remains a tab. Stops, Whole route, Summary and one Options group
replace scattered planner controls. Removed redundant summary prose, not timing
calculation, warnings, path provenance or import/export/drawing features.

Hybrid is retained as Satellite + labels, because it differs from imagery-only
Satellite. Existing serialized map-style values remain compatible. Retired tray
Settings identifiers still decode; old backups normalize them away after validation.

The iOS 27 reduced-resource hint slows discretionary camera following and pauses
decorative loading motion; route/connection/Stop cadence is unchanged. The planner
preview caches its polyline. No new timer, telemetry upload or dependency. Owner
reports only slight warmth after build 72, but no controlled energy trace was sent.
Private Codemagic run `6aee4fc824e1ec237556f9c4` passed at source
`567e6c5726c3d7c7bffd6e0e4b66d154864ed3d6`: 631 checks (492 Swift,
104 cloud, 18 Companion, 17 packaging), native app/extension compilation and IPA
inspection with zero compiler warnings/errors. One Windows-only helper test is
skipped on the Mac, not counted as a pass. Both bundles are 2.6.1 (73), arm64,
device SDK 27.1. Full logs, metadata and receipt remain under ignored
`.build/artifacts/codemagic-6aee4fc824e1ec237556f9c4/`.

Delivered only `Elsepin 2.6.1 build 73.ipa` (18,716,109 bytes) to the Desktop
project IPA folder; verified the new copy before removing only build 72 there.
The prior IPA remains archived internally. Other projects were untouched.
No public release or deployment. Physical route/UI/heat acceptance remains pending.
Phone retest: plan two stops with different leg speeds/modes, show the route,
verify map taps do nothing until X, then reopen it from Recents. Check smaller
tray/Options layout and compare idle warmth under the same conditions.

## 2.6.1 (72) - privately validated and delivered

Owner supplied a 980-event build-71 log: successful TCP probes took 0–3 ms;
unavailable endpoints waited 2001 ms. "Add stop" search returned 25 results and
returned to the planner before the next process launch. There is no OS crash stack
in this export, so navigation hazards are corrected without claiming a proven cause.
Thermal state remained nominal (0), with recorded CPU around 0.7–34.4% of one core
across mixed browsing/active periods. No controlled idle-power trace is available.
Original input is preserved privately in ignored `.build/device-feedback-build71.jsonl`.

Changes: fresh native connection for explicit commands/Stop, 750 ms TCP bound,
durable unknown-location marker at native-write boundary, deferred search selection,
immutable timeline neighbors/search route, directions timeout/stage logging, clearer
Live Activity timer, and local MetricKit report collection/current-memory diagnostics.
`SystemDiagnosticCollector` supports iOS 27 streams and the older subscriber API.
Report bytes are split into bounded base64 fields; a begin/end manifest detects
incomplete capture. Logs remain opt-in, local, capped and free of credentials.

Final review adds an acknowledged on-disk unknown-location marker before native
writes, in addition to the legacy UserDefaults key. Initial setup does not create
it. A marker-save failure blocks new movement; removal follows an accepted clear.
Tests cover preference-write loss across process restart and failed marker storage.
One bounded Groq review was consulted; its missing-context native-handle race
claims were rejected after checking queue ownership, cleanup and TCP probe code.

Private Codemagic run `6aed7105ab17f8deb75355d1` passed at source
`50467da4bd2aeb16218cadae0f044f8cb3ba453f`: 620 automated checks (481 Swift,
104 cloud, 18 Companion, 17 packaging), plus native app/extension compilation
with zero compiler warnings/errors. One Windows-only helper test was skipped
on the Mac and is not counted as a pass. Both bundles are 2.6.1 (72), arm64,
device SDK 27.1. IPA integrity, thirteen icons, helper archives, notices and
requested entitlements passed. Full logs and receipt remain under ignored
`.build/artifacts/codemagic-6aed7105ab17f8deb75355d1/`.

Delivered only `Elsepin 2.6.1 build 72.ipa` (18,719,902 bytes) to
`C:/Users/naith/Desktop/ipa/My Projects (N3mo Studio)`, verified before removing
build 71 there. Other apps/files were untouched. No release or deployment.

Phone retests: quickly disable LocalDevVPN before teleporting, and select a
restaurant in Add Stop while planning a bike/e-bike route. Preserve the honest
failed-clear warning: process exit does not prove the last simulated location
was cleared. MetricKit reports may arrive later; battery/heat improvements are
not measured yet. Saved-location widgets still require App Group access from
the signing profile. The owner confirmed Recently Deleted and visual checks
passed and believes backups work. Do not redo those unrelated interfaces.

## 2.6.1 (71) - privately validated and delivered

The owner tested build 70 with FlareStore and LocalDevVPN. Six screenshots show
mojibake, misleading connection/tray state, tiny label-only saved pins, widget
storage permission failure, icon failure and bulky controls. Build 71 addresses
these flows; see CHANGELOG.md. No public publication is authorized.

New owners: `Shared/DeveloperTunnelProbe.swift` (bounded TCP check on the serial
engine queue, no location commands), `ConnectionProbePolicy.swift` (ten-second
continuous reuse; explicit commands always fresh), `MapPinSize.swift`,
`Locus/Features/Map/MapFavoriteButton.swift`, `Locus/Support/EnergyDiagnostics.swift`.
The vendor binary's successful return remains developer-command evidence, not
provider location verification. A TCP probe also cannot verify another app.
Actual LocalDevVPN-off, signer icon/widget behavior and heating require phone tests.
Do not remove widget entitlement checks or silently claim a failed Stop succeeded.

Local identity, appearance, helper archives and 17 Python packaging tests passed.
Codemagic run `6aed1ad9ab17f8deb753426c` passed at source
`14d2050c11cdb23d7cc712b8e6ed3d9e9064d448`: 476 Swift, 104 cloud, 18 Companion
and 17 packaging checks (615 passed; the Windows-only helper test is skipped on Mac).
Native app/extension compiled with zero compiler warnings/errors; both are 2.6.1(71),
arm64/device SDK 27.1. Thirteen icons, requested App Group entitlements, helpers,
notices and archive integrity passed. Actual signing/device acceptance remains pending.

Only `Elsepin 2.6.1 build 71.ipa` was delivered to the Desktop project IPA folder;
the verified replacement removed build 70 there. No public release or deployment.
Raw logs, metadata and receipt: `.build/artifacts/codemagic-6aed1ad9ab17f8deb753426c/`.
Earlier queued run `6aed1902ab17f8deb75341fb` was canceled before starting to include
lifecycle review fixes. Run `6aed19b9ab17f8deb753421d` caught a test-only `bind`
name collision; it was corrected to `Darwin.bind` before the successful run.

## 2.6.1 (70) - validated and privately delivered

The owner resumed building on 5 November, authorizing private GitLab hosting and
Codemagic's free personal M2 runner through CLI/API only. No desktop/browser control,
paid billing, Tendelm changes/cancellation, public release or deployment is authorized.
The existing local folder is unchanged. `gitlab` points to private
`https://gitlab.com/gajula.naithik/elsepin` (project 88570064), with GitLab CI/Pages
disabled. The current branch tracks GitLab; `remote.pushDefault=gitlab`. Keep the
suspended GitHub `origin` and local `main` unchanged.

Codemagic app `6aecefbde7e295d4f44f163e` uses personal owner
`6aecdf671da16ae2cffff6c7` and an Elsepin-only read-only deploy key. Credentials are
outside the repository and must never be printed. Build
[6aeceff2ab17f8deb7533589](https://codemagic.io/app/6aecefbde7e295d4f44f163e/build/6aeceff2ab17f8deb7533589)
passed at source `0e098f220e2ca6838e2df2ca33dbeedceaf15632` on `codex/pins-search-69`.
Preflight reported 29,861 free seconds remaining, no metered subscription and no
payment information. Tendelm's active build was left alone. After account builds,
453.8 free minutes remained, still with no paid subscription/payment information.

The existing layers button now opens Map options: Pins, Areas, and the three map
styles. Both saved layers start visible. Pin names remain tap-only; hiding saved
pins keeps the selected destination visible. These display choices never change
stored items, area naming/overlap rules, route movement or connection settings.

Visible-pin filtering refreshes on camera completion, library edits and visibility
changes. Area polygons are cached on area edits. See [energy review](ENERGY-REVIEW.md)
for source findings and remaining real-device profiling. No measured battery-saving
percentage is claimed. Existing Axiom energy/location/UI skills cover this work.

Both flags are optional settings-backup fields: older backups keep current choices;
new backups support independent review/import. Settings reset clears both keys.
Two new Swift tests cover old backup preservation and independent round-trip import;
the existing reset test now verifies the two keys. All 611 distinct tests passed:
472 Swift, 104 cloud, 16 packaging, 18 Companion on Mac, plus its Windows-only
encryption test locally. Native app/extension compiled with zero compiler warnings
or errors. This PC still has no local native Apple toolchain.

Delivery target: `C:/Users/naith/Desktop/ipa/My Projects (N3mo Studio)`.
`Elsepin 2.6.1 build 70.ipa` (18,661,714 bytes) was delivered and compared with the
inspected artifact before removing build 69. Other app IPAs were untouched; no extra
files were delivered. Full logs and receipt remain in ignored
`.build/artifacts/codemagic-6aeceff2ab17f8deb7533589/`.

Build via this branch and the manual `elsepin-ipa` workflow on M2/Xcode 27.1.
Keep all tests, raw logs and failure status. Both bundles were verified as 2.6.1 (70),
arm64, SDK 27.1, with correct entitlements, thirteen icons, helper files and ZIP
integrity. No Apple provisioning profile is bundled: ad-hoc signatures preserve
entitlement requests, and the owner must still sign for sideloading. The controlled
exit-23 logging check passed. See [building](BUILDING.md).

Post-build handoff changes are documentation only; do not rebuild just for them.
No release was published. Source migration does not migrate public GitHub help,
download or update endpoints.

On-device acceptance: toggle Pins/Areas separately, reopen the app, switch all
three map styles, rename/delete saved items, check selected-destination visibility
with pins hidden, then retest route marker/skip/Stop and old backup import. Native
compilation alone cannot verify gestures, layout or battery.

## 2.6.1 (69) — Pins, Favorites, search and energy — private test build

**Native validation and delivery completed 4 November.** The alternative personal
Codemagic workflow passed at `8b155ece426f557cb81725e4a19b9b66d6629087`:
[successful run](https://codemagic.io/app/6aec13aad70bff100bb5b859/build/6aec1824004ce28f20ee09d4).
All 609 distinct tests passed: 470 Swift, 104 cloud, 16 packaging and 19 Companion.
The Mac skips the Windows account-protection test; that test passed separately
on this Windows PC. App and Live Activity extension compiled with zero warnings
or errors under Xcode 27.1. Both bundles are 2.6.1 (69); SDK, thirteen icons,
entitlements, helper resources and ZIP integrity passed artifact verification.

Original delivery was Downloads; re-delivered 5 November to the Desktop IPA folder above. Full original logs,
build metadata, package and receipt are in
`.build/artifacts/codemagic-6aec1824004ce28f20ee09d4/`. The first Codemagic run caught
an invalid library-only backup test fixture and a test cleanup concurrency warning;
the second caught an unsigned MapKit error code passed to an Int parameter. Both
were corrected before the successful third run. Their original failures/logs remain.

Use `codex/pins-search-69` in Codemagic for this update; `main` remains at build 68.
The committed workflow is manual-only, uses the personal M2 allowance and does
not publish releases. No paid subscription was enabled. See [building](BUILDING.md).
Physical pin/search/route gestures, provider behavior and energy still need device
acceptance. No release, public asset or deployment was changed.

User scope: implement locally/private validation; **do not publish a release**.
Pins are independent of favorites. Library has Favorites (Pins and Routes), Pins,
Routes and Areas. Old saved-place records retain favorite status; unstarred pins
are included in backup review/export, restoration and widget choices. The legacy
`locus.favorites` key and v1/v2 backup fields remain compatible. Optional `favorite`
fields carry the new distinction; older app versions may show all pins as favorites.

Map pin names appear only on tap. Add/edit pins without sending a location.
Area search changes its camera without changing corners. Home recents distinguish
pin actions from route actions; naming saves to Library. Route history honors
the existing retention, disable, clear and reset controls and is not exported.

General MapKit searches use cancellation, a 7-second per-request deadline, one
fallback, category interpretation and nearby POI fallback. Along-route search is
also available while traveling, for browsing/saving a pin without changing the
active route. Draft stop search remains the route-changing preview flow. Each
corridor request has a 5-second deadline and shows partial results progressively.
Cycling unavailable no longer silently substitutes walking: user must choose it.

Battery: fewer idle stop-wait wakeups, immediate control-interrupt wake, no change
to movement cadence or connection/verification/recovery settings; thermal camera
throttling only; saved-pin rendering restricted to viewport. No measured battery
or temperature reduction is claimed. No checkpoint-format migration was needed.

Earlier GitHub attempts: appearance/identity checks, helper-package integrity, 16 packaging
tests and whitespace checks passed. WSL is unresponsive even to `/bin/true`;
Swift tests could not start locally. Private Mac run **41970102369** at `1d12f675`
was rejected before any job started: GitHub reports failed account payments or a
spending limit. This was **not** compilation/test evidence; no IPA existed then.
Subsequent review fixes preserve folders, correct stop countdown advancement for
the longer wait interval, cancel abandoned native directions, and immediately
revoke visibility of cleared route history. These changes are now included in the
successful Codemagic build above. Do not rerun an older commit or publish.
Work is on **codex/pins-search-69**; main remains unchanged.
At the user's request, a fresh run **41971922423** at final app source `9d188fb3`
was attempted again and rejected with the same account billing annotation before
any step ran. The browser automation profile was signed out; the authenticated
GitHub API successfully dispatched the job. The dispatch path is not the blocker.
Latest owner instruction permits Actions but still forbids publication. No need
to ask for permission to retry once the owner confirms account access is fixed.

Owner-requested cleanup on 4 November: deleted all **15** previous workflow runs
after preserving their metadata, annotations and original logs locally. Verified
zero runs remained, then dispatched **41972757451** at `b4de4ff8`. GitHub rejected
it before any step with the same billing/spending-limit message. Only that fresh
failed run remains. Cleanup did not clear the account restriction. Archive index:
`.build/action-cleanup/archive-index.json`; newest annotation/logs:
`.build/artifacts/41972757451/`. Historical remote run links below may now be gone;
their local evidence and prior IPAs remain. No release was changed or published.

New logic tests cover legacy favorite decoding, backup round trips, bounded
history/retention, category intent, wait/camera budgets, stop countdowns and timed
wait cancellation. Physical map gestures, providers and energy need device
acceptance. Historical build 68 evidence below remains unchanged.

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
- Local validation: 461 Swift tests passed (14 new lifecycle/recovery tests), edited
  Swift 5 source parsing, appearance/identity/helper archive checks and whitespace.
  Both controlled command-gate/foreground mutations failed as intended; restored
  originals then passed. Native compilation/package verification also passed, as recorded below.

The user's 2 November clarification explicitly authorizes automatic restoration and
resumption of the previously running route. It supersedes the earlier no-auto-resume
interpretation. Private push/build 68 is authorized; publication/deployment is not.
See [lifecycle design](SESSION-CLOSURE.md) and the updated 244-step owner walkthrough.

Native build 68 **passed** on attempt 3 of
[run 41526208045](https://github.com/N3moStudio/Elsepin/actions/runs/41526208045),
at source `3c53deefbd8cbd44fd081bf64bbecc58bfb1ea8b`. All **600 tests** passed
(461 Swift, 104 cloud, 19 Companion, 16 packaging/icon). Native app and Live Activity
extension compilation passed with **zero compiler warnings/errors**. Both bundles
are 2.6.1 (68), linked against SDK 27.1; compatibility IDs, thirteen icons, resources,
bundled helpers and ZIP integrity were verified against the downloaded artifact.

The SHA-256-verified private IPA is at
`C:/Users/naith/Downloads/Elsepin 2.6.1 build 68.ipa` (18,538,590 bytes):
`31dece8b203564bb50d838fb2d842a3e5ba5c578a73d11e716ebe46e55f4c65c`.
Full original workflow logs, test results and the successful receipt are retained in
`.build/artifacts/41526208045/`. Attempts 1 and 2 failed to acquire a hosted runner
before any build steps executed. Their API annotations, empty log archives and
`receipt-blocked-attempt2.json` remain as historical evidence. Attempt 3 followed a
backoff and reused the same source/run; no runner-label or infrastructure changes.

The refreshed 244-step walkthrough, fixtures, helper ZIPs and successful receipt
are in Downloads as `Elsepin build 68 - Test Guide` and its ZIP. Build 67 remains
unchanged at SHA-256
`5b68513fc20b76d29690e8056ac2a5b40c6fd4836b0df14fe563cd87c6cfe741`.
Public release stays 2.6.0. The 2.6.1 draft remains unpublished with zero assets.
Physical recovery/collapse/gesture/provider acceptance remains pending.

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

Approved on 2 November: instruction-only Ponytail and four selected Addy skills,
native ThinkingOrbsKit, scoped private source push and existing IPA workflow.
Installed manuals/reference files remain unchanged; no hooks, AGENTS rewrite,
provider routing, credentials or deployment changes. Cleanup commit: `8b8cb07`.
See [orb integration and device checks](NATIVE-PROGRESS.md) and
[cleanup evidence](CLEANUP-AND-ORBS-REVIEW.md). Preserve build 66 and its test pack.

[Native run 41518500417](https://github.com/N3moStudio/Elsepin/actions/runs/41518500417)
passed at source `776d1915f742874e3e1ef4a968d7769ca6ddadf5`: **586 tests**
(447 Swift, 104 cloud, 19 Companion, 16 packaging/icon), native app/extension
compilation and IPA validation, with **zero compiler warnings/errors**. The
resolved dependency revision and bundled MIT notice were checked. Separately,
the unchanged native orb geometry passed 72 upstream golden cases / 70,115 values.

Downloads: `Elsepin 2.6.1 build 67.ipa`, 18,512,366 bytes; SHA-256
`5b68513fc20b76d29690e8056ac2a5b40c6fd4836b0df14fe563cd87c6cfe741`.
GitHub digest, ZIP CRC, app/extension 2.6.1 (67), SDK 27.1, compatibility IDs,
thirteen icons and bundled helper/resources passed. Build 66's hash is unchanged.
Logs/receipt: `.build/artifacts/41518500417/`. Public release remains 2.6.0;
the 2.6.1 release is still an unpublished draft with no assets. No deployment.

Phone layout, VoiceOver, interrupted requests, route-crash outcome and energy
remain owner acceptance checks. Visuals are code-based mockups, not runtime
screenshots; geometry is from the pinned native code. See the 226-step walkthrough
and the build 67 visual-preview folder in Downloads. No Library upload tool was
available in this local task; exact artifact paths are retained for the coordinator.

## 2.6.1 (66) — incident export and experimental helper audit

User authorized implementing the two diagnostic improvements and auditing experimental
connections/downloads, followed by a complete sequential test guide. Keep publication
blocked until user approval. Build 66 passed native validation and was hash-verified
in Downloads. Preserve the older test IPAs.

[Native run 41396515177](https://github.com/N3moStudio/Elsepin/actions/runs/41396515177)
passed at source `7bdf1a5f8051ccc94d38420fb45ee3d24236c6d9`: **582 tests**
(443 Swift, 104 cloud, 19 Companion, 16 packaging/icon), native Release arm64 app
and extension compilation, ad-hoc signing and package validation. The complete
retained logs contain **zero compiler warnings/errors**. Both bundles are
2.6.1 (66), SDK 27.1; thirteen icons, resources and compatibility IDs were checked.

Downloads: `Elsepin 2.6.1 build 66.ipa`, 18,444,793 bytes, SHA-256
`aadde4ce1d7277d4ca182a8d2c8bbd2fb6b03dac63528f19ae08ec7c7d1ebc22`.
The copied file matches GitHub's artifact digest; ZIP integrity passed. Complete
logs and receipt: `.build/artifacts/41396515177/`. Earlier test IPAs are retained.

The 216-step [owner walkthrough](TEST-WALKTHROUGH-2.6.1.md), test fixtures and both
helper ZIPs are also in Downloads as `Elsepin build 66 - Test Guide`. Open
`START-HERE.html` for an offline checklist with saved results and notes.
Real provider sign-in, phone crashes/gestures, push receipt and battery behavior
remain unverified. Public 2.6.0, its assets and the website are unchanged;
2.6.1 remains an unpublished draft with zero assets. No Drive upload this turn.


- `Shared/DeveloperIncident.swift`, `DeveloperLogStore.exportIncident` and the existing
  `SessionTimelineView` provide bounded ten-minute incident exports with explicit gaps.
  `RouteDiagnosticAttempt` links discrete map/engine events without driving state.
- Shared provider cache/readiness fixes and corrected source-only helper exports;
  see [audit](EXPERIMENTAL-AUDIT.md) for public anonymous availability and limitations.
- [Ordered test walkthrough](TEST-WALKTHROUGH-2.6.1.md) covers installation through
  setup, gestures, interruption/retry, backups, UI, widgets, cloud and cleanup.
- 443 Swift tests passed; helper reviewer verified 104 cloud, 19 companion, 16
  packaging/icon tests, plus independent tests of both extracted ZIPs. Native build 66 passed.
- Real phone/provider acceptance remains unknown. Find My People is unavailable.
  Public release stays 2.6.0; its helper ZIPs and public guides lack build 66 changes.

## 2.6.1 (65) — native warning cleanup — 31 October 2026

[Native run 41213887689](https://github.com/N3moStudio/Elsepin/actions/runs/41213887689) passed at
`ed1c03d85e4606cded44b842836d7fea513edc53`: **565 tests**, native app/extension compilation,
ad-hoc signature and IPA validation, with **zero compiler warnings/errors**.
The complete retained log contains no warning/error diagnostics. Both bundles
are 2.6.1 (65), SDK 27.1; thirteen icons, resources, compatibility identities,
ZIP integrity and the GitHub artifact hash were verified.

The private workflow artifact is 18,399,647 bytes, SHA-256
`2ba76ddb2e031dba53b9d2ca733b6b7687370e6ea6bad8c1c0c0a1052e809b4a`. Logs/receipt: `.build/artifacts/41213887689/`.
This validation did not replace the build 64 IPA in Downloads or upload to Drive.
Route/UI code is identical to build 64, which the user is still testing. Real
helper connections and the route-crash outcome remain device acceptance checks.
The release remains an unpublished draft with zero assets; public 2.6.0 is unchanged.


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

## Build 64 delivered — native passed, phone acceptance pending

[Native run 41176847512](https://github.com/N3moStudio/Elsepin/actions/runs/41176847512) passed at source
`39e232a971dc15e77b936a50f6321651ab17b900`: **565 tests** (436 Swift, 14 packaging/icon,
19 Companion, 96 cloud), app/extension compilation, ad-hoc signature and IPA
validation. Both bundles are 2.6.1 (64), built with SDK 27.1; thirteen icons,
required resources, compatibility IDs, ZIP CRC and GitHub SHA-256 were checked.
Three existing trust/delegate warnings remain; no new warnings.

Verified Downloads artifact: `Elsepin 2.6.1 build 64.ipa` (18,399,184 bytes).
SHA-256: `d02d11e10d6e02838d00e5dc7ba8d20d3c7d9a9be977bd7d6828733bc8abaaa7`.
Complete logs/receipt: `.build/artifacts/41176847512/`.
The release remains an unpublished draft with zero assets; Drive is unchanged.
Phone hold/drag/jump/undo, recovery/retry, live search coverage, layout and provider
speed still need acceptance. Native compilation is not a phone-crash reproduction.


The user confirmed keyboard Search works on build 63; route hold/drag still
terminates the app. An optional developer log shows successful location writes,
then a hold-began event immediately before the next process. No completed jump,
iOS exception stack, or retry attempt is captured. Do not claim a proven crash
cause or phone fix. Keep the supplied log outside the repository.

Current changes: native MapKit-only projection in route touch callbacks; weak
map reference and marker invalidation during reconnect/navigation; optional
hold-ready/visible breadcrumbs in the existing opt-in log. Manual Teleport and
serialized movement commands are unchanged. RouteStopSearchSheet adds bounded
MapKit corridor discovery for draft directions routes, plus explicit Everywhere
search, map/results, categories, favorites/recents and itinerary insertion.
Active/custom-path pauses remain on the existing path; Hold location and edit
is required for a destination detour. Advanced/More options are indented.

Build 64 was privately delivered to Downloads; no release publication.
See [changes since the public release](CHANGES-SINCE-2.6.0.md). Preserve all
appearance, pairing, backup and compatibility decisions below.

## Build 63 — native passed; Search phone-confirmed, route crash persists

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


User reports full exits to Home Screen on route hold/jump and keyboard Search
in installed build 62. No iOS analytics crash entry is available. Do not claim
these termination causes are proven or device-fixed from compilation alone.

General search now keeps results in the picker; autocomplete selection remains.
The route hold uses native map coordinates rather than a retained SwiftUI event
converter; route index identity/range guards protect route replacement. Drag
state resets on background/disappearance. Existing seek command serialization,
manual Teleport confirmation and Stop behavior remain unchanged.

`Shared/RouteTiming.swift` shares playback's motion rules with estimates, caches
per route/settings and keeps waits separate for seek/partial-stop correctness.
The planner distinguishes simulated Elsepin time from Apple Maps' estimate.
At 10 mph, 6.6667 miles takes 40 minutes before waits/slowdowns. The user's
Republican Party of Orange County → 3901 Parkview Lane, Irvine example has not
been reproduced against live MapKit results; do not force an arbitrary 40-minute ETA.

Activity layout is shorter and bounded by line/row priority; stale/error/provider
status and pairing-code privacy remain. Phone checks: keyboard Search for a
business/category/address, edit/cancel/retry; hold/drag/jump/undo/Stop and interrupt
the touch; E-bike 10 mph with Smooth on/off and section speeds; Island/Lock Screen
with long place names, accessibility text, both providers and stale states.
Release remains unpublished. Earlier build receipts below describe older code.

Speed follow-up: `RoutePlaybackClock` now uses successful-confirmation spacing
and a conservative recent latency estimate. This avoids immediately dispatching
catch-up movement after a slow write; jumps/resumes still reset the clock. The
native `location_simulation_set` API accepts only latitude/longitude, not speed.
Life360 independently samples GPS/motion and can miss points; do not promise its
MPH matches a configured value. Existing measured-speed UI remains separate
from target speed. Sources: [Life360 speed accuracy](https://support.life360.com/hc/en-us/articles/23053597039511-Driving-Speed-Accuracy),
[movement sampling](https://support.life360.com/hc/en-us/articles/23053466420887-Movement-Accuracy).

First native attempt 41173992580 passed 557 tests but failed with a Swift
type-check complexity error in the map's search-dismissal closure. Full original
logs: `.build/artifacts/41173992580/workflow-logs.zip`. The closure is now a
separate method. No IPA was produced by that attempt; the successful final run is recorded above.
Attempt 41174349587 passed the expanded 560 tests, but the same map-view compiler
limit moved to a neighboring closure. The entire map modifier chain is now split
at opaque canvas/lifecycle/route/timer/presentation boundaries, retaining one
State owner and modifier order. Full logs for both failed attempts are preserved.

## Build 62 UI follow-up — native build passed, device checks pending

Video-inspired UI pass: pairing sheet now uses the selected theme, three connected
instructions in task order and existing themed button feedback. The user requested
removal of Pairing help; do not restore that disclosure/card. Draft route modes
wrap into a grid with a single accessibility column.
No engine, PIN lifetime, Live Activity, storage or backup changes. `unslop` was
installed alongside existing skills; see [UI-POLISH](UI-POLISH.md) for provenance,
constraints and checks. Native run 41126221099 passed all 551 tests and app/extension
compilation at `a213d8b37a87759b0db719a9caa2ba571427330e`. The verified build 62 IPA is
in Downloads. The earlier 57 focused tests, syntax checks and responsive mockup
checks remain historical checkpoints. Real-device interaction is still pending.
Source and handoff are on private main; no release publication, website deployment
or Drive upload was requested. Three existing compiler warnings remain recorded below.

## Current source and boundaries
Private source: N3moStudio/Elsepin, main. Latest verified private delivery is 2.6.1 (64), delivered to Downloads on 30 October. Public downloads/help: Elsepin-Releases. Last known public release 2.6.0; 2.6.1 remains a draft with no assets. The user authorized this native build and Downloads delivery, explicitly excluding release publication. No website deployment or Drive upload was requested.
Elsepin is the full app. Veypax is separate; do not copy paid gates or branding. Preserve bundle IDs, defaults/Keychain keys, app group, backup formats and manual movement confirmation.

## Current UI and compatibility
- Eight themes, Bloom default/reset, legacy Abyss maps to Bloom. Thirteen icons retained. Rounded/compact shared presentation respects accessibility sizes.
- Only Solid and Liquid Glass are selectable surfaces, in that order. Solid is default. Legacy serialized theme material maps to Solid; explicit Glass persists. Color mode follows theme; legacy typography/color backup fields decode without overriding fixed presentation.
- Settings retains its automatic swipe-revealed native search drawer, inline title and top content margin. Keep the compact settings layout, but retain the larger “MAKE IT YOURS / Your space. Your way.” identity card (70-point icon, title2 heading and theme/surface subtitle). This is the user's final comparison choice; do not shrink it during routine polish. The duplicate Appearance row stays removed; Appearance remains searchable. Surface picker is above themes.
- LibraryBackupView opens json.site in BackupJSONBrowser, a native Safari sheet. The footer intercepts only that link. No script bridge, automatic upload or clipboard read; native Paste and existing selective import review/confirmation remain unchanged. Done returns to the importer. File picker and export paths remain intact.

## Validation
30 October build 62: run 41126221099 passed at source a213d8b37a87759b0db719a9caa2ba571427330e. All 551 tests passed (422 Swift, 14 packaging/icon, 19 Companion, 96 cloud), plus native compilation, ad-hoc signature verification and IPA validation. The downloaded artifact passed CRC, app/extension identity/version, resources, SDK and 13-icon checks and matched GitHub's digest. The same three warnings as build 61 remain; no new UI warnings. Complete logs and receipt: .build/artifacts/41126221099/. Phone acceptance remains pending.
30 October native run 41103527856 succeeded at source e7065f27ac863199b5d9a26ddcebe596a8154cc6: 422 Swift, 14 packaging/icon, 19 Companion and 96 cloud tests passed (551 total). App and extension compiled/packaged against iPhoneOS 27.1; signatures checked by the Mac packager. The exact downloaded IPA passed integrity, identity, version, resource, SDK and 13-icon validation, and its SHA-256 matched GitHub. Three pre-existing warnings remain: deprecated SecTrustGetCertificateAtIndex in CompanionClient.swift:168 and RemoteFindMyController.swift:392; CLLocationManagerDelegate isolation in LocationVerificationController.swift:6. They are not build failures or new pairing/browser diagnostics.
Complete original logs, diagnostics and receipt: .build/artifacts/41103527856/. Phone setup/background code delivery, Dynamic Island rendering, Safari interaction, appearance, signing with the user's sideloader, accessibility and battery remain pending device acceptance.
30 October pairing follow-up: all 422 portable Swift tests passed (eight new PairingActivityTests), plus 14 Python checks and the app/extension identity check; changed native pairing/activity/setup files passed syntax parsing. Logs: .build/pairing-activity-swift.log, .build/pairing-activity-python.log, .build/pairing-activity-parse.log and .build/pairing-service-final-parse.log. Native compilation and real-device pairing/Island timing remain pending.
30 October: 60 focused Swift tests passed for BackupImport, LibraryBackup, AppearancePolicy and Personalization. Swift syntax parsing passed for changed UI files. Logs: .build/settings-polish-swift.log, .build/settings-polish-parse.log. Syntax parsing is NOT iOS SDK type-checking.
29 October: full 414 portable Swift tests and 14 Python tests passed for the surface migration/search-spacing change. Logs: .build/settings-surface-swift.log and .build/settings-surface-python.log. No newer shared-model changes in this polish pass.
Build 61 has now passed native compilation; the earlier syntax-only entries above record preceding checkpoints. Use the acceptance checklist in TESTING.md. Future builds must regenerate project.yml with XcodeGen as the packager already does.

## Latest delivered IPA — build 64

[Native run 41176847512](https://github.com/N3moStudio/Elsepin/actions/runs/41176847512) passed at source
`39e232a971dc15e77b936a50f6321651ab17b900`: **565 tests** (436 Swift, 14 packaging/icon,
19 Companion, 96 cloud), app/extension compilation, ad-hoc signature and IPA
validation. Both bundles are 2.6.1 (64), built with SDK 27.1; thirteen icons,
required resources, compatibility IDs, ZIP CRC and GitHub SHA-256 were checked.
Three existing trust/delegate warnings remain; no new warnings.

Verified Downloads artifact: `Elsepin 2.6.1 build 64.ipa` (18,399,184 bytes).
SHA-256: `d02d11e10d6e02838d00e5dc7ba8d20d3c7d9a9be977bd7d6828733bc8abaaa7`.
Complete logs/receipt: `.build/artifacts/41176847512/`.
The release remains an unpublished draft with zero assets; Drive is unchanged.
Phone hold/drag/jump/undo, recovery/retry, live search coverage, layout and provider
speed still need acceptance. Native compilation is not a phone-crash reproduction.

## Earlier delivered IPA — build 63

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

## Earlier delivered IPA — build 62
Native run: https://github.com/N3moStudio/Elsepin/actions/runs/41126221099. Source: a213d8b37a87759b0db719a9caa2ba571427330e. Artifact: 13010842478. Both bundles: 2.6.1 (62), SDK 27.1. File: C:/Users/naith/Downloads/Elsepin 2.6.1 build 62.ipa (18,260,198 bytes).
SHA-256: 4d3ccac5a529b957a3ab2eb945747e2eae65d31b9c3837e6a7b8840d6f491d05.
Includes three connected pairing steps with no Pairing help, themed pairing surfaces/actions and all five visible draft route modes, plus everything in build 61. Retain the extension when sideload signing. Release is still an unpublished draft with no assets. Drive remains build 60.

## Earlier delivered IPA — build 61
Native run: https://github.com/N3moStudio/Elsepin/actions/runs/41103527856. Source: e7065f27ac863199b5d9a26ddcebe596a8154cc6. Artifact: 13000346208. Both bundles: 2.6.1 (61), SDK 27.1. File: C:/Users/naith/Downloads/Elsepin 2.6.1 build 61.ipa (18,258,461 bytes).
SHA-256: 59031619b950c09b915b9b70ca7a29501dbef3cf2df321356f7098740fe91cbc.
Includes pairing code in the existing activity, compact Settings with the retained larger identity card, explicit surfaces and in-app JSON Safari sheet. Sideload while retaining the extension; placeholder signatures are not distribution credentials. Release remains unpublished. The old Drive file still contains build 60.

## Earlier delivered IPA — build 60
Native run https://github.com/N3moStudio/Elsepin/actions/runs/40826806154 passed at source 506923c3f2f3d7a545ea660474361c575079732f. Both targets: 2.6.1 (60), SDK 27.1. Thirteen icons verified. Ad-hoc packaged; user sideload signing required.
Local: C:/Users/naith/Downloads/Elsepin 2.6.1.ipa (18,192,618 bytes).
SHA-256: 3e72bc2646e112e9664d586e60332bc4341e2ff08aa9370d26b9628f43fba547.
Drive file ID: 1xrv44UVD0SLQ9yQEKvqtI9BjrfwRJi03. Do not claim it contains the current Settings/browser changes.

## Navigation
PairOnDeviceService now starts setup presentation while foregrounded and publishes the native PIN callback to the existing Island/Lock Screen. SessionActivityController.shared serializes setup and movement through SessionActivitySelection. Codes are transient, privacy-sensitive and stale-aware. Completion/cancel/failure and a five-minute visibility timeout clear presentation and the PIN notification. A blocking native accept may still finish after UI cancellation; its old callback box is disconnected and its worker gate stays locked until it returns.
The comparison decision is compact overall with the original larger identity card; the eight theme rows/swatches and thirteen icon choices remain intact. The card-only correction passed Swift syntax parsing; device layout remains pending.
APP-MAP.md locates UI/migration entry points; BACKUPS.md describes import rules; CHANGE-LEDGER.md records evidence; docs/releases/2.6.1-DRAFT.md contains release text. CHAT-WORKFLOW.md covers sparse optional delegation.
Deleted arena branch remains deleted; recovery history is .build/elsepin-arena-3430259.bundle. Its reviewed appearance changes were subsequently explicitly authorized and reapplied. Website catalog source has eight themes but has not been redeployed in these follow-ups.

## Next phone checks for build 64
1. Hold the route, drag across a corner, lift, Teleport, Undo; then background
   during a hold and retry. Confirm no move happens before Teleport and Stop works.
2. Reopen after an interrupted connection, reconnect/recover, then hold again.
   Keep the optional log enabled for this test; exact cause remains unconfirmed.
3. Draft route → Add stop → search Coffee or a full address; try map pins,
   Along route/Everywhere, cancel/back, offline/retry and adding a second stop.
   Also test Places & stops → Add stop after Hold location and edit.
4. Expand Advanced/More options on a small screen and at accessibility text sizes.
