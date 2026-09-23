#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:---release}"
case "$CONFIGURATION" in
  --release) BUILD_CONFIGURATION=release ;;
  --debug) BUILD_CONFIGURATION=debug ;;
  *) echo "usage: $0 [--release|--debug]" >&2; exit 2 ;;
esac

APP_NAME="LivePrompt"
APP_VERSION="0.1.0"
BUNDLE_ID="com.naoki.liveprompt"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_BINARY="$APP_CONTENTS/MacOS/$APP_NAME"

if [[ -d /Library/Developer/CommandLineTools ]]; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi

cd "$ROOT_DIR"
swift build --build-system native -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build --build-system native -c "$BUILD_CONFIGURATION" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_CONTENTS/MacOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

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
  <key>CFBundleVersion</key><string>1</string>
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
