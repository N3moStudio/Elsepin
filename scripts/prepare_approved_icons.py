#!/usr/bin/env python3
"""Export the four approved, unmodified icon studies at iOS/preview sizes.

Requires Pillow. This is deterministic asset sizing, not a creative redraw:
originals, composition, colors and intrinsic finish remain in Approved/.
Only the four additions are written; historical icons are never regenerated.
"""
from pathlib import Path
import hashlib
import json

from PIL import Image, ImageCms

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'Brand/AppearanceIcons'
ADDITIONS = [
    ('A1', 'IonJumpgate', 'a1-ion.png'),
    ('A2', 'TitaniumJumpgate', 'a2-titanium.png'),
    ('A3', 'PrismJumpgate', 'a3-prism.png'),
    ('B1', 'EmberSwitchpath', 'b1-ember.png'),
]


def main():
    profile = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
    manifest_path = BRAND / 'manifest.json'
    entries = json.loads(manifest_path.read_text(encoding='utf-8'))
    added_assets = {'AppIcon' + stem for _, stem, _ in ADDITIONS}
    entries = [entry for entry in entries if entry['asset'] not in added_assets]
    # Reuse the project's existing Xcode catalog's universal iOS image well.
    catalog = ROOT / 'Locus/Resources/Assets.xcassets'
    template = json.loads((catalog / 'AppIconAfterhours.appiconset/Contents.json').read_text())
    source_records = []
    for version, stem, filename in ADDITIONS:
        original = BRAND / 'Approved' / filename
        source = Image.open(original)
        if source.mode != 'RGB' or source.width != source.height:
            raise ValueError(f'Expected an opaque square RGB original: {original}')
        asset, preview = 'AppIcon' + stem, 'ShiftIcon-' + stem + '-Default'
        folder = catalog / (asset + '.appiconset')
        folder.mkdir(parents=True, exist_ok=True)
        source.resize((1024, 1024), Image.Resampling.LANCZOS).save(
            folder / 'AppIcon.png', icc_profile=profile)
        source.resize((256, 256), Image.Resampling.LANCZOS).save(
            ROOT / 'Locus/Resources/IconPreviews' / (preview + '.png'), icc_profile=profile)
        contents = {'images': [dict(template['images'][0])], 'info': template['info']}
        contents['images'][0]['filename'] = 'AppIcon.png'
        (folder / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')
        entries.append({'design': stem, 'finish': 'Default', 'asset': asset,
                        'preview': preview, 'systemAppearances': 'automatic'})
        source_records.append({'version': version, 'file': 'Approved/' + filename,
                               'sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
                               'asset': asset})
    entries.sort(key=lambda entry: entry["asset"] != "AppIconPrismJumpgate")
    manifest_path.write_text(json.dumps(entries, indent=2) + '\n', encoding="utf-8")
    (BRAND / 'approved-sources.json').write_text(json.dumps(source_records, indent=2) + '\n')
    print('Exported four approved icons and four previews; preserved nine existing choices.')


if __name__ == '__main__':
    main()
