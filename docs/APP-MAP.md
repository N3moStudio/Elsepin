# Shift app map

Maintained alongside the [Shift Change Ledger](CHANGE-LEDGER.md). Source paths
are relative to the repository. Current main source: unreleased 2.5.8 (57), prerelease channel, consolidated 26 October 2026. The published 2.5.7 release is unchanged; validation is recorded in the ledger.
This continues the original source/branding catalog without treating historical
Locus identifiers as safe search-and-replace targets.

| Area | Main owners | Responsibilities |
| --- | --- | --- |
| Reset / local wipe (unreleased) | `Shared/AppResetRules.swift`, `Locus/Support/AppResetController.swift`, `Locus/Features/Settings/AppResetSection.swift` | Settings-only defaults; full local wipe or preserve pairing/setup; destructive review, app-lock authentication, idle/native-worker guards, failure reporting; [scope and tests](RESET-AND-RECENTLY-DELETED.md) |
| Recently Deleted selection (unreleased) | `Shared/DeletedLibraryItem.swift`, `Locus/Support/RecentlyDeletedStore.swift`, `Locus/Features/Settings/RecentlyDeletedView.swift` | Select/all/none, mixed type confirmation, stale selection guard and atomic permanent deletion |
| App entry / privacy | `Locus/App/LocusApp.swift`, `Locus/Support/AppPrivacyController.swift`, `Shared/PrivacyRules.swift` | Setup, unlock, file/deep-link entry, protected content |
| Motion pilot (unreleased) | `Locus/Support/ShiftDesign.swift`, `Locus/Features/Map/RootView.swift`, `MapHomeView.swift` | Opt-in immediate press feedback and scoped spring release on six map actions; native button semantics, Reduce Motion and disabled-state gates. [Audit, priorities and device acceptance](MOTION-AUDIT.md); not yet natively compiled or device-tested. |
| Tray and joystick touch safety (unreleased) | `Locus/Features/Map/RootView.swift`, `Locus/Features/Joystick/JoystickPad.swift`, `Shared/ControlInteraction.swift`, `Tests/ControlInteractionTests.swift` | Cancel restores the tray's committed anchor and immediately zeros held movement. Block stale touch/nudge callbacks; only the visible pad accepts input. Native handle button, projected release, finite vectors and Reduce Motion. 16 new logic tests pass in WSL; iOS event delivery/feel still needs native validation. |
| Tabs / session tray | `Locus/Features/Map/RootView.swift` | Map/Library/Settings navigation, compact route controls, selected-tab restoration |
| Map / route planning | `Locus/Features/Map/MapHomeView.swift`, `Locus/Features/Routes/RoutePlannerSheet.swift`, `Locus/Engine/RoutePlanner.swift`, `RouteBuilder.swift` | Place selection, route alternatives, numbered timeline, editable plans |
| Stop durations | `Locus/Features/Routes/StopDurationControl.swift`, `RoutePlacesEditor.swift`, `TripViews.swift`; `Shared/SpeedUnit.swift`, `TripFeatures.swift`, `RouteLifecycle.swift` | One h/m/s editor across screens; shared bounds, countdown and live insertion |
| Rehearsal / editing | `Locus/Features/Routes/RouteEditorViews.swift`, `PathEditorSheet.swift`; `Shared/RouteEditing.swift` | Preview-only playback, seeking, stop restoration, path/section edits |
| Actual simulation | `Locus/Engine/SpoofSession.swift`, `Locus/Features/Routes/TravelControls.swift`, `Locus/Features/Joystick/JoystickPad.swift` | Commands, movement, pause/resume, confirmation evidence and stop progress |
| Backup input (2.5.5 test) | `Shared/BackupImportReader.swift`, `Locus/Support/LibraryBackupInput.swift`, `Locus/Features/Settings/LibraryBackupView.swift` | File-data picker and native Paste; shared validation; bounded coordinated reads; persistent presentation; review navigation |
| Units / library | `Shared/SpeedUnit.swift`, `Locus/Features/Settings/UsualSpeedsSettingsView.swift`, `SettingsView.swift`, `Shared/LibraryBackup.swift` | MPH/KPH at display boundary; saved speeds remain MPH; places/trips/backups |
| Interface / icons | `Shared/ShiftAppearance.swift`, `Shared/ShiftBrandViews.swift`, `Locus/Support/ShiftAppearanceController.swift`, `Locus/Features/Settings/AppearanceSettingsView.swift` | Nine light/dark themes, thirteen independent icon choices, saved preferences, shared widget marks, native appearance transition |
| Approved icon sources / exports | `Brand/AppearanceIcons/design-approval.yaml`, `Brand/AppearanceIcons/approved-sources.json`, `scripts/prepare_approved_icons.py`, `scripts/check_appearance.py` | Approved complete artwork, source digests, reproducible sizing, automatic system appearances for four additions; preserves historical icons |
| iPhone verification | `Locus/Support/LocationVerificationController.swift`, `Shared/LocationVerification.swift` | Fresh iOS location report compared to timestamped sent points; not proof of another app |
| External reports | `Locus/Support/CompanionClient.swift`, `RemoteFindMyController.swift`, `Companion/`, `CloudFindMy/` | Windows Apple/Life360 adapters and Render Apple/Life360 adapters; independent auth/error/freshness states |
| Cloud settings / help | `Locus/Features/Settings/RemoteFindMyView.swift`, `FindMyChecksView.swift`, `Locus/Support/RemoteFindMyController.swift`, `docs/CLOUD-GUIDE.md` | Compact existing settings, Advanced tutorial link, optional Nearby capability discovery; no new native polling or automatic movement |
| Nearby place alerts (experimental) | `CloudFindMy/nearby.py`, `nearby_web.py`, `web_push.py`, `web_ui.py`, `static/`, `test_nearby.py` | Independent opt-in fixed-circle monitoring; existing Apple device or authorized Life360 Circle members; freshness/uncertainty/confirmation, explicit acknowledgement, repeat policy, encrypted private state and Web Push. No Find My People, moving real-me anchor, or native IPA push |
| Live Activities / Island | `Locus/Engine/SessionActivityController.swift`, `Shared/SessionPresentation.swift`, `Shared/RemoteFindMy.swift`, `Shared/CloudServiceChecks.swift`, `LocusActivity/LocusLiveActivity.swift` | One activity with separate Find My and Life360 evidence, visibility preferences, stale handling and app links |
| Official update notices | `Shared/StableReleaseUpdates.swift`, `Locus/Support/AppUpdateController.swift`, `Locus/Features/Settings/AppUpdateNotice.swift`, `SettingsView.swift` | Daily foreground-only GitHub check, ETag/cache/dismissal persistence, stable version and URL validation, native Settings notice; build channel in app Info.plist/project settings |
| Packaging / validation | `project.yml`, `Locus.xcodeproj/project.pbxproj`, `.github/workflows/build-ipa.yml`, `scripts/`, `Tests/` | Versions, identities, sources, model/helper tests, app/extension build, IPA validation |

