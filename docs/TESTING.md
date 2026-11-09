# Validation

## Current: build 76 phone checks (8 November 2026)

Build 76 passed 652 checks, native app/extension compilation and IPA inspection,
with zero compiler warnings/errors. Source `1e7b5dc`, Codemagic
`6af16be955fc448af77585cd`. This does not prove the reported satellite-zoom exit is
resolved. No full setup/reset tour is needed; the focused device checks are:

1. With no active or uncertain session/recovery, enable Dev Mode in Advanced &
   experimental -> Testing tools. Edit a demo pin, disable it, and verify the real
   library returns. Enable again and verify a fresh demo dataset.
2. In demo Recently Deleted, tap Select and drag down the selection-circle gutter;
   reverse upward, then tap Done. Selection follows the range; scrolling still works
   outside the circles. Normal tap selection and delete confirmation remain available.
3. Start one short route, switch to Satellite + labels, zoom, then save/select a
   named demo pin. No exit or frozen controls. If it exits, stop repeating the
   failing action and retain the new incident log/time for diagnosis.

Live connection/provider and widget-signing requirements still apply in Dev Mode;
the synthetic dataset does not simulate a successful connection or initiate spoofing.
No new incident export was present in Downloads during build 76 work.

## Previous: build 75 phone checks (7 November 2026)

The build-75 IPA was **2.6.1 build 75**, privately compiled and package-verified
after 640 passing automated checks, with zero compiler warnings/errors.
The owner has confirmed preview pin-tap protection, Recents reopening, connection
retry and ending a route while holding location. Earlier pairing/code access and
recently-deleted selection also worked. No need to repeat setup or wipe data.
Idle warmth settled, which does not establish measured energy use.

The owner wants minimal testing. **At minimum, do item 3 once on build 75**:
it targets the repeated phone-only crash that automated tests cannot rule out.
The rest is a short optional regression pass rather than another full setup tour:

1. **Planner/keyboard:** Add a searched stop, go Back, label Start, then Cancel
   and Save once each. No search bar or extra X may remain on the planner. Labels
   must not create Library pins. Confirm left-edge Back in the search editor.
2. **Start/retry:** With no existing spoofed location, turn LocalDevVPN off and
   start a ready route. After failure the route stays ready. Turn VPN on and
   Start again; do not claim active until the first successful write. Stop after
   confirmation. A failed clear must still say unconfirmed rather than cleared.
3. **Map crash blocker:** Start a short route; switch Standard → Satellite +
   labels, zoom out/in, and select a named pin. Repeat once on Standard. No exit,
   frozen controls or unexpected pin movement. If it exits, record the time and
   export the new incident log; stop repeating the failing gesture.
4. **Smoothing:** Plan with Smooth On, start, confirm the route menu says On.
   Turn Off there, then recalculate a different travel mode: it stays Off for
   that route. A separate saved/prepared Smooth On route must still start On.
5. **Library/import:** Swipe a disposable pin and route in both their category
   and Favorites; Unfavorite preserves the item, Delete moves it to Recently
   Deleted, Restore brings it back. Import a backup with one pin and one changed
   setting: Overview must reflect checked items and exact old → applied values;
   cancel once, import, then re-import to confirm no duplicates/false changes.

Source checks cannot close item 3. The available Downloads developer log is from
November 5 and does not include these newly reported crashes. No release approved.

## Build 62 UI acceptance (pending device checks)

- In Settings → Connection → Pair on this iPhone, confirm three connected steps,
  no Pairing help section, and a readable themed background. Check Bloom, Ion,
  and one light theme, with both Solid and Liquid Glass.
- Start pairing and confirm the real status/PIN still appears. Complete or cancel
  the attempt; the existing Dynamic Island, notification and in-app fallbacks
  must behave as in the build 61 acceptance checks below.
- In a draft route's Mode & speed section, confirm Walk, Run, Cycle, E-bike and
  Drive are visible without horizontal scrolling. Select each mode and check its
  existing speed and route behavior. At accessibility text sizes, verify a single
  readable column, VoiceOver selection feedback and no clipped labels.
- Keep the larger Settings Appearance card, swipe-revealed search and existing
  library/import/export behavior. Native compilation does not prove these phone checks.

## Public GitHub build — 2.4.4, build 47 · 15 October 2026

- The original uploaded run compiled the app and extension successfully but failed the final IPA icon validator. It also warned about the capitalization of two default-icon image filenames.
- Those issues were corrected in commit `b7278e8`. The maintainer supplied a GitHub Actions screenshot showing the corrected run succeeded.
- The supplied logs recorded 279 Swift model tests and 69 Windows/cloud helper tests passing. The 12 new IPA/resource regression tests passed locally and were added to the workflow before the successful rerun.
- The maintainer subsequently confirmed that the IPA installs and works on their iPhone. This records basic on-device use; a detailed per-feature checklist and exact tested IPA checksum were not supplied.
- Commit `53bb018` subsequently configured direct downloads and version-derived filenames. The successful screenshot above predates that download change; it is not evidence of a separate completed run for that upload behavior.

