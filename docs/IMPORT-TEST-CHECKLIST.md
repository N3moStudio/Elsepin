# Shift 2.5.7 (56) — selective import checklist

Before testing, export your current settings using **Settings → Import & export →
Export a backup → Settings**. You can restore those choices afterward.
Choose either test JSON with **Choose backup file**, or copy its entire text and
use **Paste backup text**. Both open the same **Review import** screen.

## Settings file: Shift-Settings-Test.json

Expected contents: **25 settings, 0 routes, 0 saved places, 0 areas**. Settings
start unchecked. Expand Settings to see Current and Import values. Values already
matching your phone say **Already the same** and need no change. The number of
available changes therefore depends on your current preferences.

| Setting | Imported value |
| --- | --- |
| Appearance | Light |
| Liquid Glass Map Controls | On |
| Speed units | mph |
| Walk preset | 4 mph |
| Run preset | 6.5 mph |
| Cycle preset | 12 mph |
| E-bike preset | 18 mph |
| Drive preset | 32 mph |
| Smooth movement | Off |
| Prefer walking paths | Off |
| Panel shortcuts, in order | Joystick, Saved, Settings |
| Live Activities | On |
| Lock Screen: hide location name | Off |
| Lock Screen: route progress | On |
| Dynamic Island: hide location name | On |
| Dynamic Island: route progress | Off |
| Dynamic Island: update timer | Off |
| Find My iPhone status | On |
| Life360 status | Off |
| Connection warnings | On |
| Session reminder | 60 minutes |
| Connection check interval | 15 seconds |
| Save recent locations | On (Privacy: Don't save recent locations is Off) |
| History retention | Keep until I delete |
| Map style | Standard |

Test selecting only Appearance and Walk preset. Confirm just those two changes;
all other settings should keep their prior values. If your units stay km/h,
the 4 mph walk preset should display approximately **6.4 km/h**. Then import the
file again and select all remaining changes. Restart Shift and verify the table.
Importing settings does not connect accounts, start a session, change an existing
route's saved speed, or add any locations. The settings file omits credentials,
helper URLs/keys, app lock, icon choice and recent-location entries because these
are not part of the existing portable backup format.

## Library file: Shift-Routes-Areas-Test.json

Expected contents: **2 routes, 2 saved places, 2 named areas, 0 settings**. Expand
the three groups to choose individual items. New entries start selected. Folder:
**Shift review test**. These coordinates are a made-up test path in Central Park,
not a verified walking itinerary.

| Item | Expected details |
| --- | --- |
| REVIEW TEST - South loop | Walk, 3 mph, smooth Off; 5 points; stops 15 seconds and 1 minute 30 seconds |
| REVIEW TEST - North loop | Run, 6 mph, smooth On; 5 points; stops 30 seconds and 2 hours |
| REVIEW TEST - South start | Saved place: 40.7701, -73.9751 |
| REVIEW TEST - North start | Saved place: 40.7731, -73.9731 |
| REVIEW TEST - South area | Named area with 4 boundary points around the South loop |
| REVIEW TEST - North area | Named area with 4 boundary points around the North loop |

1. First import: keep only South loop and North area checked. Select none for
   Saved places. The summary should show **1 route and 1 named area**.
2. Confirm. Find South loop in the Library folder and North area in your named
   areas. North loop, South area and both saved places should still be absent.
   Your settings should be unchanged.
3. Import the same file again. South loop and North area should say **Already
   saved — keep current…** and be unavailable. Select the four remaining items.
4. Edit a test item's name, then import again. The edited version must remain,
   with no duplicates. Restart Shift and verify the routes, waits and boundaries.
5. Delete the clearly labeled test entries when done; keep your own backups.

## Cancel, file picker and accessibility

- Select nothing: Import selected changes should be disabled.
- Cancel import or cancel final confirmation: no settings/library writes.
- Back out of review and tap Review selected backup: keep your selections.
- Try malformed text: explain the failure without replacing a valid preview.
- Try the older combined Shift-Import-Test.json: all included groups use
  the same review; original route geometry and waits are preserved.
- If file selection fails, open the JSON at json.site, copy its contents and
  use Paste in Shift. No backup is sent to a website by Shift.
- Check large text and VoiceOver: each row should speak its name, current/import
  values or item details, and selection state. Existing items are disabled.

Automated checks validate selection, preservation, duplicates, limits and sample
contents. Native build validation checks compilation and packaging. Actual Files,
LiveContainer, accessibility and persistence after relaunch require an iPhone test.
