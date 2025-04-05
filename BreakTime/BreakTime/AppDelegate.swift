import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    // Use a strong reference so the controller doesn't get deallocated
    private var appController: AppController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set activation policy to accessory to make it a menu bar app without dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize the main controller which manages the app
        appController = AppController()
        
        // Register for reactivation notifications to ensure we stay as a menu bar app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reactivateAsAccessory),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Handle login item for older macOS versions
        setupLoginItemIfNeeded()
        
        // Print confirmation to the console so we know it's running
        print("BreakTime app is now running in the menu bar")
    }
    
    private func setupLoginItemIfNeeded() {
        // Get the user preference for auto-launch
        let shouldLaunchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        
        if #available(macOS 13.0, *) {
            // Modern API for macOS 13.0+
            let service = SMAppService.mainApp
            
            // First check current status to avoid unnecessary calls
            let status = service.status
            
            do {
                if shouldLaunchAtLogin && status != .enabled {
                    // Register only if not already enabled
                    print("Attempting to register app as login item")
                    
                    // This will prompt the user for permission
                    try service.register()
                    print("Successfully registered app as login item")
                } else if !shouldLaunchAtLogin && status == .enabled {
                    // Unregister only if currently enabled
                    try service.unregister()
                    print("Successfully unregistered app as login item")
                }
            } catch {
                print("Error setting login item: \(error)")
                
                // Show a dialog to the user that explains the error and provides guidance
                // on how to enable the login item manually from System Preferences
                let alert = NSAlert()
                alert.messageText = "Could not set login item automatically"
                alert.informativeText = "To start BreakTime at login, please add it manually in System Settings → General → Login Items."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        } else {
            // For older macOS versions, use SMLoginItemSetEnabled
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, shouldLaunchAtLogin)
                if !success {
                    print("Failed to set login item using legacy API")
                    
                    // Show guidance for older macOS versions
                    let alert = NSAlert()
                    alert.messageText = "Could not set login item automatically"
                    alert.informativeText = "To start BreakTime at login, please add it manually in System Preferences → Users & Groups → Login Items."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    @objc private func reactivateAsAccessory() {
        // Ensure we're always in accessory mode (no dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Perform any cleanup if needed
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
