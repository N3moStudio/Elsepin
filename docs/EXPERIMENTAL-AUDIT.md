# Experimental connections and download audit

1 November 2026. Scope: current Elsepin code, both distributed helpers, their account-free tests, and anonymous public download access. No live Apple/Life360 credentials were used, no account was connected, and no service was deployed. Native build and delivery evidence belongs in CURRENT-WORK.md.

## What users can actually use

| Capability | Windows helper | Render helper | Private VM helper |
| --- | --- | --- | --- |
| Find My Devices report for selected own iPhone | Yes, terminal sign-in | Yes, website sign-in | Yes, terminal sign-in |
| Life360 selected own profile via authorized observer | Yes | Yes | No |
| Compare report timestamp/location with sent history | Yes, app comparison | Yes, session history/lease | Yes, session history/lease |
| Show status in existing Live Activity/Island | Yes, app must run sufficiently | Yes, same activity | Yes, same activity |
| Fixed-place Nearby enter/leave alerts | No | Yes, independent website rules | No |
| Nearby repeat/acknowledge/pause controls | No | Yes | No |
| Works while Windows laptop is off | No | Server must remain running | VM must remain running |
| Find My People | No | No | No |

Nearby has once/5/2/1-minute/gradually-more-often reminders; 1/4/8/24-hour or until-paused monitoring; explicit Stop this alert, pause/resume, pause all and push unsubscribe. Initial baseline and two distinct fresh sufficiently accurate reports are required for a crossing. Fixed circles only; no moving real-me anchor, library polygons or dwell alerts. Web Push belongs to the Home Screen web app, not the sideloaded IPA. Stopping spoofing or its helper checks does not pause website rules.

There is no operational Find My People connector hidden behind setup. The earlier separate research still lacks validated native registration/activation, sharing-key/bootstrap and live integration evidence. It is not shipped in these helpers. Do not market Devices as People.

## Public access verified without signing into GitHub

- Public `N3moStudio/Elsepin-Releases` latest release is `v2.6.0`, published 27 October 2026; it has one asset, `Elsepin-2.6.0.ipa`, 18,199,999 bytes.
- The complete anonymous IPA download passed ZIP CRC validation. Both nested helper ZIPs exactly matched the pre-build-66 source packages. This establishes availability, not real-account operation.
- Public root `SETUP.md`, `docs/CLOUD-GUIDE.md` and marketing website return HTTP 200. The private app repository returns 404 anonymously, as intended.
- No standalone helper ZIP is attached to the public release. Users can export the source-only helper ZIPs from the installed app, or extract them from its IPA. They do not need the private app source to host their own helper.
- Windows export: Settings → Find My & Life360 → Windows helper → Set up computer checks / Setup & help → Save Windows helper.
- Cloud export: Settings → Find My & Life360 → Cloud helper → Advanced → Connect your helper / Connection settings → Download helper files.
- The new corrections are in the private build's exports. The published IPA/public setup pages were deliberately not updated. Public SETUP still incorrectly describes already-published 2.6.0 as unreleased. At publication, sync the reviewed setup/cloud guide and optionally attach the two exact helper ZIPs with hashes. Never upload keys, account data or the entire private app repository.

## Defects found and corrected for build 66

1. Nearby and spoof-check polling independently fetched the same provider/target. `Owner.read_report` now serializes and reuses reports during the provider cooldown. Original provider timestamps remain unchanged; cached data is not relabeled as a new observation.
2. Nearby-only authentication failures did not update the owner readiness, leaving it shown as ready and repeatedly retrying rejected reads. It now uses the common authentication failure path. Sign-in/blocked states close that provider only; transient timeouts retain login and retry after cooldown.
3. The cloud export omitted the root `.python-version` referenced by its guide. The explicit package manifest now includes it. Root layout and dependencies are tested without private app-source access.
4. Oracle instructions named an obsolete Shift ZIP; Render notes referenced the original app repository; Windows help used old branding/settings paths. The exported guides now name the actual ZIP and explain creating the user's own private helper repository.

## Automated evidence

- 104 cloud tests (96 existing plus eight shared-read/auth regressions).
- 19 Windows companion tests.
- 16 packaging/icon tests (14 existing plus two helper archive regressions).
- Fresh extracted ZIPs pass independently with an isolated interpreter (`python -I -B`): 104 cloud and 19 Windows tests. Existing exact-pinned Python 3.12.14 dependencies were reused; this is not a fresh remote pip-install or account-login test.
- Windows manifest: 13 files. Cloud manifest: 28 files, including Python pin and regression tests. Unexpected ZIP entries are rejected.
- Logs: `.build/helper-cloud-final.log`, `helper-packaging-final.log`, `helper-extracted-cloud-final.log`, `helper-extracted-windows-final.log`.

## Still requires real acceptance

Apple/Life360 can reject unofficial access, require an unsupported challenge, change APIs or return stale locations. Test actual sign-in/selection, reports, reconnects, real crossing events and notification receipt using the ordered owner walkthrough. No mock or native compiler run proves these outcomes.

Render Free can sleep/restart and lose local state; the current implementation does not promise reliable 24/7 free monitoring. The website can continue rules only while its server and authenticated sources are available. A health ping does not authenticate a source or confirm a delivered notification. See [Render limits](https://render.com/docs/free) and [Apple Web Push requirements](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/).

## Maintainer pointers

- Provider coordination/auth: `CloudFindMy/render_server.py` (`Owner`), `nearby_web.py`, `test_polling.py`.
- Location freshness: `Companion/reports.py`, `CloudFindMy/core.py`, `Shared/LocationVerification.swift`.
- Native setup and status: `ConnectionDetailsView.swift`, `RemoteFindMyView.swift`, `CompanionClient.swift`, `RemoteFindMyController.swift`.
- ZIP allowlists and isolation checks: `scripts/package_helpers.py`, `scripts/tests/test_package_helpers.py`.
- [Line-by-line phone walkthrough](TEST-WALKTHROUGH-2.6.1.md), [current cloud guide](CLOUD-GUIDE.md), [build guide](BUILDING.md).
