import XCTest
@testable import ScanEngine
@testable import Common
@testable import DataModel
@testable import PerformanceOptimizer

final class ScanEngineTests: XCTestCase {
    
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
    
    private func createTestFileStructure() throws {
        // 创建子目录
        let subDir1 = testDirectory.appendingPathComponent("subdir1")
        let subDir2 = testDirectory.appendingPathComponent("subdir2")
        try FileManager.default.createDirectory(at: subDir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDir2, withIntermediateDirectories: true)
        
        // 创建测试文件
        let file1 = testDirectory.appendingPathComponent("file1.txt")
        let file2 = subDir1.appendingPathComponent("file2.txt")
        let file3 = subDir2.appendingPathComponent("file3.txt")
        let emptyFile = testDirectory.appendingPathComponent("empty.txt")
        
        try "Hello World 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Hello World 2 - This is a longer file".write(to: file2, atomically: true, encoding: .utf8)
        try "Hello World 3".write(to: file3, atomically: true, encoding: .utf8)
        try "".write(to: emptyFile, atomically: true, encoding: .utf8)
        
        // 创建隐藏文件
        let hiddenFile = testDirectory.appendingPathComponent(".hidden")
        try "Hidden content".write(to: hiddenFile, atomically: true, encoding: .utf8)
    }
    
    // MARK: - ScanEngine Tests
    
    func testScanEngineInitialization() throws {
        XCTAssertNotNil(scanEngine, "ScanEngine应该能够正确初始化")
        XCTAssertNotNil(ScanEngine.shared, "ScanEngine.shared应该存在")
        XCTAssertTrue(ScanEngine.shared === scanEngine, "应该是单例模式")
    }
    
    func testBasicScan() async throws {
        let result = try await scanEngine.startScan(at: testDirectory.path)
        
        XCTAssertNotNil(result, "扫描结果不应该为nil")
        XCTAssertNotNil(result.rootNode, "根节点不应该为nil")
        XCTAssertGreaterThan(result.statistics.filesScanned, 0, "应该扫描到文件")
        XCTAssertGreaterThan(result.statistics.directoriesScanned, 0, "应该扫描到目录")
        XCTAssertGreaterThan(result.statistics.totalBytesScanned, 0, "应该有字节统计")
    }
    
    func testScanWithConfiguration() async throws {
        var config = FileFilter.FilterConfiguration()
        config.includeHiddenFiles = false
        config.filterZeroSizeFiles = true
        
        let result = try await scanEngine.startScan(at: testDirectory.path, configuration: config)
        
        XCTAssertNotNil(result, "扫描结果不应该为nil")
        // 由于过滤了隐藏文件和空文件，扫描结果应该相应减少
    }
    
    func testScanInvalidPath() async throws {
        do {
            _ = try await scanEngine.startScan(at: "/nonexistent/path")
            XCTFail("应该抛出路径不存在的错误")
        } catch let error as ScanError {
            switch error {
            case .pathNotFound:
                break // 预期的错误
            default:
                XCTFail("错误类型不正确: \(error)")
            }
        }
    }
    
    func testScanEmptyPath() async throws {
        do {
            _ = try await scanEngine.startScan(at: "")
            XCTFail("应该抛出无效路径的错误")
        } catch let error as ScanError {
            switch error {
            case .invalidPath:
                break // 预期的错误
            default:
                XCTFail("错误类型不正确: \(error)")
            }
        }
    }
    
    // MARK: - FileSystemScanner Tests
    
    func testFileSystemScannerInitialization() throws {
        XCTAssertNotNil(fileSystemScanner, "FileSystemScanner应该能够正确初始化")
        XCTAssertNotNil(FileSystemScanner.shared, "FileSystemScanner.shared应该存在")
        XCTAssertTrue(FileSystemScanner.shared === fileSystemScanner, "应该是单例模式")
    }
    
    func testScannerCallbacks() async throws {
        var progressCallbackCount = 0
        var nodeDiscoveredCount = 0
        var errorCallbackCount = 0
        var completedCallbackCount = 0
        
        fileSystemScanner.onProgress = { _ in
            progressCallbackCount += 1
        }
        
        fileSystemScanner.onNodeDiscovered = { _ in
            nodeDiscoveredCount += 1
        }
        
        fileSystemScanner.onError = { _ in
            errorCallbackCount += 1
        }
        
        fileSystemScanner.onCompleted = { _ in
            completedCallbackCount += 1
        }
        
        try await fileSystemScanner.startScan(at: testDirectory.path)
        
        // 等待回调执行
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertGreaterThan(nodeDiscoveredCount, 0, "应该发现节点")
        XCTAssertEqual(completedCallbackCount, 1, "应该调用完成回调")
    }
    
    func testScannerCancellation() async throws {
        let scanTask = Task {
            try await fileSystemScanner.startScan(at: testDirectory.path)
        }
        
        // 立即取消
        fileSystemScanner.cancelScan()
        
        do {
            try await scanTask.value
        } catch {
            // 取消操作可能导致任务被取消，这是正常的
        }
        
        // 验证扫描器状态
        let statistics = fileSystemScanner.getScanStatistics()
        XCTAssertNotNil(statistics, "统计信息应该存在")
    }
    
