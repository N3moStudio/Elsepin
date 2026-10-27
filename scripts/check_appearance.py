#!/usr/bin/env python3
"""Check icon names, appearance variants and resources before an iOS build."""
from pathlib import Path
import json
import struct

ROOT = Path(__file__).resolve().parents[1]


def read_resource(directory, filename):
    # Windows can resolve a differently cased name, masking a broken Git asset
    # reference until actool reads it on a case-sensitive build volume.
    names = {path.name for path in directory.iterdir() if path.is_file()}
    if filename not in names:
        raise ValueError(f'Missing resource or filename case mismatch: {directory / filename}')
    return (directory / filename).read_bytes()


def check():
    entries = json.loads((ROOT / 'Brand/AppearanceIcons/manifest.json').read_text(encoding='utf-8'))
    assert len(entries) == 13 and len({e['asset'] for e in entries}) == 13
    assert entries[0]['asset'] == 'AppIconPrismJumpgate'
    settings = (ROOT / 'project.yml').read_text(encoding='utf-8')
    project = (ROOT / 'Locus.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    source = (ROOT / 'Shared/ShiftAppearance.swift').read_text(encoding='utf-8')
    automatic_assets = {'AppIconIonJumpgate', 'AppIconTitaniumJumpgate', 'AppIconPrismJumpgate', 'AppIconEmberSwitchpath'}
    rendition_count = 0
    for entry in entries:
        assert entry['design'].lower() in source.lower()
        if entry['asset'] != 'AppIcon':
            assert entry['asset'] in settings, entry['asset']
            assert entry['asset'] in project, entry['asset']
        directory = ROOT / 'Locus/Resources/Assets.xcassets' / (entry['asset'] + '.appiconset')
        images = json.loads((directory / 'Contents.json').read_text(encoding='utf-8'))['images']
        automatic = entry.get('systemAppearances') == 'automatic'
        assert automatic == (entry['asset'] in automatic_assets)
        expected = ['any'] if automatic else ['any', 'dark', 'tinted']
        assert [i.get('appearances', [{}])[0].get('value', 'any') for i in images] == expected
        rendition_count += len(images)
        for image in images:
            data = read_resource(directory, image['filename'])
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            width,height,depth,color = struct.unpack_from('>IIBB',data,16)
            assert (width,height) == (1024,1024)
            assert depth == 8 and color in (0,2), 'App icons must have no alpha channel'
        preview = ROOT / 'Locus/Resources/IconPreviews' / (entry['preview'] + '.png')
        read_resource(preview.parent, preview.name)
        # Hand-maintained projects use SOURCE_ROOT paths; XcodeGen uses a group
        # path plus a basename. Both must still register the image as a resource.
        full_path = preview.relative_to(ROOT).as_posix() in project
        grouped_path = (f'path = "{preview.name}";' in project and
                        'path = IconPreviews;' in project and
                        f'/* {preview.name} in Resources */' in project)
        assert full_path or grouped_path, 'Preview missing from Xcode project'
    assert 'Permission to use' in (ROOT / 'Brand/AppearanceIcons/LICENSE-Lucide.txt').read_text(encoding='utf-8-sig')
    print(f'Verified {len(entries)} icon choices, {rendition_count} supplied appearance images, previews and license.')

if __name__ == '__main__':
    check()
