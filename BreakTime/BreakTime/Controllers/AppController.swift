import Cocoa

class AppController {
    private let timerService: TimerService
    private let settingsService: SettingsService
    private let overlayWindowController: OverlayWindowController
    private var statusItem: NSStatusItem!
    
    // Standard emoji icons for better readability in menu bar
    private let workIcon = "💼" // Work icon
    private let breakIcon = "☕️" // Coffee/break icon
    private let pausedIcon = "⏰" // Timer icon
    
    init() {
        // Initialize all properties before using them
        self.settingsService = SettingsService()
        let settings = settingsService.loadSettings()
        
        self.timerService = TimerService(settings: settings)
        self.overlayWindowController = OverlayWindowController()
        
        // Set delegate after all properties are initialized
        self.timerService.delegate = self
        
        setupStatusBarItem()
        setupNotifications()
    }
    
    private func setupStatusBarItem() {
        // Use a fixed width for a smaller footprint but consistent size
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Set button properties for consistent appearance
            button.imagePosition = .imageLeft
            
            // Add spacing with title edge insets
            if let buttonCell = button.cell as? NSButtonCell {
                buttonCell.imageDimsWhenDisabled = false
            }
            
            // Use monospaced digit font to keep consistent width when numbers change
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            
            // Set a fixed width in updateStatusBarDisplay with proper formatting
            updateStatusBarDisplay()
            
            button.action = #selector(statusItemClicked)
            button.target = self
            
            // Give the button a fixed width to prevent resizing
            button.frame.size.width = 80 // Increased slightly to fit both icon and timer
        }
        
