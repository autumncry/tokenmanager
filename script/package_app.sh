#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="tokenmanager"
BUNDLE_ID="app.tokenmanager"
VERSION="${TOKENMANAGER_VERSION:-0.1.0}"
BUILD_NUMBER="${TOKENMANAGER_BUILD:-1}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"
swift build -c release --product tokenmanager
swift build -c release --product tokenmanagerctl

BUILD_BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_CONTENTS/Resources"
cp "$BUILD_BIN_DIR/tokenmanager" "$APP_MACOS/tokenmanager"
cp "$BUILD_BIN_DIR/tokenmanagerctl" "$APP_MACOS/tokenmanagerctl"
chmod +x "$APP_MACOS/tokenmanager" "$APP_MACOS/tokenmanagerctl"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>tokenmanager</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>tokenmanager</string>
  <key>CFBundleDisplayName</key>
  <string>tokenmanager</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 tokenmanager contributors.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "$APP_BUNDLE"
