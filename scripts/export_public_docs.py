"""Export only public introduction, setup, full changelog and build register.

The private Change Ledger stays private. Historical/private CI links become
record labels, since public readers cannot open them. No feature entries or
failed attempts are removed. This script never publishes, builds or deletes.
"""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def documents():
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    changelog = changelog.replace(
        "[Detailed Change Ledger](docs/CHANGE-LEDGER.md)",
        "[Build results](docs/BUILD-HISTORY.md)")
    for old, new in {
        "docs/CHANGE-LEDGER.md": "docs/BUILD-HISTORY.md",
        "docs/TESTING-2.5.md": "SETUP.md",
        "NOTICE.md": "LICENSES.txt",
    }.items():
        changelog = changelog.replace("](" + old + ")", "](" + new + ")")
    changelog = re.sub(
        r"\[([^\]]+)\]\(https://github\.com/N3moStudio/(Shift|Elsepin)/[^)]+\)",
        lambda match: match[1] + (" (historical record)" if match[2] == "Shift" else " (private CI record)"),
        changelog)
    setup = (ROOT / "SETUP.md").read_text(encoding="utf-8")
    setup = setup.replace("[the migration checklist](docs/TESTING-2.5.md)", "the backup/export steps before replacing the old installation")
    setup = setup.replace("[cloud helper](CloudFindMy/RENDER-SETUP.txt)", "[cloud helper](docs/CLOUD-GUIDE.md)")
    setup = setup.replace("[Windows helper](Companion/README.txt)", "Windows helper exported from the app")
    setup = setup.replace("[privacy and limits](docs/PRIVACY.md)", "[privacy and limits](https://elsepin.onrender.com/privacy.html)")
    return {
        "README.md": (ROOT / "docs/public/README.md").read_text(encoding="utf-8"),
        "SETUP.md": setup,
        "CHANGELOG.md": changelog,
        "docs/BUILD-HISTORY.md": (ROOT / "docs/BUILD-HISTORY.md").read_text(encoding="utf-8"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="Public checkout or staging folder")
    parser.add_argument("--check", action="store_true", help="Check for drift without writing")
    args = parser.parse_args()
    if args.output.resolve() == ROOT:
        parser.error("Choose the public checkout or a staging folder, not the private repository root")
    for name, text in documents().items():
        path = args.output / name
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                raise SystemExit("Public documentation differs: " + name)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(text.encode("utf-8"))
        print(("Verified " if args.check else "Exported ") + name)


if __name__ == "__main__":
    main()
