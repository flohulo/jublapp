#!/usr/bin/env bash
# Baut die Flutter-Web-App nach dist/ (ohne Handbuch).
# Wird von scripts/netlify-build.sh und "npm run dev" verwendet.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

node update-version.js

(
  cd app
  flutter pub get
  # Canvaskit/Schriften mitliefern statt von gstatic.com zu laden.
  flutter build web --release --no-web-resources-cdn
)

rm -rf dist
mkdir -p dist
cp -R app/build/web/. dist/
# Netlify erkennt die Formulare (Ereignis, Feedback) an dieser Datei.
cp web-extras/forms.html dist/forms.html
echo "Flutter-Web-App nach dist/ gebaut."
