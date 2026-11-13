# Elsepin current handoff

## Build 82 preparation - wider, adjustable pin visibility (13 November 2026)

User authorized building and delivering this patch. Both targets request 2.6.1
(82). Build/package checks remain pending the new GitHub run. Keep the release
unpublished and replace only the older Elsepin IPA after successful verification.

User found build 81 hides pins too soon and supplied a Library map screenshot
with quarter-mile scale divisions. A scale division is only part of the visible
map, not camera height or a radius from the phone.

- Replace the 4,000 m camera-distance cutoff with visible map-bounds width in
  ground meters, adjusted for the map center's latitude. Both the main map and
  Library pin editor use the same policy. Default: 5 miles across the map.
- Settings > Appearance > Map pins > Visible up to adjusts 0.5-20 miles in
  half-mile steps. Keep current/draft pins and route/location markers separate.
  The main-map list refreshes after camera movement or preference changes,
  including returning from Settings; never scan the library on every zoom frame.
- A native MapScaleView shares the main map's explicit namespace and sits below
  its controls, leading aligned, noninteractive and always visible outside drawing.
  Its ticks use MapKit's distance units/zoom; the slider explicitly uses miles.
- `mapPinVisibilityMiles` persists in the active workspace, reloads after reset/
  Dev Mode changes, and is an optional validated backup display field. Old backups
  and unchecked imports preserve the current value. Settings reset restores 5 mi.

Local validation: all 12 changed Swift files parse, source encoding/diff checks
pass. Updated visibility tests cover the wider default, slider thresholds, local
ground scale, invalid geometry and bounded preferences. Three new backup tests
cover round-trip/selective import, legacy backups and invalid values; reset tests
include the new key. Swift execution/native compilation and signed-phone layout
remain pending. Build 81 remains the latest delivered IPA until the authorized
build 82 passes. No release is authorized.

## Build 81 validated and delivered - 13 November 2026

GitHub run 43493662140 succeeded at 2dc937e76df21f1d321c4eea1bfae5fb8a7f8572.
692 checks passed: 553 Swift, 104 cloud, 18 Companion and 17 resource/package
tests; one Windows-only Companion case skipped on Mac. Native app/extension
compiled with zero compiler warnings/errors. Both bundles are 2.6.1 (81), arm64;
entitlements, icons, helpers, notices and IPA integrity verified.

Delivered only Elsepin 2.6.1 build 81.ipa (19,083,873 bytes) to
C:/Users/naith/Desktop/ipa/My Projects (N3mo Studio), replacing build 80.
Original logs/package receipt: .build/artifacts/github-43493662140/.
No release published. Phone acceptance of the new keyboard/layout/zoom behavior
remains pending; compilation does not prove those interactions.

### Changes included

New device feedback confirms bike/e-bike walking fallback, route Save / Favorite /
Unfavorite, and Recently Deleted worked in build 80. This is focused acceptance,
not proof that every feature or crash scenario passed.

- Library pin creation/editing no longer displays or requests addresses. Moving
  a pin still clears its stale address; selecting it on the main map can resolve
  an address. Search suggestions may fill a blank name; manual taps never do.
- Symbol offers Custom emoji. Only that choice reveals a native emoji-only
  field, rejecting letters, plain numbers and mixed/multiple-emoji paste before
  display. A new emoji replaces the previous one; flags, skin tones and family
  sequences remain intact. Save requires an emoji when Custom emoji is chosen.
- Saved pins are viewport-filtered and hidden beyond a 4,000 m camera distance
  on the main map and in the Library pin editor. This is camera zoom, not distance
  from the phone. Draft/selected pins, route markers and current location remain
  separate. Main-map filtering runs after camera movement, not on route ticks.
- The active route's three-dot menu includes Cancel next route while one is
  queued. It uses the existing cancellation path and leaves the current trip
  running. Before starting: planner > After arrival > Remove next route.

Seven changed/new Swift files parsed locally; source encoding and diff checks
passed. All six new emoji-edit/zoom-visibility regression cases passed in the
553-case Swift suite above. Keyboard/VoiceOver and physical map-layout acceptance
remain pending on the signed phone installation.

User confirmed the screenshot selected the Demo Garden pin, not Demo Garden Walk.
`RoutePlaceSearchSheet.swift` now separates recent pins/routes and labels their
types; saved search sections use Saved pins / Saved routes. The location action
reads Plan a route here. Selection callbacks and stored data are unchanged.
These search changes are included in build 81. Native rendering still needs phone acceptance.

## Build 80 validated and delivered - 12 November 2026

