# Elsepin 2.6.1 — complete owner test walkthrough

Prepared 1 November 2026 for private build **66**. Follow the numbered steps in order. A compiled build is not a completed phone test. Nothing in this checklist publishes a release.

Write `PASS`, `FAIL`, or `BLOCKED` beside each step. `BLOCKED` means a prerequisite is unavailable, not that the feature passed. Record a failure as `step / time / what you tapped / what happened`. If the app closes, reopen it and record the time immediately; do not repeatedly retry a failing command. Stop that section and continue only after the connection can be safely cleared.

**Keep these distinctions in mind:** Elsepin has no account to create or sign into. Apple/Life360 credentials are entered only in your own optional helper. A sent location, an iPhone location check, a Find My Devices report, and a Life360 report are different evidence. Find My **People** is not implemented. These tests use places and accounts you own or are authorized to use.

## 1. Save your current data and install

1. On the old installed app, stop any location session. Wait for the clear command to succeed; if it fails, reconnect Wi-Fi and LocalDevVPN and try clearing again before continuing.
2. Open **Settings → Import & export**. Choose **Everything**, export, and save as `Before-build66.json` in Files. Keep a second copy on your computer. This does not back up pairing files, helper secrets, app lock, or every device-only setting.
3. Write down your current theme, surface, icon, units, and the names/counts of your saved routes and favorites. Preserve any original pairing/helper setup files separately and privately.
4. On the computer, locate **Elsepin 2.6.1 build 66.ipa** in Downloads. Do not accidentally install build 64 or 65. The accompanying build receipt records the unsigned/ad-hoc artifact hash; your sideloader changes the signed file.
5. Install/update using the same sideloader, app identity and signing setup used for build 65. Keep the Live Activity/widget extension when signing. Do not uninstall the old app just to test this update.
6. Open Elsepin. Open **Settings → About Elsepin** and verify **2.6.1 (66)**. If it says 65, stop: the new diagnostics are not installed.
7. Check that your saved places/routes and pairing are still present. An update should keep existing preferences; Bloom/Solid are fresh-install defaults, not a forced replacement of your chosen theme.
8. Return to Settings. Reveal **Find a setting** by scrolling at the top; search `diagnostics` and open the result. Confirm the search area does not overlap the larger appearance card.
9. Turn on **Record developer log**. Open **Log tools → Something went wrong**, leave note `Build 66 test started`, and save. This is a deliberate test marker, not a real failure.
10. Open **Session timeline** and confirm the marked time/note appears. Keep detailed recording on through the tests. Its exports contain exact locations; do not post them publicly.

## 2. Connection and on-device pairing

11. Connect the iPhone to working Wi-Fi. Open **LocalDevVPN** and connect it. If missing, use **Settings → Connection → Get LocalDevVPN**, install it, and allow its VPN configuration.
12. In iPhone Settings, confirm Developer Mode is enabled. If enabling it requires a restart, complete that restart and confirmation, then reconnect Wi-Fi and LocalDevVPN.
13. In Elsepin, open **Settings → Connection → Review setup checklist**. Follow its Wi-Fi, pairing, and connection-check stages. A successful setup check must not move your location.
14. If the existing pairing works, finish the checklist and continue at step 20. To exercise new pairing, use **Pair on this iPhone** while no session is active; keep the original pairing file first if available.
15. Tap **Start pairing**. Allow the requested Local Network and Location access. Expect one setup Live Activity, not two overlapping Elsepin activities.
16. Switch directly to iPhone **Settings → Privacy & Security → Developer Mode → Pair with Elsepin**, following the app's three steps. Enter the iPhone passcode only into the system prompt.
17. Touch and hold Elsepin in the Dynamic Island when the six-digit code is ready. Enter it into the pairing prompt, preserving a leading zero if present. The Island, in-app code and notification fallback must agree.
18. Return to Elsepin. Confirm successful pairing and removal of the displayed code. Run the connection check and finish setup. Do not count seeing a code as successful pairing.
19. Later, when idle and able to restore pairing, start another pairing attempt and cancel. Confirm the code clears, no old code reappears, and a still-busy native worker is explained instead of starting overlapping attempts. If re-pairing isn't safe for this install, mark this step BLOCKED.
20. Open **Connection → Import or manage pairing**. Cancel the file picker. Open the paste option with invalid non-secret text; confirm a readable error and that your existing pairing remains. Do not remove your working pairing.
21. For iOS versions without on-device pairing, use the documented computer-created **RPPairing** file path instead. SideStore's own pairing file is not interchangeable. Mark this alternative BLOCKED if you have no test RPPairing file; do not fabricate one.
22. Open **Advanced connection settings**. Read the current tunnel address, then leave it unchanged. Canceling/editing screens must not alter a working connection.

## 3. Appearance, navigation, and accessibility

