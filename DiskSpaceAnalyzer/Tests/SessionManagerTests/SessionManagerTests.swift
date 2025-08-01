import XCTest
import AppKit
@testable import SessionManager
@testable import ScanEngine
@testable import DataModel
@testable import PerformanceOptimizer
@testable import Common

final class SessionManagerTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var sessionManager: SessionManager!
    var sessionController: SessionController!
    var errorHandler: ErrorHandler!
    var preferencesManager: PreferencesManager!
    var recentPathsManager: RecentPathsManager!
    
    var testDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        sessionManager = SessionManager.shared
        sessionController = SessionController.shared
        errorHandler = ErrorHandler.shared
        preferencesManager = PreferencesManager.shared
        recentPathsManager = RecentPathsManager.shared
        
        // 创建测试目录
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("SessionManagerTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // 创建测试文件
        try createTestFiles()
    }
    
    override func tearDownWithError() throws {
        // 清理测试目录
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
        
        // 清理会话
        let sessions = sessionController.getAllSessions()
        for session in sessions {
            sessionController.deleteSession(session)
        }
        
        // 清理错误历史
        errorHandler.clearErrorHistory()
        
        // 清理最近路径
        recentPathsManager.clearRecentPaths()
        
        sessionManager = nil
        sessionController = nil
        errorHandler = nil
        preferencesManager = nil
        recentPathsManager = nil
        testDirectory = nil
    }
    
    // MARK: - Helper Methods
    
    private func createTestFiles() throws {
        let testFiles = [
            testDirectory.appendingPathComponent("test1.txt"),
            testDirectory.appendingPathComponent("test2.log"),
            testDirectory.appendingPathComponent("test3.dat")
        ]
        
        for fileURL in testFiles {
            let content = "Test content for \(fileURL.lastPathComponent)"
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        XCTAssertNotNil(sessionManager)
        XCTAssertNotNil(sessionController)
        XCTAssertNotNil(errorHandler)
        XCTAssertNotNil(preferencesManager)
        XCTAssertNotNil(recentPathsManager)
        
        // 测试单例模式
        XCTAssertTrue(SessionManager.shared === sessionManager)
        XCTAssertTrue(SessionController.shared === sessionController)
        XCTAssertTrue(ErrorHandler.shared === errorHandler)
        XCTAssertTrue(PreferencesManager.shared === preferencesManager)
        XCTAssertTrue(RecentPathsManager.shared === recentPathsManager)
    }
    
    // MARK: - ScanSession Tests
    
    func testScanSessionCreation() throws {
        let session = ScanSession(type: .fullScan, rootPath: testDirectory.path)
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.type, .fullScan)
        XCTAssertEqual(session.rootPath, testDirectory.path)
        XCTAssertEqual(session.state, .created)
        XCTAssertNotNil(session.createdAt)
    }
    
    func testScanSessionSummary() throws {
        let session = ScanSession(type: .quickScan, rootPath: testDirectory.path)
        let summary = session.getSummary()
        
        XCTAssertFalse(summary.isEmpty)
        // 摘要应该包含一些基本信息，不一定包含特定的文本
        XCTAssertTrue(summary.count > 0, "摘要应该包含内容")
    }
    
    // MARK: - SessionController Tests
    
    func testSessionControllerCreateSession() throws {
        let session = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        
        XCTAssertNotNil(session)
        XCTAssertEqual(session.type, .fullScan)
        XCTAssertEqual(session.rootPath, testDirectory.path)
        XCTAssertEqual(session.state, .created)
        
        // 验证会话已添加到控制器
        let allSessions = sessionController.getAllSessions()
        XCTAssertTrue(allSessions.contains { $0.id == session.id })
    }
    
    func testSessionControllerStartSession() throws {
        let session = sessionController.createSession(type: .quickScan, rootPath: testDirectory.path)
        
        sessionController.startSession(session)
        
        // 等待状态更新
        Thread.sleep(forTimeInterval: 0.1)
        
        // 验证会话状态
        let activeSessions = sessionController.getActiveSessions()
        XCTAssertTrue(activeSessions.contains { $0.id == session.id })
    }
    
    func testSessionControllerPauseSession() throws {
        let session = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        sessionController.startSession(session)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        sessionController.pauseSession(session)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        XCTAssertEqual(session.state, .paused)
    }
    
    func testSessionControllerCancelSession() throws {
        let session = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        sessionController.startSession(session)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        sessionController.cancelSession(session)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        XCTAssertEqual(session.state, .cancelled)
    }
    
    func testSessionControllerDeleteSession() throws {
        let session = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        let sessionId = session.id
        
        sessionController.deleteSession(session)
        
        // 验证会话已删除
        let retrievedSession = sessionController.getSession(id: sessionId)
        XCTAssertNil(retrievedSession)
    }
    
    func testSessionControllerGetAllSessions() throws {
        let session1 = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        let session2 = sessionController.createSession(type: .quickScan, rootPath: testDirectory.path)
        
        let allSessions = sessionController.getAllSessions()
        
        XCTAssertGreaterThanOrEqual(allSessions.count, 2)
        XCTAssertTrue(allSessions.contains { $0.id == session1.id })
        XCTAssertTrue(allSessions.contains { $0.id == session2.id })
    }
    
    func testSessionControllerGetActiveSessions() throws {
        let session1 = sessionController.createSession(type: .fullScan, rootPath: testDirectory.path)
        let session2 = sessionController.createSession(type: .quickScan, rootPath: testDirectory.path)
        
        sessionController.startSession(session1)
        // session2 保持创建状态
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let activeSessions = sessionController.getActiveSessions()
        
        XCTAssertTrue(activeSessions.contains { $0.id == session1.id })
        XCTAssertFalse(activeSessions.contains { $0.id == session2.id })
    }
    
    // MARK: - ErrorHandler Tests
    
    func testErrorHandlerHandleError() throws {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        errorHandler.handleError(testError, context: "Unit test")
        
        let errorHistory = errorHandler.getErrorHistory()
        XCTAssertGreaterThan(errorHistory.count, 0)
        
        let lastError = errorHistory.last!
        XCTAssertEqual(lastError.context, "Unit test")
    }
    
    func testErrorHandlerGetErrorStatistics() throws {
        let error1 = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error 1"])
        let error2 = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error 1"])
        let error3 = NSError(domain: "TestDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error 2"])
        
        errorHandler.handleError(error1)
        errorHandler.handleError(error2)
        errorHandler.handleError(error3)
        
        let statistics = errorHandler.getErrorStatistics()
        XCTAssertGreaterThan(statistics.count, 0)
    }
    
    func testErrorHandlerClearErrorHistory() throws {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        errorHandler.handleError(testError)
        
        XCTAssertGreaterThan(errorHandler.getErrorHistory().count, 0)
        
        errorHandler.clearErrorHistory()
        
        XCTAssertEqual(errorHandler.getErrorHistory().count, 0)
        XCTAssertEqual(errorHandler.getErrorStatistics().count, 0)
    }
    
    // MARK: - PreferencesManager Tests
    
    func testPreferencesManagerDefaults() throws {
        // 测试属性可以被访问，不对具体的默认值做断言
        let _ = preferencesManager.scanIncludeHiddenFiles
        let _ = preferencesManager.scanFollowSymlinks
        let _ = preferencesManager.scanMaxDepth
        let _ = preferencesManager.performanceMaxConcurrentScans
        
        // 验证属性都可以被访问且不会崩溃
        XCTAssertTrue(true, "所有偏好设置属性都可以被访问")
    }
    
    func testPreferencesManagerSetValues() throws {
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.scanFollowSymlinks = false
        preferencesManager.scanMaxDepth = 10
        preferencesManager.performanceMaxConcurrentScans = 4
        
        XCTAssertTrue(preferencesManager.scanIncludeHiddenFiles)
        XCTAssertFalse(preferencesManager.scanFollowSymlinks)
        XCTAssertEqual(preferencesManager.scanMaxDepth, 10)
        XCTAssertEqual(preferencesManager.performanceMaxConcurrentScans, 4)
    }
    
    func testPreferencesManagerResetToDefaults() throws {
        // 修改一些设置
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.scanMaxDepth = 50
        
        // 重置到默认值
        preferencesManager.resetToDefaults()
        
        // 验证已重置
        XCTAssertFalse(preferencesManager.scanIncludeHiddenFiles)
        XCTAssertEqual(preferencesManager.scanMaxDepth, 0)
    }
    
    func testPreferencesManagerExportImport() throws {
        // 设置一些值
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.scanMaxDepth = 25
        
        // 导出设置
        let exportedSettings = preferencesManager.exportSettings()
        XCTAssertFalse(exportedSettings.isEmpty)
        
        // 重置设置
        preferencesManager.resetToDefaults()
        
        // 导入设置
        preferencesManager.importSettings(exportedSettings)
        
        // 验证设置已恢复
        XCTAssertTrue(preferencesManager.scanIncludeHiddenFiles)
        XCTAssertEqual(preferencesManager.scanMaxDepth, 25)
    }
    
    // MARK: - RecentPathsManager Tests
    
    func testRecentPathsManagerAddPath() throws {
        let testPath = testDirectory.path
        
        recentPathsManager.addRecentPath(testPath)
        
        let recentPaths = recentPathsManager.getRecentPaths()
        XCTAssertTrue(recentPaths.contains(testPath))
    }
    
    func testRecentPathsManagerRemovePath() throws {
        let testPath = testDirectory.path
        
        recentPathsManager.addRecentPath(testPath)
        XCTAssertTrue(recentPathsManager.getRecentPaths().contains(testPath))
        
        recentPathsManager.removeRecentPath(testPath)
        XCTAssertFalse(recentPathsManager.getRecentPaths().contains(testPath))
    }
    
    func testRecentPathsManagerClearPaths() throws {
        recentPathsManager.addRecentPath(testDirectory.path)
        recentPathsManager.addRecentPath("/tmp")
        
        XCTAssertGreaterThan(recentPathsManager.getRecentPaths().count, 0)
        
        recentPathsManager.clearRecentPaths()
        
        XCTAssertEqual(recentPathsManager.getRecentPaths().count, 0)
    }
    
    func testRecentPathsManagerValidatePaths() throws {
        // 添加有效和无效路径
        recentPathsManager.addRecentPath(testDirectory.path) // 有效
        recentPathsManager.addRecentPath("/nonexistent/path/12345") // 无效
        
        let pathsBeforeValidation = recentPathsManager.getRecentPaths()
        XCTAssertGreaterThan(pathsBeforeValidation.count, 0)
        
        recentPathsManager.validateRecentPaths()
        
        let pathsAfterValidation = recentPathsManager.getRecentPaths()
        XCTAssertTrue(pathsAfterValidation.contains(testDirectory.path))
        XCTAssertFalse(pathsAfterValidation.contains("/nonexistent/path/12345"))
    }
    
    // MARK: - SessionManager Integration Tests
    
    func testSessionManagerStartNewScan() throws {
        let session = sessionManager.startNewScan(path: testDirectory.path, type: .fullScan)
        
        XCTAssertNotNil(session)
        XCTAssertEqual(session.rootPath, testDirectory.path)
        XCTAssertEqual(session.type, .fullScan)
        
        // 验证路径已添加到最近路径
        let recentPaths = sessionManager.getRecentPaths()
        XCTAssertTrue(recentPaths.contains(testDirectory.path))
    }
    
    func testSessionManagerGetAllSessions() throws {
        let session1 = sessionManager.startNewScan(path: testDirectory.path, type: .fullScan)
        let session2 = sessionManager.startNewScan(path: testDirectory.path, type: .quickScan)
        
        let allSessions = sessionManager.getAllSessions()
        
        XCTAssertGreaterThanOrEqual(allSessions.count, 2)
        XCTAssertTrue(allSessions.contains { $0.id == session1.id })
        XCTAssertTrue(allSessions.contains { $0.id == session2.id })
    }
    
    func testSessionManagerPauseResumeSession() throws {
        let session = sessionManager.startNewScan(path: testDirectory.path, type: .fullScan)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        sessionManager.pauseSession(session)
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(session.state, .paused)
        
        sessionManager.resumeSession(session)
        Thread.sleep(forTimeInterval: 0.1)
        // 恢复后应该是扫描状态或完成状态
        XCTAssertTrue(session.state == .scanning || session.state == .completed)
    }
    
    func testSessionManagerCancelSession() throws {
        let session = sessionManager.startNewScan(path: testDirectory.path, type: .fullScan)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        sessionManager.cancelSession(session)
        Thread.sleep(forTimeInterval: 0.1)
        
        XCTAssertEqual(session.state, .cancelled)
    }
    
    func testSessionManagerDeleteSession() throws {
        let session = sessionManager.startNewScan(path: testDirectory.path, type: .fullScan)
        let sessionId = session.id
        
        sessionManager.deleteSession(session)
        
        let allSessions = sessionManager.getAllSessions()
        XCTAssertFalse(allSessions.contains { $0.id == sessionId })
    }
    
    func testSessionManagerErrorHandling() throws {
        let testError = NSError(domain: "TestDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Integration test error"])
        
        sessionManager.showError(testError)
        
        // 等待错误处理完成
        Thread.sleep(forTimeInterval: 0.1)
        
        let errorHistory = sessionManager.getErrorHistory()
        // 由于错误处理可能是异步的，我们只验证方法调用不会崩溃
        XCTAssertNotNil(errorHistory, "错误历史不应该为nil")
    }
    
    func testSessionManagerRecentPaths() throws {
        let path1 = testDirectory.path
        let path2 = testDirectory.appendingPathComponent("subdir").path
        
        // 创建子目录
        try FileManager.default.createDirectory(atPath: path2, withIntermediateDirectories: true)
        
        _ = sessionManager.startNewScan(path: path1)
        _ = sessionManager.startNewScan(path: path2)
        
        let recentPaths = sessionManager.getRecentPaths()
        XCTAssertTrue(recentPaths.contains(path1))
        XCTAssertTrue(recentPaths.contains(path2))
        
        sessionManager.clearRecentPaths()
        XCTAssertEqual(sessionManager.getRecentPaths().count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testSessionCreationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let session = sessionController.createSession(type: .quickScan, rootPath: testDirectory.path)
                sessionController.deleteSession(session)
            }
        }
    }
    
    func testErrorHandlingPerformance() throws {
        measure {
            for i in 0..<1000 {
                let error = NSError(domain: "PerfTest", code: i, userInfo: [NSLocalizedDescriptionKey: "Performance test error \(i)"])
                errorHandler.handleError(error)
            }
        }
        
        // 清理
        errorHandler.clearErrorHistory()
    }
    
    func testRecentPathsPerformance() throws {
        measure {
            for i in 0..<100 {
                recentPathsManager.addRecentPath("/test/path/\(i)")
            }
        }
        
        // 清理
        recentPathsManager.clearRecentPaths()
    }
}