The release notes no longer carry the checksum or SDK-specific packaging claims
from the earlier portable IPA. Record the exact tested IPA's hash and build run
when attaching it to a release. A renamed file keeps the same bytes and hash;
a rebuilt or re-signed IPA may not.

## Earlier portable package — historical evidence

The earlier 2.4.4 portable package passed 279 Foundation tests in Swift/Linux,
compiled the app and extension against iOS SDK 27.1, and passed archive,
entitlement, resource, notice and portable-icon checks. Its public copy redacted
local compiler paths and recomputed ad-hoc signature/resource hashes.

That package used explicit system-size icon PNGs. Native Xcode builds use asset
catalogs, including any/dark/tinted artwork. The two packages have different
build evidence and must not share an assumed checksum simply because both
identify as 2.4.4 (47).

## Device checks before relying on a release

1. Launch cleanly, update over an existing install, and confirm pairing/library retention with the same signing setup.
2. Test pairing, a connection check, teleport, Stop, and recovery after a failed clear. A failure must stay visible.
3. Draw/tap/edit a route and a named area; pan/pinch with two fingers, wait through status updates, then undo, cancel and save. Drafts and the map must remain stable.
4. Rotate the map and move the joystick in all directions; release/background it and confirm movement stops.
5. Start/pause/resume/end a route, exercise stops and jumps, and check the last point before Stop.
6. Switch all styles and icons, light/dark, large text, VoiceOver, Reduce Motion and Reduce Transparency. Confirm a fresh regular notification on the device; do not infer it from the Home Screen icon.
7. Check widgets and Live Activities with extension signing intact, including stale evidence, privacy settings and an unavailable helper.
8. Export/import a library, restore a deleted item and an earlier trip version. Do not use your only backup for testing.
9. Compare similar battery/reliability runs; account for charging, screen use, signal, Low Power Mode and interrupted execution.

Passing model tests and an IPA build do not establish native gesture behavior,
account sign-in success, notification appearance, or continuous background operation.

## Build 61 Settings and JSON sheet acceptance (pending device checks)
- With Solid and Glass, reveal/cancel Settings search, open a search result, return, and confirm the first card has space below the search area. Repeat at an accessibility text size.
- Tap the larger “Your space. Your way.” Appearance card. Confirm Surface is near the top, both choices persist across themes, all eight themes/thirteen icons remain reachable, and Back preserves navigation.
- In Import & export, tap json.site. Confirm Safari opens inside the app. Use a non-sensitive fixture file on the site, copy JSON, tap Done, then tap the app's Paste button. Check the same selective preview/confirmation flow; dismissal alone must not import anything.
- Close Safari with Done and swipe dismissal, reopen it, and test offline/error pages. The importer must remain usable and must not retain a stuck sheet.
- Cancel the Files picker; then open Safari. Repeat with a successful file import and an export. Confirm modal presentations do not overlap and cancellation cannot write imported data.
- Check VoiceOver link/action labels, long translated labels, keyboard behavior and the larger Appearance card at the largest accessibility size.

## Build 61 pairing Live Activity acceptance (native build passed; device checks pending)
- Start on-device pairing with Live Activities enabled, then switch directly to iPhone Settings. Confirm a single Elsepin activity appears before the code exists, progresses to Preparing code, then shows the six digits on press-and-hold. It must match the native pairing prompt/in-app code, including leading zeros.
- Repeat with notification permission denied. The activity must not depend on notification authorization. Repeat with Live Activities disabled and the extension omitted; the app/notification fallback must remain usable and pairing must not crash.
- Complete pairing, cancel from either setup entry point, fail a pairing attempt, and leave the setup screen. Confirm code/activity removal, cleared PIN notifications, and no late callback restoring the old code. After cancellation native work can still finish; retry must explain a busy worker rather than silently do nothing.
- Wait five minutes with the code displayed; test Lock Screen privacy/redaction and a stale activity after suspension/force-quit. The code must be hidden when the system marks the activity stale. Do not infer native-code validity from this presentation timeout.
- Confirm regular spoofing/journey/Find My/Life360 activities still work after setup and on restart, including Live Activities off, stale-state handling and Stop. Setup cannot start over an active spoofing session.
- Inspect expanded layout and VoiceOver digit reading on supported Dynamic Island phones, plus Lock Screen fallback on phones without an Island. Record OS/signing/extension setup. Portable tests cannot prove background delivery, rendering latency or energy use.
