import XCTest
@testable import PerformanceOptimizer
@testable import Common

final class PerformanceOptimizerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var optimizer: PerformanceOptimizer!
    var cpuOptimizer: CPUOptimizer!
    var throttleManager: ThrottleManager!
    var taskScheduler: TaskScheduler!
    var performanceMonitor: PerformanceOptimizer.PerformanceMonitor!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        optimizer = PerformanceOptimizer.shared
        cpuOptimizer = CPUOptimizer.shared
        throttleManager = ThrottleManager.shared
        taskScheduler = TaskScheduler.shared
        performanceMonitor = PerformanceOptimizer.PerformanceMonitor.shared
    }
    
    override func tearDownWithError() throws {
        optimizer.stopOptimization()
        throttleManager.clearAllThrottles()
        taskScheduler.cancelAllTasks()
        optimizer = nil
        cpuOptimizer = nil
        throttleManager = nil
        taskScheduler = nil
        performanceMonitor = nil
    }
    
    // MARK: - PerformanceOptimizer Tests
    
    func testPerformanceOptimizerInitialization() throws {
        XCTAssertNotNil(optimizer, "PerformanceOptimizer应该能够正确初始化")
        XCTAssertNotNil(PerformanceOptimizer.shared, "PerformanceOptimizer.shared应该存在")
        XCTAssertTrue(PerformanceOptimizer.shared === optimizer, "应该是单例模式")
    }
    
    func testStartStopOptimization() throws {
        // 测试开始优化
        XCTAssertNoThrow(optimizer.startOptimization(), "开始优化不应该抛出异常")
        
        // 测试停止优化
        XCTAssertNoThrow(optimizer.stopOptimization(), "停止优化不应该抛出异常")
    }
    
    func testGetPerformanceReport() throws {
        let report = optimizer.getPerformanceReport()
        
        XCTAssertNotNil(report, "性能报告不应该为nil")
        XCTAssertNotNil(report.cpuSavings, "CPU节省统计不应该为nil")
        XCTAssertNotNil(report.queueStatistics, "队列统计不应该为nil")
        XCTAssertNotNil(report.performanceStatistics, "性能统计不应该为nil")
        XCTAssertTrue(report.timestamp.timeIntervalSinceNow < 1.0, "时间戳应该是最近的")
    }
    
    // MARK: - CPUOptimizer Tests
    
    func testCPUOptimizerInitialization() throws {
        XCTAssertNotNil(cpuOptimizer, "CPUOptimizer应该能够正确初始化")
        XCTAssertNotNil(CPUOptimizer.shared, "CPUOptimizer.shared应该存在")
        XCTAssertTrue(CPUOptimizer.shared === cpuOptimizer, "应该是单例模式")
    }
    
    func testGetCurrentCPUUsage() throws {
        let cpuUsage = cpuOptimizer.getCurrentCPUUsage()
        
        XCTAssertGreaterThanOrEqual(cpuUsage, 0.0, "CPU使用率应该不小于0")
        XCTAssertLessThanOrEqual(cpuUsage, 1.0, "CPU使用率应该不大于1")
    }
    
    func testOptimizeCPUUsage() throws {
        let concurrency = cpuOptimizer.optimizeCPUUsage()
        
        XCTAssertGreaterThan(concurrency, 0, "并发度应该大于0")
        XCTAssertLessThanOrEqual(concurrency, 16, "并发度应该在合理范围内")
    }
    
    func testCPUSavingsStatistics() throws {
        // 先执行一些优化操作
        _ = cpuOptimizer.optimizeCPUUsage()
        _ = cpuOptimizer.optimizeCPUUsage()
        
        let stats = cpuOptimizer.getCPUSavingsStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.averageSavings, 0, "平均节省应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.totalOptimizations, 0, "总优化次数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.maxSavings, 0, "最大节省应该不小于0")
    }
    
    // MARK: - ThrottleManager Tests
    
    func testThrottleManagerInitialization() throws {
        XCTAssertNotNil(throttleManager, "ThrottleManager应该能够正确初始化")
        XCTAssertNotNil(ThrottleManager.shared, "ThrottleManager.shared应该存在")
        XCTAssertTrue(ThrottleManager.shared === throttleManager, "应该是单例模式")
    }
    
    func testThrottleExecution() throws {
        let expectation = XCTestExpectation(description: "节流执行")
        var executionCount = 0
        
        // 快速调用多次，应该只执行一次
        for _ in 0..<5 {
            throttleManager.throttle(key: "test", interval: 0.1) {
                executionCount += 1
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "节流应该只执行一次")
    }
    
    func testDebounceExecution() throws {
        let expectation = XCTestExpectation(description: "防抖执行")
        var executionCount = 0
        
        // 快速调用多次，应该只执行最后一次
        for _ in 0..<3 {
            throttleManager.debounce(key: "debounce_test", delay: 0.1) {
                executionCount += 1
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "防抖应该只执行一次")
    }
    
    func testCancelThrottle() throws {
        var executed = false
        
        throttleManager.throttle(key: "cancel_test", interval: 0.5) {
            executed = true
        }
        
        // 立即取消
        throttleManager.cancelThrottle(key: "cancel_test")
        
        // 等待足够长的时间
        Thread.sleep(forTimeInterval: 0.6)
        
        XCTAssertFalse(executed, "取消的节流不应该执行")
    }
    
    func testClearAllThrottles() throws {
        var executed1 = false
        var executed2 = false
        
        throttleManager.throttle(key: "clear_test1", interval: 0.5) {
            executed1 = true
        }
        
        throttleManager.throttle(key: "clear_test2", interval: 0.5) {
            executed2 = true
        }
        
        // 清除所有节流
        throttleManager.clearAllThrottles()
        
        // 等待足够长的时间
        Thread.sleep(forTimeInterval: 0.6)
        
        XCTAssertFalse(executed1, "清除的节流1不应该执行")
        XCTAssertFalse(executed2, "清除的节流2不应该执行")
    }
    
    // MARK: - TaskScheduler Tests
    
    func testTaskSchedulerInitialization() throws {
        XCTAssertNotNil(taskScheduler, "TaskScheduler应该能够正确初始化")
        XCTAssertNotNil(TaskScheduler.shared, "TaskScheduler.shared应该存在")
        XCTAssertTrue(TaskScheduler.shared === taskScheduler, "应该是单例模式")
    }
    
    func testScheduleTask() throws {
        let expectation = XCTestExpectation(description: "任务执行")
        var executed = false
        
        taskScheduler.scheduleTask(id: "test_task", priority: .normal) {
            executed = true
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(executed, "任务应该被执行")
    }
    
    func testScheduleTaskWithCompletion() throws {
        let taskExpectation = XCTestExpectation(description: "任务执行")
        let completionExpectation = XCTestExpectation(description: "完成回调")
        
        var taskExecuted = false
        var completionExecuted = false
        
        taskScheduler.scheduleTask(
            id: "completion_test",
            priority: .high,
            operation: {
                taskExecuted = true
                taskExpectation.fulfill()
            },
            completion: {
                completionExecuted = true
                completionExpectation.fulfill()
            }
        )
        
        wait(for: [taskExpectation, completionExpectation], timeout: 2.0)
        XCTAssertTrue(taskExecuted, "任务应该被执行")
        XCTAssertTrue(completionExecuted, "完成回调应该被执行")
    }
    
    func testCancelTask() throws {
        var executed = false
        
        taskScheduler.scheduleTask(id: "cancel_task", priority: .low) {
            Thread.sleep(forTimeInterval: 1.0) // 模拟长时间任务
            executed = true
        }
        
        // 立即取消任务
        taskScheduler.cancelTask(id: "cancel_task")
        
        // 等待一段时间
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertFalse(executed, "取消的任务不应该执行")
    }
    
    func testGetQueueStatistics() throws {
        let stats = taskScheduler.getQueueStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.highPriorityCount, 0, "高优先级队列计数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.normalPriorityCount, 0, "普通优先级队列计数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.lowPriorityCount, 0, "低优先级队列计数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.backgroundCount, 0, "后台队列计数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.activeTaskCount, 0, "活跃任务计数应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.totalTaskCount, 0, "总任务计数应该不小于0")
    }
    
    func testTaskPriorityHandling() throws {
        let expectation = XCTestExpectation(description: "不同优先级任务执行")
        expectation.expectedFulfillmentCount = 4
        
        // 调度不同优先级的任务
        taskScheduler.scheduleTask(id: "urgent", priority: .urgent) {
            expectation.fulfill()
        }
        
        taskScheduler.scheduleTask(id: "high", priority: .high) {
            expectation.fulfill()
        }
        
        taskScheduler.scheduleTask(id: "normal", priority: .normal) {
            expectation.fulfill()
        }
        
        taskScheduler.scheduleTask(id: "low", priority: .low) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - PerformanceMonitor Tests
    
    func testPerformanceMonitorInitialization() throws {
        XCTAssertNotNil(performanceMonitor, "PerformanceMonitor应该能够正确初始化")
        XCTAssertNotNil(PerformanceOptimizer.PerformanceMonitor.shared, "PerformanceMonitor.shared应该存在")
        XCTAssertTrue(PerformanceOptimizer.PerformanceMonitor.shared === performanceMonitor, "应该是单例模式")
    }
    
    func testGetCPUUsage() throws {
        let cpuUsage = performanceMonitor.getCPUUsage()
        
        XCTAssertGreaterThanOrEqual(cpuUsage, 0.0, "CPU使用率应该不小于0")
        XCTAssertLessThanOrEqual(cpuUsage, 1.0, "CPU使用率应该不大于1")
    }
    
    func testGetMemoryUsage() throws {
        let memoryUsage = performanceMonitor.getMemoryUsage()
        
        XCTAssertGreaterThan(memoryUsage, 0, "内存使用应该大于0")
        XCTAssertLessThan(memoryUsage, 1024 * 1024 * 1024 * 8, "内存使用应该在合理范围内") // < 8GB
    }
    
    func testGetPerformanceStatistics() throws {
        // 先获取一些性能数据
        _ = performanceMonitor.getCPUUsage()
        _ = performanceMonitor.getMemoryUsage()
        
        let stats = performanceMonitor.getPerformanceStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.averageCPUUsage, 0.0, "平均CPU使用率应该不小于0")
        XCTAssertLessThanOrEqual(stats.averageCPUUsage, 1.0, "平均CPU使用率应该不大于1")
        XCTAssertGreaterThanOrEqual(stats.maxCPUUsage, 0.0, "最大CPU使用率应该不小于0")
        XCTAssertLessThanOrEqual(stats.maxCPUUsage, 1.0, "最大CPU使用率应该不大于1")
        XCTAssertGreaterThanOrEqual(stats.averageMemoryUsage, 0, "平均内存使用应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.maxMemoryUsage, 0, "最大内存使用应该不小于0")
        XCTAssertGreaterThan(stats.sampleCount, 0, "样本数量应该大于0")
    }
    
    // MARK: - Integration Tests
    
    func testPerformanceOptimizationIntegration() throws {
        // 开始优化
        optimizer.startOptimization()
        
        // 等待一段时间让优化生效
        Thread.sleep(forTimeInterval: 1.5)
        
        // 获取性能报告
        let report = optimizer.getPerformanceReport()
        
        XCTAssertNotNil(report, "性能报告应该存在")
        XCTAssertGreaterThanOrEqual(report.cpuSavings.totalOptimizations, 0, "应该有优化记录")
        
        // 停止优化
        optimizer.stopOptimization()
    }
    
    func testConcurrentTaskExecution() throws {
        let expectation = XCTestExpectation(description: "并发任务执行")
        expectation.expectedFulfillmentCount = 10
        
        // 调度多个并发任务
        for i in 0..<10 {
            taskScheduler.scheduleTask(id: "concurrent_\(i)", priority: .normal) {
                Thread.sleep(forTimeInterval: 0.1) // 模拟工作
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThrottleWithHighFrequency() throws {
        let expectation = XCTestExpectation(description: "高频节流")
        var executionCount = 0
        
        // 高频调用节流函数
        for _ in 0..<100 {
            throttleManager.throttle(key: "high_freq", interval: 0.05) {
                executionCount += 1
                if executionCount == 1 {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(executionCount, 1, "高频调用应该只执行一次")
    }
    
    // MARK: - Performance Tests
    
    func testCPUOptimizationPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = cpuOptimizer.optimizeCPUUsage()
            }
        }
    }
    
    func testThrottlePerformance() throws {
        measure {
            for i in 0..<1000 {
                throttleManager.throttle(key: "perf_test_\(i)", interval: 0.01) {
                    // 空操作
                }
            }
        }
    }
    
    func testTaskSchedulingPerformance() throws {
        measure {
            for i in 0..<100 {
                taskScheduler.scheduleTask(id: "perf_\(i)", priority: .normal) {
                    // 空操作
                }
            }
        }
    }
}
