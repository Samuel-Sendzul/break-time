import Cocoa

// Create the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Since we're a menu bar app, let's make sure we're not in the dock
app.setActivationPolicy(.accessory)

// Run the application
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)