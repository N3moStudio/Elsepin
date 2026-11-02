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
Native compilation, artifact details and final counts will be recorded after CI.
Portable tests cannot establish VoiceOver speech, layout, frame pacing or energy.

## Phone acceptance: follow after the existing 216-step walkthrough

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

## Undo

Revert the focused native-progress commit to remove the package, label, call-site
changes and four new tests. Revert `8b8cb07` separately to restore unused code.
Review newer edits first; do not reset the working tree or remove user backups.
Uninstall only the five named skill folders and their added reference/license
files if no other installed skill relies on them. No hook/config rollback is needed.
