# Build Shift

The source includes the app, WidgetKit/Live Activity extension, tests, artwork,
helper source/downloads, Xcode project, and the bundled idevice engine library.
No Apple signing credentials or deployed helper are included.

## GitHub Actions — works from Windows

1. Upload the extracted repository using **GitHub Desktop**. Preserve `.github`, `Vendor`, `Shared`, and `LocusActivity`; put `project.yml` at the repository root.
2. Open **Actions → Build Shift IPA → Run workflow**. Choose the branch containing these files. The default **Package a downloadable IPA** switch is off: tests and native compilation run without generating an IPA. Turn it on only for a requested distributable/device-test build.
3. With packaging enabled, after the run succeeds, download **Shift <version>.ipa** directly under Artifacts and sign it with SideStore. There is no extra ZIP to extract. Retain its extension. The filename automatically follows the app version in future builds.

The manual workflow uses GitHub’s `xcode-27` runner, verifies bundled helper
downloads, runs Python helper tests and Swift model tests, regenerates the
project with XcodeGen, then builds and checks both targets. Availability and
your account’s Actions quota apply. It does not publish a release or deploy a helper.

Start a **new run after pushing changes**. Re-running an older job uses its
original commit. Runner reference: [GitHub’s supported images](https://github.com/actions/runner-images#available-images).

## Local Mac

Use Xcode 27 and XcodeGen. From the repository root:

```sh
brew install xcodegen
swift test
bash scripts/build-ipa.sh
```

Output: `build/Shift <version>.ipa` (the current development version is 2.5.8).
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
| `Locus/` | Shift’s SwiftUI app and connection/session engine |
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

Official 2.5.8 (58) uses `SHIFT_RELEASE_CHANNEL: stable` in `project.yml`
and the checked-in project. Its IPA is the exact release candidate tested and
accepted by the maintainer; promotion changes documentation only. For future
version/channel changes, regenerate/build and verify the resolved
`ShiftReleaseChannel` in the packaged app Info.plist. Small fixes are collected
on `main` without changing the published release; do not build or publish a prerelease for every fix.
Build a distributable IPA when a release or device-test build is requested.
Do not change an already-distributed beta into an official release merely by
editing GitHub labels. See [the release/update checklist](UPDATES.md).