23. Open the large **Your space. Your way.** card. It should remain larger than ordinary Settings rows. The rest of Settings should be compact and rounded.
24. Select **Bloom**, then **Solid**. Check Settings, Map controls, and Library. Panels should be opaque, text readable, and the selection retained when you go back.
25. Select **Liquid Glass**. Visit the same three tabs. Return to Appearance and select **Solid** again. These are the only Surface choices; no Theme default choice should appear.
26. Select **Glacier**, inspect Map and Settings, then return to Appearance.
27. Repeat step 26 with **Afterhours**, **Porcelain**, **Ion**, **Ember**, **Blueprint**, and **Titanium**, in that order. Ion's dark presentation should have dark green/graphite panels and citron accents. No Abyss option should appear.
28. Return to **Bloom → Solid**. Confirm there is no app font-family or text-size selector. Compact/rounded presentation must not disable the iPhone's accessibility text sizing.
29. In iPhone Settings → Display & Brightness, switch Light/Dark and inspect Glacier, which follows the system. Other themes set their own palette; there is no app color-mode selector. Restore the system choice and Bloom/Solid.
30. In the icon picker, select each available icon once, following the displayed order, including the four Jumpgate/Switchpath options and the finishes of the original three designs. There should be **13 choices**. Check Home Screen artwork and return to Settings after each.
31. Set **Prism Jumpgate** again. Confirm changing an icon doesn't lose the selected tab or require reconnecting a session. iOS may show its own icon-change confirmation.
32. Temporarily enable a large accessibility text size in iPhone Settings. Check Settings search, the appearance card, route buttons, stop duration editor, and the diagnostics export button. Text should remain readable and actions reachable. Restore the original text size.
33. Temporarily enable **Reduce Motion**, open/close the bottom tray and route screens, then restore it. No controls should become stuck. Repeat with **Reduce Transparency** and restore that setting.
34. If you use VoiceOver, enable it and navigate one search result, a stop editor, the route marker's adjustable action, and Stop. Confirm meaningful labels and reachable actions; then turn it off. Mark BLOCKED if you cannot perform this test reliably.

## 4. Map, search, favorite, and teleport

35. On Map, search **Central Park, New York** and press keyboard **Search/Enter**, without choosing a suggestion first. Expect a results list and no app exit.
36. Clear the query and search **Central Park Zoo**. Choose a suggestion. Confirm its map pin and place name. Close search, reopen it, then cancel; cancellation must not teleport.
37. Search nonsense such as `zzzz-no-such-place-98463`. Expect no results or a clear message, not a crash. Search a valid place immediately afterward.
38. Select a nearby point on the map and inspect its preview. Use the pin-adjustment/magnifier control, drag, then cancel once. Repeat and confirm. The selected preview must not automatically become the simulated location.
39. Save a selected point as favorite **TEST A**. Save a second nearby point, roughly one kilometre away, as **TEST B**. Use public test places, not private home addresses.
40. Open Library → Favorites. Open/edit TEST A's name and folder, then return to Map. Confirm selecting a favorite only prepares the pin.
41. Tap **Teleport to pin** (or the shown Start/Teleport action). Expect a confirmed sent update and a single Live Activity. Check Apple Maps separately; do not infer its result from Elsepin's label alone.
42. Select TEST B while TEST A is active. Confirm the preview changes while the sent location stays at A until you explicitly tap Teleport. Then confirm Teleport and check the result.
43. Open **Settings → Advanced & experimental → Check iPhone location → Check now**. Record its result. This reads what the iPhone reports to Elsepin; it is not a Find My or Life360 check.
44. Start another iPhone check, then immediately leave the screen or background the app. Return; the old request should not overwrite a newer check or leave the screen permanently busy.
45. Use the available map styles one after another, then return to Standard. Pan, pinch and rotate. Verify that map controls and the sent-location indicator stay usable.
46. Tap **Stop**. Wait for confirmation that the clear request succeeded. Inspect Apple Maps after allowing it to refresh. If clearing fails, keep the visible warning and reconnect before retrying; do not record PASS simply because the UI closed.

## 5. Build a route and test stops before moving