## Branding boundaries

- Visible names and descriptions: SwiftUI copy, notifications, Info.plist display
  strings, help/setup, README/release text and helper pages. Review all together
  for any future selected name.
- Visual assets: `Brand/`, icon packages/catalogs, previews, screenshots, and the
  shared activity/widget mark. Update resource references and packaging checks.
- Compatibility contracts: bundle IDs/app groups, URL schemes, Keychain services,
  defaults keys, widget kinds, backup formats and helper protocols. These require
  a migration decision, not a blind replacement of Shift/Locus text. The official
  update endpoint and allowed release URLs are also tied to the repository identity.
- Attribution: retain upstream names in licensing, notices and historical facts.

No new brand has been selected. The 2.5.0 identity separation is already a storage
migration from 2.4.x; see [migration instructions](TESTING-2.5.md).

Selective import (official from 2.5.7): `Shared/BackupImportReview.swift` owns per-setting differences and selection plans; `Locus/Features/Settings/BackupImportReviewView.swift` owns the checkboxes and confirmation. `LibraryBackupView.swift` owns file/Paste input and export scope. See `IMPORT-TEST-CHECKLIST.md` for separate samples.

Named areas: `Shared/NamedArea.swift` owns interior-overlap geometry; `NamedAreasView.swift` and `PathEditorSheet.swift` show validation; `SketchMapView.swift` caches saved outlines and labels. Persistence/import guards are in `SpoofSession.swift` and `LibraryBackup.swift`.

Location widgets: `Shared/WidgetLibrary.swift` owns the bounded name/ID catalog and preview links; `HomeWidgetPublisher.swift` publishes on changes; `LocusHomeWidgets.swift` owns App Intents configuration; `RootView.swift` resolves saved IDs into preview pins only. Only manual controls call Teleport/Start.

## Elsepin 2.6 maintenance

Start with the [Product Atlas](BRAND-MAP.md) for appearance, identity, distribution and compatibility dependencies. The older entries above describe historical source owners.

## 2.6.1 appearance and compatibility navigation
- `Shared/ShiftAppearance.swift`: theme catalog, Bloom default, retired Abyss decoder. Keep unknown JSON values as errors; do not silently map every invalid theme.
- `Shared/AppearancePolicy.swift`: Solid/Glass choices, fixed typography and legacy `theme`-to-Solid decoding. Preserve serialized backup compatibility.
- `Locus/Support/AppearancePresentation.swift`: rounded/compact presentation; never shrink accessibility categories.
- `Locus/Support/SessionPreferences.swift`: persisted surface/theme and theme-owned color mode. Preserve storage keys.
- `Locus/Features/Settings/AppearanceSettingsView.swift`: theme/surface/icon UI. All Elsepin icons remain available.
- `Locus/Engine/SpoofSession.swift`: backup export/import integration; fixed exported typography and ignored retired controls.
- `Shared/BackupImportReview.swift`: selectable import fields; retired presentation controls must not reappear.
- `Tests/AppearancePolicyTests.swift`, `Tests/LibraryBackupTests.swift`, `Tests/BackupImportReviewTests.swift`: migration, library preservation and selective-import regression coverage.

Settings search layout: `Locus/Features/Settings/SettingsView.swift` owns the inline title, automatic navigation search drawer and scroll-content top margin. Preserve swipe-to-reveal; do not force `.always` or overlay search over the list. Confirm scroll behavior on-device.
