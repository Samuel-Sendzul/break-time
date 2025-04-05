import Cocoa

class OverlayWindowController: NSWindowController {
    // Global event monitor to track screen changes
    private var eventMonitor: Any?
    private var overlayWindow: NSWindow!
    private var breakViewController: BreakViewController!
    
    override init(window: NSWindow?) {
        super.init(window: nil)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    private func setupWindow() {
        // Initially create with a dummy rect - we'll set the proper frame later
        let initialRect = NSRect(x: 0, y: 0, width: 100, height: 100)
        
        // Create a custom window that can become key
        overlayWindow = KeyableWindow(
            contentRect: initialRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Use maximum window level to appear above everything
        overlayWindow.level = .popUpMenu  // One of the highest levels, above status bar and modal panel
        
        // Initially transparent (will animate in when shown)
        overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.0)
        
        // Critical window settings to block interaction
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.acceptsMouseMovedEvents = true
        overlayWindow.isReleasedWhenClosed = false
        
        // Make sure the window is always on top
        overlayWindow.isMovableByWindowBackground = false
        
        // Prevent user interaction with window border
        overlayWindow.styleMask = [.borderless]
        
        // Make the window appear on all spaces including full screen apps
        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,   // Show on all spaces/desktops
            .fullScreenAuxiliary // Show above full-screen apps
        ]
        
        // Stay on top even when not active
        overlayWindow.hidesOnDeactivate = false
        
        // Set floats flag to keep on top
        overlayWindow.styleMask.insert(.utilityWindow)
        
        // Set as key window to receive all events
        overlayWindow.makeKey()
        
        self.window = overlayWindow
        
        // Create the break view controller
        self.breakViewController = BreakViewController()
        self.breakViewController.delegate = self
        self.breakViewController.loadView()
        self.window?.contentViewController = self.breakViewController
    }
    
    func showBreakScreen(remainingSeconds: Int) {
        // Update window frame to match active screen
        updateWindowFrame()
        
        // Reset to maximum window level and force to front
        overlayWindow.level = .popUpMenu
        
        // Bring window to front and make it key (active) to capture all input
        overlayWindow.makeKeyAndOrderFront(nil)
        
        // Activate our app
        NSApp.activate(ignoringOtherApps: true)
        
        // Set focus to our window to prevent typing elsewhere
        overlayWindow.makeFirstResponder(breakViewController.view)
        
        // Update timer display
        breakViewController.updateTimer(seconds: remainingSeconds)
        
        // Set window opacity immediately - no fade in
        overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.4)
        
        // Ensure window stays on top during and after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.overlayWindow.orderFrontRegardless()
        }
        
        // Set up event monitoring to follow user between monitors
        setupScreenChangeMonitoring()
    }
    
    /// Updates just the timer display without showing the window again
    func updateBreakTimer(seconds: Int) {
        // Only update the timer if the window is visible
        if overlayWindow.isVisible {
            breakViewController.updateTimer(seconds: seconds)
        }
    }
    
    /// Update window frame to cover the active screen
    private func updateWindowFrame() {
        // Find the active screen (where the cursor is)
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first!
        
        // Get the frame of the active screen
        let visibleFrame = activeScreen.frame
        
        // Update window frame to cover the entire active screen
        overlayWindow.setFrame(visibleFrame, display: true)
    }
    
    func hideBreakScreen() {
        // Stop monitoring for screen changes
        removeScreenChangeMonitoring()
        
        // Animate fade out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 2.0  // Slower fade out over 2 seconds
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            overlayWindow.animator().backgroundColor = NSColor.black.withAlphaComponent(0.0)
        }, completionHandler: { [weak self] in
            self?.overlayWindow.orderOut(nil)
        })
    }
    
    // Set up monitoring to detect when user changes active screen
    private func setupScreenChangeMonitoring() {
        // Remove any existing monitor
        removeScreenChangeMonitoring()
        
        // Create a new global monitor for mouse moved events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            // Don't update window frame on every mouse move - add delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                // Only update if the mouse has moved to a different screen
                let mouseLocation = NSEvent.mouseLocation
                if !NSMouseInRect(mouseLocation, self.overlayWindow.frame, false) {
                    self.updateWindowFrame()
                    self.overlayWindow.orderFrontRegardless()
                }
            }
        }
    }
    
    private func removeScreenChangeMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

extension OverlayWindowController: BreakViewControllerDelegate {
    func postponeBreakRequested(minutes: Int) {
        // This will be handled by the app controller
        NotificationCenter.default.post(
            name: Notification.Name("PostponeBreakRequested"),
            object: nil,
            userInfo: ["minutes": minutes]
        )
    }
    
    func skipBreakRequested() {
        // This will be handled by the app controller
        NotificationCenter.default.post(
            name: Notification.Name("SkipBreakRequested"),
            object: nil
        )
    }
}

/// Custom window class that can become key and captures all events
class KeyableWindow: NSWindow {
    // Allow the window to become key even without a title bar
    override var canBecomeKey: Bool {
        return true
    }
    
    // Allow the window to become main
    override var canBecomeMain: Bool {
        return true
    }
    
    // Capture all keyboard events when key
    override var acceptsFirstResponder: Bool {
        return true
    }
}