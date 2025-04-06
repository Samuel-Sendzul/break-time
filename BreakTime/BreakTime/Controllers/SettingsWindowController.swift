import Cocoa
import SwiftUI
import ServiceManagement
import Combine

// Observable object to track settings changes
class SettingsObservable: ObservableObject {
    @Published var settings = TimerSettings.defaultSettings
}

// Main SwiftUI view for settings
struct SettingsView: View {
    // Use ObservableObject to track settings
    @ObservedObject var settingsObservable: SettingsObservable
    @State var hasChanges = false
    private var onSave: (TimerSettings) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // Common work durations in minutes
    private let workDurationOptions = [1, 15, 20, 25, 30, 45, 50, 60, 90]
    
    // Common break durations in minutes
    private let breakDurationOptions = [5, 10, 15, 20, 30]
    
    init(settingsObservable: SettingsObservable, onSave: @escaping (TimerSettings) -> Void) {
        self.settingsObservable = settingsObservable
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Work duration picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Work Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $settingsObservable.settings.workDurationMinutes) {
                    ForEach(workDurationOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
                .frame(width: 180)
                .onChange(of: settingsObservable.settings.workDurationMinutes) { newValue in
                    print("Work duration changed to: \(newValue)")
                    hasChanges = true
                }
            }
            
            // Break duration picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Break Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $settingsObservable.settings.breakDurationMinutes) {
                    ForEach(breakDurationOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
                .frame(width: 180)
                .onChange(of: settingsObservable.settings.breakDurationMinutes) { newValue in
                    print("Break duration changed to: \(newValue)")
                    hasChanges = true
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Start at login
            Toggle("Start at login", isOn: $settingsObservable.settings.startAtLogin)
                .toggleStyle(.switch)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 280, height: 200)
        .onChange(of: settingsObservable.settings.startAtLogin) { newValue in 
            print("Start at login changed to: \(newValue)")
            hasChanges = true
            updateLoginItemStatus(newValue)
        }
        .onDisappear { 
            print("Settings view disappearing, hasChanges: \(hasChanges)")
            if hasChanges {
                saveSettings()
            }
        }
    }
    
    func saveSettings() {
        // Print debug info to verify settings values before saving
        print("View saveSettings called - Work: \(settingsObservable.settings.workDurationMinutes), Break: \(settingsObservable.settings.breakDurationMinutes)")
        updateLoginItemStatus(settingsObservable.settings.startAtLogin)
        // Save the settings from our observable
        onSave(settingsObservable.settings) 
    }
    
    // Helper function to update login item status
    private func updateLoginItemStatus(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error setting login item: \(error)")
            }
        } else {
            // For older versions
            UserDefaults.standard.set(enabled, forKey: "LaunchAtLogin")
            
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
            }
        }
    }
}

// Host controller to bridge between NSWindowController and SwiftUI
class SettingsWindowController: NSWindowController {
    // Using a regular property for settings
    private var settings: TimerSettings
    private var onSave: ((TimerSettings) -> Void)?
    // We'll use a StateObject to track changes
    private var settingsObservable = SettingsObservable()
    
    init(settings: TimerSettings, onSave: @escaping (TimerSettings) -> Void) {
        // Ensure we have valid defaults
        var validSettings = settings
        if validSettings.workDurationMinutes <= 0 {
            validSettings.workDurationMinutes = TimerSettings.defaultSettings.workDurationMinutes
        }
        if validSettings.breakDurationMinutes <= 0 {
            validSettings.breakDurationMinutes = TimerSettings.defaultSettings.breakDurationMinutes
        }
        
        self.settings = validSettings
        self.onSave = onSave
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "BreakTime Settings"
        window.isReleasedWhenClosed = false
        window.center() // Center on current screen
        
        // Position window in the center of the main screen
        if let screenFrame = NSScreen.main?.visibleFrame {
            let x = screenFrame.midX - (window.frame.width / 2)
            let y = screenFrame.midY - (window.frame.height / 2)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Critical settings to prevent window from disappearing
        window.hidesOnDeactivate = false
        window.level = .floating
        
        super.init(window: window)
        
        // Set delegate to handle window closing
        window.delegate = self
        
        // Initialize the observable with current settings
        settingsObservable.settings = settings
        
        // Create the SwiftUI view with our observable
        let settingsView = SettingsView(settingsObservable: settingsObservable) { [weak self] newSettings in
            print("SettingsWindowController received settings: Work: \(newSettings.workDurationMinutes), Break: \(newSettings.breakDurationMinutes)")
            // Update our local copy as well
            self?.settings = newSettings
            self?.onSave?(newSettings)
        }
        
        // Create the hosting controller
        let hostingController = NSHostingController(rootView: settingsView)
        
        // Set the window's content view controller
        window.contentViewController = hostingController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        if let window = window {
            // Force window to update immediately
            window.display()
        }
    }
}

// MARK: - NSWindowDelegate
extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Always save settings when window closes
        print("Window closing with settings - Work: \(settingsObservable.settings.workDurationMinutes), Break: \(settingsObservable.settings.breakDurationMinutes)")
        
        // Update our local copy with the latest values
        settings = settingsObservable.settings
        
        // Save settings from the observable
        onSave?(settingsObservable.settings)
        
        // If the timer service is running, stop it
        NotificationCenter.default.post(name: NSNotification.Name("StopTimerOnSettingsClosed"), object: nil)
        
        // Ensure we always reset back to accessory mode (no dock icon)
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
