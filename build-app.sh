#!/bin/bash
set -e

APP_NAME="Cursor Highlight"
BUNDLE_ID="com.jestillore.cursor-highlight"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/CursorHighlight" "$APP_DIR/Contents/MacOS/"

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
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Done! Created '$APP_DIR'"
echo ""
echo "To install: drag '$APP_DIR' into /Applications"
echo "To distribute: zip it with: zip -r 'Cursor Highlight.zip' '$APP_DIR'"
