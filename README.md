# Cursor Highlight

A lightweight macOS menu bar app that draws a colored circle around your cursor, making it easy to find on screen. Supports multiple displays.

## Installation

Download the latest `.dmg` from [Releases](https://github.com/jestillore/cursor-highlight/releases), open it, and drag **Cursor Highlight** to your Applications folder.

### Bypassing Gatekeeper

Since the app is not signed with an Apple Developer certificate, macOS will block it by default. Use one of these methods to open it:

**Option 1: Right-click to open (simplest)**

1. Open Finder and navigate to the app
2. Right-click (or Control-click) on **Cursor Highlight**
3. Select **Open** from the context menu
4. Click **Open** in the dialog that appears

You only need to do this once. After that, the app will open normally.

**Option 2: Allow in System Settings**

1. Double-click the app — macOS will show a warning and refuse to open it
2. Open **System Settings > Privacy & Security**
3. Scroll down to the **Security** section
4. You'll see a message about Cursor Highlight being blocked — click **Open Anyway**
5. Enter your password when prompted

**Option 3: Remove the quarantine attribute**

```sh
xattr -d com.apple.quarantine /Applications/Cursor\ Highlight.app
```

## Building from source

### Requirements

- macOS 10.15+
- Swift 5.7+ (included with Xcode or Xcode Command Line Tools)

### Build and run

```sh
# Build the app bundle and create a .dmg
./build-app.sh

# Run the app
open "Cursor Highlight.app"
```

### Development

```sh
# Build and run directly with Swift
swift build
.build/debug/CursorHighlight
```
