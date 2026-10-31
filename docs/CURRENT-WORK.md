# Elsepin current handoff

Updated 30 October 2026. Read AGENTS.md, inspect Git status, preserve newer work.

## Build 63 route/search follow-up — native build passed, phone retest pending

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
Private source: N3moStudio/Elsepin, main. Development version 2.6.1 (62), privately delivered to Downloads on 30 October. Public downloads/help: Elsepin-Releases. Last known public release 2.6.0; 2.6.1 remains a draft with no assets. The user authorized this native build and Downloads delivery, explicitly excluding release publication. No website deployment or Drive upload was requested.
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

## Latest delivered IPA — build 63

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
