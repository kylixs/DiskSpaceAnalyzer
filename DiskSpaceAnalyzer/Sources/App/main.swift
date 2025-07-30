import Cocoa

// MARK: - Application Entry Point

// Create the application instance
let app = NSApplication.shared

// Set the application delegate
let delegate = AppDelegate()
app.delegate = delegate

// Configure application properties
app.setActivationPolicy(.regular)

// Start the application run loop
app.run()
