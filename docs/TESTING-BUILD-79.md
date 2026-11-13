# Build 79 phone spot checks

Automated tests and packaging do not prove finger alignment, visual spacing,
MapKit names or LocalDevVPN behavior. These are focused checks of the new work;
use Dev Mode for disposable data. No release is published by a test build.

1. **Route save and star:** Open Demo Garden Walk, Show route, toggle its star,
   and check Favorites and Routes. Unfavorite must keep one saved route. Create
   a new route from the map: the first star offers Save to Library or Save &
   Favorite. Create one from Library: Save route & preview saves it unstarred.
2. **Pins:** Add pin in Library. Save starts disabled. Search or tap a location,
   then use the suggested name or enter one. Expand the map and return; the pin
   stays put. Choose an emoji and fixed color, save, then change theme. Its color
   stays fixed; Follow theme changes with the theme. Check its name/address in
   Recents and confirm tapping a pin during a route does not alter that route.
3. **Areas:** Draw three or more corners. Undo twice and Redo twice. Undo once,
   add a different corner, and confirm Redo clears. Expand the map, search and
   return; the outline remains. Save/reopen starts without old Redo history.
4. **Selection and tray:** In Recently Deleted, Select and drag down/up through
   the circles before and after scrolling. The selected rows should match your
   finger. Check one-action and Teleport/Stop tray spacing; buttons stay reachable.
5. **Optional next route:** In the planner, After arrival > Next route, choose
   Return to start or another destination, then Use this route. Set a short wait
   and explicitly enable automatic start. Start the first route normally. At
   arrival the second starts once after the wait. In a separate attempt, cancel
   the next route or Stop before arrival; it must not start later. Automatic
   permission is deliberately not restored after relaunch or prolonged suspension.

For a connection check, turn LocalDevVPN off before a new explicit Start or
Teleport: it must not report a confirmed successful write. A previous location
may remain until clearing succeeds. Re-enable LocalDevVPN and clear normally;
accepted writes do not independently prove Find My or Life360 received them.

Report only failures and the step involved. Export diagnostics if there is a new
exit to Home Screen or unclear connection state; no log is needed for a clean pass.