GitHub run 43376928555 succeeded at 6a1a29c: 686 checks passed (547 Swift,
104 cloud, 18 Companion, 17 resources; one Windows-only case skipped).
Native app/extension compiled with zero compiler warnings/errors. Both bundles
are 2.6.1 (80); arm64, entitlements, icons, helpers and notices verified.
Delivered Elsepin 2.6.1 build 80.ipa to the usual Desktop IPA folder, replacing
build 79. Logs/receipt: .build/artifacts/github-43376928555/.
No release published. Physical-device acceptance remains pending. Earlier
not-built/pending-native notes below are superseded by this result.


Updated 12 November 2026. Read AGENTS.md, inspect Git status, preserve newer work.

## Build 80 preparation - not built (12 November 2026)

User reported build-79 planner/pin regressions and requested adjacent regression
review and better bike/e-bike routing. Latest instruction: finish fixes and wait
for the user to say when to build. Do not dispatch a workflow/package/release.
`project.yml` reserves 2.6.1 (80); this is not build evidence. Build 79 remains
the latest delivered IPA. Current source branch is still `codex/pins-search-69`.
Repair source `7e4c328` is synced to GitHub and GitLab. Local checks: 17 resource
tests passed, identity/appearance/helper archives passed, 25 changed/new Swift
files passed syntax parsing, and local documentation links resolved. The 21 new
Swift cases and native app/extension compilation remain pending the Mac run.

See [build 80 review](BUILD-80-REVIEW.md) for fixes, evidence and outstanding
native/device checks, and CHANGELOG.md for the complete user-visible scope.
Manual pin-editor taps now leave names blank; search suggestions may fill them.
This supersedes build 79's manual-editor automatic naming. Main-map label hints
remain. Do not reintroduce required environment objects in MapKit annotations.

## Build 79 - validated and delivered (12 November 2026)

User authorized all post-78 changes and a test IPA, not a release. Final app source
is `9d6411043771947a0643dc2bbd4fc70eff3ec154` on `codex/pins-search-69`, synced to
public GitHub and private GitLab. Main is older. Subsequent documentation-only
commits record this result. See CHANGELOG.md for scope and APP-MAP.md for owners.

Includes area Redo, taller/full-screen pin/area maps, pin validation and automatic
name/address hints, emoji/fixed colors, grouped Recents, route save/favorite
identity, Library Create route, tray spacing, global-coordinate drag selection,
connection freshness and one optional next route with explicit automatic consent.
Old backup fields/IDs, the annotation crash fix, stop/clear semantics, themes,
manual widget confirmation and demo isolation are retained.

Initial Mac run `43355566346` stopped in portable Swift compilation: the new
row hit-test helper needed an explicit CoreGraphics import. Corrected in
`b9c4e6e`. Complete log remains in `.build/artifacts/github-43355566346/`.
Runs `43355966234` and `43356552566` passed native checks during integration.
Final run `43356906705` passed 665 checks: 526 Swift, 104 cloud, 18 Companion and
17 packaging/resource tests (one Windows-only Companion case skipped on Mac).
Native app and extension compilation completed with zero compiler warnings/errors.
Both IPA bundles are 2.6.1 (79), arm64; identities, entitlements, icon resources,
helpers and notices passed package verification. Complete logs and the delivery
receipt are in `.build/artifacts/github-43356906705/`.

Delivered only `Elsepin 2.6.1 build 79.ipa` (19,005,315 bytes) to the usual Desktop
IPA folder, replacing only Elsepin build 78. No release, main merge or billing
change. Device UI/gesture, MapKit labels and real VPN/provider behavior remain
phone acceptance checks; see [five focused spot checks](TESTING-BUILD-79.md).
Compilation is not evidence of perfect physical-device behavior.

## Build 78 - public GitHub build (12 November 2026)

The owner authorized public visibility for `N3moStudio/Elsepin`; GitLab remains
private and Veypax is unchanged. Source `e3976f7` is local and pushed to both
remotes on `codex/pins-search-69`. Main is older. No release is authorized.
Codemagic is out of free minutes (HTTP 402); paid billing remains disabled.
Public GitHub Actions now runs successfully past the earlier account block.
The first run, `43347794492`, passed tests but caught a missing
`change.replacement` qualification in the planner. This is corrected in `e3976f7`.
Run `43348423568` succeeded: 653 checks passed (514 Swift, 104 cloud, 18
Companion, 17 resources; one Windows-only case skipped on Mac). Native build had
zero compiler warnings/errors. Both bundles are 2.6.1 (78), arm64; entitlements,
icons, helpers and notices verified. Delivered only `Elsepin 2.6.1 build 78.ipa`
to the usual Desktop IPA folder, replacing build 77. Phone acceptance remains pending. Raw logs and receipts belong in ignored
`.build/artifacts/`; do not publish local diagnostic exports or credentials.
## Local interaction fixes after build 77 (12 November 2026)

