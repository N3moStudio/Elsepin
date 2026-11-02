"""Distribution checks for an exported helper without private app-source access."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import package_helpers

ROOT = Path(__file__).resolve().parents[2]


class HelperArchiveTests(unittest.TestCase):
    def test_cloud_export_has_runtime_pin_and_documented_hosting_layout(self):
        name = "Elsepin-FindMy-Cloud"
        archive_path = ROOT / "Locus/Resources" / (name + ".zip")
        expected = package_helpers.expected_files(ROOT, name, package_helpers.manifests()[name])
        package_helpers.verify(archive_path, expected)
        with tempfile.TemporaryDirectory() as temporary:
            with zipfile.ZipFile(archive_path) as archive:
                archive.extractall(temporary)
            folder = Path(temporary) / name
            self.assertEqual((folder / ".python-version").read_text().strip(),
                             (ROOT / ".python-version").read_text().strip())
            for relative in ("CloudFindMy/requirements.txt", "CloudFindMy/render_server.py",
                             "CloudFindMy/CLOUD-GUIDE.md", "Companion/reports.py",
                             "CloudFindMy/static/nearby.js", "CloudFindMy/test_polling.py"):
                self.assertTrue((folder / relative).is_file(), relative)

    def test_unlisted_pairing_file_is_rejected_even_when_zip_is_valid(self):
        name = "Elsepin-Windows-Helper"
        expected = package_helpers.expected_files(ROOT, name, package_helpers.manifests()[name])
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "helper.zip"
            shutil.copyfile(ROOT / "Locus/Resources" / (name + ".zip"), path)
            with zipfile.ZipFile(path, "a") as archive:
                archive.writestr(name + "/ElsepinCompanionPairing.json", '{"synthetic":true}')
            with self.assertRaisesRegex(ValueError, "extra, missing, or duplicate"):
                package_helpers.verify(path, expected)


if __name__ == "__main__":
    unittest.main()
