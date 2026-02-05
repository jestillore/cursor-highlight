import AppKit

// MARK: - HighlightView

class HighlightView: NSView {
    var cursorPosition: NSPoint = .zero
    var isMouseDown = false
    var currentRadius: CGFloat = 40
    let normalRadius: CGFloat = 40
    let activeRadius: CGFloat = 60
    let radiusSpeed: CGFloat = 4

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        let targetRadius = isMouseDown ? activeRadius : normalRadius
        if currentRadius < targetRadius {
            currentRadius = min(currentRadius + radiusSpeed, targetRadius)
        } else if currentRadius > targetRadius {
            currentRadius = max(currentRadius - radiusSpeed, targetRadius)
        }

        let r = currentRadius
        let rect = CGRect(
            x: cursorPosition.x - r,
            y: cursorPosition.y - r,
            width: r * 2,
            height: r * 2
        )
        ctx.setFillColor(CGColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 0.3))
        ctx.fillEllipse(in: rect)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    var highlightView: HighlightView!
    var statusItem: NSStatusItem!
    var animationTimer: Timer?
    var isOverlayVisible = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupOverlayWindow()
        setupStatusBar()
        setupEventMonitors()
        startAnimationTimer()
    }

    // MARK: Overlay Window

    func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }
        overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlayWindow.level = .screenSaver
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        highlightView = HighlightView(frame: screen.frame)
        overlayWindow.contentView = highlightView
        overlayWindow.orderFrontRegardless()
    }

    // MARK: Status Bar

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let size: CGFloat = 18
            let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
                NSColor.controlTextColor.setFill()
                let inset = rect.insetBy(dx: 3, dy: 3)
                NSBezierPath(ovalIn: inset).fill()
                return true
            }
            image.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Highlight (⌥X)", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: Event Monitors

    func setupEventMonitors() {
        // Global: mouse movement
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.updateCursorPosition()
        }

        // Global: mouse down
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.highlightView.isMouseDown = true
        }

        // Global: mouse up
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] _ in
            self?.highlightView.isMouseDown = false
        }

        // Global: key down (Alt+X)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.charactersIgnoringModifiers == "x" {
                self?.toggleOverlay()
            }
        }

        // Local: key down (Escape and Alt+X when app is focused)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideOverlay()
                return nil
            }
            if event.modifierFlags.contains(.option) && event.charactersIgnoringModifiers == "x" {
                self?.toggleOverlay()
                return nil
            }
            return event
        }
    }

    func updateCursorPosition() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = overlayWindow.screen ?? NSScreen.main else { return }
        let windowPoint = NSPoint(
            x: mouseLocation.x - screen.frame.origin.x,
            y: mouseLocation.y - screen.frame.origin.y
        )
        highlightView.cursorPosition = windowPoint
    }

    // MARK: Animation

    func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.highlightView.needsDisplay = true
        }
    }

    // MARK: Actions

    @objc func toggleOverlay() {
        if isOverlayVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    func showOverlay() {
        overlayWindow.orderFrontRegardless()
        isOverlayVisible = true
    }

    func hideOverlay() {
        overlayWindow.orderOut(nil)
        isOverlayVisible = false
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