47. Open the route planner from Map. Choose TEST A as start and TEST B as destination. Wait for directions; if those points have no valid route, choose nearby public road/path points and repeat.
48. Select **Walk**, **Run**, **Cycle**, **E-bike**, then **Drive**, one at a time. After each, check the displayed mode, available directions and speed. End on **E-bike, 10 mph**.
49. Open **Settings → Usual speeds**. Switch mph to km/h. The same 10 mph speed should read approximately **16.1 km/h**, not become 10 km/h. Switch back to mph.
50. Edit a usual speed for each of Walk/Run/Cycle/E-bike/Drive, reopen the screen and confirm persistence. Try each displayed range boundary; invalid values must not enter playback. Use **Restore starting presets**, then set E-bike back to 10 mph for this test.
51. In the draft planner, tap **Add stop**. Search `coffee` with **Along route** selected. Expect map pins and results near the planned path; labels describe path proximity, not a promised road detour duration.
52. Select one result. Confirm it appears as an intermediate stop and directions update. The destination must remain TEST B.
53. Add another stop using a full address and **Everywhere**. Move it earlier/later in the itinerary; confirm order and route refresh. Remove that second stop again.
54. Tap the remaining stop and set its wait to **15 seconds**. Reopen the editor; it should still say 15 seconds.
55. Change the wait to **1 minute 30 seconds**, then **2 hours**, then **24 hours**. Confirm the full duration range is supported and values above 24 hours cannot be saved. End with **15 seconds** so the test is quick.
56. Open **Advanced options → Edit names & places**. Rename the stop **TEST COFFEE** without moving it. The wait and path should remain unchanged. Cancel one edit and confirm it is discarded.
57. Use **Move places on the map** to adjust an intermediate place, then save and inspect refreshed directions. Undo/cancel a second move. Do not mistake the orange order lines for the final routed path.
58. Expand/collapse **Advanced options** and **More options**. Their indented content should be visibly separate from the main route controls and should not jump into unrelated Settings.
59. Turn **Smooth route movement** off. At 10 mph, moving time should be about **6 minutes per mile**, plus the listed stop wait. Record distance, Elsepin moving time, stop time and total. Apple Maps' travel estimate may legitimately differ.
60. Turn Smooth movement on, compare the estimate, then turn it off for the next tests. For cycling, toggle **Prefer walking paths** and inspect the chosen network/path; it is not a guarantee of a dedicated cycling route.
61. Enable **Different mode for each section**, set the first section to Walk and the next to Cycle, and inspect the time estimate and section labels. Disable it afterward and restore E-bike 10 mph.
62. Open **Preview**. Play, pause, scrub, change preview speed, jump to the stop, skip its preview wait, and reset. Only the preview dot should move; no spoofing should start.
63. Close Preview. Save this plan as **TEST ROUTE**, in folder **TESTS**. Reopen it from Library and confirm endpoints, stop, 15-second wait, mode and speed.

## 6. Active route, jump marker, Undo, and Stop

64. Start TEST ROUTE manually. Confirm progress begins and the Live Activity shows the route. Let it move for about 20 seconds.
65. Pause. Wait 10 seconds and confirm route progress stops advancing. Continue and confirm it resumes without racing to catch up for the paused time.
66. **Hold the route line ahead of your current position.** A selectable marker should appear. Record whether any freeze or app exit occurs.
67. **Drag that marker around a corner**, then lift. The marker should follow the route and remain selectable. Your simulated location must not jump merely because you dragged.
68. Tap **Teleport** beside the marker. Confirm progress and remaining distance change to the selected position and no app exit occurs.
69. Tap **Undo** promptly while it is offered. Confirm return to the earlier route position and the appropriate paused/moving state. Undo should not remain available after its time limit.
70. Repeat hold → drag → lift → Teleport **three times**, including a point behind the current location and a point near the end. Do not jump beyond arrival until after the next stop test.
71. Hold a marker, then switch to another app mid-gesture. Return. Expect no stuck dragging state or stale marker that bypasses confirmation. Place a new marker and use it once.
72. Place another marker and wait more than **30 seconds** without holding it. The expired preview should disappear or be rejected. A new hold should work.
73. While paused, jump just before TEST COFFEE and continue. Observe the 15-second wait countdown. **Continue from stop** should end the wait manually; it must not double-count the wait later.
74. Open the active route's **Places & stops → Add stop**, add a wait farther ahead on the existing path, and confirm it appears. Trying to insert behind progress or during an unavailable connection should give feedback rather than crash.
75. For a destination detour, use **Hold location and edit**, then change/add a destination and review the new route before manually starting it. Cancel once and verify the held location remains safe.
76. End/stop the route while keeping the location held if that control is offered, then press the main **Stop** to clear the simulated location. Confirm the distinction between ending playback and clearing the location.
77. Open **Diagnostics → Log tools → Session timeline**. You should see route-jump requests and confirmations/interruption outcomes. A request alone must not say it was confirmed.

## 7. Disconnect/reconnect and app interruption — the previous crash sequence

