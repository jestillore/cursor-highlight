#!/bin/bash
set -e

APP_NAME="Cursor Highlight"
BUNDLE_ID="com.jestillore.cursor-highlight"
VERSION="1.1.1"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/CursorHighlight" "$APP_DIR/Contents/MacOS/"
cp AppIcon.icns "$APP_DIR/Contents/Resources/"

cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>CursorHighlight</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Signing app bundle..."
codesign --force --sign - "$APP_DIR"

echo "Creating DMG..."
DMG_NAME="CursorHighlight-${VERSION}.dmg"
DMG_TEMP="dmg-temp"

rm -rf "$DMG_TEMP" "$DMG_NAME"
mkdir -p "$DMG_TEMP"
cp -R "$APP_DIR" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_NAME"

rm -rf "$DMG_TEMP"

echo ""
echo "Done! Created '$DMG_NAME'"
echo "Distribute: share '$DMG_NAME' — users open it and drag to Applications."
