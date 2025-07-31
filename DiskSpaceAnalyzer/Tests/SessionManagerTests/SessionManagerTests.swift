import XCTest
import AppKit
@testable import SessionManager
@testable import Common
@testable import DataModel
@testable import PerformanceOptimizer
@testable import ScanEngine

final class SessionManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var sessionManager: SessionManager!
    var sessionController: SessionController!
    var errorHandler: ErrorHandler!
    var preferencesManager: PreferencesManager!
    var recentPathsManager: RecentPathsManager!
    
    var testPath: String!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        sessionManager = SessionManager.shared
        sessionController = SessionController.shared
        errorHandler = ErrorHandler.shared
        preferencesManager = PreferencesManager.shared
        recentPathsManager = RecentPathsManager.shared
        
        // 创建测试路径
        testPath = NSTemporaryDirectory()
    }
    
    override func tearDownWithError() throws {
        // 清理测试数据
        recentPathsManager.clearRecentPaths()
        errorHandler.clearErrorHistory()
        
        sessionManager = nil
        sessionController = nil
        errorHandler = nil
        preferencesManager = nil
        recentPathsManager = nil
        testPath = nil
    }
    
    // MARK: - SessionManager Tests
    
    func testSessionManagerInitialization() throws {
        XCTAssertNotNil(sessionManager, "SessionManager应该能够正确初始化")
        XCTAssertNotNil(SessionManager.shared, "SessionManager.shared应该存在")
        XCTAssertTrue(SessionManager.shared === sessionManager, "应该是单例模式")
    }
    
    func testGetAllSessions() throws {
        let sessions = sessionManager.getAllSessions()
        XCTAssertNotNil(sessions, "应该能获取所有会话")
        XCTAssertTrue(sessions.isEmpty, "初始状态应该没有会话")
    }
    
    func testGetActiveSessions() throws {
        let activeSessions = sessionManager.getActiveSessions()
        XCTAssertNotNil(activeSessions, "应该能获取活跃会话")
        XCTAssertTrue(activeSessions.isEmpty, "初始状态应该没有活跃会话")
    }
    
    func testGetRecentPaths() throws {
        let recentPaths = sessionManager.getRecentPaths()
        XCTAssertNotNil(recentPaths, "应该能获取最近路径")
        XCTAssertTrue(recentPaths.isEmpty, "初始状态应该没有最近路径")
    }
    
    func testClearRecentPaths() throws {
        // 先添加一个路径
        recentPathsManager.addRecentPath(testPath)
        XCTAssertFalse(sessionManager.getRecentPaths().isEmpty, "应该有最近路径")
        
        // 清除路径
        sessionManager.clearRecentPaths()
        XCTAssertTrue(sessionManager.getRecentPaths().isEmpty, "最近路径应该被清除")
    }
    
    func testGetPreferences() throws {
        let preferences = sessionManager.getPreferences()
        XCTAssertNotNil(preferences, "应该能获取偏好设置")
        XCTAssertTrue(preferences === preferencesManager, "应该是同一个实例")
    }
    
    func testGetErrorHistory() throws {
        let errorHistory = sessionManager.getErrorHistory()
        XCTAssertNotNil(errorHistory, "应该能获取错误历史")
        XCTAssertTrue(errorHistory.isEmpty, "初始状态应该没有错误历史")
    }
    
    func testClearErrorHistory() throws {
        // 先添加一个错误
        let error = AppError.scanError("测试错误")
        errorHandler.handleError(error)
        XCTAssertFalse(sessionManager.getErrorHistory().isEmpty, "应该有错误历史")
        
        // 清除错误历史
        sessionManager.clearErrorHistory()
        XCTAssertTrue(sessionManager.getErrorHistory().isEmpty, "错误历史应该被清除")
    }
    
    // MARK: - SessionState Tests
    
    func testSessionStateEnum() throws {
        let states: [SessionState] = [.created, .scanning, .completed, .paused, .cancelled, .error]
        XCTAssertEqual(states.count, 6, "应该有6种会话状态")
    }
    
    // MARK: - SessionType Tests
    
    func testSessionTypeEnum() throws {
        let types: [SessionType] = [.fullScan, .quickScan, .incrementalScan]
        XCTAssertEqual(types.count, 3, "应该有3种会话类型")
    }
    
    // MARK: - ScanSession Tests
    
    func testScanSessionInitialization() throws {
        let session = ScanSession(type: .fullScan, rootPath: testPath)
        
        XCTAssertNotNil(session.id, "会话ID不应该为nil")
        XCTAssertEqual(session.type, .fullScan, "会话类型应该匹配")
        XCTAssertEqual(session.rootPath, testPath, "根路径应该匹配")
        XCTAssertEqual(session.state, .created, "初始状态应该是created")
        XCTAssertEqual(session.progress, 0.0, "初始进度应该是0")
        XCTAssertNil(session.rootNode, "初始根节点应该为nil")
        XCTAssertNil(session.error, "初始错误应该为nil")
        XCTAssertNil(session.completedAt, "初始完成时间应该为nil")
    }
    
    func testScanSessionGetSummary() throws {
        let session = ScanSession(type: .fullScan, rootPath: testPath)
        let summary = session.getSummary()
        
        XCTAssertTrue(summary.contains(testPath), "摘要应该包含路径")
        XCTAssertTrue(summary.contains("已创建"), "摘要应该包含状态")
        XCTAssertTrue(summary.contains("0.0%"), "摘要应该包含进度")
    }
    
    // MARK: - SessionController Tests
    
    func testSessionControllerInitialization() throws {
        XCTAssertNotNil(sessionController, "SessionController应该能够正确初始化")
        XCTAssertNotNil(SessionController.shared, "SessionController.shared应该存在")
        XCTAssertTrue(SessionController.shared === sessionController, "应该是单例模式")
    }
    
    func testCreateSession() throws {
        let session = sessionController.createSession(type: .fullScan, rootPath: testPath)
        
        XCTAssertNotNil(session, "应该能创建会话")
        XCTAssertEqual(session.type, .fullScan, "会话类型应该匹配")
        XCTAssertEqual(session.rootPath, testPath, "根路径应该匹配")
        XCTAssertEqual(session.state, .created, "初始状态应该是created")
    }
    
    func testGetSession() throws {
        let session = sessionController.createSession(type: .quickScan, rootPath: testPath)
        let retrievedSession = sessionController.getSession(id: session.id)
        
        XCTAssertNotNil(retrievedSession, "应该能获取会话")
        XCTAssertEqual(retrievedSession?.id, session.id, "会话ID应该匹配")
    }
    
    func testDeleteSession() throws {
        let session = sessionController.createSession(type: .incrementalScan, rootPath: testPath)
        
        // 验证会话存在
        XCTAssertNotNil(sessionController.getSession(id: session.id), "会话应该存在")
        
        // 删除会话
        sessionController.deleteSession(session)
        
        // 验证会话已删除
        XCTAssertNil(sessionController.getSession(id: session.id), "会话应该被删除")
    }
    
    func testSessionCallbacks() throws {
        var sessionCreated: ScanSession?
        var stateChanged = false
        var progressUpdated = false
        var sessionCompleted: ScanSession?
        var sessionError: ScanSession?
        
        sessionController.onSessionCreated = { session in
            sessionCreated = session
        }
        
        sessionController.onSessionStateChanged = { _, _, _ in
            stateChanged = true
        }
        
        sessionController.onSessionProgressUpdated = { _, _ in
            progressUpdated = true
        }
        
        sessionController.onSessionCompleted = { session in
            sessionCompleted = session
        }
        
        sessionController.onSessionError = { session, _ in
            sessionError = session
        }
        
        // 创建会话
        let session = sessionController.createSession(type: .fullScan, rootPath: testPath)
        
        XCTAssertNotNil(sessionCreated, "应该触发会话创建回调")
        XCTAssertEqual(sessionCreated?.id, session.id, "回调会话应该匹配")
        
        // 验证回调设置
        XCTAssertNotNil(sessionController.onSessionCreated, "会话创建回调应该被设置")
        XCTAssertNotNil(sessionController.onSessionStateChanged, "状态变化回调应该被设置")
        XCTAssertNotNil(sessionController.onSessionProgressUpdated, "进度更新回调应该被设置")
        XCTAssertNotNil(sessionController.onSessionCompleted, "会话完成回调应该被设置")
        XCTAssertNotNil(sessionController.onSessionError, "会话错误回调应该被设置")
    }
    
    // MARK: - AppError Tests
    
    func testAppErrorTypes() throws {
        let errors: [AppError] = [
            .scanError("扫描错误"),
            .fileSystemError("文件系统错误"),
            .permissionDenied("/test/path"),
            .diskSpaceInsufficient,
            .networkError("网络错误"),
            .dataCorruption("数据损坏"),
            .unknownError("未知错误")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "错误描述不应该为nil")
            XCTAssertNotNil(error.recoverySuggestion, "恢复建议不应该为nil")
        }
    }
    
    func testAppErrorDescriptions() throws {
        let scanError = AppError.scanError("测试扫描错误")
        XCTAssertTrue(scanError.errorDescription?.contains("扫描错误") == true, "应该包含扫描错误描述")
        
        let permissionError = AppError.permissionDenied("/test/path")
        XCTAssertTrue(permissionError.errorDescription?.contains("权限不足") == true, "应该包含权限错误描述")
        
        let diskError = AppError.diskSpaceInsufficient
        XCTAssertTrue(diskError.errorDescription?.contains("磁盘空间不足") == true, "应该包含磁盘空间错误描述")
    }
    
    // MARK: - ErrorHandler Tests
    
    func testErrorHandlerInitialization() throws {
        XCTAssertNotNil(errorHandler, "ErrorHandler应该能够正确初始化")
        XCTAssertNotNil(ErrorHandler.shared, "ErrorHandler.shared应该存在")
        XCTAssertTrue(ErrorHandler.shared === errorHandler, "应该是单例模式")
    }
    
    func testHandleError() throws {
        let error = AppError.scanError("测试错误")
        
        var errorOccurred: AppError?
        errorHandler.onErrorOccurred = { appError in
            errorOccurred = appError
        }
        
        errorHandler.handleError(error)
        
        XCTAssertNotNil(errorOccurred, "应该触发错误回调")
        XCTAssertEqual(errorOccurred?.localizedDescription, error.localizedDescription, "错误描述应该匹配")
        
        let errorHistory = errorHandler.getErrorHistory()
        XCTAssertEqual(errorHistory.count, 1, "错误历史应该有一条记录")
        XCTAssertEqual(errorHistory.first?.error.localizedDescription, error.localizedDescription, "错误记录应该匹配")
    }
    
    func testErrorStatistics() throws {
        let error1 = AppError.scanError("错误1")
        let error2 = AppError.scanError("错误2")
        let error3 = AppError.permissionDenied("/test")
        
        errorHandler.handleError(error1)
        errorHandler.handleError(error2)
        errorHandler.handleError(error3)
        
        let statistics = errorHandler.getErrorStatistics()
        XCTAssertGreaterThan(statistics.count, 0, "应该有错误统计")
    }
    
    func testClearErrorHistory() throws {
        let error = AppError.unknownError("测试错误")
        errorHandler.handleError(error)
        
        XCTAssertFalse(errorHandler.getErrorHistory().isEmpty, "应该有错误历史")
        
        errorHandler.clearErrorHistory()
        
        XCTAssertTrue(errorHandler.getErrorHistory().isEmpty, "错误历史应该被清除")
        XCTAssertTrue(errorHandler.getErrorStatistics().isEmpty, "错误统计应该被清除")
    }
    
    // MARK: - PreferencesManager Tests
    
    func testPreferencesManagerInitialization() throws {
        XCTAssertNotNil(preferencesManager, "PreferencesManager应该能够正确初始化")
        XCTAssertNotNil(PreferencesManager.shared, "PreferencesManager.shared应该存在")
        XCTAssertTrue(PreferencesManager.shared === preferencesManager, "应该是单例模式")
    }
    
    func testScanPreferences() throws {
        // 测试默认值
        XCTAssertFalse(preferencesManager.scanIncludeHiddenFiles, "默认不包含隐藏文件")
        XCTAssertFalse(preferencesManager.scanFollowSymlinks, "默认不跟随符号链接")
        XCTAssertEqual(preferencesManager.scanMaxDepth, 0, "默认无深度限制")
        
        // 测试设置值
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.scanFollowSymlinks = true
        preferencesManager.scanMaxDepth = 10
        
        XCTAssertTrue(preferencesManager.scanIncludeHiddenFiles, "应该包含隐藏文件")
        XCTAssertTrue(preferencesManager.scanFollowSymlinks, "应该跟随符号链接")
        XCTAssertEqual(preferencesManager.scanMaxDepth, 10, "最大深度应该是10")
    }
    
    func testUIPreferences() throws {
        // 测试默认值
        XCTAssertTrue(preferencesManager.uiShowFileExtensions, "默认显示文件扩展名")
        XCTAssertEqual(preferencesManager.uiColorScheme, "auto", "默认自动颜色方案")
        XCTAssertTrue(preferencesManager.uiTreeMapAnimation, "默认启用TreeMap动画")
        
        // 测试设置值
        preferencesManager.uiShowFileExtensions = false
        preferencesManager.uiColorScheme = "dark"
        preferencesManager.uiTreeMapAnimation = false
        
        XCTAssertFalse(preferencesManager.uiShowFileExtensions, "不应该显示文件扩展名")
        XCTAssertEqual(preferencesManager.uiColorScheme, "dark", "颜色方案应该是dark")
        XCTAssertFalse(preferencesManager.uiTreeMapAnimation, "不应该启用TreeMap动画")
    }
    
    func testPerformancePreferences() throws {
        // 测试默认值
        XCTAssertEqual(preferencesManager.performanceMaxConcurrentScans, 3, "默认最大并发扫描数是3")
        XCTAssertEqual(preferencesManager.performanceCacheSize, 100, "默认缓存大小是100")
        
        // 测试设置值
        preferencesManager.performanceMaxConcurrentScans = 5
        preferencesManager.performanceCacheSize = 200
        
        XCTAssertEqual(preferencesManager.performanceMaxConcurrentScans, 5, "最大并发扫描数应该是5")
        XCTAssertEqual(preferencesManager.performanceCacheSize, 200, "缓存大小应该是200")
    }
    
    func testWindowStatePreferences() throws {
        // 测试默认值
        XCTAssertNil(preferencesManager.windowFrame, "默认窗口框架应该为nil")
        XCTAssertNil(preferencesManager.windowSplitterPosition, "默认分割器位置应该为nil")
        
        // 测试设置值
        let testFrame = NSRect(x: 100, y: 100, width: 800, height: 600)
        preferencesManager.windowFrame = testFrame
        preferencesManager.windowSplitterPosition = 0.3
        
        XCTAssertEqual(preferencesManager.windowFrame, testFrame, "窗口框架应该匹配")
        XCTAssertEqual(preferencesManager.windowSplitterPosition, 0.3, "分割器位置应该是0.3")
    }
    
    func testResetToDefaults() throws {
        // 设置一些非默认值
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.uiColorScheme = "dark"
        preferencesManager.performanceMaxConcurrentScans = 10
        
        // 重置到默认值
        preferencesManager.resetToDefaults()
        
        // 验证默认值
        XCTAssertFalse(preferencesManager.scanIncludeHiddenFiles, "应该重置为默认值")
        XCTAssertEqual(preferencesManager.uiColorScheme, "auto", "应该重置为默认值")
        XCTAssertEqual(preferencesManager.performanceMaxConcurrentScans, 3, "应该重置为默认值")
    }
    
    func testExportImportSettings() throws {
        // 设置一些值
        preferencesManager.scanIncludeHiddenFiles = true
        preferencesManager.uiColorScheme = "dark"
        preferencesManager.performanceMaxConcurrentScans = 5
        
        // 导出设置
        let exportedSettings = preferencesManager.exportSettings()
        
        XCTAssertEqual(exportedSettings["scanIncludeHiddenFiles"] as? Bool, true, "导出的设置应该匹配")
        XCTAssertEqual(exportedSettings["uiColorScheme"] as? String, "dark", "导出的设置应该匹配")
        XCTAssertEqual(exportedSettings["performanceMaxConcurrentScans"] as? Int, 5, "导出的设置应该匹配")
        
        // 重置设置
        preferencesManager.resetToDefaults()
        
        // 导入设置
        preferencesManager.importSettings(exportedSettings)
        
        // 验证导入的设置
        XCTAssertTrue(preferencesManager.scanIncludeHiddenFiles, "导入的设置应该生效")
        XCTAssertEqual(preferencesManager.uiColorScheme, "dark", "导入的设置应该生效")
        XCTAssertEqual(preferencesManager.performanceMaxConcurrentScans, 5, "导入的设置应该生效")
    }
    
    // MARK: - RecentPathsManager Tests
    
    func testRecentPathsManagerInitialization() throws {
        XCTAssertNotNil(recentPathsManager, "RecentPathsManager应该能够正确初始化")
        XCTAssertNotNil(RecentPathsManager.shared, "RecentPathsManager.shared应该存在")
        XCTAssertTrue(RecentPathsManager.shared === recentPathsManager, "应该是单例模式")
    }
    
    func testAddRecentPath() throws {
        let path1 = "/test/path1"
        let path2 = "/test/path2"
        
        recentPathsManager.addRecentPath(path1)
        recentPathsManager.addRecentPath(path2)
        
        let recentPaths = recentPathsManager.getRecentPaths()
        
        XCTAssertEqual(recentPaths.count, 2, "应该有2个最近路径")
        XCTAssertEqual(recentPaths.first, path2, "最新的路径应该在最前面")
        XCTAssertEqual(recentPaths.last, path1, "较早的路径应该在后面")
    }
    
    func testAddDuplicateRecentPath() throws {
        let path = "/test/duplicate"
        
        recentPathsManager.addRecentPath(path)
        recentPathsManager.addRecentPath(path)
        
        let recentPaths = recentPathsManager.getRecentPaths()
        
        XCTAssertEqual(recentPaths.count, 1, "重复路径应该只保留一个")
        XCTAssertEqual(recentPaths.first, path, "路径应该匹配")
    }
    
    func testRemoveRecentPath() throws {
        let path1 = "/test/path1"
        let path2 = "/test/path2"
        
        recentPathsManager.addRecentPath(path1)
        recentPathsManager.addRecentPath(path2)
        
        XCTAssertEqual(recentPathsManager.getRecentPaths().count, 2, "应该有2个路径")
        
        recentPathsManager.removeRecentPath(path1)
        
        let recentPaths = recentPathsManager.getRecentPaths()
        XCTAssertEqual(recentPaths.count, 1, "应该剩余1个路径")
        XCTAssertEqual(recentPaths.first, path2, "剩余的路径应该是path2")
    }
    
    func testClearRecentPaths() throws {
        recentPathsManager.addRecentPath("/test/path1")
        recentPathsManager.addRecentPath("/test/path2")
        
        XCTAssertFalse(recentPathsManager.getRecentPaths().isEmpty, "应该有最近路径")
        
        recentPathsManager.clearRecentPaths()
        
        XCTAssertTrue(recentPathsManager.getRecentPaths().isEmpty, "最近路径应该被清除")
    }
    
    func testValidateRecentPaths() throws {
        // 添加一个存在的路径和一个不存在的路径
        let existingPath = NSTemporaryDirectory()
        let nonExistingPath = "/non/existing/path"
        
        recentPathsManager.addRecentPath(existingPath)
        recentPathsManager.addRecentPath(nonExistingPath)
        
        XCTAssertEqual(recentPathsManager.getRecentPaths().count, 2, "应该有2个路径")
        
        // 验证路径
        recentPathsManager.validateRecentPaths()
        
        let validPaths = recentPathsManager.getRecentPaths()
        XCTAssertEqual(validPaths.count, 1, "应该只剩1个有效路径")
        XCTAssertEqual(validPaths.first, existingPath, "剩余的应该是存在的路径")
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() throws {
        // 创建会话
        let session = sessionManager.startNewScan(path: testPath, type: .quickScan)
        
        XCTAssertNotNil(session, "应该能创建会话")
        XCTAssertEqual(session.rootPath, testPath, "路径应该匹配")
        XCTAssertEqual(session.type, .quickScan, "类型应该匹配")
        
        // 验证最近路径被添加
        let recentPaths = sessionManager.getRecentPaths()
        XCTAssertTrue(recentPaths.contains(testPath), "最近路径应该包含测试路径")
        
        // 验证会话在列表中
        let allSessions = sessionManager.getAllSessions()
        XCTAssertTrue(allSessions.contains { $0.id == session.id }, "会话应该在列表中")
    }
    
    // MARK: - Performance Tests
    
    func testSessionCreationPerformance() throws {
        measure {
            for i in 0..<100 {
                let session = sessionController.createSession(type: .fullScan, rootPath: "/test/path\(i)")
                sessionController.deleteSession(session)
            }
        }
    }
    
    func testRecentPathsPerformance() throws {
        measure {
            for i in 0..<100 {
                recentPathsManager.addRecentPath("/test/path\(i)")
            }
            recentPathsManager.clearRecentPaths()
        }
    }
    
    func testErrorHandlingPerformance() throws {
        measure {
            for i in 0..<100 {
                let error = AppError.scanError("错误\(i)")
                errorHandler.handleError(error)
            }
            errorHandler.clearErrorHistory()
        }
    }
}
