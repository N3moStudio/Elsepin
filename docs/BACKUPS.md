# Import and export — official 2.5.7

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
