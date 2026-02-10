import AppKit
import Carbon

// MARK: - Settings Keys

private enum SettingsKey {
    static let colorRed = "circleColorRed"
    static let colorGreen = "circleColorGreen"
    static let colorBlue = "circleColorBlue"
    static let colorAlpha = "circleColorAlpha"
    static let normalRadius = "normalRadius"
    static let activeRadius = "activeRadius"
}

private let defaultColor = NSColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 0.3)
private let defaultNormalRadius: CGFloat = 40
private let defaultActiveRadius: CGFloat = 60

// MARK: - Settings

struct Settings {
    var color: NSColor
    var normalRadius: CGFloat
    var activeRadius: CGFloat

    static func load() -> Settings {
        let ud = UserDefaults.standard
        let hasColor = ud.object(forKey: SettingsKey.colorRed) != nil
        let color: NSColor
        if hasColor {
            color = NSColor(
                red: CGFloat(ud.double(forKey: SettingsKey.colorRed)),
                green: CGFloat(ud.double(forKey: SettingsKey.colorGreen)),
                blue: CGFloat(ud.double(forKey: SettingsKey.colorBlue)),
                alpha: CGFloat(ud.double(forKey: SettingsKey.colorAlpha))
            )
        } else {
            color = defaultColor
        }
        let normal = ud.object(forKey: SettingsKey.normalRadius) != nil
            ? CGFloat(ud.double(forKey: SettingsKey.normalRadius))
            : defaultNormalRadius
        let active = ud.object(forKey: SettingsKey.activeRadius) != nil
            ? CGFloat(ud.double(forKey: SettingsKey.activeRadius))
            : defaultActiveRadius
        return Settings(color: color, normalRadius: normal, activeRadius: active)
    }

    func save() {
        let ud = UserDefaults.standard
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let c = color.usingColorSpace(.sRGB) ?? color
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        ud.set(Double(r), forKey: SettingsKey.colorRed)
        ud.set(Double(g), forKey: SettingsKey.colorGreen)
        ud.set(Double(b), forKey: SettingsKey.colorBlue)
        ud.set(Double(a), forKey: SettingsKey.colorAlpha)
        ud.set(Double(normalRadius), forKey: SettingsKey.normalRadius)
        ud.set(Double(activeRadius), forKey: SettingsKey.activeRadius)
    }
}

// MARK: - HighlightView

class HighlightView: NSView {
    var cursorPosition: NSPoint = .zero
    var isMouseDown = false
    var currentRadius: CGFloat = 40
    var normalRadius: CGFloat = 40
    var activeRadius: CGFloat = 60
    var fillColor: NSColor = defaultColor
    let radiusSpeed: CGFloat = 4
    var isActive = true

    func applySettings(_ settings: Settings) {
        fillColor = settings.color
        normalRadius = settings.normalRadius
        activeRadius = settings.activeRadius
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        guard isActive else { return }

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
        let c = fillColor.usingColorSpace(.sRGB) ?? fillColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        c.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        ctx.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: alpha))
        ctx.fillEllipse(in: rect)
    }
}

// MARK: - SettingsWindowController

class SettingsWindowController: NSWindowController {
    var colorWell: NSColorWell!
    var normalRadiusField: NSTextField!
    var activeRadiusField: NSTextField!
    var onSettingsChanged: ((Settings) -> Void)?

    convenience init(settings: Settings, onChanged: @escaping (Settings) -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        self.init(window: window)
        self.onSettingsChanged = onChanged
        setupUI(settings: settings)
    }

    private func setupUI(settings: Settings) {
        guard let contentView = window?.contentView else { return }
        let padding: CGFloat = 20
        let labelWidth: CGFloat = 100
        let fieldX = padding + labelWidth + 8
        let fieldWidth: CGFloat = 300 - fieldX - padding
        var y: CGFloat = 130

        // Color
        let colorLabel = NSTextField(labelWithString: "Color:")
        colorLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: 24)
        colorLabel.alignment = .right
        contentView.addSubview(colorLabel)

        colorWell = NSColorWell(frame: NSRect(x: fieldX, y: y, width: 44, height: 24))
        colorWell.color = settings.color
        colorWell.target = self
        colorWell.action = #selector(settingChanged)
        contentView.addSubview(colorWell)

        y -= 40

