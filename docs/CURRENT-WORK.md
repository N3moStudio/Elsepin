# Elsepin current handoff

Updated 30 October 2026. Read AGENTS.md, inspect Git status, preserve newer work.

## Current source and boundaries
Private source: N3moStudio/Elsepin, main. Development version 2.6.1 (61), unreleased. Public downloads/help: Elsepin-Releases. Last known public release 2.6.0; 2.6.1 is a draft with no assets. Recheck remote state before publication. No release, IPA build or deployment was authorized by this UI-polish task.
Elsepin is the full app. Veypax is separate; do not copy paid gates or branding. Preserve bundle IDs, defaults/Keychain keys, app group, backup formats and manual movement confirmation.

## Current UI and compatibility
- Eight themes, Bloom default/reset, legacy Abyss maps to Bloom. Thirteen icons retained. Rounded/compact shared presentation respects accessibility sizes.
- Only Solid and Liquid Glass are selectable surfaces, in that order. Solid is default. Legacy serialized theme material maps to Solid; explicit Glass persists. Color mode follows theme; legacy typography/color backup fields decode without overriding fixed presentation.
- Settings retains its automatic swipe-revealed native search drawer, inline title and top content margin. Keep the compact settings layout, but retain the larger “MAKE IT YOURS / Your space. Your way.” identity card (70-point icon, title2 heading and theme/surface subtitle). This is the user's final comparison choice; do not shrink it during routine polish. The duplicate Appearance row stays removed; Appearance remains searchable. Surface picker is above themes.
- LibraryBackupView opens json.site in BackupJSONBrowser, a native Safari sheet. The footer intercepts only that link. No script bridge, automatic upload or clipboard read; native Paste and existing selective import review/confirmation remain unchanged. Done returns to the importer. File picker and export paths remain intact.

## Validation
30 October pairing follow-up: all 422 portable Swift tests passed (eight new PairingActivityTests), plus 14 Python checks and the app/extension identity check; changed native pairing/activity/setup files passed syntax parsing. Logs: .build/pairing-activity-swift.log, .build/pairing-activity-python.log, .build/pairing-activity-parse.log and .build/pairing-service-final-parse.log. Native compilation and real-device pairing/Island timing remain pending.
30 October: 60 focused Swift tests passed for BackupImport, LibraryBackup, AppearancePolicy and Personalization. Swift syntax parsing passed for changed UI files. Logs: .build/settings-polish-swift.log, .build/settings-polish-parse.log. Syntax parsing is NOT iOS SDK type-checking.
29 October: full 414 portable Swift tests and 14 Python tests passed for the surface migration/search-spacing change. Logs: .build/settings-surface-swift.log and .build/settings-surface-python.log. No newer shared-model changes in this polish pass.
Build 61 has NOT been natively compiled. Next requested native build must regenerate project.yml with XcodeGen. Use the acceptance checklist in TESTING.md. Phone layout, Safari file/copy/dismissal flow, provider behavior, signing and battery remain separate acceptance.

## Last delivered IPA (does not contain build 61 follow-ups)
Native run https://github.com/N3moStudio/Elsepin/actions/runs/40826806154 passed at source 506923c3f2f3d7a545ea660474361c575079732f. Both targets: 2.6.1 (60), SDK 27.1. Thirteen icons verified. Ad-hoc packaged; user sideload signing required.
Local: C:/Users/naith/Downloads/Elsepin 2.6.1.ipa (18,192,618 bytes).
SHA-256: 3e72bc2646e112e9664d586e60332bc4341e2ff08aa9370d26b9628f43fba547.
Drive file ID: 1xrv44UVD0SLQ9yQEKvqtI9BjrfwRJi03. Do not claim it contains the current Settings/browser changes.

## Navigation
PairOnDeviceService now starts setup presentation while foregrounded and publishes the native PIN callback to the existing Island/Lock Screen. SessionActivityController.shared serializes setup and movement through SessionActivitySelection. Codes are transient, privacy-sensitive and stale-aware. Completion/cancel/failure and a five-minute visibility timeout clear presentation and the PIN notification. A blocking native accept may still finish after UI cancellation; its old callback box is disconnected and its worker gate stays locked until it returns.
The comparison decision is compact overall with the original larger identity card; the eight theme rows/swatches and thirteen icon choices remain intact. The card-only correction passed Swift syntax parsing; device layout remains pending.
APP-MAP.md locates UI/migration entry points; BACKUPS.md describes import rules; CHANGE-LEDGER.md records evidence; docs/releases/2.6.1-DRAFT.md contains release text. CHAT-WORKFLOW.md covers sparse optional delegation.
Deleted arena branch remains deleted; recovery history is .build/elsepin-arena-3430259.bundle. Its reviewed appearance changes were subsequently explicitly authorized and reapplied. Website catalog source has eight themes but has not been redeployed in these follow-ups.
