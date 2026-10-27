# Elsepin

Private development repository for the next chapter of the Shift app.

**2.6.0 (59) — development; not released.** Prism Jumpgate is the default icon. All nine themes and thirteen regular-edition icons remain available.

The new appearance system adds theme-specific color modes, solid/glass surfaces, fonts and relative text sizes. Ion defaults to dark olive and citron. Settings has a refreshed overview and a manual official-release update check. The responsive website is in `website/`.

## Start here

- [Product Atlas / brand and compatibility map](docs/BRAND-MAP.md)
- [Feature map](docs/APP-MAP.md)
- [Change Ledger](docs/CHANGE-LEDGER.md)
- [Setup guide](SETUP.md)
- [Build instructions](docs/BUILDING.md)
- [Website source and publishing](website/README.md)
- [Identity brief and outstanding name checks](docs/ELSEPIN-IDENTITY.md)

## Distribution boundaries

Approved public downloads and help belong in [Elsepin-Releases](https://github.com/N3moStudio/Elsepin-Releases). This private repository contains implementation and validation work. No new IPA is published merely because source changes are pushed. The paid Veypax product uses its own private repository, versioning and plan policies.

## Licenses and provenance

Elsepin continues Shift and includes code derived from Locus and the idevice project. Inherited and previously MIT-licensed work retains its [MIT license](LICENSE). Only expressly listed new original additions use the separate [rights notice](NEW-ADDITIONS-LICENSE.md). Third-party notices remain packaged in the app. This is not a claim that inherited code is proprietary or that prior permissions have been revoked.

## Validation

Shared-rule tests can run with `swift test`; native SwiftUI and extension validation require Xcode on a Mac. `scripts/check_app_identity.py`, `scripts/check_appearance.py` and `scripts/package_helpers.py --check` protect install identity, icon resources and source-only helper packages. See the Change Ledger for the exact tested revision and remaining device checks.
