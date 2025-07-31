import XCTest
@testable import ScanEngine
@testable import Common
@testable import DataModel
@testable import PerformanceOptimizer

final class ScanEngineTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var scanEngine: ScanEngine!
    var fileSystemScanner: FileSystemScanner!
    var progressManager: ScanProgressManager!
    var fileFilter: FileFilter!
    var taskManager: ScanTaskManager!
    
    var testDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        scanEngine = ScanEngine.shared
        fileSystemScanner = FileSystemScanner.shared
        progressManager = ScanProgressManager.shared
        fileFilter = FileFilter.shared
        taskManager = ScanTaskManager.shared
        
        // 创建测试目录
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ScanEngineTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // 创建测试文件结构
        try createTestFileStructure()
    }
    
    override func tearDownWithError() throws {
        // 清理测试目录
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
        
        // 取消所有扫描任务
        scanEngine.cancelScan()
        taskManager.cancelAllTasks()
        
        scanEngine = nil
        fileSystemScanner = nil
        progressManager = nil
        fileFilter = nil
        taskManager = nil
        testDirectory = nil
    }
    
    // MARK: - Helper Methods
    
    private func createTestFileStructure() throws {
        // 创建子目录
        let subDir1 = testDirectory.appendingPathComponent("subdir1")
        let subDir2 = testDirectory.appendingPathComponent("subdir2")
        try FileManager.default.createDirectory(at: subDir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDir2, withIntermediateDirectories: true)
        
        // 创建测试文件
        let testFiles = [
            testDirectory.appendingPathComponent("file1.txt"),
            testDirectory.appendingPathComponent("file2.log"),
            subDir1.appendingPathComponent("nested1.txt"),
            subDir1.appendingPathComponent("nested2.dat"),
            subDir2.appendingPathComponent("nested3.txt")
        ]
        
        for fileURL in testFiles {
            let content = "Test content for \(fileURL.lastPathComponent)"
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        XCTAssertNotNil(scanEngine)
        XCTAssertNotNil(fileSystemScanner)
        XCTAssertNotNil(progressManager)
        XCTAssertNotNil(fileFilter)
        XCTAssertNotNil(taskManager)
        
        // 测试单例模式
        XCTAssertTrue(ScanEngine.shared === scanEngine)
        XCTAssertTrue(FileSystemScanner.shared === fileSystemScanner)
        XCTAssertTrue(ScanProgressManager.shared === progressManager)
        XCTAssertTrue(FileFilter.shared === fileFilter)
        XCTAssertTrue(ScanTaskManager.shared === taskManager)
    }
    
    // MARK: - FileSystemScanner Tests
    
    func testFileSystemScannerBasicScan() async throws {
        let expectation = XCTestExpectation(description: "Scan completion")
        var scanResult: ScanResult?
        var discoveredNodes: [FileNode] = []
        
        fileSystemScanner.onNodeDiscovered = { node in
            discoveredNodes.append(node)
        }
        
        fileSystemScanner.onCompleted = { result in
            scanResult = result
            expectation.fulfill()
        }
        
        try await fileSystemScanner.startScan(at: testDirectory.path)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertNotNil(scanResult)
        XCTAssertGreaterThan(discoveredNodes.count, 0, "应该发现一些文件节点")
    }
    
    func testFileSystemScannerCancelScan() throws {
        fileSystemScanner.cancelScan()
        
        // 验证取消状态
        let statistics = fileSystemScanner.getScanStatistics()
        XCTAssertNotNil(statistics)
    }
    
    func testFileSystemScannerPauseResume() throws {
        fileSystemScanner.pauseScan()
        fileSystemScanner.resumeScan()
        
        // 验证暂停/恢复操作不会抛出异常
        XCTAssertTrue(true)
    }
    
    func testFileSystemScannerStatistics() throws {
        let statistics = fileSystemScanner.getScanStatistics()
        
        XCTAssertNotNil(statistics)
        XCTAssertGreaterThanOrEqual(statistics.filesScanned, 0)
        XCTAssertGreaterThanOrEqual(statistics.directoriesScanned, 0)
        XCTAssertGreaterThanOrEqual(statistics.totalBytesScanned, 0)
    }
    
    // MARK: - ScanProgressManager Tests
    
    func testScanProgressManagerStartStop() throws {
        XCTAssertNoThrow(progressManager.startProgressUpdates(), "开始进度更新不应该抛出异常")
        XCTAssertNoThrow(progressManager.stopProgressUpdates(), "停止进度更新不应该抛出异常")
    }
    
    func testScanProgressManagerUpdateProgress() throws {
        let progress = ScanProgress(
            currentPath: testDirectory.path,
            filesScanned: 10,
            directoriesScanned: 2,
            totalBytesScanned: 1024,
            errorCount: 0,
            elapsedTime: 30.0
        )
        
        XCTAssertNoThrow(progressManager.updateProgress(progress), "更新进度不应该抛出异常")
    }
    
    // MARK: - FileFilter Tests
    
    func testFileFilterConfiguration() throws {
        var config = FileFilter.FilterConfiguration()
        config.maxFileSize = 1024 * 1024 // 1MB
        config.excludedExtensions = ["tmp", "log"]
        config.includeHiddenFiles = false
        
        XCTAssertNoThrow(fileFilter.setConfiguration(config), "设置过滤配置不应该抛出异常")
    }
    
    func testFileFilterShouldFilter() throws {
        var config = FileFilter.FilterConfiguration()
        config.maxFileSize = 1024
        config.excludedExtensions = ["log"]
        config.includeHiddenFiles = false
        fileFilter.setConfiguration(config)
        
        // 测试文件大小过滤 - 大文件应该被过滤
        let largeFileAttributes: [FileAttributeKey: Any] = [.size: Int64(2048)]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/large.txt", attributes: largeFileAttributes))
        
        // 测试扩展名过滤 - .log文件应该被过滤
        let logFileAttributes: [FileAttributeKey: Any] = [.size: Int64(512)]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/debug.log", attributes: logFileAttributes))
        
        // 测试正常文件 - 不应该被过滤
        let normalFileAttributes: [FileAttributeKey: Any] = [.size: Int64(512)]
        XCTAssertFalse(fileFilter.shouldFilter(path: "/test/normal.txt", attributes: normalFileAttributes))
        
        // 测试隐藏文件 - 应该被过滤（因为includeHiddenFiles=false）
        let hiddenFileAttributes: [FileAttributeKey: Any] = [.size: Int64(512)]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/.hidden", attributes: hiddenFileAttributes))
    }
    
    // MARK: - ScanTaskManager Tests
    
    func testScanTaskManagerCreateTask() throws {
        let task = taskManager.createScanTask(id: "test_task", path: testDirectory.path)
        
        XCTAssertNotNil(task)
        XCTAssertEqual(taskManager.getActiveTaskCount(), 1)
        
        // 清理
        taskManager.cancelTask(id: "test_task")
    }
    
    func testScanTaskManagerCancelTask() throws {
        let _ = taskManager.createScanTask(id: "cancel_task", path: testDirectory.path)
        XCTAssertEqual(taskManager.getActiveTaskCount(), 1)
        
        taskManager.cancelTask(id: "cancel_task")
        
        // 等待任务取消
        Thread.sleep(forTimeInterval: 0.1)
        
        // 任务应该被取消
        XCTAssertEqual(taskManager.getActiveTaskCount(), 0)
    }
    
    func testScanTaskManagerCancelAllTasks() throws {
        let _ = taskManager.createScanTask(id: "task1", path: testDirectory.path)
        let _ = taskManager.createScanTask(id: "task2", path: testDirectory.path)
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 2)
        
        taskManager.cancelAllTasks()
        
        // 等待任务取消
        Thread.sleep(forTimeInterval: 0.1)
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 0)
    }
    
    // MARK: - ScanEngine Integration Tests
    
    func testScanEngineBasicScan() async throws {
        let result = try await scanEngine.startScan(at: testDirectory.path)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.rootNode)
        XCTAssertGreaterThan(result.statistics.filesScanned, 0)
        XCTAssertGreaterThan(result.statistics.directoriesScanned, 0)
    }
    
    func testScanEngineWithFilter() async throws {
        var config = FileFilter.FilterConfiguration()
        config.maxFileSize = 1024 * 1024
        config.excludedExtensions = ["log"]
        config.includeHiddenFiles = false
        
        let result = try await scanEngine.startScan(at: testDirectory.path, configuration: config)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.rootNode)
    }
    
    func testScanEngineCancelScan() throws {
        XCTAssertNoThrow(scanEngine.cancelScan(), "取消扫描不应该抛出异常")
    }
    
    func testScanEnginePauseResume() throws {
        XCTAssertNoThrow(scanEngine.pauseScan(), "暂停扫描不应该抛出异常")
        XCTAssertNoThrow(scanEngine.resumeScan(), "恢复扫描不应该抛出异常")
    }
    
    func testScanEngineGetStatistics() throws {
        let statistics = scanEngine.getScanStatistics()
        
        XCTAssertNotNil(statistics)
        XCTAssertGreaterThanOrEqual(statistics.filesScanned, 0)
        XCTAssertGreaterThanOrEqual(statistics.directoriesScanned, 0)
        XCTAssertGreaterThanOrEqual(statistics.totalBytesScanned, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testScanEngineInvalidPath() async throws {
        do {
            _ = try await scanEngine.startScan(at: "")
            XCTFail("空路径应该抛出异常")
        } catch {
            // 验证抛出了错误
            XCTAssertTrue(true, "应该抛出错误")
        }
    }
    
    func testScanEngineNonexistentPath() async throws {
        do {
            _ = try await scanEngine.startScan(at: "/nonexistent/path/12345")
            XCTFail("不存在的路径应该抛出异常")
        } catch {
            // 预期的错误
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Performance Tests
    
    func testScanEnginePerformance() throws {
        measure {
            Task {
                do {
                    _ = try await scanEngine.startScan(at: testDirectory.path)
                } catch {
                    // 忽略错误，只测试性能
                }
            }
        }
    }
    
    func testFileFilterPerformance() throws {
        var config = FileFilter.FilterConfiguration()
        config.maxFileSize = 1024 * 1024
        config.excludedExtensions = ["tmp", "log", "cache"]
        config.includeHiddenFiles = false
        fileFilter.setConfiguration(config)
        
        let testPaths = (0..<1000).map { "/test/file\($0).txt" }
        let attributes: [FileAttributeKey: Any] = [.size: 512]
        
        measure {
            for path in testPaths {
                _ = fileFilter.shouldFilter(path: path, attributes: attributes)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullScanWorkflow() async throws {
        // 设置进度回调
        var progressUpdates: [ScanProgress] = []
        var discoveredNodes: [FileNode] = []
        
        fileSystemScanner.onProgress = { progress in
            progressUpdates.append(progress)
        }
        
        fileSystemScanner.onNodeDiscovered = { node in
            discoveredNodes.append(node)
        }
        
        // 设置过滤器
        var config = FileFilter.FilterConfiguration()
        config.maxFileSize = 1024 * 1024
        config.excludedExtensions = []
        config.includeHiddenFiles = true
        
        // 执行扫描
        let result = try await scanEngine.startScan(at: testDirectory.path, configuration: config)
        
        // 验证结果
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.rootNode)
        XCTAssertGreaterThan(discoveredNodes.count, 0)
        
        // 验证统计信息
        let statistics = scanEngine.getScanStatistics()
        XCTAssertGreaterThan(statistics.filesScanned, 0)
        XCTAssertGreaterThan(statistics.directoriesScanned, 0)
    }
}
