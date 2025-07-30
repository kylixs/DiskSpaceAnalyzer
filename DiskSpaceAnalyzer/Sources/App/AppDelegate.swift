import Cocoa

/// Application delegate responsible for managing the application lifecycle
/// and coordinating with the SessionManager for overall application state
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// The main session manager that coordinates all application modules
    private var sessionManager: AnyObject? // 暂时使用AnyObject，后续实现SessionManager时会替换
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the session manager and core application components
        // This will be implemented as part of the SessionManager module
        print("DiskSpaceAnalyzer application launched successfully")
        
        // TODO: Initialize SessionManager
        // sessionManager = SessionManager()
        // sessionManager?.initializeApplication()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Perform cleanup and save application state
        // sessionManager?.prepareForTermination()
        print("DiskSpaceAnalyzer application terminating")
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Handle application becoming active
        // sessionManager?.handleApplicationDidBecomeActive()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        // Handle application becoming inactive
        // sessionManager?.handleApplicationWillResignActive()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Allow application to terminate when last window is closed
        return true
    }
}
