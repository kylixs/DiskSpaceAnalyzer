import XCTest
@testable import DataModel
@testable import Common

final class ScanSessionTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var tempDirectory: URL!
    var scanSession: ScanSession!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScanSessionTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        scanSession = ScanSession(scanPath: tempDirectory.path)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        scanSession = nil
        tempDirectory = nil
    }
    
    // MARK: - Basic Tests
    
    func testScanSessionInitialization() throws {
        XCTAssertNotNil(scanSession)
        XCTAssertEqual(scanSession.scanPath, tempDirectory.path)
        XCTAssertEqual(scanSession.status, .pending)
        XCTAssertNil(scanSession.startedAt)
        XCTAssertNil(scanSession.completedAt)
        XCTAssertEqual(scanSession.statistics.filesScanned, 0)
        XCTAssertEqual(scanSession.statistics.directoriesScanned, 0)
        XCTAssertEqual(scanSession.statistics.totalBytesScanned, 0)
    }
    
    func testStartScan() throws {
        scanSession.start()
        
        XCTAssertEqual(scanSession.status, .scanning)
        XCTAssertNotNil(scanSession.startedAt)
        XCTAssertNil(scanSession.completedAt)
        
        let timeDifference = abs(scanSession.startedAt!.timeIntervalSinceNow)
        XCTAssertLessThan(timeDifference, 1.0, "开始时间应该接近当前时间")
    }
    
    func testCompleteScan() throws {
        scanSession.start()
        
        // 模拟扫描过程
        scanSession.updateProgress(currentPath: "/test/path", progress: 0.5, speed: 100.0, estimatedTime: 10.0)
        
        scanSession.complete()
        
        XCTAssertEqual(scanSession.status, .completed)
        XCTAssertNotNil(scanSession.startedAt)
        XCTAssertNotNil(scanSession.completedAt)
        XCTAssertEqual(scanSession.progress, 0.5)
        XCTAssertEqual(scanSession.scanSpeed, 100.0)
        XCTAssertEqual(scanSession.estimatedTimeRemaining, 10.0)
        
        let duration = scanSession.completedAt!.timeIntervalSince(scanSession.startedAt!)
        XCTAssertGreaterThan(duration, 0)
    }
    
    func testPauseScan() throws {
        scanSession.start()
        scanSession.updateProgress(currentPath: "/test/path", progress: 0.3, speed: 50.0, estimatedTime: 20.0)
        
        scanSession.pause()
        
        XCTAssertEqual(scanSession.status, .paused)
        XCTAssertNotNil(scanSession.startedAt)
        XCTAssertNotNil(scanSession.pausedAt)
        XCTAssertEqual(scanSession.progress, 0.3)
        XCTAssertEqual(scanSession.scanSpeed, 50.0)
        XCTAssertEqual(scanSession.estimatedTimeRemaining, 20.0)
    }
    
    func testFailScan() throws {
        scanSession.start()
        
        let testError = ScanError(
            message: "Test error",
            path: "/test/path",
            category: .fileSystem,
            severity: .error
        )
        scanSession.addError(testError)
        scanSession.complete(success: false)
        
        XCTAssertEqual(scanSession.status, .failed)
        XCTAssertNotNil(scanSession.startedAt)
        XCTAssertNotNil(scanSession.completedAt)
        XCTAssertEqual(scanSession.errors.count, 1)
        XCTAssertEqual(scanSession.errors.first?.message, "Test error")
    }
    
    func testUpdateProgress() throws {
        scanSession.start()
        
        scanSession.updateProgress(currentPath: "/test/path1", progress: 0.25, speed: 75.0, estimatedTime: 30.0)
        XCTAssertEqual(scanSession.currentPath, "/test/path1")
        XCTAssertEqual(scanSession.progress, 0.25)
        XCTAssertEqual(scanSession.scanSpeed, 75.0)
        XCTAssertEqual(scanSession.estimatedTimeRemaining, 30.0)
        
        // 更新进度
        scanSession.updateProgress(currentPath: "/test/path2", progress: 0.75, speed: 120.0, estimatedTime: 15.0)
        XCTAssertEqual(scanSession.currentPath, "/test/path2")
        XCTAssertEqual(scanSession.progress, 0.75)
        XCTAssertEqual(scanSession.scanSpeed, 120.0)
        XCTAssertEqual(scanSession.estimatedTimeRemaining, 15.0)
    }
    
    func testDurationCalculation() throws {
        XCTAssertEqual(scanSession.duration, 0, "未开始的扫描持续时间应为0")
        
        scanSession.start()
        Thread.sleep(forTimeInterval: 0.1)
        
        let durationWhileScanning = scanSession.duration
        XCTAssertGreaterThan(durationWhileScanning, 0)
        XCTAssertLessThan(durationWhileScanning, 1.0)
        
        scanSession.complete()
        let finalDuration = scanSession.duration
        XCTAssertGreaterThan(finalDuration, 0)
        XCTAssertGreaterThanOrEqual(finalDuration, durationWhileScanning)
    }
    
    func testDuration() throws {
        XCTAssertEqual(scanSession.duration, 0, "未开始的扫描持续时间应为0")
        
        scanSession.start()
        Thread.sleep(forTimeInterval: 0.1)
        
        let durationWhileScanning = scanSession.duration
        XCTAssertGreaterThan(durationWhileScanning, 0)
        XCTAssertLessThan(durationWhileScanning, 1.0)
        
        scanSession.complete()
        let finalDuration = scanSession.duration
        XCTAssertGreaterThan(finalDuration, 0)
        XCTAssertGreaterThanOrEqual(finalDuration, durationWhileScanning)
    }
    
    func testSessionSerialization() throws {
        scanSession.start()
        scanSession.updateProgress(currentPath: "/test", progress: 0.8, speed: 90.0, estimatedTime: 5.0)
        scanSession.complete()
        
        // 序列化
        let encoder = JSONEncoder()
        let data = try encoder.encode(scanSession)
        XCTAssertFalse(data.isEmpty)
        
        // 反序列化
        let decoder = JSONDecoder()
        let deserializedSession = try decoder.decode(ScanSession.self, from: data)
        
        XCTAssertEqual(deserializedSession.scanPath, scanSession.scanPath)
        XCTAssertEqual(deserializedSession.status, scanSession.status)
        XCTAssertEqual(deserializedSession.progress, scanSession.progress)
        XCTAssertEqual(deserializedSession.scanSpeed, scanSession.scanSpeed)
        XCTAssertEqual(deserializedSession.estimatedTimeRemaining, scanSession.estimatedTimeRemaining)
        
        // 时间比较（允许小的误差）
        if let originalStart = scanSession.startedAt, let deserializedStart = deserializedSession.startedAt {
            XCTAssertEqual(originalStart.timeIntervalSince1970, deserializedStart.timeIntervalSince1970, accuracy: 1.0)
        }
    }
    
    func testSessionComparison() throws {
        let session1 = ScanSession(scanPath: "/path1")
        session1.start()
        session1.updateProgress(currentPath: "/path1/file", progress: 0.5, speed: 100.0, estimatedTime: 10.0)
        session1.complete()
        
        let session2 = ScanSession(scanPath: "/path2")
        session2.start()
        session2.updateProgress(currentPath: "/path2/file", progress: 0.8, speed: 150.0, estimatedTime: 5.0)
        session2.complete()
        
        XCTAssertNotEqual(session1.id, session2.id)
        XCTAssertNotEqual(session1.scanPath, session2.scanPath)
        XCTAssertEqual(session1.status, session2.status) // 都是completed
        XCTAssertLessThan(session1.progress, session2.progress)
        XCTAssertLessThan(session1.scanSpeed, session2.scanSpeed)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleStartCalls() throws {
        scanSession.start()
        let firstStartTime = scanSession.startedAt
        
        // 再次调用start应该不会改变开始时间
        scanSession.start()
        XCTAssertEqual(scanSession.startedAt, firstStartTime)
        XCTAssertEqual(scanSession.status, .scanning)
    }
    
    func testCompleteWithoutStart() throws {
        // 未开始就完成应该不会改变状态
        scanSession.complete()
        XCTAssertEqual(scanSession.status, .pending)
        XCTAssertNil(scanSession.startedAt)
        XCTAssertNil(scanSession.completedAt)
    }
    
    func testProgressBounds() throws {
        scanSession.start()
        
        // 负数进度应该被处理为0
        scanSession.updateProgress(currentPath: "/test", progress: -0.5, speed: 50.0, estimatedTime: 10.0)
        XCTAssertEqual(scanSession.progress, 0.0)
        
        // 超过1的进度应该被处理为1
        scanSession.updateProgress(currentPath: "/test", progress: 1.5, speed: 50.0, estimatedTime: 10.0)
        XCTAssertEqual(scanSession.progress, 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        scanSession.start()
        
        let error1 = ScanError(
            message: "Permission denied",
            path: "/restricted/path",
            category: .permission,
            severity: .error
        )
        
        let error2 = ScanError(
            message: "File not found",
            path: "/missing/file",
            category: .fileSystem,
            severity: .warning
        )
        
        scanSession.addError(error1)
        scanSession.addError(error2)
        
        XCTAssertEqual(scanSession.errors.count, 2)
        XCTAssertEqual(scanSession.errors[0].category, .permission)
        XCTAssertEqual(scanSession.errors[1].category, .fileSystem)
    }
}
