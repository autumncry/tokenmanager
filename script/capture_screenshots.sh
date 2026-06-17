#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/docs/screenshots"
APP_BUNDLE="$("$ROOT_DIR/script/package_app.sh" | tail -n 1)"

mkdir -p "$OUT_DIR"

quit_tokenmanager() {
  osascript -e 'tell application "tokenmanager" to quit' >/dev/null 2>&1 || true
  pkill -x tokenmanager >/dev/null 2>&1 || true
}

capture() {
  local target="$1"
  local output="$2"
  shift 2

  quit_tokenmanager
  open -n "$APP_BUNDLE" --args --demo "$@"
  swift "$ROOT_DIR/script/capture_window.swift" "$target" "$output"
  quit_tokenmanager
  sleep 0.7
}

capture main "$OUT_DIR/tokenmanager-dashboard.png"
capture quick "$OUT_DIR/tokenmanager-quick-view.png" --open-quick-preview
capture settings "$OUT_DIR/tokenmanager-settings.png" --open-settings

echo "$OUT_DIR"
