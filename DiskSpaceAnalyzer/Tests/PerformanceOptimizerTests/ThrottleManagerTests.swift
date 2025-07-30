import XCTest
@testable import Core

class ThrottleManagerTests: XCTestCase {
    
    var throttleManager: ThrottleManager!
    
    override func setUp() {
        super.setUp()
        throttleManager = ThrottleManager.shared
        throttleManager.clearAllTasks()
    }
    
    override func tearDown() {
        throttleManager.clearAllTasks()
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testRegisterAndExecuteThrottleTask() {
        let expectation = XCTestExpectation(description: "Throttle task executed")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "test_task", interval: 0.1) {
            executionCount += 1
            expectation.fulfill()
        }
        
        throttleManager.executeThrottledTask(id: "test_task")
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "Task should be executed once")
    }
    
    func testThrottleLeadingType() {
        let expectation = XCTestExpectation(description: "Leading throttle executed immediately")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "leading_task", interval: 0.5, type: .leading) {
            executionCount += 1
            if executionCount == 1 {
                expectation.fulfill()
            }
        }
        
        // 第一次应该立即执行
        throttleManager.executeThrottledTask(id: "leading_task")
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(executionCount, 1, "Leading throttle should execute immediately")
        
        // 短时间内再次调用应该被节流
        throttleManager.executeThrottledTask(id: "leading_task")
        
        // 等待一小段时间确保没有额外执行
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(executionCount, 1, "Subsequent calls should be throttled")
    }
    
    func testThrottleTrailingType() {
        let expectation = XCTestExpectation(description: "Trailing throttle executed after delay")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "trailing_task", interval: 0.1, type: .trailing) {
            executionCount += 1
            expectation.fulfill()
        }
        
        // 连续调用多次
        throttleManager.executeThrottledTask(id: "trailing_task")
        throttleManager.executeThrottledTask(id: "trailing_task")
        throttleManager.executeThrottledTask(id: "trailing_task")
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "Trailing throttle should execute only once after delay")
    }
    
    func testCancelThrottleTask() {
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "cancel_task", interval: 0.2, type: .trailing) {
            executionCount += 1
        }
        
        throttleManager.executeThrottledTask(id: "cancel_task")
        throttleManager.cancelThrottleTask(id: "cancel_task")
        
        // 等待足够长的时间确保任务不会执行
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertEqual(executionCount, 0, "Cancelled task should not execute")
    }
    
    func testRemoveThrottleTask() {
        throttleManager.registerThrottleTask(id: "remove_task", interval: 0.1) {
            // Should not execute
        }
        
        throttleManager.removeThrottleTask(id: "remove_task")
        
        // 尝试执行已移除的任务应该不会崩溃
        throttleManager.executeThrottledTask(id: "remove_task")
        
        // 验证统计信息中没有这个任务
        let stats = throttleManager.getThrottleStats(for: "remove_task")
        XCTAssertNil(stats, "Removed task should not have stats")
    }
    
    // MARK: - Statistics Tests
    
    func testThrottleStatistics() {
        let expectation = XCTestExpectation(description: "Task executed for statistics")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "stats_task", interval: 0.1, type: .trailing) {
            executionCount += 1
            if executionCount == 1 {
                expectation.fulfill()
            }
        }
        
        // 执行多次以生成统计数据
        for _ in 0..<5 {
            throttleManager.executeThrottledTask(id: "stats_task")
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        guard let stats = throttleManager.getThrottleStats(for: "stats_task") else {
            XCTFail("Should have statistics for the task")
            return
        }
        
        XCTAssertEqual(stats.taskId, "stats_task", "Task ID should match")
        XCTAssertEqual(stats.totalCalls, 5, "Should record all calls")
        XCTAssertEqual(stats.actualExecutions, 1, "Should execute only once due to throttling")
        XCTAssertEqual(stats.throttledCalls, 4, "Should throttle 4 calls")
        XCTAssertEqual(stats.throttleRate, 0.8, accuracy: 0.01, "Throttle rate should be 80%")
    }
    
    func testGetAllThrottleStats() {
        throttleManager.registerThrottleTask(id: "task1", interval: 0.1) { }
        throttleManager.registerThrottleTask(id: "task2", interval: 0.1) { }
        
        throttleManager.executeThrottledTask(id: "task1")
        throttleManager.executeThrottledTask(id: "task2")
        
        let allStats = throttleManager.getAllThrottleStats()
        XCTAssertEqual(allStats.count, 2, "Should have stats for both tasks")
        
        let taskIds = Set(allStats.map { $0.taskId })
        XCTAssertTrue(taskIds.contains("task1"), "Should contain task1")
        XCTAssertTrue(taskIds.contains("task2"), "Should contain task2")
    }
    
    func testClearStatistics() {
        throttleManager.registerThrottleTask(id: "clear_task", interval: 0.1) { }
        throttleManager.executeThrottledTask(id: "clear_task")
        
        // 验证有统计数据
        var stats = throttleManager.getThrottleStats(for: "clear_task")
        XCTAssertNotNil(stats, "Should have statistics before clearing")
        XCTAssertGreaterThan(stats?.totalCalls ?? 0, 0, "Should have call count")
        
        // 清除统计数据
        throttleManager.clearStatistics()
        
        // 验证统计数据被清除
        stats = throttleManager.getThrottleStats(for: "clear_task")
        XCTAssertEqual(stats?.totalCalls ?? -1, 0, "Total calls should be reset to 0")
        XCTAssertEqual(stats?.actualExecutions ?? -1, 0, "Actual executions should be reset to 0")
    }
    
    // MARK: - Convenience Methods Tests
    
    func testThrottleConvenienceMethod() {
        let expectation = XCTestExpectation(description: "Convenience throttle executed")
        var executionCount = 0
        
        throttleManager.throttle(id: "convenience_task", interval: 0.1) {
            executionCount += 1
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "Convenience method should work")
    }
    
    func testDebounceMethod() {
        let expectation = XCTestExpectation(description: "Debounce executed")
        var executionCount = 0
        
        // 连续调用debounce
        for _ in 0..<5 {
            throttleManager.debounce(id: "debounce_task", interval: 0.1) {
                executionCount += 1
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "Debounce should execute only once")
    }
    
    func testThrottleLeadingConvenienceMethod() {
        let expectation = XCTestExpectation(description: "Leading throttle executed")
        var executionCount = 0
        
        throttleManager.throttleLeading(id: "leading_convenience", interval: 0.5) {
            executionCount += 1
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(executionCount, 1, "Leading throttle should execute immediately")
    }
    
    // MARK: - Performance Tests
    
    func testThrottlePerformance() {
        let taskCount = 1000
        let expectation = XCTestExpectation(description: "Performance test completed")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "performance_task", interval: 0.01, type: .trailing) {
            executionCount += 1
            if executionCount == 1 {
                expectation.fulfill()
            }
        }
        
        measure {
            for _ in 0..<taskCount {
                throttleManager.executeThrottledTask(id: "performance_task")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // 验证节流效果
        guard let stats = throttleManager.getThrottleStats(for: "performance_task") else {
            XCTFail("Should have performance statistics")
            return
        }
        
        XCTAssertEqual(stats.totalCalls, taskCount, "Should record all calls")
        XCTAssertEqual(stats.actualExecutions, 1, "Should execute only once due to throttling")
        XCTAssertGreaterThan(stats.throttleRate, 0.9, "Should have high throttle rate")
    }
    
    // MARK: - Edge Cases
    
    func testNonExistentTask() {
        // 执行不存在的任务不应该崩溃
        throttleManager.executeThrottledTask(id: "non_existent")
        
        let stats = throttleManager.getThrottleStats(for: "non_existent")
        XCTAssertNil(stats, "Non-existent task should not have stats")
    }
    
    func testZeroInterval() {
        let expectation = XCTestExpectation(description: "Zero interval task executed")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "zero_interval", interval: 0.0) {
            executionCount += 1
            expectation.fulfill()
        }
        
        throttleManager.executeThrottledTask(id: "zero_interval")
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(executionCount, 1, "Zero interval should still work")
    }
    
    func testNegativeInterval() {
        let expectation = XCTestExpectation(description: "Negative interval task executed")
        var executionCount = 0
        
        throttleManager.registerThrottleTask(id: "negative_interval", interval: -0.1) {
            executionCount += 1
            expectation.fulfill()
        }
        
        throttleManager.executeThrottledTask(id: "negative_interval")
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(executionCount, 1, "Negative interval should still work")
    }
}