    func testScannerPauseResume() async throws {
        let scanTask = Task {
            try await fileSystemScanner.startScan(at: testDirectory.path)
        }
        
        // 暂停扫描
        fileSystemScanner.pauseScan()
        
        // 等待一段时间
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // 恢复扫描
        fileSystemScanner.resumeScan()
        
        try await scanTask.value
        
        let statistics = fileSystemScanner.getScanStatistics()
        XCTAssertGreaterThan(statistics.filesScanned, 0, "暂停恢复后应该完成扫描")
    }
    
    // MARK: - ScanProgressManager Tests
    
    func testProgressManagerInitialization() throws {
        XCTAssertNotNil(progressManager, "ScanProgressManager应该能够正确初始化")
        XCTAssertNotNil(ScanProgressManager.shared, "ScanProgressManager.shared应该存在")
        XCTAssertTrue(ScanProgressManager.shared === progressManager, "应该是单例模式")
    }
    
    func testProgressUpdates() throws {
        let expectation = XCTestExpectation(description: "进度更新")
        var updateCount = 0
        
        progressManager.onProgressUpdate = { _ in
            updateCount += 1
            if updateCount >= 3 {
                expectation.fulfill()
            }
        }
        
        progressManager.startProgressUpdates()
        
        // 模拟进度更新
        let progress1 = ScanProgress(filesScanned: 10, directoriesScanned: 2)
        let progress2 = ScanProgress(filesScanned: 20, directoriesScanned: 4)
        let progress3 = ScanProgress(filesScanned: 30, directoriesScanned: 6)
        
        progressManager.updateProgress(progress1)
        progressManager.updateProgress(progress2)
        progressManager.updateProgress(progress3)
        
        wait(for: [expectation], timeout: 2.0)
        
        progressManager.stopProgressUpdates()
        
        XCTAssertGreaterThanOrEqual(updateCount, 3, "应该收到进度更新")
    }
    
    // MARK: - FileFilter Tests
    
    func testFileFilterInitialization() throws {
        XCTAssertNotNil(fileFilter, "FileFilter应该能够正确初始化")
        XCTAssertNotNil(FileFilter.shared, "FileFilter.shared应该存在")
        XCTAssertTrue(FileFilter.shared === fileFilter, "应该是单例模式")
    }
    
    func testFilterConfiguration() throws {
        var config = FileFilter.FilterConfiguration()
        config.includeHiddenFiles = false
        config.filterZeroSizeFiles = true
        config.minFileSize = 100
        config.excludedExtensions = ["tmp", "log"]
        
        fileFilter.setConfiguration(config)
        
        // 测试隐藏文件过滤
        let hiddenFileAttributes: [FileAttributeKey: Any] = [
            .size: 1000,
            .type: FileAttributeType.typeRegular
        ]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/.hidden", attributes: hiddenFileAttributes), "应该过滤隐藏文件")
        
        // 测试零大小文件过滤
        let zeroSizeAttributes: [FileAttributeKey: Any] = [
            .size: 0,
            .type: FileAttributeType.typeRegular
        ]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/empty.txt", attributes: zeroSizeAttributes), "应该过滤零大小文件")
        
        // 测试最小文件大小过滤
        let smallFileAttributes: [FileAttributeKey: Any] = [
            .size: 50,
            .type: FileAttributeType.typeRegular
        ]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/small.txt", attributes: smallFileAttributes), "应该过滤小文件")
        
        // 测试扩展名过滤
        let tmpFileAttributes: [FileAttributeKey: Any] = [
            .size: 1000,
            .type: FileAttributeType.typeRegular
        ]
        XCTAssertTrue(fileFilter.shouldFilter(path: "/test/temp.tmp", attributes: tmpFileAttributes), "应该过滤tmp文件")
        
        // 测试正常文件不被过滤
        let normalFileAttributes: [FileAttributeKey: Any] = [
            .size: 1000,
            .type: FileAttributeType.typeRegular
        ]
        XCTAssertFalse(fileFilter.shouldFilter(path: "/test/normal.txt", attributes: normalFileAttributes), "正常文件不应该被过滤")
    }
    
    // MARK: - ScanTaskManager Tests
    
    func testTaskManagerInitialization() throws {
        XCTAssertNotNil(taskManager, "ScanTaskManager应该能够正确初始化")
        XCTAssertNotNil(ScanTaskManager.shared, "ScanTaskManager.shared应该存在")
        XCTAssertTrue(ScanTaskManager.shared === taskManager, "应该是单例模式")
    }
    
    func testTaskCreationAndCancellation() async throws {
        let taskId = "test_task"
        
        // 创建任务
        let task = taskManager.createScanTask(id: taskId, path: testDirectory.path)
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 1, "应该有一个活跃任务")
        
