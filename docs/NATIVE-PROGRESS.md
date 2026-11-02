# Native request progress

Build 67, 2 November 2026. User-approved, private test build only.

## Scope and source

The existing place search and route-stop search use a 20-point searching orb.
Cloud helper's explicit **Test connection** uses a connecting orb. These are
truthful request states, not AI activity. A single label component reuses the
existing theme/typography environment and the existing request-owned busy flags.
No delay, polling, persistent animation, gesture change or new permission.

[ThinkingOrbsKit](https://github.com/Jakubantalik/Libraries.dev/tree/54722cc9a3dcb167037f7d449d6cca4d174e9eb5/packages/thinking-orbs/ports/ios/ThinkingOrbsKit)
is pinned to `54722cc9a3dcb167037f7d449d6cca4d174e9eb5` in `project.yml`.
Only that product links to the app. The iOS 18 minimum and extension remain unchanged.
The source uses Canvas and TimelineView; no network, microphone, web bridge or
additional runtime dependency is used by this target. Its preset cache is locked.
The MIT notice is included in the existing in-app OpenSourceNotices resource.

`ElsepinProgressLabel` hides the decorative orb from VoiceOver and exposes the
existing status text once. The orb scales with accessibility type. Reduce Motion,
Low Power Mode, inactive scene or disappearance selects the upstream static Canvas
path, which does not construct TimelineView. Completion removes the entire label.
This visual policy never controls the request, movement, cancellation or Stop.

## Skills applied

Installed unchanged, instruction-only, without hooks or global rule changes:

- Ponytail `96608e078b2d5ea607c5c3b8b5a54d1c1fba6846`: one small shared label,
  existing busy state and existing power notifications; no loading framework.
- Addy `301b02b12bff98e4688e6984af6556802322bbde`: code-simplification,
  code-review-and-quality, test-driven-development, context-engineering.
  Cleanup and feature commits are separate; inspect callers and data/OS boundaries,
  prove tests fail for a broken motion gate, retain logs and short indexed handoffs.

The three referenced Addy documents and upstream licenses were installed too.
Receipt: ignored `.build/approved-upstream-review/installation-receipt.json`.
AGENTS.md and earlier skills were preserved. Graphify/OmniRoute were not installed;
no model, key, routing, hook or remote analysis configuration changed. No token,
battery or performance savings are claimed from line counts or upstream benchmarks.

## Validation

Four motion-policy tests first failed against a deliberately incomplete policy,
then passed. An inverted Low Power guard caused the expected failures, and was
restored before the full suite. Logs: `.build/orbs-{red,green,mutation,full}-swift.log`.
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

Portable tests cannot establish VoiceOver speech, layout, frame pacing or energy.

## Focused phone acceptance

These checks are also included as steps 204–213 in the updated 226-step
[complete walkthrough](TEST-WALKTHROUGH-2.6.1.md). Use that walkthrough for one
continuous installation-to-cleanup sequence; this list is the short motion retest.

1. Install the separately numbered build 67 IPA over Elsepin without deleting it.
   Confirm Settings shows 2.6.1 (67), and your library/appearance are retained.
2. Search for a place using the keyboard Search button. During a slow request,
   expect the small orb and **Finding place…**, with **Cancel search** still usable.
   Fast results may finish before the indicator is noticeable; no delay was added.
3. Cancel a request, change the query and search again. The newest results should
   appear, with no stuck label or accidental movement. Select only when ready.
4. Plan a route, open stop search and choose Coffee. While loading, expect
   **Searching places…** and Cancel. Confirm results and Along route/Everywhere
   work as before. Cancel and reopen without adding a stop.
5. If your own cloud helper is already paired, open its Advanced section and tap
   **Test connection**. Expect **Connecting…** then the existing result/error.
   This is a connection check, not proof Apple/Life360 reported a location.
6. Repeat a search with iOS Reduce Motion enabled: the orb stays still and the
   text/results/Cancel still work. Restore your preferred accessibility setting.
7. Repeat with Low Power Mode enabled. Expect the same static feedback. Restore
   your previous power setting. Do not expect the network request itself to pause.
8. During a request, open Control Center or lock the phone, then return. Feedback
   should resume or disappear if finished; the request must not be restarted by
   the visual, and returning must not initiate movement.
9. Check a dark theme and Porcelain/light appearance, then a large accessibility
   text size. Expect readable status text, visible orb and reachable Cancel.
   Restore your preferred theme/text settings afterward.
10. With VoiceOver, inspect progress: expect the status once, with no duplicate
    “searching image” announcement. Cancel remains a separate action.

## Delivered previews and verification

Downloads contains `Elsepin build 67 - Visual Previews/index.html`, two JPEG
captures of the mockups, their source/license note and the build receipt. Its
matching ZIP is portable. These are browser-rendered mockups with geometry exported
from the pinned Swift package, not simulator or device screenshots. Native layout
and dynamic fonts are approximated. Default and phone-width layouts were inspected;
no browser console errors were recorded, and the phone layout did not overflow
horizontally. The preview honored the host's Reduce Motion setting, so no claim of
visually testing its moving frames is made. The current screenshots show static
states; the offline HTML provides an explicit Play/Pause control.

The current code diff from `60f084e` adds 52 and removes 268 production Swift
lines (net 216 removed), with 23 new test lines. This distinguishes the original
264-line cleanup from the added native-progress functionality. Dependency source
is separately pinned upstream, not counted as application line deletion.

## Undo

Revert the focused native-progress commit to remove the package, label, call-site
changes and four new tests. Revert `8b8cb07` separately to restore unused code.
Review newer edits first; do not reset the working tree or remove user backups.
Uninstall only the five named skill folders and their added reference/license
files if no other installed skill relies on them. No hook/config rollback is needed.