Baseline `073f8f4`; see [the assessment and blueprint](INTERACTION-REVIEW-2026-11-12.md).
Pin taps now reveal names during active/prepared routes without changing destination.
Dropped-pin/held-location trays no longer collapse. Joystick speed controls no longer
show a route-only smoothing switch. Arrival uses an explicit menu; Add stop opens
place search, while Pause on this path is a separate option. Stored-path changes
require recalculation confirmation; live search edits first require Hold location.

Local identity/appearance checks and 17 resource tests passed; seven changed Swift
files parsed. Added a saved-pin interaction matrix Swift test; the public Mac run executes it:
no local Swift/Xcode. Native compilation and physical UI acceptance remain pending.
These were the pre-build local results; see the build 78 status above. Build 77's
652-check receipt does not cover these newer changes. Use the existing public GitHub Mac
workflow for the next explicitly requested build. Python in PATH is a broken Store
alias and the old Python313 installation lacks its library; verified temporary
runtime is `.build/python-3.13.7/python.exe`. Full local check log:
`.build/interaction-review-tests.log`.

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

## Build 76 phone failure - release blocker (8 November 2026)

Owner reports Elsepin closed to Home Screen about one second after tapping Start
on **Demo Garden Walk**, after movement had begun. The spoofed location remained.
This disproves treating build 76's automated success as resolution of the exits.
At the initial report, no fresh export was available. The later supplied export
and build-77 diagnosis above supersede that evidence gap. Route-start/source inspection does not establish a root cause.
The demo route shares normal playback and uses a small four-point synthetic path;
do not assume either excessive route size or memory pressure without incident evidence.
The last accepted simulated location can remain after process termination; preserve
the durable uncertain-clear marker and require a confirmed clear. Never treat an
unchanged Live Activity or location as proof that the app/playback is still running.
Next evidence: existing developer-log export from this incident and, if available,
the matching Elsepin/Locus or JetsamEvent report. No rebuild/publication in this
follow-up; avoid another speculative crash-fix build before inspecting evidence.

## Build 76 - Dev Mode, sweep selection and map hardening (8 November 2026)

Private run `6af16be955fc448af77585cd` succeeded on source
`1e7b5dc14dd6581c9fa883dfc43984b930b22e38`: 652 checks passed and native app/extension
compiled with zero compiler warnings/errors. Both bundles are 2.6.1 (76).
The verified IPA is delivered in the usual Desktop IPA folder, replacing only build 75.
Source is synced to both private remotes on `codex/pins-search-69`; main is unchanged.
The first run `6af1674a154a790c0488506a` passed tests but failed native compilation
on root SwiftUI expression complexity, with two non-Sendable defaults captures.
The final build splits presentation from lifecycle observers and captures the
immutable workspace context. Complete original logs are retained in `.build/artifacts/`.
Owner reports build 75 still exits on satellite
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

Validation: 513 Swift, 104 cloud, 18 Companion and 17 packaging/resource tests passed;
one Windows-only helper test was skipped on Mac and excluded from that total.
New tests cover workspace separation/relaunch, failed seeds, demo fixture round-trips,
drag ranges and diagnostic values. IPA inspection verified arm64 app/extension,
SDK 27.1, compatibility IDs/entitlements, 13 icons and bundled helpers/notices.
Phone acceptance remains pending: toggle demo on/off, sweep-select deleted demo
items, and check satellite zoom/pin saving once. Do not describe the crash as fixed
without phone evidence. No public release, deployment, or paid billing change.

## GitHub access restored; Actions still account-blocked

Owner reported the GitHub account unbanned and requested a sync/build attempt.
Verified `N3moStudio/Elsepin` remains private, Actions enabled, and push access
works. Fast-forwarded `origin/codex/pins-search-69` from `ea41165` to `bdbc5da`,
matching the existing local/GitLab source and build-75 handoff. GitHub `main`
was not changed. Local checkout/branch and `remote.pushDefault=gitlab` remain.

