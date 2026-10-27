# Elsepin website

Responsive static site, built from approved icon assets and the app's actual palette definitions. No npm dependencies, analytics, account forms or location requests.

Build: `python3 website/build.py`

Preview: `python3 -m http.server 8770 --bind 127.0.0.1 --directory website/dist`

## Render

Create a **Static Site** connected to the replacement repository:

- Build command: `python3 website/build.py`
- Publish directory: `website/dist`
- Health URL, if desired: `/healthz`
- No environment variables, credentials, persistent disk or background worker.

Publish only `website/dist`; never serve the repository root. A static site is served from the hosting CDN and does not need keepalive pings. Hosting allowances still apply. The location helper is a separate service and is not deployed by these instructions.

The site currently labels the redesigned app as in development. Add a verified public download URL only after a tested release is approved. A private GitHub release is not a public download link. Do not publish a signed URL with an expiry or credentials.

## Source map

- `public/index.html`: homepage and interactive phone illustration.
- `public/styles.css`: cream editorial layout, responsive rules and preview surfaces.
- `public/app.js`: accessible theme/icon/screen controls; page-memory state only.
- `build.py`: allowlisted publish directory, palette extraction and icon copying.
- `public/guide.html`: short setup guide; keep aligned with in-app pairing.
- `public/privacy.html`: actual website data behavior.

The map is an illustration, not live MapKit. App-owned surfaces can match; iOS maps and system menus remain platform-controlled.
