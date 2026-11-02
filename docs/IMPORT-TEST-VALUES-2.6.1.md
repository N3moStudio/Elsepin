# Build 66 — legacy backup values to check

Use `Shift-Settings-Test.json`. The fixture carries 25 historical values; **24
are selectable settings in this app**. Its old Appearance=Light field still
decodes but is no longer an editable setting. Theme palettes, compact text and
rounded font remain governed by the current appearance policy. Counts of actual
changes vary with what is already on your phone.

| Setting | Expected after selecting it |
| --- | --- |
| Liquid Glass (legacy setting) | On / Liquid Glass surface |
| Speed units | mph |
| Walk preset | 4 mph |
| Run preset | 6.5 mph |
| Cycle preset | 12 mph |
| E-bike preset | 18 mph |
| Drive preset | 32 mph |
| Smooth movement | Off |
| Prefer walking paths | Off |
| Panel shortcuts | Joystick, Saved, Settings, in that order |
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
| Save recent locations | On; Don't save recent locations is Off |
| History retention | Keep until I delete |
| Map style | Standard |

Settings start unchecked in review. Select only what the current test step asks
for. An unchanged value does not count as a change. Pairing, helper secrets,
icons, app lock, recents and recovery points are not part of this fixture.

`Shift-Routes-Areas-Test.json` contains 2 routes, 2 places, 2 areas, no settings:

| Item | Expected |
| --- | --- |
| REVIEW TEST - South loop | Walk, 3 mph, smooth off; waits 15 and 90 seconds |
| REVIEW TEST - North loop | Run, 6 mph, smooth on; waits 30 seconds and 2 hours |
| REVIEW TEST - South start | 40.7701, -73.9751 |
| REVIEW TEST - North start | 40.7731, -73.9731 |
| REVIEW TEST - South area | Four corners around the synthetic South loop |
| REVIEW TEST - North area | Four corners around the synthetic North loop |

The folder is `Shift review test`. These old fixture names intentionally test
compatibility; they are not evidence of incorrect visible app branding.

`Elsepin-Area-Conflict-Test.json` uses a different ID with the exact North area
outline. Import North area first; then this conflict must be rejected/deselected
without damaging existing data. If North area is absent, it is a valid standalone
area and an overlap rejection is not expected.

`Elsepin-Legacy-Appearance-Test.json` includes retired `abyss`, material `theme`,
font `monospaced`, and size `large`. Select only Theme and Surfaces when reviewing:
expect **Bloom / Solid / compact / rounded**. The old font/size values must not
reintroduce removed controls. Its other values match the legacy settings fixture;
leave those unchecked for this targeted test.

`Shift-Everything-Test.json` combines the legacy settings and library fixtures.
`Shift-Import-Test.json` is an older combined example: 2 places, 1 route, settings.
All files here are synthetic test data. Keep your own exported backup separately.
