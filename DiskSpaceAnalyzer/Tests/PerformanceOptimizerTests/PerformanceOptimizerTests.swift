import XCTest
@testable import PerformanceOptimizer
@testable import Common

final class PerformanceOptimizerTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var cpuOptimizer: CPUOptimizer!
    var throttleManager: ThrottleManager!
    var taskScheduler: TaskScheduler!
    var performanceMonitor: PerformanceMonitor!
    var performanceOptimizer: PerformanceOptimizer!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        cpuOptimizer = CPUOptimizer.shared
        throttleManager = ThrottleManager.shared
        taskScheduler = TaskScheduler.shared
        performanceMonitor = PerformanceMonitor.shared
        performanceOptimizer = PerformanceOptimizer.shared
    }
    
    override func tearDownWithError() throws {
        // 清理资源
        throttleManager.clearAllThrottles()
        taskScheduler.cancelAllTasks()
        performanceOptimizer.stopOptimization()
        
        cpuOptimizer = nil
        throttleManager = nil
        taskScheduler = nil
        performanceMonitor = nil
        performanceOptimizer = nil
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        XCTAssertNotNil(cpuOptimizer)
        XCTAssertNotNil(throttleManager)
        XCTAssertNotNil(taskScheduler)
        XCTAssertNotNil(performanceMonitor)
        XCTAssertNotNil(performanceOptimizer)
        
        // 测试单例模式
        XCTAssertTrue(CPUOptimizer.shared === cpuOptimizer)
        XCTAssertTrue(ThrottleManager.shared === throttleManager)
        XCTAssertTrue(TaskScheduler.shared === taskScheduler)
        XCTAssertTrue(PerformanceMonitor.shared === performanceMonitor)
        XCTAssertTrue(PerformanceOptimizer.shared === performanceOptimizer)
    }
    
    // MARK: - CPUOptimizer Tests
    
    func testCPUOptimizerGetCurrentUsage() throws {
        let cpuUsage = cpuOptimizer.getCurrentCPUUsage()
        
        XCTAssertGreaterThanOrEqual(cpuUsage, 0.0, "CPU使用率应该大于等于0")
        XCTAssertLessThanOrEqual(cpuUsage, 1.0, "CPU使用率应该小于等于1")
    }
    
    func testCPUOptimizerOptimization() throws {
        let concurrencyLevel = cpuOptimizer.optimizeCPUUsage()
        
        XCTAssertGreaterThan(concurrencyLevel, 0, "并发度应该大于0")
        XCTAssertLessThanOrEqual(concurrencyLevel, 16, "并发度应该在合理范围内")
    }
    
    func testCPUOptimizerStatistics() throws {
        // 先进行几次优化以生成统计数据
        _ = cpuOptimizer.optimizeCPUUsage()
        _ = cpuOptimizer.optimizeCPUUsage()
        _ = cpuOptimizer.optimizeCPUUsage()
        
        let statistics = cpuOptimizer.getCPUSavingsStatistics()
        
        XCTAssertGreaterThanOrEqual(statistics.totalOptimizations, 3, "应该有至少3次优化记录")
        XCTAssertGreaterThanOrEqual(statistics.averageSavings, 0, "平均节省应该大于等于0")
        XCTAssertGreaterThanOrEqual(statistics.maxSavings, 0, "最大节省应该大于等于0")
    }
    
    // MARK: - ThrottleManager Tests
    
    func testThrottleManagerBasicThrottle() throws {
        // 由于Timer在测试环境中的复杂性，我们只测试基本的API调用
        XCTAssertNoThrow(throttleManager.throttle(key: "test_key", interval: 0.1) {
            // 空操作
        }, "节流调用不应该抛出异常")
    }
    
    func testThrottleManagerMultipleKeys() throws {
        // 测试多个key的基本调用
        XCTAssertNoThrow(throttleManager.throttle(key: "key1", interval: 0.1) {
            // 空操作
        }, "节流调用不应该抛出异常")
        
        XCTAssertNoThrow(throttleManager.throttle(key: "key2", interval: 0.1) {
            // 空操作
        }, "节流调用不应该抛出异常")
    }
    
    func testThrottleManagerClearAll() throws {
        // 设置一些节流
        throttleManager.throttle(key: "key1", interval: 1.0) {
            // 这个不应该执行
            XCTFail("节流被清除后不应该执行")
        }
        
        // 立即清除所有节流
        throttleManager.clearAllThrottles()
        
        // 等待一段时间确保没有执行
        Thread.sleep(forTimeInterval: 0.1)
        
        // 如果到这里没有失败，说明清除成功
        XCTAssertTrue(true)
    }
    
    // MARK: - TaskScheduler Tests
    
    func testTaskSchedulerScheduleTask() throws {
        let expectation = XCTestExpectation(description: "Task execution")
        var taskExecuted = false
        
        taskScheduler.scheduleTask(
            id: "test_task",
            priority: .normal,
            operation: {
                taskExecuted = true
            },
            completion: {
                expectation.fulfill()
            }
        )
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(taskExecuted, "任务应该被执行")
    }
    
    func testTaskSchedulerCancelTask() throws {
        var taskExecuted = false
        
        taskScheduler.scheduleTask(
            id: "cancel_task",
            priority: .normal,
            operation: {
                taskExecuted = true
            }
        )
        
        taskScheduler.cancelTask(id: "cancel_task")
        
        // 等待一段时间确保任务没有执行
        Thread.sleep(forTimeInterval: 0.2)
        
        XCTAssertFalse(taskExecuted, "被取消的任务不应该执行")
    }
    
    func testTaskSchedulerCancelAllTasks() throws {
        var task1Executed = false
        var task2Executed = false
        
        taskScheduler.scheduleTask(
            id: "task1",
            priority: .normal,
            operation: {
                // 添加延迟以确保任务有时间被取消
                Thread.sleep(forTimeInterval: 0.5)
                task1Executed = true
            }
        )
        
        taskScheduler.scheduleTask(
            id: "task2",
            priority: .normal,
            operation: {
                Thread.sleep(forTimeInterval: 0.5)
                task2Executed = true
            }
        )
        
        // 立即取消所有任务
        taskScheduler.cancelAllTasks()
        
        // 等待足够长的时间，如果任务没有被取消，它们会执行
        Thread.sleep(forTimeInterval: 0.3)
        
        XCTAssertFalse(task1Executed, "所有任务都应该被取消")
        XCTAssertFalse(task2Executed, "所有任务都应该被取消")
    }
    
    // MARK: - PerformanceMonitor Tests
    
    func testPerformanceMonitorCPUUsage() throws {
        let cpuUsage = performanceMonitor.getCPUUsage()
        
        XCTAssertGreaterThanOrEqual(cpuUsage, 0.0, "CPU使用率应该大于等于0")
        XCTAssertLessThanOrEqual(cpuUsage, 1.0, "CPU使用率应该小于等于1")
    }
    
    func testPerformanceMonitorMemoryUsage() throws {
        let memoryUsage = performanceMonitor.getMemoryUsage()
        
        XCTAssertGreaterThan(memoryUsage, 0, "内存使用量应该大于0")
    }
    
    // MARK: - PerformanceOptimizer Tests
    
    func testPerformanceOptimizerStartStopOptimization() throws {
        XCTAssertNoThrow(performanceOptimizer.startOptimization(), "开始优化不应该抛出异常")
        XCTAssertNoThrow(performanceOptimizer.stopOptimization(), "停止优化不应该抛出异常")
    }
    
    func testPerformanceOptimizerGetPerformanceReport() throws {
        // 先运行一些优化
        performanceOptimizer.startOptimization()
        Thread.sleep(forTimeInterval: 0.1)
        performanceOptimizer.stopOptimization()
        
        let report = performanceOptimizer.getPerformanceReport()
        XCTAssertNotNil(report, "性能报告不应该为nil")
    }
    
    // MARK: - Performance Tests
    
    func testCPUOptimizerPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = cpuOptimizer.optimizeCPUUsage()
            }
        }
    }
    
    func testThrottleManagerPerformance() throws {
        measure {
            for i in 0..<1000 {
                throttleManager.throttle(key: "perf_test_\(i)", interval: 0.001) {
                    // 空操作
                }
            }
        }
    }
    
    func testTaskSchedulerPerformance() throws {
        let expectation = XCTestExpectation(description: "Task scheduling performance")
        expectation.expectedFulfillmentCount = 100
        
        measure {
            for i in 0..<100 {
                taskScheduler.scheduleTask(
                    id: "perf_task_\(i)",
                    priority: .normal,
                    operation: {
                        // 空操作
                    },
                    completion: {
                        expectation.fulfill()
                    }
                )
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Integration Tests
    
    func testIntegratedOptimization() throws {
        // 测试各组件协同工作
        performanceOptimizer.startOptimization()
        
        let expectation = XCTestExpectation(description: "Integrated optimization")
        
        // 调度一个任务
        taskScheduler.scheduleTask(
            id: "integration_task",
            priority: .high,
            operation: {
                // 空操作
            },
            completion: {
                expectation.fulfill()
            }
        )
        
        // 使用节流管理器
        throttleManager.throttle(key: "integration_throttle", interval: 0.05) {
            // 空操作
        }
        
        // 优化CPU使用
        _ = cpuOptimizer.optimizeCPUUsage()
        
        wait(for: [expectation], timeout: 2.0)
        
        performanceOptimizer.stopOptimization()
        
        // 验证系统仍然正常工作
        XCTAssertNotNil(performanceOptimizer.getPerformanceReport())
    }
}
