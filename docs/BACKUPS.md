# Import and export — official 2.5.7

## Build 75 review (privately built; phone import check pending)

Overview now groups only selected additions and current-to-applied setting values;
it does not compare with app defaults. Speed descriptions use the units that will
actually remain after selective import. Legacy `glassPanel` is compared against
the current effective `material`; unchanged legacy values are not false changes.
The backup wire format, old files, IDs, unchecked-settings default and duplicate
handling are unchanged. A current route's smoothing is saved with that route;
settings exports continue to contain the future-route smoothing default.
The expanded BackupImportReviewTests passed within 501 Swift tests, alongside
native app/extension compilation. Phone import/layout acceptance is still separate.

## Build 73 retired tray shortcut compatibility

Keep the serialized `settings` and `batterySaver` shortcut enum cases so old
settings files still decode. Validation accepts their former unique, at-most-three
shape, then normalizes away the retired buttons; duplicate/malformed lists still
fail. Re-exports use the current choices. Main Settings remains available.
Route leg edits use existing travelSections/stop/speed fields, with interval and
Codable tests; no format version bump or identifier migration. Planned Recents
stay local and obey history opt-out/retention; they are not exported as library data.

## Build 69 pin/favorite compatibility (unreleased)

All named pins are exported and reviewed, including unstarred pins. Favorites
are a flag on the saved item, not a second copy. Missing `favorite` on a legacy
saved-place record means favorited; missing it on a saved route means unstarred.
The optional flag round-trips in the existing v1/v2-compatible library shape.
Older app versions can still read these backups but may show every pin as a
favorite because they do not understand the new flag. Existing local identities
still win during import. Recent pins/routes remain local history and are not
backup contents. Widgets continue to offer all saved pins.

The historical instructions and examples below retain their original names.

## Map visibility choices (build 70)

Build 71 adds optional `display.mapPinSize` (22–64 points). Old backups leave the
current size alone; new backups can review/import the size independently. The
default is 34 points and reset restores it. No file format or identity changes.

Settings exports include optional `display.showSavedPinsOnMap` and
`display.showNamedAreasOnMap` flags. Review lists Pins on map and Areas on map
independently. Missing flags in old backups preserve the phone's current choices;
older versions ignore the added fields. These are display-only choices and never
remove library data or stop area naming. Both default to on and settings reset
restores them. File format/version and legacy fields are unchanged.

