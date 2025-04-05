import Cocoa
import ServiceManagement

class SettingsWindowController: NSWindowController {
    private var settings: TimerSettings
    private var onSave: ((TimerSettings) -> Void)?
    
    private var workDurationField: NSTextField!
    private var breakDurationField: NSTextField!
    private var startAtLoginCheckbox: NSButton!
    
    // Custom formatter that only allows numbers
    class NumberOnlyFormatter: NumberFormatter, @unchecked Sendable {
        override func isPartialStringValid(_ partialString: String, 
                                         newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, 
                                         errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
            // Empty string is valid
            if partialString.isEmpty {
                return true
            }
            
            // Only digits are valid
            if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: partialString)) {
                return true
            }
            
            return false
        }
    }
    
    init(settings: TimerSettings, onSave: @escaping (TimerSettings) -> Void) {
        self.settings = settings
        self.onSave = onSave
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Break Time Settings"
        window.center()
        window.isReleasedWhenClosed = false // Prevent premature deallocation
        
        // Critical settings to prevent window from disappearing:
        window.hidesOnDeactivate = false // Don't auto-hide when app is inactive
        window.level = .floating // Keep above most windows
        
        super.init(window: window)
        
        // Set delegate to handle window closing after super.init
        window.delegate = self
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Add a container view for better layout
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Title header
        let titleLabel = NSTextField(labelWithString: "Break Time Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Description
        let descriptionLabel = NSTextField(labelWithString: "Configure your work and break intervals")
        descriptionLabel.font = NSFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // Work duration label
        let workLabel = NSTextField(labelWithString: "Work Duration (minutes):")
        workLabel.font = NSFont.systemFont(ofSize: 14)
        workLabel.textColor = NSColor.labelColor
        workLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(workLabel)
        
        // Work duration field with number-only formatter
        workDurationField = NSTextField()
        workDurationField.font = NSFont.systemFont(ofSize: 14)
        workDurationField.alignment = .center
        workDurationField.translatesAutoresizingMaskIntoConstraints = false
        workDurationField.stringValue = "\(settings.workDurationMinutes)"
        workDurationField.wantsLayer = true
        workDurationField.layer?.cornerRadius = 4.0
        workDurationField.layer?.borderWidth = 1.0
        workDurationField.layer?.borderColor = NSColor.separatorColor.cgColor
        
        // Apply the number-only formatter
        let formatter = NumberOnlyFormatter()
        workDurationField.formatter = formatter
        
        containerView.addSubview(workDurationField)
        
        // Break duration label
        let breakLabel = NSTextField(labelWithString: "Break Duration (minutes):")
        breakLabel.font = NSFont.systemFont(ofSize: 14)
        breakLabel.textColor = NSColor.labelColor
        breakLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(breakLabel)
        
        // Break duration field with number-only formatter
        breakDurationField = NSTextField()
        breakDurationField.font = NSFont.systemFont(ofSize: 14)
        breakDurationField.alignment = .center
        breakDurationField.translatesAutoresizingMaskIntoConstraints = false
        breakDurationField.stringValue = "\(settings.breakDurationMinutes)"
        breakDurationField.wantsLayer = true
        breakDurationField.layer?.cornerRadius = 4.0
        breakDurationField.layer?.borderWidth = 1.0
        breakDurationField.layer?.borderColor = NSColor.separatorColor.cgColor
        
        // Apply the number-only formatter to break duration field
        breakDurationField.formatter = NumberOnlyFormatter()
        
        containerView.addSubview(breakDurationField)
        
        // Start at login checkbox
        startAtLoginCheckbox = NSButton(checkboxWithTitle: "Start at login", target: nil, action: nil)
        
        // Check the actual login item status
        let isLoginEnabled: Bool
        if #available(macOS 13.0, *) {
            isLoginEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isLoginEnabled = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
        
        // Set checkbox state based on the actual status, not just the saved setting
        startAtLoginCheckbox.state = isLoginEnabled ? .on : .off
        startAtLoginCheckbox.font = NSFont.systemFont(ofSize: 14)
        startAtLoginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(startAtLoginCheckbox)
        
        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separator)
        
        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSettings))
        cancelButton.bezelStyle = .rounded
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        containerView.addSubview(cancelButton)
        
        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.keyEquivalent = "\r" // Return key
        containerView.addSubview(saveButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container takes full size
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Title at the top
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Description under the title
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Work duration controls
            workLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 25),
            workLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            workLabel.widthAnchor.constraint(equalToConstant: 180),
            
            workDurationField.centerYAnchor.constraint(equalTo: workLabel.centerYAnchor),
            workDurationField.leadingAnchor.constraint(equalTo: workLabel.trailingAnchor, constant: 10),
            workDurationField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            workDurationField.widthAnchor.constraint(equalToConstant: 80),
            workDurationField.heightAnchor.constraint(equalToConstant: 24),
            
            // Break duration controls
            breakLabel.topAnchor.constraint(equalTo: workLabel.bottomAnchor, constant: 20),
            breakLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            breakLabel.widthAnchor.constraint(equalToConstant: 180),
            
            breakDurationField.centerYAnchor.constraint(equalTo: breakLabel.centerYAnchor),
            breakDurationField.leadingAnchor.constraint(equalTo: breakLabel.trailingAnchor, constant: 10),
            breakDurationField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            breakDurationField.widthAnchor.constraint(equalToConstant: 80),
            breakDurationField.heightAnchor.constraint(equalToConstant: 24),
            
            // Start at login checkbox
            startAtLoginCheckbox.topAnchor.constraint(equalTo: breakDurationField.bottomAnchor, constant: 24),
            startAtLoginCheckbox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Separator before buttons
            separator.topAnchor.constraint(equalTo: startAtLoginCheckbox.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Buttons at the bottom
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -10),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 30),
            
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func saveSettings() {
        // Get string values and convert to integers
        let workString = workDurationField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let breakString = breakDurationField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate that the strings contain only numbers
        guard workString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil,
              breakString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil,
              !workString.isEmpty,
              !breakString.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Invalid Input"
            alert.informativeText = "Please enter only numbers for durations."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Convert to integers
        guard let workMinutes = Int(workString),
              let breakMinutes = Int(breakString) else {
            let alert = NSAlert()
            alert.messageText = "Invalid Input"
            alert.informativeText = "Please enter valid numbers for durations."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Final validation check
        guard workMinutes >= 1, workMinutes <= 120,
              breakMinutes >= 1, breakMinutes <= 60 else {
            let alert = NSAlert()
            alert.messageText = "Invalid Values"
            alert.informativeText = "Work duration must be between 1-120 minutes. Break duration must be between 1-60 minutes."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        // Get the login checkbox state
        let startAtLogin = startAtLoginCheckbox.state == .on
        
        let newSettings = TimerSettings(
            workDurationMinutes: workMinutes,
            breakDurationMinutes: breakMinutes,
            startAtLogin: startAtLogin
        )
        
        // Update login item status
        if #available(macOS 13.0, *) {
            do {
                if startAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error setting login item: \(error)")
            }
        } else {
            // For older versions, set UserDefaults key that App Delegate will check
            UserDefaults.standard.set(startAtLogin, forKey: "LaunchAtLogin")
            
            // Try to set the login item if the bundle identifier is available
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                do {
                    try SMLoginItemSetEnabled(bundleIdentifier as CFString, startAtLogin)
                } catch {
                    print("Error setting login item: \(error)")
                }
            }
        }
        
        // Call the save callback
        onSave?(newSettings)
        
        // Close the window
        window?.close()
        
        // Bring the focus back to the menu bar
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Log to console for debugging
        print("Saving new settings: Work=\(workMinutes)min, Break=\(breakMinutes)min")
        print("Timer will start immediately with these new settings")
        
        // Call the save callback - this will also start the timer in AppController
        onSave?(newSettings)
        
        // Close the window
        window?.close()
        
        // Bring the focus back to the menu bar
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    @objc private func cancelSettings() {
        // Log cancel action
        print("Settings cancelled")
        
        // Close the window
        window?.close()
        
        // Bring the focus back to the menu bar
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - NSWindowDelegate
extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Ensure we always reset back to accessory mode (no dock icon)
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