78. Start TEST ROUTE again. Enable **Settings → Trip recovery → Remember interrupted trips**. Return to Map and wait for at least one confirmed update.
79. In **Diagnostics → Log tools → Mark a test event**, mark that you are about to change connectivity. Note the exact time.
80. Open iPhone **Settings → Wi-Fi** and turn Wi-Fi off there. Do not rely on Control Center's temporary disconnect button. Keep cellular as it normally is.
81. Return to Elsepin for 30–60 seconds. Record whether the existing tunnel survives or becomes stale/disconnected; neither outcome is assumed. A helper's internet availability is separate from a working developer connection.
82. If disconnected, tap Retry once. Expect an explanation or a failed connection attempt, not an app exit, invented success, or lost saved route.
83. Re-enable Wi-Fi and reconnect LocalDevVPN. Return to Elsepin. Use **Retry connection** if offered. A retained route retry should hold it paused until you choose to continue.
84. **Immediately test hold → drag → Teleport again after retry.** This is the important regression sequence. Stop the section if the app exits and record the time.
85. Tap Stop and confirm clearing succeeds. Then start a fresh route and pause it.
86. Turn **Airplane Mode** on in iPhone Settings, checking that Wi-Fi is actually off too. Return to Elsepin; record the loss/staleness and any warning. It must not claim a fresh successful check while offline.
87. Turn Airplane Mode off, restore Wi-Fi and LocalDevVPN, and retry/clear as instructed by the app. Confirm Stop is reachable throughout recovery.
88. Start TEST ROUTE once more. Mark **About to force-close Elsepin**, allow a moment for the marker to save, then swipe Elsepin away from the app switcher. Reopen it.
89. Expect an interrupted/unconfirmed state, not an assertion that closing the app cleared the simulated location. Reconnect. Use **Trip recovery → Resume trip** if a checkpoint is available, then test a new route marker. Record whether progress/stops were preserved.
90. If no recoverable checkpoint exists, mark that result and use **Try clearing previous location** before beginning a new session. Do not loop the same failing recovery action.
91. In Diagnostics, mark **Something went wrong** with note `Recovery test result`, including the approximate earlier event time if it actually failed. A marker made after reopening records that later time; its export is not a crash stack trace.

## 8. New incident export, then full developer export

92. Open **Diagnostics → Log tools → Session timeline**. Under the marker from step 91, tap **Export around this moment**. Confirm the warning mentions locations and notes.
93. Choose **Prepare incident log** and save the file to Files. Expect a smaller JSONL file covering retained events up to five minutes before/after the marker. Export does not wait five minutes or create missing future evidence.
94. Open the file as text on your computer. The first record should be `incident_export_information`, with the selected marker, time range, event count, and truncation/malformed-line flags. A later note for that same marker may be included outside the window.
95. Search for `route_interaction`. Follow one `attempt` through hold/drag/request/queued/write result/completion. A linked `write` ID should match the actual location command. Missing completion is evidence of an unfinished record sequence, not automatic proof of a crash.
96. Go back and cancel another incident export. Confirm the timeline and original full log remain. Turn recording off temporarily and export the retained incident again; exporting must not secretly turn recording on.
97. Turn recording on again. Use **Export data log for developer** to save the complete log. Confirm it still works and contains the full retained batch, separate from the smaller incident file.
98. Open **Settings → Report a problem**, choose a category and inspect the report. This separate report avoids automatic coordinate capture; notes you type may still contain personal information. Cancel sending/sharing unless you intend to share it.

## 9. Joystick and the control tray

99. Teleport to TEST A. Open the joystick. Hold up, right, down, and left in order, releasing between each. Movement should stop when you release.
100. Rotate the map 90 degrees and repeat up/right. Direction should follow the screen/map orientation rather than a stale compass orientation.
101. While holding the joystick, switch apps and return. Repeat while collapsing the tray. No stale touch should continue movement after the control is interrupted or hidden.
102. Open **Settings → Panel shortcuts**. Reorder a shortcut, add one, remove one, and return to the tray. Confirm order/content updates. Reset shortcuts afterward; at least one usable shortcut must remain.
103. Drag the tray between its allowed positions, release halfway, and interrupt another drag by changing apps. It should settle to a usable position with Stop reachable.
104. Press Stop and confirm the simulated location clears.

## 10. Saved routes, drawing, areas, folders, and restoration

105. Open TEST ROUTE, change its name to **TEST ROUTE EDIT**, save, reopen, and confirm the edit. Open its edit-history/version screen and restore the earlier version; inspect the restored name/stops/path.
106. Assign it to **TESTS** using the folder control. Filter/search Library by that folder and by the route name. Check Favorites and Routes independently.
107. In a new route draft, open **More options → Draw an exact path**. Tap at least three points, undo one, add it back, then use the available drawing tool. Two-finger pan/zoom should not add unwanted points.
108. Edit a point/corner in that path, cancel once, then save a short path as **TEST DRAWN**. Open its Preview; it should use your drawn geometry, not silently replace it with road directions.
109. Use **Export selected route** to save a GPX. Start another draft and use **Import GPX** on that file. Inspect the imported geometry before saving. Cancel a second GPX import without changing the current draft.
110. Open Library's Areas view and tap **Draw a named area**. Draw a small non-overlapping triangle around TEST A, name it **TEST ZONE**, and save. Drawing is preview-only.
111. Start drawing another nearby area. Existing outlines must be visible. Attempt an overlapping outline; expect an error and no save. Undo/edit the corners until separate, then save it with the same **TEST ZONE** name.
112. Edit one area's corners; cancel once and verify the original remains. Save a valid edit. Crossing/self-intersecting or too-small invalid outlines should be rejected.
113. Teleport manually inside the first area, check its label in Elsepin/Live Activity, then outside it and check again. The area name does not rename the place inside Find My or Life360. Stop afterward.
114. Delete a test favorite, TEST DRAWN, and one TEST ZONE using the Library controls. Open **Recently Deleted**. Restore selected items, verifying that unselected items remain deleted.
115. Delete only those disposable test items again. In Recently Deleted test Select all/none and cancel a permanent deletion. Permanently delete one disposable test item and verify it cannot be restored.
116. Reopen Elsepin and verify the remaining TEST ROUTE, favorite and area are still present. Do not delete your real library during these tests.

