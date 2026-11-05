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
2. Select the intended branch and check for `codemagic.yaml`. For build 69 use
   `codex/pins-search-69`; `main` still contains the previous app build.
3. Start **Build Elsepin IPA**. Download the IPA after all steps pass and sign it
   with the existing sideloading method, retaining the extension.

Original stdout/stderr and test results are retained in `build/logs/` and as
downloadable diagnostic artifacts. Every pipeline uses `pipefail`, so capturing
logs does not turn a failed check/build into success. These logs stay outside
source control; delivery to Downloads should contain the requested IPA only.

The GitHub workflow remains available. Removing `codemagic.yaml` removes this
alternative without changing app behavior. Account allowance and runner availability
still apply; see [Codemagic pricing](https://docs.codemagic.io/billing/pricing/).

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

The latest validated development source is Elsepin 2.6.1 (69) on
`codex/pins-search-69`, privately built in Codemagic for owner testing. `main`
still contains build 68; select the branch intentionally.
See [build history](BUILD-HISTORY.md) for native results and the artifact checksum.
Creating an IPA artifact does not publish a release or declare it stable. Verify both target
versions and the resolved `ShiftReleaseChannel` metadata before distribution;
that internal compatibility key intentionally retains its old name.

Collect small fixes on `main`. Start a distributable build when one is needed;
do not create a prerelease for every small fix. Publishing an official release
is a separate action, after device acceptance, in `Elsepin-Releases`.

ThinkingOrbsKit is pinned in `project.yml` and linked only to the app target.
Xcode resolves it during the existing native build; the portable Swift package
does not import SwiftUI or this dependency. The dependency adds no CI hook or runtime service.
