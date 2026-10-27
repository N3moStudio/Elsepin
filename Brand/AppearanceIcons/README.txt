Shift appearance artwork

Settings > Appearance offers Glacier, Afterhours, Porcelain, Ion, Ember, Abyss,
Bloom, Blueprint and Titanium independently from Choose App Icon. The original
three icon families retain Default, Dark and Tinted choices. Glacier Default
remains the primary icon and saved selections retain the same identifiers.

SVG files preserve the original vector designs. Approved/ preserves the four
additional Imagegen studies A1, A2, A3 and B1 and their prompts. Approval and
source digests are recorded in design-approval.yaml and approved-sources.json.
The full RGB art is retained; Icon Composer was not used. Export additions with
python scripts/prepare_approved_icons.py (Pillow required). The exporter resizes
the original pixels and tags sRGB, without cropping or changing the artwork.
PNG masters are opaque 1024x1024 squares; iOS applies the outer icon mask.

Locus/Resources/Assets.xcassets contains thirteen named icon sets. The original
nine include any, dark and grayscale tinted variants. The four new choices
(Ion Jumpgate, Titanium Jumpgate, Prism Jumpgate, Ember Switchpath) each use one
approved master and iOS automatic dark/tinted treatment. Home Screen tint is
chosen by the user in iOS, independently from Shift's style. IconPreviews supplies
the thirteen choice thumbnails. New thumbnails are 256px to keep selection light.

Portable xtool builds can package the manifest's manually selectable PNG icons
using CFBundleIcons and CFBundleIcons~ipad. They do not compile Assets.car, so
custom automatic dark/tinted artwork requires an Xcode build. The Dark and
Tinted choices remain explicitly selectable in the portable build.

The original navigation, orbit and move-up-right symbols derive from Lucide;
see LICENSE-Lucide.txt. New Jumpgate/Switchpath icon studies use built-in Imagegen.
Static preflight and source checks do not replace an Xcode build or real iOS
Home Screen, automatic appearance, icon-switching and accessibility checks.
