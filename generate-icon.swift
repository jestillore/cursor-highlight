#!/usr/bin/env swift
import AppKit

// Generate a macOS app icon for Cursor Highlight
// Design: Dark rounded-rect background with a glowing highlight circle and cursor arrow

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // --- Background: Rounded rectangle (macOS squircle-like) ---
    let cornerRadius = size * 0.22
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background: deep navy to dark blue
    let gradient = NSGradient(
        starting: NSColor(red: 0.08, green: 0.08, blue: 0.20, alpha: 1.0),
        ending: NSColor(red: 0.05, green: 0.12, blue: 0.28, alpha: 1.0)
    )!
    gradient.draw(in: bgPath, angle: -45)

    // --- Glow circle (the "highlight") ---
    let centerX = size * 0.48
    let centerY = size * 0.48
    let glowRadius = size * 0.28

    // Outer glow - very soft
    let outerGlowRadius = glowRadius * 1.8
    let outerGlowColors = [
        NSColor(red: 0.30, green: 0.70, blue: 1.0, alpha: 0.0).cgColor,
        NSColor(red: 0.30, green: 0.70, blue: 1.0, alpha: 0.08).cgColor,
        NSColor(red: 0.30, green: 0.70, blue: 1.0, alpha: 0.15).cgColor,
    ]
    let outerGlowGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: outerGlowColors as CFArray,
        locations: [1.0, 0.5, 0.0]
    )!
    ctx.drawRadialGradient(
        outerGlowGradient,
        startCenter: CGPoint(x: centerX, y: centerY),
        startRadius: 0,
        endCenter: CGPoint(x: centerX, y: centerY),
        endRadius: outerGlowRadius,
        options: []
    )

    // Inner highlight circle
    let highlightColors = [
        NSColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.35).cgColor,
        NSColor(red: 0.30, green: 0.65, blue: 1.0, alpha: 0.20).cgColor,
        NSColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 0.05).cgColor,
    ]
    let highlightGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: highlightColors as CFArray,
        locations: [0.0, 0.6, 1.0]
    )!
    ctx.drawRadialGradient(
        highlightGradient,
        startCenter: CGPoint(x: centerX, y: centerY),
        startRadius: 0,
        endCenter: CGPoint(x: centerX, y: centerY),
        endRadius: glowRadius,
        options: []
    )

    // Circle ring/border
    let ringRect = NSRect(
        x: centerX - glowRadius,
        y: centerY - glowRadius,
        width: glowRadius * 2,
        height: glowRadius * 2
    )
    let ringPath = NSBezierPath(ovalIn: ringRect)
    NSColor(red: 0.40, green: 0.78, blue: 1.0, alpha: 0.45).setStroke()
    ringPath.lineWidth = 2.5 * scale
    ringPath.stroke()

    // --- Cursor arrow ---
    // Classic macOS pointer arrow, positioned at center of the highlight
    let cursorScale = size * 0.0048
    let cursorX = centerX - size * 0.08
    let cursorY = centerY + size * 0.15

    let cursorPath = NSBezierPath()
    // Arrow shape (pointing up-left, classic cursor style)
    // Coordinates relative to tip of cursor, scaled
    let points: [(CGFloat, CGFloat)] = [
        (0, 0),          // tip
        (0, -100),       // left edge down
        (28, -72),       // notch left
        (58, -110),      // handle bottom-right
        (72, -96),       // handle top-right
        (42, -58),       // notch right
        (72, -58),       // right edge
    ]

    cursorPath.move(to: NSPoint(x: cursorX + points[0].0 * cursorScale, y: cursorY + points[0].1 * cursorScale))
    for i in 1..<points.count {
        cursorPath.line(to: NSPoint(x: cursorX + points[i].0 * cursorScale, y: cursorY + points[i].1 * cursorScale))
    }
    cursorPath.close()

    // Cursor shadow
    ctx.saveGState()
    let shadowOffset = 3.0 * scale
    let shadowPath = cursorPath.copy() as! NSBezierPath
    let shadowTransform = AffineTransform(translationByX: shadowOffset, byY: -shadowOffset)
    shadowPath.transform(using: shadowTransform)
    NSColor(red: 0, green: 0, blue: 0, alpha: 0.35).setFill()
    shadowPath.fill()
    ctx.restoreGState()

    // Cursor body - white with slight gradient feel
    NSColor.white.setFill()
    cursorPath.fill()

    // Cursor border - dark outline
    NSColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 0.8).setStroke()
    cursorPath.lineWidth = 1.5 * scale
    cursorPath.lineJoinStyle = .round
    cursorPath.stroke()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// Create iconset directory
let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate all required icon sizes
let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

print("Generating icon images...")
let masterImage = drawIcon(size: 1024)

for entry in sizes {
    let path = "\(iconsetPath)/\(entry.name)"
    savePNG(masterImage, to: path, pixelSize: entry.pixels)
    print("  Created \(entry.name) (\(entry.pixels)x\(entry.pixels))")
}

print("Converting to .icns...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Successfully created AppIcon.icns")
    // Clean up iconset
    try? fm.removeItem(atPath: iconsetPath)
} else {
    print("Error: iconutil failed with status \(process.terminationStatus)")
}
