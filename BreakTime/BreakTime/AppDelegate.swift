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
        if #available(macOS 13.0, *) {
            // Modern API is handled by LoginItemService directly
            return
        }
        
        // For older macOS versions, use SMLoginItemSetEnabled
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let shouldLaunchAtLogin = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
            
            do {
                try SMLoginItemSetEnabled(bundleIdentifier as CFString, shouldLaunchAtLogin)
            } catch {
                print("Error setting login item: \(error)")
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