## 11. Backup compatibility and selective imports

117. Stop any active session. In **Import & export**, export **Everything** as `Build66-before-import.json`, then export **Settings** and **Saved routes & areas** separately. Confirm Everything is the initial export choice and saved places are included in the library export.
118. Choose the supplied **Shift-Routes-Areas-Test.json** from the test pack. In the review, expect two routes, two saved places and two areas available only if their identities are not already stored.
119. Check only **REVIEW TEST - South loop** and **REVIEW TEST - North area**; uncheck the other items. Confirm **Import selected changes**. Find only the selected additions. Settings must stay unchanged.
120. Import that same file again. Already-present items should not be duplicated. Select the remaining four additions and confirm. Their folder is **Shift review test**.
121. Inspect South loop: Walk 3 mph, smooth off, waits 15 seconds and 90 seconds. Inspect North loop: Run 6 mph, smooth on, waits 30 seconds and two hours. These are synthetic Central Park paths, not verified road directions.
122. Rename South loop locally and import the original file again. Your edited existing item should be kept, without creating a second copy of the same identity.
123. Choose **Shift-Settings-Test.json**. Confirm settings initially remain unchecked and values that differ appear before Already the same. Select only the Walk preset and speed units, then confirm. Expect 4 mph while unrelated settings stay unchanged.
124. Reopen review and select all remaining settings. Confirm against the separate **IMPORT-TEST-CHECKLIST.md** in this test pack; it lists the legacy fixture values. The old Appearance field is accepted for compatibility but does not create a selectable color-mode change; compact/rounded typography remains fixed. This is not every device-only preference.
125. Choose **Shift-Everything-Test.json**, review it, and cancel. Then choose **Shift-Import-Test.json**, the older combined fixture, and inspect the preview. Expect older supported formats to be accepted without changing pairing/helper secrets.
126. Copy complete JSON text from a test fixture and use **Paste backup text**. Confirm it reaches the same selective review. Cancel without applying it.
127. Open the **json.site** link. It should open an in-app Safari sheet. Use only a synthetic test fixture there, copy its JSON, tap Done, then Paste in Elsepin. No file should be automatically uploaded or imported. Cancel the review.
128. Try incomplete text such as `{`, then a URL instead of JSON. Expect a useful error; an earlier valid preview should not be silently replaced with broken data.
129. Cancel Files selection, reopen it, choose a file downloaded locally, and repeat once from your Files cloud provider if available. A provider may need to download the file first; the app should recover from a canceled read.
130. Start a held session. Review a library-only backup; applying new library entries should be allowed without changing movement. Try applying changed settings: the app must require stopping, or let you uncheck settings. Cancel, then Stop.
131. Test an imported area conflicting with an existing outline, using a duplicate test fixture with a new ID if supplied. Expect an overlap explanation and the ability to deselect it; do not hand-edit your only real backup. Mark BLOCKED if no conflict fixture is available.
132. Restore desired settings from `Build66-before-import.json` using only selected settings. Reopen the app and verify persistence. Keep all backups until the whole test is complete.

## 12. Live Activities, notifications, and widgets

133. In **Live Activities**, enable the feature, show location names, route progress, and the Island timer. Start TEST ROUTE and lock the phone. Confirm readable layout without the bottom row being cut off.
134. Expand the Dynamic Island. Check mode, progress, remaining distance/ETA and update age. Jump ahead once in-app, return to the Island, and confirm its route data updates.
135. Turn **Hide location name** on for Lock Screen only. Check the Lock Screen and expanded Island separately. Then test the Island-only privacy toggle. Restore your preferred settings afterward.
136. Toggle route progress off/on separately for Lock Screen and Island, then the Island update timer. Confirm each affects its own surface and does not stop the route.
137. Turn Live Activities off. Confirm the session can continue in-app without the activity. Turn it on again while foregrounded and check the next session. Stop and verify the activity ends appropriately.
138. In **Notifications**, enable connection warnings and choose the 15-minute session reminder. Begin a held session, leave it running while doing later non-destructive steps, and note whether the reminder arrives. Permission/Focus may block delivery; record that condition.
139. Turn reminders off afterward. Stop. Confirm no new reminder for the ended session is scheduled. A notification already delivered may remain in Notification Center.
140. In **Home Screen widgets**, select TEST A and TEST ROUTE, then choose a Favorite shortcut. Add Elsepin's **Location shortcut**, **Favorite shortcut**, and **Saved shortcuts** widgets from the iPhone Home Screen widget gallery if available.
141. Edit two Location shortcut widgets to use different saved items. Tap the TEST A widget. It must only prepare a pin; manually tap Teleport inside Elsepin to move.
142. While a different session is already active, tap the TEST ROUTE-start widget. The active location must not jump until manual confirmation. Check the medium/large Saved shortcuts show the selected items.
143. If no widgets appear or selections cannot be shared, check that the extension was retained by your sideloader and record the signing setup. Mark BLOCKED rather than claiming the widget code failed or passed. Stop the test session.