        // Normal radius
        let normalLabel = NSTextField(labelWithString: "Default Size:")
        normalLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: 24)
        normalLabel.alignment = .right
        contentView.addSubview(normalLabel)

        normalRadiusField = NSTextField(frame: NSRect(x: fieldX, y: y, width: fieldWidth, height: 24))
        normalRadiusField.doubleValue = Double(settings.normalRadius)
        normalRadiusField.formatter = radiusFormatter()
        normalRadiusField.target = self
        normalRadiusField.action = #selector(settingChanged)
        contentView.addSubview(normalRadiusField)

        y -= 40

        // Active radius
        let activeLabel = NSTextField(labelWithString: "Clicked Size:")
        activeLabel.frame = NSRect(x: padding, y: y, width: labelWidth, height: 24)
        activeLabel.alignment = .right
        contentView.addSubview(activeLabel)

        activeRadiusField = NSTextField(frame: NSRect(x: fieldX, y: y, width: fieldWidth, height: 24))
        activeRadiusField.doubleValue = Double(settings.activeRadius)
        activeRadiusField.formatter = radiusFormatter()
        activeRadiusField.target = self
        activeRadiusField.action = #selector(settingChanged)
        contentView.addSubview(activeRadiusField)
    }

    private func radiusFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimum = 5
        f.maximum = 200
        f.maximumFractionDigits = 0
        return f
    }

    @objc private func settingChanged() {
        let settings = Settings(
            color: colorWell.color,
            normalRadius: CGFloat(normalRadiusField.doubleValue),
            activeRadius: CGFloat(activeRadiusField.doubleValue)
        )
        settings.save()
        onSettingsChanged?(settings)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindows: [(window: NSWindow, view: HighlightView)] = []
    var activeView: HighlightView?
    var statusItem: NSStatusItem!
    var animationTimer: Timer?
    var isOverlayVisible = true
    var settingsWindowController: SettingsWindowController?
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.load()
        setupOverlayWindows(settings: settings)
        setupStatusBar()
        setupEventMonitors()
        registerHotKey()
        startAnimationTimer()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: Overlay Windows

    func setupOverlayWindows(settings: Settings) {
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let view = HighlightView(frame: screen.frame)
            view.applySettings(settings)
            view.isActive = false
            window.contentView = view
            window.orderFrontRegardless()

            overlayWindows.append((window: window, view: view))
        }
    }

    @objc func screensChanged() {
        let settings: Settings
        if let view = overlayWindows.first?.view {
            settings = Settings(
                color: view.fillColor,
                normalRadius: view.normalRadius,
                activeRadius: view.activeRadius
            )
        } else {
            settings = Settings.load()
        }
        for entry in overlayWindows {
            entry.window.orderOut(nil)
        }
        overlayWindows.removeAll()
        activeView = nil
        setupOverlayWindows(settings: settings)
        if !isOverlayVisible {
            overlayWindows.forEach { $0.window.orderOut(nil) }
        }
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
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: Event Monitors

    func setupEventMonitors() {
        // Global: mouse down
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.overlayWindows.forEach { $0.view.isMouseDown = true }
        }

        // Global: mouse up
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] _ in
            self?.overlayWindows.forEach { $0.view.isMouseDown = false }
        }

        // Local: key down (Escape when app is focused)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideOverlay()
                return nil
            }
            return event
        }
    }

    func updateCursorPosition() {
        let mouseLocation = NSEvent.mouseLocation

        // Find which overlay window's screen contains the cursor
        var targetEntry: (window: NSWindow, view: HighlightView)?
        for entry in overlayWindows {
            if entry.window.frame.contains(mouseLocation) {
                targetEntry = entry
                break
            }
        }

        guard let active = targetEntry else { return }

        // Transfer radius animation state for smooth transitions across screens
        if let prev = activeView, prev !== active.view {
            active.view.currentRadius = prev.currentRadius
        }
        activeView = active.view

        // Convert to window-local coordinates
        let windowPoint = NSPoint(
            x: mouseLocation.x - active.window.frame.origin.x,
            y: mouseLocation.y - active.window.frame.origin.y
        )
        active.view.cursorPosition = windowPoint
        active.view.isActive = true
        active.view.needsDisplay = true

        // Deactivate other views
        for entry in overlayWindows where entry.view !== active.view {
            if entry.view.isActive {
                entry.view.isActive = false
                entry.view.needsDisplay = true
            }
        }
    }

    // MARK: Global Hot Key (Carbon)

    func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x43484C54), id: 1) // "CHLT"
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        // Store a raw pointer to self so the C callback can reach us
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, inEvent, refcon -> OSStatus in
                guard let refcon = refcon else { return OSStatus(eventNotHandledErr) }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                delegate.toggleOverlay()
                return noErr
            },
            1,
            &eventType,
            refcon,
            nil
        )
        // kVK_ANSI_X = 0x07, optionKey = 0x0800
        RegisterEventHotKey(
            UInt32(kVK_ANSI_X),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    // MARK: Animation

    func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateCursorPosition()
        }
        RunLoop.current.add(animationTimer!, forMode: .common)
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
        overlayWindows.forEach { $0.window.orderFrontRegardless() }
        isOverlayVisible = true
    }

    func hideOverlay() {
        overlayWindows.forEach { $0.window.orderOut(nil) }
        isOverlayVisible = false
    }

    @objc func openSettings() {
        if let existing = settingsWindowController {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = overlayWindows.first?.view
        let current = Settings(
            color: view?.fillColor ?? defaultColor,
            normalRadius: view?.normalRadius ?? defaultNormalRadius,
            activeRadius: view?.activeRadius ?? defaultActiveRadius
        )
        settingsWindowController = SettingsWindowController(settings: current) { [weak self] newSettings in
            self?.overlayWindows.forEach { $0.view.applySettings(newSettings) }
        }
        settingsWindowController?.window?.delegate = self
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindowController?.window {
            settingsWindowController = nil
        }
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
