#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TOKENMANAGER_VERSION:-0.1.0}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/tokenmanager.app"
ZIP_PATH="$DIST_DIR/tokenmanager-$VERSION.app.zip"

"$ROOT_DIR/script/package_app.sh" >/dev/null

rm -f "$ZIP_PATH"
(
  cd "$DIST_DIR"
  COPYFILE_DISABLE=1 zip -qry -X "$(basename "$ZIP_PATH")" "$(basename "$APP_BUNDLE")"
)

echo "$ZIP_PATH"
