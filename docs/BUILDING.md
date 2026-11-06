# Build Elsepin

The source includes the app, WidgetKit/Live Activity extension, tests, artwork,
helper source/downloads, Xcode project, and the bundled idevice engine library.
No Apple signing credentials or deployed helper are included.

## GitHub Actions — works from Windows

1. Open the private Elsepin repository and choose **Actions → Build Elsepin IPA → Run workflow**.
2. Select `main` (or the specific branch you intend to build). There is no packaging checkbox: every run checks, builds and packages the IPA.
3. After success, download **Elsepin <version>.ipa** under Artifacts. This is the only downloadable build artifact; there is no outer ZIP to extract. Sign it with SideStore and retain the extension.

The manual workflow uses GitHub’s `xcode-27` runner, verifies bundled helper
downloads, runs Python helper tests and Swift model tests, regenerates the
project with XcodeGen, then builds and checks both targets. Availability and
your account’s Actions quota apply. It does not publish a release or deploy a helper.

Start a **new run after pushing changes**. Re-running an older job uses its
original commit. Runner reference: [GitHub’s supported images](https://github.com/actions/runner-images#available-images).

## Codemagic — alternative private Mac builder

Use a **personal account**, the **Mac mini M2** instance and the committed
`codemagic.yaml`. The manual `elsepin-ipa` workflow pins Xcode 27.1 and runs the
same resource, Python, Swift and native/package checks as GitHub Actions. It
does not publish a release, configure Apple account signing or trigger on pushes.
Leave paid billing disabled to stay within the personal account's free allowance.

1. Connect the private Elsepin repository in Codemagic and open its configuration.
2. Select the intended branch and check for `codemagic.yaml`. For builds 69–71 use
   `codex/pins-search-69`; `main` still contains the previous app build.
3. Start **Build Elsepin IPA**. Download the IPA after all steps pass and sign it
   with the existing sideloading method, retaining the extension.

Original stdout/stderr and test results are retained in `build/logs/` and as
downloadable diagnostic artifacts. Every pipeline uses `pipefail`, so capturing
logs does not turn a failed check/build into success. These logs stay outside
source control. Since 5 November, the delivery folder is
`C:/Users/naith/Desktop/ipa/My Projects (N3mo Studio)`: only the latest requested
Elsepin test IPA, replacing older Elsepin IPAs after a complete replacement.
Leave other apps untouched; no checksum sidecars, ZIP bundles or diagnostic files.

The GitHub workflow remains available. Removing `codemagic.yaml` removes this
alternative without changing app behavior. Account allowance and runner availability
still apply; see [Codemagic pricing](https://docs.codemagic.io/billing/pricing/).

## Current private source and API build access

GitHub rejected uploads after an account suspension. On 5 November the owner
resumed private builds with GitLab and Codemagic, without browser/desktop automation.
Use the existing local folder and `gitlab` remote:
`https://gitlab.com/gajula.naithik/elsepin.git`. GitLab CI/Pages are disabled.
`codex/pins-search-69` tracks this remote; `remote.pushDefault=gitlab` prevents a
normal push from targeting suspended GitHub. `origin` and local main are retained.

Codemagic app: `6aecefbde7e295d4f44f163e`, personal account owner
`6aecdf671da16ae2cffff6c7`. A dedicated read-only repository deploy key gives the
builder access; do not reuse another app's key or expose credentials in source/logs.
The workflow is `elsepin-ipa`, `mac_mini_m2`, Xcode 27.1, maximum 30 minutes. Check
free allowance before dispatch; leave paid billing disabled and allow queuing behind
other apps. No push trigger, release publishing or Apple signing account is configured.

Latest validated source: `14d2050c11cdb23d7cc712b8e6ed3d9e9064d448`, build 71,
Codemagic run `6aed1ad9ab17f8deb753426c`. Subsequent documentation-only commits
record that result; see [build history](BUILD-HISTORY.md) for test and delivery evidence.

On this Windows workstation, the authenticated CLI is
`C:/Users/naith/.codex/tools/gitlab-cli/1.128.0/bin/glab.exe`. The owner-provided
Codemagic credential is the account-encrypted
`C:/Users/naith/.codex/credentials/codemagic-tendelm/api-token.clixml`; its directory
name does not limit it to Tendelm. Import it locally only, never print its token,
and never alter Tendelm. Elsepin's separate read-only deployment key is under
`C:/Users/naith/.codex/credentials/codemagic-elsepin/`. These paths are local tooling,
not application dependencies or files to upload. Git pushes use existing Git
authentication; no credential extraction or browser interaction is needed.
Build calls can use the [Codemagic API](https://docs.codemagic.io/rest-api/builds/).
Inspect the exact commit, full logs and private artifact before delivery. Changing
source hosting does not migrate the app's existing public help/update endpoints.

## Local Mac

Use Xcode 27 and XcodeGen. From the repository root:

```sh
brew install xcodegen
swift test
bash scripts/build-ipa.sh
```

Output: `build/Elsepin <version>.ipa` (the current development version is 2.6.1).
The filename uses the built app’s version. The packager verifies the extension,
required resources, app-group entitlements, and appearance metadata. Its ad-hoc
signatures are placeholders; SideStore still needs to sign the installation.

`project.yml` is the project definition. Run `xcodegen generate` before opening
`Locus.xcodeproj` after source/configuration changes; the build script does this.
The checked-in project can be older than the generator input.

## Helpers and checks

```sh
python3 scripts/check_appearance.py
python3 scripts/check_app_identity.py
python3 scripts/package_helpers.py --check
python3 -m venv .venv
.venv/bin/python -m pip install -r CloudFindMy/requirements.txt
.venv/bin/python -m unittest discover -s Companion -p 'test_*.py' -v
.venv/bin/python -m unittest discover -s CloudFindMy -p 'test_*.py' -v
```

On Windows, use `.venv\Scripts\python.exe` for the virtual environment. After
changing helper source or guides, regenerate the in-app downloads with
`python3 scripts/package_helpers.py`, then check them again.

## Repository map

| Folder | Contents |
| --- | --- |
| `Locus/` | Elsepin’s SwiftUI app and connection/session engine |
| `Shared/` | App/extension models, appearance and status rules |
| `LocusActivity/` | Live Activities, Dynamic Island and widgets |
| `Companion/`, `CloudFindMy/` | Optional Windows and cloud helpers |
| `Tests/`, `scripts/` | Model tests, resource checks and packaging |
| `Brand/` | Current icon families and retained earlier brand assets |
| `Vendor/idevice/` | Existing static engine library, header and MIT notice |

The bundled engine is a prebuilt dependency, not a fresh build of the upstream
Rust source. Its upstream source is [idevice](https://github.com/jkcoxson/idevice).
No exact rebuild of that vendor binary is claimed here.

From 2.5.0, the app uses `com.n3mostudio.shift`, its extension uses
`com.n3mostudio.shift.activity`, and both share `group.com.n3mostudio.shift`.
Shift registers `shift://`; Locus keeps ownership of `locus://` links. This is a
separate installation from 2.4.x; follow [the migration checklist](TESTING-2.5.md).
Internal source/target names and serialized MPH fields remain compatible with
existing backups. `check_app_identity.py` verifies the source configuration; the
IPA validator checks the compiled bundle IDs and URL scheme.

## Official versus prerelease builds

The latest validated development source is Elsepin 2.6.1 (70) at `0e098f2` on
`codex/pins-search-69`, privately built from GitLab in Codemagic for owner testing. `main`
still contains build 68; select the branch intentionally.
See [build history](BUILD-HISTORY.md) for native results and retained local evidence.
Creating an IPA artifact does not publish a release or declare it stable. Verify both target
versions and the resolved `ShiftReleaseChannel` metadata before distribution;
that internal compatibility key intentionally retains its old name.

Collect small fixes on `main`. Start a distributable build when one is needed;
do not create a prerelease for every small fix. Publishing an official release
is a separate action, after device acceptance, in `Elsepin-Releases`.

ThinkingOrbsKit is pinned in `project.yml` and linked only to the app target.
Xcode resolves it during the existing native build; the portable Swift package
does not import SwiftUI or this dependency. The dependency adds no CI hook or runtime service.