## 13. Privacy, updates, and reliability tools

144. Open **Privacy & history**, enable **Hide Elsepin Contents in App Switcher**, switch apps and inspect the preview. Return and confirm navigation/session state is preserved.
145. Enable **Require Face ID or passcode**, leave and reopen Elsepin. Test biometric/passcode authentication and one canceled authentication. Protected content must not become visible before unlocking. Turn it off again if desired.
146. Test **Don't save recent locations**: read and cancel its clear-history confirmation first. Enable it only if losing current recents is acceptable; select/teleport to a disposable place and verify no new recent is kept. Turn recent saving back on.
147. Change the recents retention option, confirm it persists, then restore it. Test **Clear recent locations** only when you are willing to delete recents; favorites/routes should remain. For bulk favorite/trip deletion, review and cancel on your real library.
148. Open **Software updates → Check for updates**. Expect a successful stable-release check or a useful network/backoff message. The current public release is 2.6.0; this private 2.6.1 build should not offer a downgrade or a draft as an update.
149. Turn internet access off briefly and manually check again; record the result. Restore Wi-Fi/VPN. Repeated taps must not create overlapping checks or evade server backoff. Do not expect to test a genuinely newer-release banner without a newer official release.
150. Open **About Elsepin**; test website/help/release/license links. Confirm visible branding and acknowledgments are readable. Compatibility filenames/IDs may still contain Shift/Locus internally.
151. Start a held session, open **Advanced & experimental → Test a session**, and tap **Start test**. Leave it running at least 20 minutes without charging if comparing battery; keep conditions noted (screen, signal, other apps, Low Power Mode).
152. During that test, spend time in another app and lock/unlock once. End the test and inspect confirmed/unconfirmed time, battery change and saved result. Unconfirmed time must not be described as proof spoofing stopped.
153. Run a second comparable test when practical. Use the previous-test comparison and inspect/delete one disposable result. These readings include the whole phone's activity, not isolated Elsepin power use. Stop afterward.

## 14. Windows helper: install, sign in, compare, disconnect

154. Open **Settings → Find My & Life360 → Windows helper → Set up computer checks → Save Windows helper**. Save the ZIP to Files and transfer it privately to your Windows computer.
155. Extract the entire ZIP into a new folder. Confirm `Start Companion.cmd`, its PowerShell launcher, `requirements-windows.lock.txt`, `README.txt`, and Python source files exist. Do not try to run it from inside the ZIP.
156. Double-click **Start Companion.cmd**. If it reports no Python, install supported Python 3.12/3.13 with Add Python to PATH, reopen the launcher, and let it create its local environment. This does not need the private Elsepin app repo.
157. Confirm/select your computer's private Wi-Fi IPv4 address. If Windows Firewall asks, allow the helper on **Private networks**. Keep the computer and iPhone on the same non-isolated Wi-Fi; do not expose the helper port publicly.
158. Choose Find My Devices, Life360, or both in the helper. Enter credentials only in its local prompts, never into a GitHub file, chat or exported log.
159. For Apple, complete the actual verification flow and select **your iPhone** from Devices. If Apple rejects the unofficial sign-in, record BLOCKED with its non-secret error and stop that branch. Do not disable account security to force it through.
160. For Life360, use an authorized observer account that already sees your own profile, then select the correct Circle/profile. Do not reuse the phone's active account if it would sign that phone out. Missing sharing cannot be created by Elsepin.
161. Transfer the generated **ElsepinCompanionPairing.json** privately to iPhone Files. In the Windows helper screen, **Import setup file**, review its origin and confirm. This file contains a token and certificate fingerprint; do not upload it publicly.
162. Tap **Test connection**, enable **Use Windows helper**, then start a held Elsepin session. Wait approximately a minute or longer for provider data. Record each report's timestamp and match/different/unavailable result.
163. Compare each report with the corresponding official service. A recently downloaded old report must not be marked fresh; an accepted developer command must not automatically turn both providers green.
164. In **Live Activities**, enable both service-status rows and inspect the single existing activity. Hide one row and verify checks still run; hiding the status is not disabling its provider.
165. Stop the helper with Ctrl+C. Leave Elsepin open long enough to show unavailable/stale evidence. Confirm no app crash or permanent fake Match. Restart the helper, sign in again, and test reconnection.
166. On the same computer/address, retained pairing identity should allow reconnecting without a new import. If the address/key/certificate changed, import its new setup file. Do not accept an unexplained certificate mismatch.
167. Turn **Use Windows helper** off and confirm reports stop being treated as current. Use **Disconnect computer** only if you intend to remove saved setup. Stop the location session.

## 15. Cloud helper: obtain every file and host it yourself

