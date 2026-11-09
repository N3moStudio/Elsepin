# Dev Mode isolation

Read before changing library, preferences, recovery or widget persistence.

Settings -> Advanced & experimental -> Testing tools -> Dev Mode opens synthetic
sample data. Turning it off returns to the personal workspace. Re-enabling starts
a fresh sample; relaunch while enabled retains the current demo edits.

`AppDataWorkspace` routes library/preferences to a separate UserDefaults suite and
`Application Support/Locus/DevMode/<UUID>/`. Production keys/files keep their exact
names and schema. No snapshot-and-overwrite restore is used. Seed failure leaves
the personal store active. Publish the routing marker only after seeding completes.

Only the main-actor `DevModeController` switches. It blocks while spoofing, clearing,
pairing/checking, changing icons, running a reliability test or retaining a route/
recovery. Pending recent-route/recovery writes and model callbacks must finish.
Queued work captures its original store/file; never look up the active store from
inside a delayed write. A TripLibrary instance captures its workspace generation
and rejects mutations after switching, including shared-trash operations.

After switching, reload session/preferences/trash, recreate editor/planner drafts,
clear incoming actions and rebuild widget snapshots. Stop/Teleport/Start retain
the same real connection checks and explicit confirmation. No fixture grants a
green provider result or starts playback. Synthetic routes are drawn examples,
not road-verified directions. Cloud checks still require configured helpers;
saved-location widgets still require signing/App Group access.

Device-wide data deliberately stays outside the namespace: pairing and tunnel
address, Keychain/accounts, setup, security/lock settings, app icon, session-lifetime
clear evidence, diagnostics/reliability records and update throttles. App-wide
reset is blocked while demo data is open. Backup import/export uses the current
workspace and the unchanged public format; exports are ordinary user-controlled
files and are not deleted on switching. Demo exports may be manually imported into
the personal workspace, with the usual preview and confirmation.

Fixture coverage: eight pins (starred/unstarred), six routes including eBike and
mixed legs, seconds/long stops, folders, two nonoverlapping areas, edit history,
recent pins/routes and ten deleted items. `DevModeDatasetTests` verifies validity
and old-format round-trips; `AppDataWorkspaceTests` verifies independent files,
relaunch, fresh activation and failure rollback. Swift tests need a Swift host;
native/phone interaction acceptance remains separate.

Build 76 validation: the workspace, fixture and selection tests ran successfully
within 513 Swift tests; all 652 checks passed and the native app/extension compiled
without warnings in Codemagic `6af16be955fc448af77585cd`, source `1e7b5dc`.
This validates compilation/storage rules, not physical gesture or crash acceptance.
