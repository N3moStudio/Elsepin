#!/usr/bin/env python3
"""Build an allowlisted static site. Never publish the repository or helper state.

Theme colors come from the same Swift palette used by the app. Icon pixels come
from approved app previews; this script doesn't redraw or recolor any artwork.
"""
from pathlib import Path
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'website'
PUBLIC = SITE / 'public'
OUT = SITE / 'dist'
INKS = ['accent', 'onAccent', 'secondary', 'canvas', 'surface', 'text', 'muted']
DETAILS = {
    'glacier': ('COOL & COLLECTED', 'Ice blue, silver, and a little breathing room.', 'light', 'rounded'),
    'afterhours': ('AFTER THE LIGHTS', 'Deep ink and violet. A softer kind of night.', 'dark', 'system'),
    'porcelain': ('QUIET CONFIDENCE', 'Chalk, graphite, and a considered serif.', 'light', 'serif'),
    'ion': ('HIGH VOLTAGE', 'Citron on deep olive. Bright controls. Solid surfaces.', 'dark', 'system'),
    'ember': ('SLOW BURN', 'Copper highlights on warm charcoal.', 'dark', 'system'),
    'bloom': ('A SOFTER SIDE', 'Petal pink, berry, and rounded details.', 'light', 'rounded'),
    'blueprint': ('A CLEAR DIRECTION', 'Cobalt, pale paper, and precise typography.', 'light', 'monospaced'),
    'titanium': ('BUILT TO LAST', 'Platinum details on a grounded ink canvas.', 'dark', 'system'),
}


def catalog():
    source = (ROOT / 'Shared/ShiftAppearance.swift').read_text(encoding='utf-8')
    palettes = re.findall(r'case \.(\w+):\s*light = \[([^]]+)\]\s*night = \[([^]]+)\]', source)
    assert len(palettes) == 8, 'Update the catalog parser when the palette format changes.'
    themes = []
    for name, light, dark in palettes:
        eyebrow, detail, mode, font = DETAILS[name]
        def colors(text):
            values = re.findall(r'0x([A-Fa-f0-9]{6})', text)
            assert len(values) == len(INKS)
            return dict(zip(INKS, ['#' + v.lower() for v in values]))
        themes.append(dict(id=name, title=name.capitalize(), eyebrow=eyebrow, detail=detail,
                           mode=mode, font=font, light=colors(light), dark=colors(dark)))
    manifest = json.loads((ROOT / 'Brand/AppearanceIcons/manifest.json').read_text(encoding='utf-8'))
    icons = []
    for entry in manifest:
        title = re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', entry['design'])
        if entry['finish'] != 'Default': title += ' · ' + entry['finish']
        icons.append(dict(id=entry['preview'].replace('ShiftIcon-', 'ElsepinIcon-'), title=title))
    return dict(themes=themes, icons=icons)


def build():
    # Fail closed on stale output: never deploy an old QA page or stray file.
    # The caller can move its prior dist folder aside, then rebuild cleanly.
    data = catalog()
    allowed = {Path(name) for name in ['index.html', 'styles.css', 'app.js', 'guide.html', 'privacy.html', '404.html', 'robots.txt', 'healthz', 'catalog.js', 'licenses.txt']}
    allowed |= {Path('assets') / (icon['id'] + '.png') for icon in data['icons']}
    allowed.add(Path('assets/prism.png'))
    if OUT.is_symlink():
        raise ValueError('The site output must not be a symbolic link.')
    for existing in OUT.rglob('*') if OUT.exists() else []:
        if existing.is_symlink() or not existing.resolve().is_relative_to(OUT.resolve()):
            raise ValueError('The site output contains an unsafe path.')
        if existing.is_file() and existing.relative_to(OUT) not in allowed:
            raise ValueError(f'Unexpected site output; move it aside before building: {existing.name}')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'assets').mkdir(exist_ok=True)
    # Explicit allowlist: a stray secret or future helper file cannot enter the site.
    for name in ['index.html', 'styles.css', 'app.js', 'guide.html', 'privacy.html', '404.html', 'robots.txt', 'healthz']:
        shutil.copyfile(PUBLIC / name, OUT / name)
    (OUT / 'catalog.js').write_text('window.ELSEPIN_CATALOG = ' + json.dumps(data, ensure_ascii=True) + ';\n', encoding='utf-8')
    for icon in data['icons']:
        shutil.copyfile(ROOT / 'Locus/Resources/IconPreviews' / (icon['id'].replace('ElsepinIcon-', 'ShiftIcon-') + '.png'), OUT / 'assets' / (icon['id'] + '.png'))
    shutil.copyfile(ROOT / 'Locus/Resources/IconPreviews/ShiftIcon-PrismJumpgate-Default.png', OUT / 'assets/prism.png')
    shutil.copyfile(ROOT / 'Locus/Resources/OpenSourceNotices.txt', OUT / 'licenses.txt')
    print(f'Static site ready: {OUT} ({len(data["themes"])} themes, {len(data["icons"])} icons).')


if __name__ == '__main__':
    build()
