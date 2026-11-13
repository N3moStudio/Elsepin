# Build 80 preparation review

## Build 80 validated and delivered - 12 November 2026

GitHub run 43376928555 succeeded at 6a1a29c: 686 checks passed (547 Swift,
104 cloud, 18 Companion, 17 resources; one Windows-only case skipped).
Native app/extension compiled with zero compiler warnings/errors. Both bundles
are 2.6.1 (80); arm64, entitlements, icons, helpers and notices verified.
Delivered Elsepin 2.6.1 build 80.ipa to the usual Desktop IPA folder, replacing
build 79. Logs/receipt: .build/artifacts/github-43376928555/.
No release published. Physical-device acceptance remains pending. Earlier
not-built/pending-native notes below are superseded by this result.


12 November 2026. Local repairs after build 79; no build 80 IPA has been made.
The owner will request the next Mac build. No release is authorized.

## Confirmed source issues addressed

| Observation | Source finding and correction |
| --- | --- |
| No planner map before directions | The preview was conditional on a valid route. It is now always present, with a bound camera, larger frame and Fit control. |
| Saved/demo directions fail after editing | Accepting Move places on map always requested fresh directions, even with unchanged geometry. No-op acceptance now preserves the path. Refresh/Swap confirm before replacing it; failed recalculations retain an explicit restore snapshot. |
| Categories only near the phone/route | Choose search area can center on a city and use a panned/zoomed viewport. Start/destination and stop search support it. Required regions and result filtering apply only to explicit selections. |
| Bike requests stop at no cycling path | Cycling now falls back once to a labeled walking path only for missing paths or unavailable cycling API. The chosen mode/speed and section settings are retained. |
| Pin taps expand the editor | Expansion was an overlay button in a Form map row. It is now an isolated borderless button beside Search. Phone gesture acceptance remains pending. |
| Editing cannot move/starts too wide | Existing-pin tap/search guards blocked moving. Removed those guards, initialize the camera near the pin, and retain the actual camera across full-screen transitions. |
| Manual names/address/white circle | Manual editor placement only updates location/address. Search may fill a blank name. Main-map labels are name-only; extra symbol backing removed. |
| Moving changes a coordinate-based pin ID | Added source/collision validation, atomic replacement, widget UUID relocation, stale-workspace checks and old-address clearing. Existing routes do not move with the pin. |
| Reversing a mixed-mode route | Previously Swap reversed stops but left incoming-leg choices attached to their old destination keys. Modes and speeds now follow the reversed segments. |
| Extra next-route request | Destination selection used to launch a request that was immediately canceled by a second one. It now starts one request. |

Opening saved/demo routes normally keeps their existing coordinates without a
network request. Source review did **not** establish that merely opening Demo
Garden Walk itself triggers recalculation. That exact device report remains a
retest item rather than a proven root cause.

## Scope preserved

- Backup keys/formats and optional pin fields, old imported trips and speeds.
- Demo workspace isolation, saved route identity and independent favorites.
- Per-leg speed/movement, waits, explicit keep-path/recalculate choice and next route.
- Stop/clear semantics, movement confirmation, manual widget confirmation.
- Annotation crash fix: explicit inputs, no required environment objects inside pins.
- Existing themes, appearance defaults, area undo/redo and gestures elsewhere.
- No provider migration, paid service, new dependency, background polling or build hook.

## Evidence and limits

- Windows resource suite: 17 tests passed. Identity, 13 icons/31 appearance images,
  source text encoding and both bundled helper archives passed their checks.
- All 25 changed/new Swift sources parsed successfully with tree-sitter. This detects syntax
  issues; it is **not** Swift type checking or an iOS build.
- Added 21 portable regression cases for bike fallback/error propagation, pin-ID
  replacement/collisions, geographic bounds including the dateline, unchanged
  map geometry and reversed leg choices. Swift execution awaits the Mac run.
- Reviewed saved/demo loading, Recents library lookup, preparation/dismissal,
  cancellation, next-route handoff, atomic pin updates and widget mapping.
- Not tested here: real MapKit coverage/results, native layout/taps/zoom, physical
  crash behavior, signing, VPN/provider location reports, battery or accessibility
  screenshots. No claim that static checks prove those.
- Experimental cloud/account services, pairing and every unrelated screen were
  not re-audited; their code is unchanged in this repair.
- Old imported paths with travel-section boundaries/IDs that do not correspond
  to their stop intervals still play their stored sections. Recalculating such a
  path cannot be assumed to preserve arbitrary within-leg speed changes; those
  legacy cases need a separate fixture/native check. No backup migration was made.

Apple exposes [cycling directions](https://developer.apple.com/documentation/mapkit/mkdirectionstransporttype/cycling),
but [coverage is not universal](https://support.apple.com/en-ie/guide/iphone/iph431ac5856/ios).
Walking fallback is labeled because pedestrian paths can include stairs or bike
restrictions. It never invents a connection after offline/timeout errors.

## Focused next build/phone checks

1. Open Demo Garden Walk and Library Create route: map visible; saved route opens
   without network. Accept unchanged Move places on map; route stays identical.
2. Bike/e-bike: try available cycling, missing cycling with walking available,
   and offline. Inspect source label, unchanged speed and accurate failure.
3. Search fast food in a chosen distant city/area, then Reset and search outside it.
4. Add/edit pin: map tap stays embedded, manual name stays blank, search can fill
   blank name, movement preserves one record/favorite/style and map shows only name.
5. Reverse a mixed walk/drive route, and exercise failed recalculation plus Restore.

The native run must execute the full existing checks and both app/extension
builds. Keep complete logs outside source. Build 79 remains the delivered IPA
until its verified replacement exists.
