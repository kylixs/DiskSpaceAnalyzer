import XCTest
@testable import Core

class SessionManagerTests: XCTestCase {
    
    func testSessionController() {
        let controller = SessionController.shared
        let stats = controller.getSessionStatistics()
        
        XCTAssertNotNil(stats["totalSessions"])
        XCTAssertNotNil(stats["activeSessions"])
    }
    
    func testErrorHandler() {
        let handler = ErrorHandler.shared
        let stats = handler.getErrorStatistics()
        
        XCTAssertNotNil(stats["totalErrors"])
        XCTAssertNotNil(stats["recentErrors"])
    }
    
    func testLogManager() {
        let manager = LogManager.shared
        manager.info("Test log message")
        
        let stats = manager.getLogStatistics()
        XCTAssertNotNil(stats["totalLogs"])
    }
    
    func testProgressDialogManager() {
        let manager = ProgressDialogManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testSessionManager() {
        let manager = SessionManager.shared
        let metrics = manager.getPerformanceMetrics()
        
        XCTAssertNotNil(metrics["sessionMetrics"])
        XCTAssertNotNil(metrics["errorMetrics"])
        XCTAssertNotNil(metrics["logMetrics"])
    }
    
    func testScanSession() {
        let session = ScanSession(rootPath: "/tmp", priority: .normal)
        
        XCTAssertEqual(session.rootPath, "/tmp")
        XCTAssertEqual(session.priority, .normal)
        XCTAssertEqual(session.state, .created)
    }
}
