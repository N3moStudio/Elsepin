# Elsepin build history

Updated **4 November 2026**, America/Los_Angeles. Read the [full changelog](../CHANGELOG.md)
for feature details. This page separates compilation, test artifacts and published
releases so a successful check is not mistaken for an available download.

## Build 69 — native validation blocked, 4 November 2026

Private run [41970102369](https://github.com/N3moStudio/Elsepin/actions/runs/41970102369)
for `1d12f675bfbfae72a6a94539587da79ffe9e842f` did not start any job. GitHub's
annotation says recent account payments failed or the spending limit needs to
be increased. No Swift tests, native build, package or IPA resulted. Subsequent
review changes are on `codex/pins-search-69`; dispatch a **new run at its latest
head** after the account block is resolved. Complete original run log archive
and diagnostics are retained in `.build/artifacts/41970102369/`.

Local appearance/identity/helper-package checks and 16 Python packaging tests
pass. WSL startup is unresponsive, so the added Swift tests remain unexecuted.
This entry does not replace the successful build 68 evidence below. No public
release, release asset, helper deployment or website deployment was changed.

A fresh owner-requested dispatch,
[41971922423](https://github.com/N3moStudio/Elsepin/actions/runs/41971922423),
at final app source `9d188fb3` received the same billing rejection before any
steps ran. Full annotation JSON and original logs are under
`.build/artifacts/41971922423/`. Main stays at `be810d7`; select
`codex/pins-search-69` when manually running Actions for this update.

## Latest native build and private delivery: 2.6.1 (68) — 2 November 2026

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

## Earlier native build and private delivery: 2.6.1 (67) — 2 November 2026

[Run 41518500417](https://github.com/N3moStudio/Elsepin/actions/runs/41518500417)
passed at `776d1915f742874e3e1ef4a968d7769ca6ddadf5`: 586 tests (447 Swift,
104 cloud, 19 Companion, 16 packaging/icon), native app/extension compilation and
IPA validation, zero compiler warnings/errors. SDK 27.1, both bundles 2.6.1 (67).
Downloads IPA is 18,512,366 bytes, SHA-256
`5b68513fc20b76d29690e8056ac2a5b40c6fd4836b0df14fe563cd87c6cfe741`.
The 226-step build 67 guide and older IPAs are retained. This does not validate
build 68 changes or physical-phone behavior.

## Earlier native validation and private delivery: 2.6.1 (66) — 1 November 2026

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

## Earlier native validation: 2.6.1 (65) — 31 October 2026

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

## Earlier private test build: 2.6.1 (64) — 30 October 2026

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

## Earlier private test build: 2.6.1 (63) — 30 October 2026

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

Failed native attempts: `41173992580` (557 tests passed) and `41174349587`
(560 tests passed). Splitting the map modifier chain resolved the compiler
limit in the final run; these failures were not device-crash reproductions.

## Earlier private test build: 2.6.1 (62) — 30 October 2026

[Run 41126221099](https://github.com/N3moStudio/Elsepin/actions/runs/41126221099) passed
at source `a213d8b37a87759b0db719a9caa2ba571427330e`. This adds the three-step pairing
guide without Pairing help, themed pairing surfaces/actions and all five visible
draft travel modes. All 551 tests passed (422 Swift, 14 packaging/icon, 19 Companion,
96 cloud), followed by native app/extension compilation and signature/package checks.

Artifact `13010842478`: 18,260,198 bytes; both bundles 2.6.1 (62), SDK 27.1;
13 icons and required resources verified. The GitHub digest matches the exact
Downloads copy at `C:/Users/naith/Downloads/Elsepin 2.6.1 build 62.ipa`:
`4d3ccac5a529b957a3ab2eb945747e2eae65d31b9c3837e6a7b8840d6f491d05`.

Logs and receipt: `.build/artifacts/41126221099/`. The same three compiler warnings
as build 61 remain: two deprecated certificate lookups and location-delegate actor
isolation. No new UI diagnostics. Device acceptance is pending; release 2.6.1 is
still an unpublished draft without assets. No website deployment or Drive upload.

## Earlier private test build: 2.6.1 (61) — 30 October 2026

User authorized an IPA in Downloads for pairing/UI testing, with release publication explicitly excluded. [Run 41103527856](https://github.com/N3moStudio/Elsepin/actions/runs/41103527856) succeeded at source `e7065f27ac863199b5d9a26ddcebe596a8154cc6`. All 551 tests passed: 422 Swift model, 14 packaging/icon, 19 Companion and 96 cloud-helper tests. Native app/extension compilation, ad-hoc signature checks and packaging passed.

Artifact `13000346208`: 18,258,461 bytes; both bundles 2.6.1 (61), SDK 27.1; 13 icons verified. Exact GitHub digest matches the copy at `C:/Users/naith/Downloads/Elsepin 2.6.1 build 61.ipa`:
`59031619b950c09b915b9b70ca7a29501dbef3cf2df321356f7098740fe91cbc`.

Original logs and local receipt: `.build/artifacts/41103527856/`. Three pre-existing compiler warnings: deprecated certificate lookup in `CompanionClient.swift:168` and `RemoteFindMyController.swift:392`, and delegate actor isolation in `LocationVerificationController.swift:6`. No new pairing/browser compile warnings. Device UI, background pairing/Island delivery, permissions, sideload signing and energy behavior remain user acceptance checks. Release 2.6.1 remains a draft with no uploaded assets; build 60 on Google Drive is unchanged.

## Current public release: 2.6.0 (59), official — 27 October 2026

Published the exact IPA from successful Mac run `40460137350`, source
`304756f035172d6e8e3406a451ee57c25cd07951`. Workflow tests and native packaging
passed. The Downloads IPA passed integrity and identity checks and matched the
GitHub artifact SHA-256 `c8cb9197d1b856bcd90a9de7d29311f82411eddd7b825a5d32a2080747156d22`.
No rebuild or binary modification was performed during publication.

[Official release](https://github.com/N3moStudio/Elsepin-Releases/releases/tag/v2.6.0)

Earlier development records follow; their no-IPA statements apply to those runs.

The runs below are in the private development repository. Their identifiers and
results are recorded here for traceability; visitors cannot open private CI logs.

| Date/time (Pacific) | Run / source | Result | What happened |
| --- | --- | --- | --- |
| 26 Oct, 7:55 PM | `40441280998` / `a863660` | Failed | Native compilation found appearance migration reading a stored property before initialization completed. Initialization ordering was corrected. No IPA. |
| 26 Oct, 7:59 PM | `40441622492` / `ea91bd2` | Failed | The appearance check expected full file paths, but the generated Xcode project used groups and relative paths. The checker was corrected to validate the generated representation. No IPA. |
| 26 Oct, 8:08 PM | `40442493014` / `b5f5b24` | Passed | 533 automated tests: 404 Swift, 14 packaging/icon, 19 Windows-helper and 96 cloud-helper. Native app and extension compilation passed. Only diagnostics were uploaded; no IPA. |

### Follow-up work, without another app build

- **`991adc1`:** recorded native validation and exported the website for static hosting.
  Public website source/assets were published in `c2051ff`; responsive preview
  checks at 320, 375, 430 and 768 pixels found no horizontal overflow.
- **`217bd09`:** finished the backup-error and diagnostic-export wording. All 32
  targeted backup/log tests passed. The first local test invocation had a shell
  argument error; the corrected invocation reused the compiled tests and passed.
  This two-label cleanup was not followed by another native build.
- **Documentation and workflow update:** refreshed the public introduction,
  published the complete changelog and this register, and simplified Actions to
  **Build Elsepin IPA**. Each future manual run checks the app, builds and uploads
  one IPA. No build or release is started merely by changing this workflow.

Device appearance, real provider responses, notification delivery, accessibility
and measured battery behavior remain separate acceptance checks. The previous
Shift iPhone smoke test does not prove every new Elsepin change on a phone.

## Earlier Shift builds

Elsepin continues Shift. These are **historical Shift records**, not Elsepin
downloads or renamed releases. The original repository is no longer accessible
through its former URL at this review; the records below come from the preserved
Change Ledger and artifact verification notes. Missing dates or runs are not invented.

| Version / build | Date | Recorded run(s) | Changes and outcome |
| --- | --- | --- | --- |
| 2.5.8 / 58 | 26 Oct 2026 | `40414605689` | Six additional themes, four icons and the complete route/cloud/motion update. 526 tests, app/extension build and IPA checks passed. Maintainer tested it on iPhone; the exact candidate IPA was promoted to official `v2.5.8` without rebuilding. |
| 2.5.8 / 57, main consolidation | 26 Oct 2026 | `40398031406` | Consolidated full development work and current setup links. 524 tests and native compilation passed. Packaging was off; no new IPA or release. |
| 2.5.8 / 57, test IPA | 25 Oct 2026 | `40259930059` | Compact cloud UI, helper website, experimental Nearby alerts, safer tray/joystick handling and reset controls. 524 tests, native build and IPA checks passed. Test artifact only. |
| Reset/recovery development | 25 Oct 2026 | `40222489196` | Scoped resets and Recently Deleted bulk selection. 474 tests and app/extension compilation passed. No IPA. |
| 2.5.7 / 56 | 25 Oct 2026 | `40215371297` | Selective import refinements, nearby area outlines/overlap checks and configurable location widgets with mandatory manual confirmation. 455 tests and IPA checks passed. Official release. |
| 2.5.6 / 55 | 25 Oct 2026 | `40211268590` | Per-setting before/after review; individual routes, places and areas; separate exports. 442 tests and IPA checks passed. Test artifact only. |
| 2.5.5 / 54 | 25 Oct 2026 | `40208929771` | File/pasted-JSON import repair, bounded reads and detailed test data. 431 tests and IPA checks passed. Test artifact only. |
| Backup-import development | 24 Oct 2026 | `40167635354` | File/paste import groundwork. 430 tests and native compilation passed; no IPA. A local fixture error was repaired before this successful run. |
| 2.5.4 / 53 | 24 Oct 2026 | `40153593002` | Official promotion with stable update metadata. 420 tests and native/package checks passed. Official `v2.5.4`. |
| 2.5.4 / 52 | 24 Oct 2026 | `40152801782` | Daily, official-only update checks; dismissible cards, caching and release links. 420 tests and IPA checks passed. Prerelease `v2.5.4-beta.1`. |
| 2.5.3 / 51 | 23 Oct 2026 | `40066022555`, `40066390461` | Cloud Life360, shared Live Activity provider rows and clearer helper errors. Both attempts passed 402 tests and built IPAs; the second refined the Island layout and became `v2.5.3-beta.1`. |
| 2.5.2 / 50 | 23 Oct 2026 | `40052908812` | Hours/minutes/seconds stop editor, up to 24 hours per stop, with persistence/countdown coverage. 384 tests and IPA checks passed. Prerelease `v2.5.2-beta.1`. |
| 2.5.1 / 49 | 23 Oct 2026 | `39986065262`, `39986538008` | Compact route controls, timeline, wait presets, scrubbable preview and icon-switch handling. Both builds succeeded; the delivered second build passed 377 tests and included accessibility/help refinements. |
| 2.5.0 / 48 | 22 Oct 2026 | `39913718958` | Seconds-based stops, mph/km/h, independent install identity, notification routing and pairing validation. 373 tests and IPA checks passed. Test artifact only. |
| 2.4.4 / 47 | 15 Oct 2026 | Preserved release notes; no run ID recorded here | Icon/packaging follow-up and native notifications. A successful GitHub build and maintainer iPhone smoke test were recorded. |

Earlier feature milestones, including diagnostic builds 42–43 and versions before
2.4.4, remain in the [complete changelog](../CHANGELOG.md). Some were internal
iterations; their entries do not imply a public release or a separately verified
build. Dates are omitted when no reliable release record exists.

## Preserved artifact fingerprints

These identify past artifacts only. They are **not** checksums for a future
Elsepin download. Copying or renaming an IPA does not make it a new version.

| Artifact | SHA-256 |
| --- | --- |
| Shift 2.5.8 (58), official | `62e73269cccfcaf0da9bfa855768038f75145ae9b060ff9860ee58a916e62a08` |
| Shift 2.5.8 (57), test | `6ff4810cdab58e37e92aa3e848e34c834206ef825ebe2461abc20eb37c2afb5c` |
| Shift 2.5.7 (56), official | `17982b0862722b0d02b4e0097f199959a1c285de798114067312b35908f3b468` |
| Shift 2.5.4 (53), official | `6efa0a1aa3179e61cb29d126e7c77ef2517486c22c2fcb69255b9dcf0e371853` |

## How new records are added

Each build belongs to its actual version and build number. Record failed attempts
and fixes before the final result, distinguish tests from phone acceptance, and
state whether an IPA or release exists. Small source or documentation fixes stay
under the current development entry instead of inventing a new release.
