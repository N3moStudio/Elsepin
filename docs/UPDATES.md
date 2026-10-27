# Official release notices

Shift 2.5.4 (53) checks the public repository's latest official release when the
app becomes active or Settings opens. It makes **at most one automatic attempt
every rolling 24 hours**, not one per calendar date. A long uninterrupted session
does not start a new timer; the next foreground/Settings entry performs a due check.

An eligible release gets a small card at the top of Settings with **More info**
and **X**. More info opens that exact GitHub release. Dismissal is remembered for
its tag across launches; a different, newer official version can appear later.
About Shift → Software updates keeps the release link available after dismissal.
Searching Settings for updates or official releases leads to About Shift.

## What counts as an update

- Read `GET https://api.github.com/repos/N3moStudio/Shift/releases/latest`.
- Require a published, non-draft, non-prerelease response and a numeric version
  tag such as `v2.6.0`. Reject beta/RC suffixes even if mislabelled on GitHub.
- Compare numeric components: 2.10 is newer than 2.9. Never suggest an older version.
- Official installs require a greater version. An explicitly marked prerelease
  install may also discover the same numeric version's official release.
- Only accept HTTPS release links for this repository and the reported tag.
  Release-body Markdown is never rendered or executed; linked web content and IPA
  assets are not fetched automatically.

Official release `v2.5.4` uses build 53 and the stable channel. Installed build
52 (`v2.5.4-beta.1`) can discover this same-version official release at its next
eligible check. Stable build 53 does not offer itself again. Older 2.4.x installs
do not contain this checker and need to visit GitHub manually. Test fixtures and
the SwiftUI preview also cover future newer versions.

## Battery, privacy and failure behavior

There is no polling timer, background task, push subscription, notification
permission, location request or automatic installation. A foreground task uses
anonymous HTTPS with a 10-second request timeout and 15-second resource timeout.
It is canceled when its foreground task ends. No GitHub sign-in, token, cookie,
device identifier or location payload is sent. GitHub necessarily sees the
request's network address and a generic Shift request header.

The daily attempt is persisted before requesting, so offline, canceled or failed
attempts also wait until another day. There is no retry loop or manual button that
bypasses the daily limit. A server rate-limit delay can extend that wait. Simultaneous
app/Settings events cannot duplicate requests. Clock rollback rebases the wait.

Successful metadata and ETags are stored locally; an unchanged response can be
returned without the release body. Conditional anonymous requests are not claimed
to bypass GitHub rate limits. The app does not persist release notes or assets.
Cached notices expire after seven days without a successful check. A 404 clears
the cached release. Failures stay quiet, retain bounded-age cached information,
and are described under About without claiming the app is up to date.

These choices keep work small; they do not establish zero battery consumption.
Measure energy on a physical iPhone under controlled conditions. No other battery
proposals in BATTERY-OPTIONS.md are authorized or implemented by this feature.

## Maintainer publication checklist

1. Collect small fixes on `main`; do not automatically build or publish a
   prerelease for each fix. Publish test IPAs only when requested or when a batch
   is approved for testing. Ordinary test releases use `prerelease` and the
   GitHub **Pre-release** label. Official 2.5.8 (58) uses `stable`. A candidate
   built with `stable` metadata may be held in an unpublished draft for device
   testing and published unchanged after explicit maintainer acceptance.
2. For an explicitly approved official release, select the intended version/build,
   set the app target's `SHIFT_RELEASE_CHANNEL` to `stable` in `project.yml`, and
   regenerate/build the project. Verify `ShiftReleaseChannel` is `stable` in the
   packaged app's Info.plist. Do not merely relabel the old beta binary as stable.
3. Publish the verified IPA with a numeric tag such as `v2.6.0`, mark it official
   (neither Draft nor Pre-release), and designate the intended **Latest** release.
   The updater follows GitHub's latest-release endpoint rather than every tag.
4. Verify the public endpoint returns that tag, `draft: false`, `prerelease: false`,
   a publication timestamp and its exact release URL. Existing installs will
   discover it on their next eligible foreground check, not immediately at publish.
5. Record source commit, validation, artifact checksum and remaining device checks
   in the Change Ledger. A new release's visibility is not a claim of compatibility
   with every iOS/signing setup; include those requirements in the release notes.

References checked 24 October 2026:
[GitHub releases API](https://docs.github.com/en/rest/releases/releases#get-the-latest-release)
and [GitHub API best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api).
