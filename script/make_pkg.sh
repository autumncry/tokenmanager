#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${TOKENMANAGER_VERSION:-0.1.0}"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/pkg-root"
APP_BUNDLE="$DIST_DIR/tokenmanager.app"
PKG_PATH="$DIST_DIR/tokenmanager-$VERSION.pkg"

"$ROOT_DIR/script/package_app.sh" >/dev/null

rm -rf "$STAGE_DIR" "$PKG_PATH"
mkdir -p "$STAGE_DIR/Applications"
COPYFILE_DISABLE=1 ditto --norsrc "$APP_BUNDLE" "$STAGE_DIR/Applications/tokenmanager.app"
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$STAGE_DIR" >/dev/null 2>&1 || true
fi

pkgbuild \
  --root "$STAGE_DIR" \
  --identifier app.tokenmanager \
  --version "$VERSION" \
  --install-location / \
  "$PKG_PATH"

echo "$PKG_PATH"