[Run 42448203209](https://github.com/N3moStudio/Elsepin/actions/runs/42448203209)
used `bdbc5da4476c3e91070ff0dae1479a30c4a0ede1` but was rejected before any step
ran. Check annotation: "The job was not started because recent account payments
have failed or your spending limit needs to be increased." This does not identify
an exact remaining-minutes balance. Do not repeat the unchanged rejected job or
change billing. Existing Codemagic build 75 is complete (not still queued), and
its verified Desktop IPA remains unchanged. No release/deployment or other build
was cancelled. Both private remotes retain the same production source.

## Build 75 - device-feedback follow-up, privately validated and delivered

Current branch remains `codex/pins-search-69`. Latest delivered IPA is **2.6.1 (75)**,
built from `fc3887a00b85eeed97d911461ffc07a46e3d8481` by private Codemagic run
`6aeffd199b54af17623a586e`. Owner requested this test build on 7 November;
no public publication is authorized. It includes these fixes after build 74:

- Route labels explicitly belong only to the route, not the saved pin library.
  Search fields now belong to their editor views rather than an ancestor native
  search controller; leaving a search editor clears focus and cancels its work.
- Keep the prepared preview until the first location write succeeds. A definite
  pre-write failure with no previous location to clear restores the preview;
  uncertain writes retain the existing interrupted-session/clear safeguards.
- Prepared, recovered and recalculated routes preserve their own smoothing.
  In-route changes say "This route only" and do not overwrite future defaults.
- Remove retained SwiftUI coordinate-converter fallbacks from native pin
  gestures; keep MapKit recognizer configuration stable during holds. Reject
  invalid camera/overlay values. Add opt-in settled-map/style and route-start
  diagnostics, with no per-frame logging or new polling timer. These address
  credible hazards, not a confirmed cause of the reported zoom-out crashes.
- Pins/routes have Favorite/Unfavorite and confirmed Delete swipes, including
  Favorites. Recently Deleted has Restore/Delete swipes. No destructive full
  swipe; existing trash and active-route protections remain.
- Import Overview groups selected additions and current-to-applied setting
  changes. Fix corrupt separators and legacy glassPanel comparison with the
  actual surface. Existing schema, identifiers and selective import stay intact.

Validation: 640 automated checks passed (501 Swift, 104 cloud, 18 Companion,
17 packaging). One Windows-only helper case was skipped on the Mac and excluded
from that count. Native app/extension compilation passed with zero compiler
warnings/errors. Both arm64 bundles are 2.6.1 (75), SDK 27.1; identities,
entitlements, helper downloads and all 13 icon choices passed IPA inspection.
Complete original logs/receipt are in ignored
`.build/artifacts/codemagic-6aeffd199b54af17623a586e/`.
The first run `6aeffac04ed44a8f85aaa7c7` passed all tests and compilation but had
one callback-ownership warning; final source fixed it and the full run was repeated.
Only `Elsepin 2.6.1 build 75.ipa` (18,767,708 bytes) was delivered to the Desktop
project IPA folder after verification, replacing 74; other projects were untouched.
Private GitLab source is updated; no public release or deployment. Phone crash,
gesture/layout and battery acceptance remain distinct from these build checks.

Owner confirms staged routes survive map taps and reopen from Recents; connection
retry and ending a route while holding location worked. Pairing/code access and
the smaller UI were reported working earlier. Idle warmth settled; this is not
a measured energy result. Owner reports repeated zoom-out exits on satellite
labels and while a named pin/route was visible. The previously available November 5 log is no longer in Downloads as of
November 8. No new incident export is present; obtain it if the exits continue.
See the short current [device checklist](TESTING.md). Crashes still block release.

## 2.6.1 (74) - simpler planning and explicit path choice - privately validated/delivered

Cross-network leg changes now offer Keep current path or Recalculate directions.
The existing travel-section format retains the new speed/mode on unchanged geometry.
Planning removes Whole route, Individual leg settings, Route notes and Edit names
& places. Plain leg rows replace boxed controls. Arrival belongs at Destination;
three-dot menus rename start/stops/destination, with Name route at Start. Move
places on map stays. Active edits still require explicit hold confirmation.

Restore native Back/edge-pop in pushed editors; standalone dismissals remain.
Add Stop's map expands with search and custom-pin selection followed by explicit
confirmation. Saved automatic routes support searched stops; exact-path pauses
snap to the unchanged path and still need Add. Idle guidance has no collapse arrow.
AGENTS/UI-POLISH record grouping by task rather than a card per small control.
No identity, backup-format, provider or movement-cadence changes. Private run
`6aeebd6324e1ec23755711eb`, source `b66aad460fca0be505e5a7e98edb019ab38acdf6`,
passed 634 checks (495 Swift, 104 cloud, 18 Companion, 17 packaging), native app
and extension compilation and IPA inspection with zero compiler warnings/errors.
One Windows-only helper skip is excluded. Both bundles are 2.6.1 (74), arm64,
SDK 27.1. Evidence is in ignored `.build/artifacts/codemagic-6aeebd6324e1ec23755711eb/`.
Only `Elsepin 2.6.1 build 74.ipa` (18,721,476 bytes) was delivered to the Desktop
project IPA folder, verified before removing build 73 there. Previous IPA remains
archived internally; other projects were untouched. No public release/deployment.
Phone retests: cross-network Keep current path versus Recalculate, back swipe from
destination/leg/map editors, custom stop selection, arrival/naming menus and idle tray.

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