        // Immediately create a menu so it's ready to display
        updateMenuItems()
    }
    
    private func updateStatusBarDisplay() {
        // Only update if the button exists
        guard let button = statusItem.button else { return }
        
        // Make sure text is center-aligned for consistency
        button.alignment = .center
        
        // Remove any explicit tint color to allow system to handle dark/light mode
        button.contentTintColor = nil
        
        // Remove any image
        button.image = nil
        
        // Create an attributed string for fixed-width rendering
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        ]
        
        switch timerService.state {
        case .working:
            // Work icon + time remaining with fixed-width formatting
            let timeText = formatTimeRemaining(timerService.secondsRemaining)
            
            // Format with fixed width by using a monospaced font
            let attrString = NSMutableAttributedString(string: "\(workIcon) \(timeText)", attributes: attributes)
            button.attributedTitle = attrString
            
            // Set tooltip for accessibility
            button.toolTip = "Work time: \(timeText) remaining"
            
        case .breaking:
            // Break icon + time remaining with fixed-width formatting
            let timeText = formatTimeRemaining(timerService.secondsRemaining)
            
            // Format with fixed width
            let attrString = NSMutableAttributedString(string: "\(breakIcon) \(timeText)", attributes: attributes)
            button.attributedTitle = attrString
            
            // Set tooltip for accessibility
            button.toolTip = "Break time: \(timeText) remaining"
            
        case .paused:
            // Determine which icon to show based on the last active state
            let icon = timerService.secondsRemaining > 0 ? pausedIcon : "⏸️"
            let timeText = timerService.secondsRemaining > 0 ? formatTimeRemaining(timerService.secondsRemaining) : "--:--"
            
            // Format with fixed width
            let attrString = NSMutableAttributedString(string: "\(icon) \(timeText)", attributes: attributes)
            button.attributedTitle = attrString
            
            // Set tooltip for accessibility
            button.toolTip = "Timer is paused. Click to resume or start a new timer."
            
        case .stopped:
            // Stopped icon using placeholder text with same width as timer
            let attrString = NSMutableAttributedString(string: "\(pausedIcon) --:--", attributes: attributes)
            button.attributedTitle = attrString
            
            // Set tooltip for accessibility
            button.toolTip = "BreakTime is stopped. Click to start a new timer."
        }
        
        // Ensure button stays at our desired fixed width
        if button.frame.size.width != 80 {
            button.frame.size.width = 80
        }
    }
    
    private func formatTimeRemaining(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        // Use a fixed-width format to ensure consistent width
        // Always show at least two digits for minutes even if below 10
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // Alternative compact format for potential future use
    private func formatCompactTimeRemaining(_ seconds: Int) -> String {
        let minutes = seconds / 60
        
        if seconds % 60 == 0 {
            // If exact minutes, show more compact format
            return String(format: "%dm", minutes)
        } else {
            // Otherwise show standard time format
            return formatTimeRemaining(seconds)
        }
    }
    
    private func setupNotifications() {
        // Observe postpone requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostponeRequest),
            name: Notification.Name("PostponeBreakRequested"),
            object: nil
        )
        
        // Observe skip break requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSkipBreakRequest),
            name: Notification.Name("SkipBreakRequested"),
            object: nil
        )
    }
    
    @objc private func statusItemClicked() {
        // Update the menu before displaying it
        updateMenuItems()
        
        // Get the status bar button to position the menu correctly
        if let button = statusItem.button {
            // Position the menu below the status item
            statusItem.menu?.popUp(positioning: nil, at: NSPoint(x: button.frame.origin.x,
                                                              y: button.frame.origin.y - 5),
                                 in: button.superview)
        } else {
            // Fallback to mouse location if button isn't available
            statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }
    
    private func updateMenuItems() {
        let menu = NSMenu()
        
        // Add menu items based on current state
        switch timerService.state {
        case .working, .breaking:
            // Show pause option when timer is running
            let pauseItem = NSMenuItem(title: "Pause Timer", action: #selector(pauseTimer), keyEquivalent: "p")
            pauseItem.target = self
            menu.addItem(pauseItem)
            
            // Show stop option when timer is running
            let stopItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            
        case .paused:
            // Show resume option when paused
            let resumeItem = NSMenuItem(title: "Resume Timer", action: #selector(resumeTimer), keyEquivalent: "r")
            resumeItem.target = self
            menu.addItem(resumeItem)
            
            // Show stop option when paused
            let stopItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
            
        case .stopped:
            // Show start work timer when stopped
            let startItem = NSMenuItem(title: "Start Work Timer", action: #selector(startWorkTimer), keyEquivalent: "w")
            startItem.target = self
            menu.addItem(startItem)
        }
        
        // Add separator and other common items
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func startWorkTimer() {
        print("Starting work timer")
        timerService.startWorkTimer()
        
        // Update UI elements
        updateMenuItems()
        updateStatusBarDisplay()
        
        // Log the current state for debugging
        print("Timer state: \(timerService.state), remaining time: \(timerService.secondsRemaining) seconds")
    }
    
    @objc private func pauseTimer() {
        print("Pausing timer")
        timerService.pauseTimer()
        
        // Update UI elements
        updateMenuItems()
        updateStatusBarDisplay()
    }
    
    @objc private func resumeTimer() {
        print("Resuming timer")
        timerService.resumeTimer()
        
        // Update UI elements
        updateMenuItems()
        updateStatusBarDisplay()
    }
    
    @objc private func stopTimer() {
        print("Stopping timer")
        timerService.stopTimer()
        
        // Update UI elements
        updateMenuItems()
        updateStatusBarDisplay()
    }
    
    // Reference to keep the settings window controller alive
    private var currentSettingsController: SettingsWindowController?
    
    @objc private func showSettings() {
        // Create the settings window controller and store a reference to it
        currentSettingsController = SettingsWindowController(settings: settingsService.loadSettings()) { [weak self] settings in
            // Save the new settings
            self?.settingsService.saveSettings(settings)
            self?.timerService.updateSettings(settings)
            
            // Start a new work timer immediately when settings are saved
            self?.timerService.startWorkTimer()
            self?.updateStatusBarDisplay()
            
            // Clear the reference when done
            self?.currentSettingsController = nil
        }
        
        // Show the settings window and make it key and front
        currentSettingsController?.showWindow(nil)
        
        // Ensure window is visible
        if let settingsWindow = currentSettingsController?.window {
            settingsWindow.makeKeyAndOrderFront(nil)
            
            // Set a higher level temporarily to make sure it appears
            settingsWindow.level = .floating
            
            // Set the appearance to match system
            settingsWindow.appearance = NSApp.effectiveAppearance
        }
        
        // Temporarily change activation policy to regular to show window properly
        let originalPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        
        // Bring the app to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Then go back to accessory after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.setActivationPolicy(originalPolicy)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func handlePostponeRequest(notification: Notification) {
        if let minutes = notification.userInfo?["minutes"] as? Int {
            print("Starting work session with \(minutes) extra minutes")
            timerService.postponeBreak(byMinutes: minutes)
            overlayWindowController.hideBreakScreen()
        }
    }
    
    @objc private func handleSkipBreakRequest(notification: Notification) {
        print("Skipping break")
        // Hide the break screen
        overlayWindowController.hideBreakScreen()
        
        // End the current break and start a new work session
        if timerService.state == .breaking {
            timerService.pauseTimer()
            timerService.startWorkTimer()
        }
    }
    
}

// MARK: - TimerServiceDelegate
extension AppController: TimerServiceDelegate {
    func timerStateDidChange(state: TimerState) {
        DispatchQueue.main.async { [weak self] in
            // Update menu items based on new state
            self?.updateMenuItems()
            
            // Update the status bar display
            self?.updateStatusBarDisplay()
            
            // Handle overlay window
            switch state {
            case .breaking:
                self?.overlayWindowController.showBreakScreen(remainingSeconds: self?.timerService.secondsRemaining ?? 0)
                
            case .paused:
                // Only hide break screen if we were in break mode
                if self?.timerService.secondsRemaining == 0 {
                    self?.overlayWindowController.hideBreakScreen()
                }
                
            case .stopped, .working:
                self?.overlayWindowController.hideBreakScreen()
            }
        }
    }
    
    func timerDidComplete() {
        DispatchQueue.main.async { [weak self] in
            // If work period completed, start break. If break completed, start work.
            if self?.timerService.state == .working {
                self?.timerService.startBreakTimer()
            } else if self?.timerService.state == .breaking {
                self?.overlayWindowController.hideBreakScreen()
                self?.timerService.startWorkTimer()
            }
        }
    }
    
    func timerDidUpdate(secondsRemaining: Int) {
        DispatchQueue.main.async { [weak self] in
            // Always update the status bar display with the current time
            self?.updateStatusBarDisplay()
            
            // Only update the timer on the overlay screen, don't show it repeatedly
            if self?.timerService.state == .breaking {
                self?.overlayWindowController.updateBreakTimer(seconds: secondsRemaining)
            }
        }
    }
}