168. Open **Find My & Life360 → Cloud helper → Advanced → Connect your helper → Download helper files**. Save **Elsepin-FindMy-Cloud.zip** and transfer it to the computer.
169. Extract it. At the exported root, confirm **CloudFindMy/**, **Companion/**, **LICENSE**, and **.python-version**. The guide is **CloudFindMy/CLOUD-GUIDE.md**. Windows may hide the leading-dot file; inspect hidden files if needed.
170. Create your own **private** helper GitHub repository and upload the extracted contents at its root. Do not upload private pairing JSON, provider passwords, helper keys, `data/`, or session folders. You do not need access to N3moStudio's private app source.
171. In Render, create **New → Web Service**, connect that private helper repository, choose Python, and leave **Root Directory blank**. This is a new private-account setup you perform, not a deployment the test IPA does for you.
172. Set Build Command to `pip install -r CloudFindMy/requirements.txt`, Start Command to `python CloudFindMy/render_server.py`, and Health Check Path to `/healthz`.
173. Choose **Free** for this experiment only if available and its limits are acceptable. Generate a unique secret of at least 32 characters in your password manager and set it as **SHIFT_ADMIN_KEY**. Keep it private and unchanged unless deliberately resetting private state.
174. Deploy and open your service's exact HTTPS `*.onrender.com` URL. It must show your helper, not Elsepin's marketing website. Open `/healthz` once to confirm it responds without an account key in the URL.
175. Unlock the helper with your helper key. Sign into Apple, finish verification, and select your own iPhone. Separately sign into an authorized Life360 observer account and select its Circle and your own comparison profile. Record unsupported account challenges as BLOCKED.
176. In Elsepin's **Connect cloud helper** screen enter that HTTPS address and helper key and connect. Alternatively download **ElsepinFindMyPairing.json** from your own helper and use **Import setup file instead**. Test one path first, then the other while idle.
177. Return to Cloud helper → Advanced and tap **Test connection**. Expect a successful helper reply and discovery of supported features. This confirms connectivity, not a location match.
178. Enable **Check while spoofing**, **Check Find My iPhone**, and **Check Life360**. Enabling cloud checks should switch away from Windows helper use while retaining its saved setup.
179. Start a held location session. Wait for fresh reports and inspect timestamps. Compare them with the official Apple Devices/Life360 views. Test each provider switch off/on individually; the other service should continue independently.
180. Test **Warn me if checks fail** and the two service-status display switches. Observe changes inside the existing Island/Lock Screen activity. Do not expect a second Island or a claim about Find My People.
181. Stop spoofing and leave the app. Spoof-check polling is session/lease-based; it must not be presented as continuous tracking. A website health ping does not renew the phone's check lease.
182. Temporarily stop/restart the Render helper. Expect lost provider sign-ins; sign in again and Test connection. Do not assume memory-only authentication survived a restart.
183. For failure handling, log out a provider through the helper's control, or observe a real expired/blocked session without repeatedly submitting bad passwords. Expect sign-in-needed/blocked feedback, no fresh Match, and the other provider left usable.
184. Switch back to Windows helper once, then cloud again. Confirm only the selected helper supplies checks and credentials remain saved until explicitly disconnected.

## 16. Nearby alerts — a separate website feature, not Find My People

185. In the cloud helper, open **Nearby alerts**. If Elsepin has no link, run **Test connection** against the updated helper. Older/non-Render helpers do not expose this capability; mark BLOCKED rather than looking for hidden native People support.
186. Open your helper in iPhone Safari, choose **Share → Add to Home Screen**, then launch that new web app. Unlock it. Tap **Enable notifications**, allow the prompt, and tap **Send test**.
187. Verify the test notification actually reaches the iPhone, including with the web app closed. A server saying sent is not enough. Check Focus and notification permissions if it does not appear.
188. Create a rule named **TEST ARRIVAL**. Choose a device/profile you own or are authorized to monitor, a fixed place's latitude/longitude, a generous test radius such as **500 m**, **Enter**, reminder **Once**, and duration **1 hour**. Confirm the sharing checkbox and Start monitoring.
189. Wait for fresh, accurate reports while the target is outside the place. The first sample establishes a baseline and must not trigger an arrival. Repeated copies of the same provider report must not count as new confirmations.
190. Have the authorized test device cross into the place, or deliberately change your own test device's location during this test. Wait for two distinct fresh provider reports confirming it is inside. Record provider timestamps and actual notification arrival; do not assume exact one-minute delivery.
191. Open the website and dismiss the notification, but do not acknowledge the alert yet. Neither action should silently count as **Stop this alert**.
192. Tap **Stop this alert**. Confirm it stops reminders for that crossing while the rule remains able to monitor a later new crossing.
193. Create a **Leave** rule for the same place. Establish an inside baseline, then move the authorized test device clearly outside. Confirm departure behavior, not an immediate alert at creation.
194. Change a test rule to **Every 1 minute**. Trigger a new confirmed crossing, observe one repeat, then Stop this alert. Confirm no additional reminders are generated; an already queued push may still arrive.
195. Inspect **Every 2 minutes**, **Every 5 minutes**, and **Gradually more often**. If fully testing timing, trigger a new crossing for each and measure: gradual waits 5 minutes, then 2, then 1-minute intervals. A label inspection alone is not a delivery PASS.
196. Pause one rule; confirm it stops its own monitoring/reminders. Resume it and confirm a new baseline rather than replay of the old arrival.
197. Use **Pause all alerts**. Confirm all rules pause. Stopping the IPA's spoofing session or disconnecting its helper setup alone must not be mistaken for this website action.
198. Inspect the durations **1, 4, 8, 24 hours, Until I pause**. Create a short one-hour test and verify actual expiry when time permits. Longer duration timing can remain BLOCKED; do not label it tested after only choosing it.
199. While a rule is active, disconnect/sign out its provider. Expect source-unavailable/sign-in feedback and no new crossing/reminder based on missing data. Reconnect, then deliberately resume/re-establish baseline as instructed.
200. Run one spoof-check session and a Nearby rule for the same selected target together. Confirm both show compatible provider timestamps; the helper should reuse recent provider reports rather than double-requesting the same target.
201. Restart the helper once. With retained storage, restored rules must start paused. With Render Free's ephemeral filesystem, rules/subscriptions may be gone; record that limitation and set them up again rather than expecting guaranteed persistence.
202. Use **Turn off here** to remove this browser's push subscription. Re-enable notifications and send one more test if you intend to keep them. Then pause/delete all disposable test rules.
203. Do not try to test Find My People, moving “near me,” polygon/drawn-area monitoring, or dwell alerts: they are **not available** in this implementation. Named areas in the IPA are a different feature.

## 17. Finish cleanly and preserve evidence

204. Pause all Nearby rules you do not intend to keep. Disable unwanted Windows/cloud checks. Stop the Windows helper if unused. A free Render web service may sleep, lose local state, hit quotas or restart; a ping does not make it guaranteed 24/7.
205. If using an uptime service, configure only an unauthenticated GET to your helper's `/healthz`; never send provider credentials or helper keys. This tests reachability only and can consume the host's included usage. You do not need a ping for the separate static marketing website.
206. In Elsepin tap Stop and wait for the clear request's result. Verify your real location independently after the other app refreshes. Keep an unsuccessful-clear warning as a failure until resolved.
207. Export the full developer log and any relevant incident files. Save this checklist with PASS/FAIL/BLOCKED marks, build number, device/iOS version, sideloader/extension configuration, test times and non-secret failure descriptions.
208. Turn detailed developer recording off when testing ends. Exported files are yours to delete; automatic log retention does not delete your exported copies.
209. Restore desired appearance, units, shortcuts, privacy and reminder settings. Delete only disposable test library items. Keep the pre-test backup and any private setup files securely.
210. Decide readiness from actual results: route drag/jump/retry/Stop, data compatibility and core navigation must pass. Provider login, push receipt and background reliability remain explicitly unverified wherever BLOCKED. Do not publish merely because the build passed.

## 18. Destructive reset tests — disposable install only

These are included so reset behavior has a test path. Do **not** run them on your only real library or pairing. Your JSON backup does not include every credential/device-only setting. If you cannot restore a separate test installation, mark 211–216 BLOCKED.

211. In an idle disposable install with only test data, open **Advanced & experimental → Restore default settings…**. Review and Cancel first; nothing should change.
212. Repeat and confirm. Expect Bloom/Solid, compact rounded presentation and starting settings; saved library and connection setup should remain. Reopen the app to confirm persistence.
213. Open **Wipe everything…**, inspect the available keep-setup/full-wipe choices, and cancel each review first. An active session or pending command should prevent the wipe.
214. After verified backups, use the option retaining pairing/setup on the disposable install. Confirm test library/history/log/recovery data is cleared and retained setup still works. Import your test library again to prove recovery.
215. Only when you can re-pair, use the full wipe on the disposable install. Expect fresh setup, no saved library, no helper credentials, no retained developer log, and fresh appearance defaults. Repeat the initial connection setup before moving again.
216. If a reset reports partial failure, record exactly which steps finished; do not claim the reset was atomic. Keep real data out of this test.

## Evidence and references

- The current build and audit receipts are in [CURRENT-WORK](CURRENT-WORK.md) and [EXPERIMENTAL-AUDIT](EXPERIMENTAL-AUDIT.md). This checklist is a test plan, not a claim that its phone steps passed.
- [Cloud setup](CLOUD-GUIDE.md), [backup rules](BACKUPS.md), and [legacy fixture values](IMPORT-TEST-CHECKLIST.md).
- [Public downloads](https://github.com/N3moStudio/Elsepin-Releases/releases/latest). The published 2.6.0 IPA contains helper exports; this private build's fixes are not public until approved.
- [Render Free limits](https://render.com/docs/free): sleep, ephemeral storage, quotas and restarts matter; choose hosting based on the reliability you need.
- [Apple Web Push](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/): Home Screen web app notifications require user permission; paid Apple Developer membership is not required for this Web Push path.
