# Elsepin brand and compatibility map

This is the **Product Atlas**: the quick route from a requested change to its implementation and its side effects. Pair it with `APP-MAP.md` for features and `CHANGE-LEDGER.md` for delivery evidence.

## Identity

Current display name: **Elsepin**. Say “ELSS-pin”: elsewhere + pin. Primary artwork: **Prism Jumpgate**, selected from the approved existing collection. No other icon/theme is removed from the regular edition.

| Surface | Source of truth / implementation | Change with care |
|---|---|---|
| Brand inventory | `Brand/product.json` | Build/config/scripts must agree; inventory is not a runtime override |
| Home Screen name, permission prompts | `Locus/Resources/Info.plist`, `LocusActivity/Info.plist` | Keep installation IDs and signing entitlements stable for upgrades |
| Default/alternate icons | `Shared/ShiftAppearance.swift`, `project.yml`, `Brand/AppearanceIcons/manifest.json` | Manifest first item is primary; retain old asset names for installed alternate icons |
| Theme palette | `Shared/ShiftAppearance.swift` | Contrast tests cover all inks on canvas/surface; website reads these palettes |
| Theme defaults | `Shared/AppearancePolicy.swift` | Pure presentation policy; no session, map or route mutation |
| Overrides / persistence | `SessionPreferences.swift` | User choices survive theme changes; settings reset includes override keys |
| Font, relative size, navigation chrome | `AppearancePresentation.swift`, `ShiftDesign.swift`, `RootView.swift` | Never recreate the root with an appearance `.id`; preserve Dynamic Type accessibility sizes |
| Glass/solid controls | `Theme.swift`, `RootView.swift` | Solid mode must cover floating controls and tabs, not just the tray; OS alerts remain system-owned |
| Settings organization | `SettingsView.swift`, `Shared/Personalization.swift` | Update destinations and search aliases together |
| Manual/automatic updates | `AppUpdateController.swift`, `Shared/StableReleaseUpdates.swift`, `AppUpdateNotice.swift` | Manual skips daily gate only; backoff, one in-flight request, official-only filtering remain |
| Live Activities / widgets | `LocusActivity/`, `Shared/ShiftBrandViews.swift` | Keep widget kind names and activity schema compatible; report provider evidence honestly |
| Pairing host / notifications | `PairOnDeviceService.swift`, `PairableHostAdvertiser.swift`, `SessionNotifications.swift` | Display host name changes; pairing format and stored credentials do not |
| Export names / helper packages | `LibraryBackupView.swift`, `scripts/package_helpers.py`, `scripts/build-ipa.sh` | Regenerate archives after any helper/docs/license edits; never include live credentials |
| Portable appearance backup | `LibraryBackup.swift`, `BackupImportReview.swift`, `SpoofSession.swift` | Optional fields keep older files readable; individual checkboxes must preserve unchecked fields |
| Website | `website/public/`, `website/build.py` | Publish only generated `website/dist`; never the repo or cloud helper state |
| Licenses | `LICENSE`, `NEW-ADDITIONS-LICENSE.md`, `OpenSourceNotices.txt` | A brand change does not remove copyright or prior license grants |

## Deliberately retained compatibility identifiers

- Bundle IDs `com.n3mostudio.shift` and `.activity`; shared group `group.com.n3mostudio.shift`.
- `shift://` links and widget kind `ShiftLocation`. Changing a widget kind can orphan an existing widget.
- `locus.*` / `shift.*` preference keys, keychain service names, backup format `Shift library`, and `ShiftAppearance.json`.
- Source/target names `Locus` and `LocusActivity`, vendor APIs, historical release records, and original legal notices.
- Helper protocol fields such as `X-Shift-CSRF`. Renaming HTTP/storage protocol identifiers requires compatible readers and a migration.

Visible download/export filenames and pairing host labels use Elsepin. Existing pairing/backup file contents remain accepted independent of filename.

## Repository boundaries

- `N3moStudio/Elsepin`: private implementation, tests, build configuration, website source.
- `N3moStudio/Elsepin-Releases`: public approved downloads, release notes and help only. Never put signing keys, source checkout archives, session state or credentials here.
- `N3moStudio/Veypax-Basic-Ultimate`: separate private paid product with its own identity and enforced plan policies.

Deleting the former Shift repository breaks old links/update endpoints. It cannot revoke licenses or erase others' clones. The old repository's code, releases and issue records are preserved locally before deletion; no history is falsified.

## Editing checklist

1. Find the responsible area above and inspect its callers.
2. Preserve data/identity contracts unless there is a tested migration.
3. Add a short comment only where a non-obvious side effect or boundary matters.
4. Run focused tests; for SwiftUI changes, validate a native app/extension build as well.
5. Update the Change Ledger with exact changes and evidence; label device checks separately.
