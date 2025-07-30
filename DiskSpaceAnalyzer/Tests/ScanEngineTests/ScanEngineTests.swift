import XCTest
@testable import Core

class ScanEngineTests: XCTestCase {
    
    var scanEngine: ScanEngine!
    
    override func setUp() {
        super.setUp()
        scanEngine = ScanEngine.shared
    }
    
    override func tearDown() {
        scanEngine.clearCompletedTasks()
        scanEngine.resetStatistics()
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testScanEngineInitialization() {
        XCTAssertNotNil(scanEngine.fileSystemScanner, "FileSystemScanner should be initialized")
        XCTAssertNotNil(scanEngine.progressManager, "ProgressManager should be initialized")
        XCTAssertNotNil(scanEngine.fileFilter, "FileFilter should be initialized")
        XCTAssertNotNil(scanEngine.taskManager, "TaskManager should be initialized")
    }
    
    func testScanEngineConfiguration() {
        let config = ScanEngine.ScanEngineConfiguration(
            maxConcurrency: 2,
            followSymlinks: true,
            includeHiddenFiles: true,
            maxDepth: 5,
            enableProgressTracking: true,
            enableFileFiltering: true
        )
        
        scanEngine.configure(with: config)
        
        // 验证配置是否正确应用
        XCTAssertEqual(scanEngine.taskManager.maxConcurrentTasks, 2, "Max concurrency should be updated")
    }
    
    func testFilterRuleManagement() {
        let rule = FilterRule(
            type: .extension,
            operation: .exclude,
            pattern: "tmp"
        )
        
        scanEngine.addFilterRule(rule)
        
        let rules = scanEngine.getAllFilterRules()
        XCTAssertTrue(rules.contains { $0.id == rule.id }, "Rule should be added")
        
        scanEngine.removeFilterRule(id: rule.id)
        
        let updatedRules = scanEngine.getAllFilterRules()
        XCTAssertFalse(updatedRules.contains { $0.id == rule.id }, "Rule should be removed")
    }
    
    func testStatisticsRetrieval() {
        let taskStats = scanEngine.getTaskManagerStatistics()
        XCTAssertNotNil(taskStats, "Task manager statistics should be available")
        
        let filterStats = scanEngine.getFilterStatistics()
        XCTAssertNotNil(filterStats, "Filter statistics should be available")
        
        // Progress statistics might be nil if no scan is active
        let progressStats = scanEngine.getProgressStatistics()
        // This is expected to be nil initially
    }
    
    func testComprehensiveReport() {
        let report = scanEngine.getComprehensiveReport()
        
        XCTAssertFalse(report.isEmpty, "Comprehensive report should not be empty")
        XCTAssertTrue(report.contains("Scan Engine Comprehensive Report"), "Report should contain title")
        XCTAssertTrue(report.contains("Configuration:"), "Report should contain configuration section")
        XCTAssertTrue(report.contains("Task Management"), "Report should contain task management section")
    }
    
    func testFullLogExport() {
        let log = scanEngine.exportFullLog()
        
        XCTAssertFalse(log.isEmpty, "Full log should not be empty")
        XCTAssertTrue(log.contains("Scan Engine Full Log"), "Log should contain title")
    }
    
    // MARK: - Edge Cases
    
    func testInvalidTaskOperations() {
        let invalidTaskId = "invalid-task-id"
        
        XCTAssertFalse(scanEngine.pauseScan(taskId: invalidTaskId), "Should return false for invalid task ID")
        XCTAssertFalse(scanEngine.resumeScan(taskId: invalidTaskId), "Should return false for invalid task ID")
        XCTAssertFalse(scanEngine.cancelScan(taskId: invalidTaskId), "Should return false for invalid task ID")
        
        XCTAssertNil(scanEngine.getScanTask(id: invalidTaskId), "Should return nil for invalid task ID")
        XCTAssertNil(scanEngine.getScanStatistics(for: invalidTaskId), "Should return nil for invalid task ID")
    }
    
    func testEmptyTaskList() {
        let allTasks = scanEngine.getAllScanTasks()
        let activeTasks = scanEngine.getActiveScanTasks()
        
        // Initially should be empty or contain only system tasks
        XCTAssertTrue(allTasks.isEmpty || allTasks.allSatisfy { $0.status != .running }, "Should not have running tasks initially")
        XCTAssertTrue(activeTasks.isEmpty, "Should not have active tasks initially")
    }
    
    func testStatisticsReset() {
        // Add some filter rules first
        let rule = FilterRule(type: .extension, operation: .exclude, pattern: "test")
        scanEngine.addFilterRule(rule)
        
        // Reset statistics
        scanEngine.resetStatistics()
        
        let filterStats = scanEngine.getFilterStatistics()
        XCTAssertEqual(filterStats.totalFilesProcessed, 0, "Filter statistics should be reset")
        
        let progressStats = scanEngine.getProgressStatistics()
        XCTAssertNil(progressStats, "Progress statistics should be nil after reset")
    }
}
