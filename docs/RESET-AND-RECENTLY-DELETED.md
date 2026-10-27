# Reset Shift and Recently Deleted

Unreleased development work after official 2.5.7. No new IPA or release.

Settings → Advanced & experimental → Reset Shift has Restore default settings
and Wipe everything. Wipe everything opens two choices; choosing one opens a
review with a destructive confirmation and Cancel. No deletion happens on entry.

| Content | Restore default settings | Wipe data, keep setup | Wipe everything & restart setup |
| --- | --- | --- | --- |
| Appearance, installed icon, speeds, controls, privacy, notification and experimental preferences | Defaults | Defaults | Defaults |
| Saved routes and revisions, places, areas, recents, Recently Deleted | Keep | Delete | Delete |
| Trip checkpoint and diagnostic/reliability history | Keep | Delete | Delete |
| Cloud/Windows helper credentials stored by Shift | Keep, checks disabled | Delete locally | Delete locally |
| Device pairing file, tunnel address, completed/deferred setup and last setup step | Keep | Keep | Delete last; show setup |
| Shared widget catalog | Republish current library with default choices | Clear | Clear |
| Installed Home Screen widget configurations | Keep | Keep; old targets unavailable | Keep; old targets unavailable |
| Daily release-check cache/dismissal | Keep | Clear, ignore late responses | Clear, ignore late responses |
| Exports in Files; remote helper accounts; iOS permissions, trust, Developer Mode, LocalDevVPN | Keep | Keep | Keep |

Reset requires no active/unfinished spoofing session, no stop/command in flight,
no running reliability test, and no native setup/pairing work still finishing.
It never calls Stop or sends a location to bypass those gates. App lock requires
fresh device authentication before its preference can be reset. Backgrounding
during authentication cancels the authorization. Open drafts close after reset.

The app disables interaction and incoming imports while resetting. Recovery and
developer-log deletion waits behind earlier writes on their serial queues.
Only Shift's exact helper Keychain service/account entries are deleted. Each
stage reports failure; completed deletions cannot be rolled back. A failed stage
may be partly cleared, later stages do not run, and pairing/setup are last.
This is a local app reset, not revocation of a computer's iOS pairing trust.

Recently Deleted → Select supports individual choices, Select All and Deselect
All. The final alert lists the selected count and content types. Cancel keeps
the selection. Confirmation snapshots exact identities and payloads; changed,
restored or expired selected items reject the entire operation. New items added
after review and unselected items stay. The store writes the complete resulting
bin atomically once and changes memory only after success. Restore still works.

## Device acceptance checks

Use a disposable test installation with exported fixtures, never the only copy
of valuable routes. Test Cancel at each review, empty selection, mixed selection,
Select All, leaving/returning to the screen and restoring an item. Check the
counts, remaining items and relaunch persistence. Exercise save-failure tests
with test storage, not by filling a personal device.

For each reset choice, import known fixtures, set nondefault settings, save a
recovery point and pair only a test installation. Check the table before/after
relaunch. Verify app-lock authentication success/cancel/background, icon reset,
busy/unfinished-stop blocking, and a cancelled pairing worker still blocking
reset until it finishes or the app restarts. Check that old widgets report a
missing target after data deletion and that every widget tap still needs manual
Teleport/Start. Native compilation is separate evidence from these iPhone checks.
