#!/usr/bin/env bash
# Netlify-Build: Flutter installieren, Web-App bauen, Handbuch (MkDocs) erzeugen.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.1}"

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter-sdk}"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true

bash scripts/build-web.sh

pip install -r requirements.txt
mkdocs build   # schreibt nach dist/handbuch (siehe mkdocs.yml)