        // 取消任务
        taskManager.cancelTask(id: taskId)
        
        // 等待任务清理
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 0, "活跃任务应该被清理")
    }
    
    func testMultipleTasks() async throws {
        let task1Id = "task1"
        let task2Id = "task2"
        
        // 创建多个任务
        let task1 = taskManager.createScanTask(id: task1Id, path: testDirectory.path)
        let task2 = taskManager.createScanTask(id: task2Id, path: testDirectory.path)
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 2, "应该有两个活跃任务")
        
        // 取消所有任务
        taskManager.cancelAllTasks()
        
        // 等待任务清理
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        XCTAssertEqual(taskManager.getActiveTaskCount(), 0, "所有活跃任务应该被清理")
    }
    
    // MARK: - Data Structure Tests
    
    func testScanProgress() throws {
        let progress = ScanProgress(
            currentPath: "/test/path",
            filesScanned: 100,
            directoriesScanned: 10,
            totalBytesScanned: 1024000,
            errorCount: 2,
            elapsedTime: 5.0
        )
        
        XCTAssertEqual(progress.currentPath, "/test/path")
        XCTAssertEqual(progress.filesScanned, 100)
        XCTAssertEqual(progress.directoriesScanned, 10)
        XCTAssertEqual(progress.totalBytesScanned, 1024000)
        XCTAssertEqual(progress.errorCount, 2)
        XCTAssertEqual(progress.elapsedTime, 5.0)
        
        XCTAssertEqual(progress.totalItemsScanned, 110, "总项目数应该是文件数+目录数")
        XCTAssertEqual(progress.scanSpeed, 22.0, accuracy: 0.1, "扫描速度应该正确计算")
    }
    
    func testScanResult() throws {
        let rootNode = FileNode(name: "root", path: "/test", size: 0, isDirectory: true)
        let statistics = ScanStatistics()
        let errors: [ScanError] = []
        
        let result = ScanResult(rootNode: rootNode, statistics: statistics, errors: errors)
        
        XCTAssertEqual(result.rootNode.name, "root")
        XCTAssertNotNil(result.statistics)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testScanError() throws {
        let invalidPathError = ScanError.invalidPath("测试路径")
        let pathNotFoundError = ScanError.pathNotFound("测试路径")
        let accessDeniedError = ScanError.accessDenied("测试路径")
        let cancelledError = ScanError.scanCancelled
        let unknownError = ScanError.unknownError("测试错误")
        
        XCTAssertNotNil(invalidPathError.errorDescription)
        XCTAssertNotNil(pathNotFoundError.errorDescription)
        XCTAssertNotNil(accessDeniedError.errorDescription)
        XCTAssertNotNil(cancelledError.errorDescription)
        XCTAssertNotNil(unknownError.errorDescription)
        
        XCTAssertTrue(invalidPathError.errorDescription!.contains("无效路径"))
        XCTAssertTrue(pathNotFoundError.errorDescription!.contains("路径未找到"))
        XCTAssertTrue(accessDeniedError.errorDescription!.contains("访问被拒绝"))
        XCTAssertTrue(cancelledError.errorDescription!.contains("已取消"))
        XCTAssertTrue(unknownError.errorDescription!.contains("未知错误"))
    }
    
    // MARK: - Integration Tests
    
    func testFullScanWorkflow() async throws {
        var progressUpdates: [ScanProgress] = []
        var discoveredNodes: [FileNode] = []
        var errors: [ScanError] = []
        
        // 设置回调
        fileSystemScanner.onProgress = { progress in
            progressUpdates.append(progress)
        }
        
        fileSystemScanner.onNodeDiscovered = { node in
            discoveredNodes.append(node)
        }
        
        fileSystemScanner.onError = { error in
            errors.append(error)
        }
        
        // 执行完整扫描
        let result = try await scanEngine.startScan(at: testDirectory.path)
        
        // 验证结果
        XCTAssertNotNil(result, "扫描结果不应该为nil")
        XCTAssertGreaterThan(discoveredNodes.count, 0, "应该发现节点")
        XCTAssertGreaterThan(result.statistics.filesScanned, 0, "应该扫描到文件")
        XCTAssertGreaterThan(result.statistics.directoriesScanned, 0, "应该扫描到目录")
    }
    
    // MARK: - Performance Tests
    
    func testScanPerformance() throws {
        measure {
            let task = Task {
                do {
                    _ = try await scanEngine.startScan(at: testDirectory.path)
                } catch {
                    XCTFail("扫描失败: \(error)")
                }
            }
            
            // 等待任务完成
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                _ = try? await task.value
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    func testFilterPerformance() throws {
        let config = FileFilter.FilterConfiguration()
        fileFilter.setConfiguration(config)
        
        let attributes: [FileAttributeKey: Any] = [
            .size: 1000,
            .type: FileAttributeType.typeRegular
        ]
        
        measure {
            for i in 0..<1000 {
                _ = fileFilter.shouldFilter(path: "/test/file\(i).txt", attributes: attributes)
            }
        }
    }
}
