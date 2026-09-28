#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:---release}"
case "$CONFIGURATION" in
  --release) BUILD_CONFIGURATION=release ;;
  --debug) BUILD_CONFIGURATION=debug ;;
  *) echo "usage: $0 [--release|--debug]" >&2; exit 2 ;;
esac

APP_NAME="LivePrompt"
APP_VERSION="0.1.3"
BUNDLE_ID="com.naoki.liveprompt"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${LIVEPROMPT_OUTPUT_DIR:-$ROOT_DIR/dist}"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_BINARY="$APP_CONTENTS/MacOS/$APP_NAME"

if [[ -d /Library/Developer/CommandLineTools ]]; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi

cd "$ROOT_DIR"
SWIFT_BUILD_ARGS=(--build-system native -c "$BUILD_CONFIGURATION")
if [[ "${LIVEPROMPT_HOMEBREW_BUILD:-0}" == "1" ]]; then
  SWIFT_BUILD_ARGS+=(--disable-sandbox --disable-dependency-cache --manifest-cache local)
fi
swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_CONTENTS/MacOS"
mkdir -p "$APP_CONTENTS/Resources"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

ICONSET_DIR="$(mktemp -d "${TMPDIR:-/tmp}/LivePrompt.XXXXXX.iconset")"
trap 'rm -rf "$ICONSET_DIR"' EXIT
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ROOT_DIR/Assets/AppIcon.png" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  double_size=$((size * 2))
  sips -z "$double_size" "$double_size" "$ROOT_DIR/Assets/AppIcon.png" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns -o "$APP_CONTENTS/Resources/AppIcon.icns" "$ICONSET_DIR"

cat > "$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$APP_VERSION</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>CFBundleIconFile</key><string>AppIcon.icns</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSAudioCaptureUsageDescription</key><string>Macで再生される音声を英語字幕と日本語訳にするために使用します。録音は保存しません。</string>
  <key>NSSpeechRecognitionUsageDescription</key><string>Macで再生される英語音声を端末内で文字起こしするために使用します。</string>
</dict>
</plist>
PLIST

plutil -lint "$APP_CONTENTS/Info.plist"
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --strict "$APP_BUNDLE"
printf '%s\n' "$APP_BUNDLE"