Open **Settings → Import & export**. Choose a backup file, or copy its complete
JSON text and use **Paste backup text**. The small [json.site](https://json.site)
link opens an editor where you can open the file and copy its JSON. Shift never
sends the backup to that site automatically. Copy the contents, not a file link.

## Review before importing

One importer accepts settings-only, routes/areas-only and combined backups.
**Settings & Library Import Overview** reports differences from the phone's
current data: new routes, new saved places, new areas and changed settings. These
are all available changes before checkbox selections, not total file contents.
Already saved identities keep their current versions and do not count as additions.

Expand each group to check individual items. Changed settings appear before
**Already the same** values, with Current and Import values beside each change.
Settings start unchecked; new library items start selected. The bottom summary
shows only checked changes. Tap **Import selected changes**, then confirm.
Canceling makes no writes. Reimporting does not duplicate existing items.

File/Paste analysis and review can run while spoofing. Library-only imports can
also be applied while active. **Changed settings require stopping spoofing**:
movement, interval and activity settings must not change under a live session.
Uncheck Settings if you only want to add library items now.

New area interiors cannot overlap existing or other selected areas. Shared borders
are allowed. Overlap errors identify an area; uncheck the conflicting outline or
edit it separately. Legacy backups remain readable and existing local versions
are kept. Original route geometry, stops, speeds and waits retain their meaning.

## Export choices

The default is **Everything**, followed by **Settings**, then **Saved routes &
areas** (which includes saved places). The formats remain compatible with older
Shift/Locus v1/v2 backups. Settings are the existing portable allowlist of 25
preferences; pairing, helper credentials, app lock, icon choice, recent-location
entries and recovery points remain on the phone.

Both file and text readers validate contents with a 32 MiB limit. The file-data
picker avoids dependence on JSON extension recognition. Provider files may need
to be downloaded in Files first. Failed/canceled reads preserve a valid preview;
late results cannot replace newer input. Unrelated JSON, GPX, pairing files,
partial JSON and web links are not library backups.

## Test files

- [Everything](Shift-Everything-Test.json): all 25 supported preferences, 2 routes,
  2 saved places and 2 named areas.
- [Settings only](Shift-Settings-Test.json): all 25 preferences, no location data.
- [Routes and areas](Shift-Routes-Areas-Test.json): 2 routes, 2 saved places,
  2 named areas, no settings. Stops include 15/90/30 seconds and 2 hours.
- [Exact values and selection checklist](IMPORT-TEST-CHECKLIST.md).

Export your own settings before testing. If test items/settings already match
this phone, the overview correctly shows fewer changes, possibly zero. The
samples describe made-up Central Park paths, not verified walking itineraries.

## Device checks

Check local/provider file selection, pasted JSON, cancel/retry, relaunch persistence,
large text and VoiceOver. Test individual selections, reimport after local edits,
active-session library import and the changed-settings stop guard. Test an
invalid input after a valid preview. The build/test evidence does not establish
physical-device behavior for every file provider or signing configuration.

## Earlier combined import test

Use [Shift-Import-Test.json](Shift-Import-Test.json). The preview should
show **2 saved places and 1 saved trip**, with settings available. **Expand Settings and select the values you want before confirming**; they start unchecked. After importing, open
**Library → Shift import test** and find **TEST - Park loop** with waits of
**15 seconds** and **1 minute 30 seconds**. The coordinates describe a made-up
test path in Central Park, not a verified walking itinerary. Importing the same
file again should not create duplicates. Delete the clearly labeled test items
when finished. You can select the file or copy all of its text and use Paste.

### Settings included in the sample

The revised sample includes every preference currently supported by the backup
format. Only the checked settings replace those choices. Export your own settings
first if you want to restore them afterward.

| Setting | Expected value |
| --- | --- |
| Appearance | Dark |
| Liquid Glass Map Controls | Off |
| Map style | Hybrid (satellite imagery with labels) |
| Speed units | km/h |
| Walk / Run / Cycle / E-bike / Drive presets | 5 / 10 / 20 / 25 / 50 km/h |
| Smooth movement | On |
| Prefer walking paths | On |
| Panel shortcuts, in order | Saved, Speed, Pause / Continue |
| Live Activities | On |
| Lock Screen: hide location name | On |
| Lock Screen: route progress | Off |
| Dynamic Island: hide location name | Off |
| Dynamic Island: route progress | On |
| Dynamic Island: command timer | On |
| Find My iPhone status | On |
| Life360 status | On |
| Connection alerts | On |
| Session reminder | 30 minutes |
| Connection check interval | 10 seconds |
| Save recent locations | On (Privacy: Don't save recent locations is Off) |
| History retention | Keep until I delete |

The route itself stays at its saved 3 mph (about 4.8 km/h); the walk preset of
5 km/h is a separate preference. Importing settings does not start a session or
authenticate Find My/Life360. Their visibility switches affect an existing Live
Activity; provider connections still require your own setup.

App icon/palette choices, app lock, pairing/helper credentials, tunnel address,
actual recent-history entries and recovery points are outside this backup format.
A settings import does not transfer them. Reopen Shift and recheck the values to
verify persistence, then reimport the same file to check that routes/places do not
duplicate.

## Pin name and appearance additions after build 78

`address` and `emoji` are optional saved-pin/BackupPlace fields. Old backups decode
with both absent; old readers ignore them. Emoji is one bounded extended grapheme,
retaining native skin-tone/flag/family sequences. New import validation rejects
multiple emoji or arbitrary strings. User-entered pin names still win over lookup.
The existing serialized `mint` color continues to mean theme accent; its visible
label is now Follow theme. All fixed color values and pin identities are unchanged.
Automatic lookup changes labels only, never a coordinate, favorite status or saved
identity. Fresh Library pin editors center the map without selecting that center.
