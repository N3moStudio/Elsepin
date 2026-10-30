# Validation

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
