# Local cleanup and native orb review

2 November 2026. Base: `60f084ee829a218e57e9dbf3325b0f34f92e80ed` on private
Elsepin `main`. Working tree was clean before editing. Repository access succeeded;
the other chat's earlier Permission denied result did not recur. No restriction was
bypassed. This pass is local and uncommitted: no push, release, deployment or new IPA.

## Cleanup completed

Reference review covered 169 remaining Swift source/test files, plus tracked project
references. The installed Axiom Swift simplifier's 26 detection patterns were also
run individually over `AppearancePolicy.swift` and `SetupReadiness.swift`; their
surrounding code was reviewed. No cosmetic shorthand rewrites were needed there.
Removal candidates were checked for ordinary references, framework requirements,
entry points and retained replacements; a lone text occurrence is not proof of dead code.

| Removed | Evidence and preserved implementation |
| --- | --- |
| `MapDropPin.swift` | No construction site. Current map/marker implementation remains in `MapHomeView.swift` and `MapPinAdjustment.swift`. The earlier motion audit also identified this view as dormant. |
| `LocusEasterEggView.swift` | Unreachable SwiftUI value type, with no navigation/presentation entry point; not an app entry point or dynamically registered Objective-C class. |
| `ShiftSettingsLink`, `ShiftSettingsDivider`, `ShiftSettingsGroup`, `IconButton` | No callers. Current Settings rows, card, press style and map controls remain. |
| `NamedAreasView` wrapper | No callers. `SettingsView.swift` still constructs `NamedAreasSection` and `NamedAreaEditor`; drawing, validation and saving remain. Other types in `NamedAreasView.swift` were retained. |
| Six unused helpers/properties | `coordinateLabel`, `SetupStage.welcome`, `ShiftVisualStyle.defaultMaterial`, `ShiftPalette.activityBackground`, and the two unread SetupGate getters. Setup raw cases, keys and writes remain unchanged. |

Physical diff totals: **0 production Swift lines added, 264 removed**. **0 test lines
added or removed**. Eight obsolete Xcode-project reference lines were removed for the
two deleted files. Documentation changes are counted separately. No minification,
feature gating, blanket abstraction removal, token-savings or speed claim.

## Left as-is

- Backup font/text-size enums, raw values, keys, compatibility IDs and decoding.
- Apple protocol members such as `affectsColorAppearance`, Widget/App entry points,
  AppEntity query/display members and activity `ContentState` alias.
- Supported iOS 18 floor, all themes/icons, accessibility, larger Settings identity
  card and native controls. No visible reachable UI was redesigned in this pass.
- Active gesture, route movement/retry, Stop, pairing, network trust and notification
  behavior. Removing an unused function from `SpoofSession` is not a route-crash fix.
- Large live SwiftUI bodies: structural extraction needs a separate, focused SwiftUI
  architecture review because it can change identity/state. Not justified for line count.
- Existing AGENTS.md and complete skill manuals; no new global preload or hooks.

## Verification

- 443 Swift tests passed before and after cleanup using the existing WSL Swift 6.4
  toolchain. No test source/expectation changed; this does not measure runtime coverage.
- 16 packaging/icon tests passed; app identity, all 13 icon choices/31 supplied images,
  appearance metadata and both exact helper ZIP manifests passed.
- All eight modified, retained Swift files passed syntax parsing in Swift 5 mode.
- No warnings/errors in the final portable test or parse logs. The first parse wrapper
  failed before compilation because Windows emitted CRLF; fixed only the local script's
  line endings and retained both failed and successful logs.
- Deleted symbol/project-ID checks and `git diff --check` passed. Build 66 in Downloads
  still hashes to `aadde4ce1d7277d4ca182a8d2c8bbd2fb6b03dac63528f19ae08ec7c7d1ebc22`.
- **Native Xcode build not run.** This is Windows; the supported Mac workflow needs
  uploaded changes, and this request does not authorize a push. Portable tests and
  syntax parsing do not prove Apple SDK type checking or physical-device behavior.
  Build 66's previous native success applies to its original source only.

Evidence: ignored `.build/cleanup-before-swift.log`, `cleanup-after-swift.log`,
`cleanup-packaging-tests.log`, `cleanup-native-parse-first.log`,
`cleanup-native-parse.log`, `cleanup-simplifier-scan.json`, `cleanup-metrics.json`.

## Requested tools: status and fit

| Tool | Decision and boundary |
| --- | --- |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | Instruction-only skill is a possible complement. Installation approval is pending in the coordinating chat; not installed or executed. Do not enable its lifecycle hooks or replace AGENTS.md. |
| [Addy agent skills](https://github.com/addyosmani/agent-skills) | Select code-simplification, code-review-and-quality, test-driven-development and context-engineering on demand after approval. Not installed. No full-suite preloading. |
| [Graphify](https://pypi.org/project/graphifyy/) | Optional local code-only AST index, not required for these removals. Docs advertise a local code path, but Swift resolution and useful savings here remain unverified. Not installed/run; no LLM transmission, cloud account or hooks. Existing APP-MAP plus targeted search sufficed. |
| [OmniRoute](https://github.com/cheaper-inference/OmniRoute) | Separate model-routing infrastructure, not source cleanup. Not installed/run; no provider, key, endpoint, account, model or server changes. |

No private app code was sent to an external model. The proposed savings have not
been benchmarked; measured line deletion does not establish lower future token use.

## Thinking Orbs: proposed native integration, approval pending

[Native package documentation](https://github.com/Jakubantalik/Libraries.dev/tree/main/packages/thinking-orbs/ports/ios/ThinkingOrbsKit)
describes `Canvas`/`TimelineView`, Reduce Motion static rendering and a `paused` flag.
The root [package manifest](https://github.com/Jakubantalik/Libraries.dev/blob/main/Package.swift)
requires iOS 17; the isolated orb package supports iOS 15. Both fit Elsepin's iOS 18
minimum. No React/WebView bridge or Metal dependency is needed for ThinkingOrbsKit.
Its MIT notice must accompany any approved integration. No source installed or run.

Two bounded placements after exact dependency approval:

1. A 20-point searching orb beside the existing truthful search/loading text in
   `RoutePlaceSearchSheet` and `RouteStopSearchSheet`, only while the request is in flight.
2. A connecting orb during explicit helper Test connection in `RemoteFindMyView`.
   Preserve cancellation, error text, touch targets and existing busy-state ownership.

No always-running map decoration, PIN animation, fake AI/microphone state, or extra
Live Activity animation. Use static feedback for Reduce Motion, Low Power Mode and
inactive scenes; remove off-screen/finished indicators. Keep a single accessible
status label rather than having VoiceOver announce both the label and the orb.
Use a pinned reviewed revision and only ThinkingOrbsKit. Verify licensing/source,
theme contrast, accessibility sizes and actual iPhone energy/frame behavior before
claiming improvement. Upstream benchmarks are not Elsepin device measurements.

## Undo

Before applying later work, use the saved reverse patch
`.build/cleanup-2026-11-02.patch` with `git apply --reverse --check`, then
`git apply --reverse` if the check passes. It covers this pass's tracked changes only;
remove the newly added review document separately if desired. Do not reset all files
after another chat edits them. Original bytes for the eleven production/project files
are also in `.build/cleanup-2026-11-02-before/`, with a manifest. Neither method touches
build 66 or the existing Downloads test pack. Source remains recoverable from base HEAD.
