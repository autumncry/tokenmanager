#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TOKENMANAGER_VERSION:-0.1.0}"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/tokenmanager-$VERSION.dmg"
APP_BUNDLE="$DIST_DIR/tokenmanager.app"

"$ROOT_DIR/script/package_app.sh" >/dev/null

rm -rf "$STAGE_DIR" "$DMG_PATH"
mkdir -p "$STAGE_DIR"
COPYFILE_DISABLE=1 ditto --norsrc "$APP_BUNDLE" "$STAGE_DIR/tokenmanager.app"
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$STAGE_DIR" >/dev/null 2>&1 || true
fi
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "tokenmanager" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
