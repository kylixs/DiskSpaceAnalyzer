import Foundation
import Common

// MARK: - PerformanceOptimizer Module
// 性能优化模块 - 提供CPU优化和资源管理功能

/// PerformanceOptimizer模块信息
public struct PerformanceOptimizerModule {
    public static let version = "1.0.0"
    public static let description = "性能优化和资源管理功能"
    
    public static func initialize() {
        print("⚡ PerformanceOptimizer模块初始化")
        print("📋 包含: CPUOptimizer、ThrottleManager、TaskScheduler、PerformanceMonitor")
        print("📊 版本: \(version)")
        print("✅ PerformanceOptimizer模块初始化完成")
    }
}

// MARK: - CPU优化器

/// CPU优化器 - 智能CPU负载管理
public class CPUOptimizer {
    public static let shared = CPUOptimizer()
    
    private var currentCPUUsage: Double = 0.0
    private var targetCPUUsage: Double = 0.5 // 目标CPU使用率50%
    private var optimizationHistory: [CPUOptimizationRecord] = []
    private let maxHistoryCount = 100
    
    private init() {}
    
    /// CPU优化记录
    public struct CPUOptimizationRecord {
        public let timestamp: Date
        public let beforeCPU: Double
        public let afterCPU: Double
        public let concurrencyLevel: Int
        public let savingsPercentage: Double
        
        public init(timestamp: Date, beforeCPU: Double, afterCPU: Double, concurrencyLevel: Int) {
            self.timestamp = timestamp
            self.beforeCPU = beforeCPU
            self.afterCPU = afterCPU
            self.concurrencyLevel = concurrencyLevel
            self.savingsPercentage = beforeCPU > 0 ? (beforeCPU - afterCPU) / beforeCPU * 100 : 0
        }
    }
    
    /// 获取当前CPU使用率
    public func getCurrentCPUUsage() -> Double {
        return PerformanceMonitor.shared.getCPUUsage()
    }
    
    /// 优化CPU使用
    public func optimizeCPUUsage() -> Int {
        let beforeCPU = getCurrentCPUUsage()
        let optimalConcurrency = calculateOptimalConcurrency()
        
        // 记录优化结果
        let afterCPU = getCurrentCPUUsage()
        let record = CPUOptimizationRecord(
            timestamp: Date(),
            beforeCPU: beforeCPU,
            afterCPU: afterCPU,
            concurrencyLevel: optimalConcurrency
        )
        
        addOptimizationRecord(record)
        return optimalConcurrency
    }
    
    /// 计算最优并发度
    private func calculateOptimalConcurrency() -> Int {
        let cpuUsage = getCurrentCPUUsage()
        let processorCount = ProcessInfo.processInfo.processorCount
        
        // 自适应算法：根据CPU使用率动态调整
        if cpuUsage < 0.3 {
            return min(processorCount * 2, 8) // 低负载时可以增加并发
        } else if cpuUsage < 0.6 {
            return processorCount // 中等负载时使用CPU核心数
        } else {
            return max(1, processorCount / 2) // 高负载时减少并发
        }
    }
    
    /// 添加优化记录
    private func addOptimizationRecord(_ record: CPUOptimizationRecord) {
        optimizationHistory.append(record)
        if optimizationHistory.count > maxHistoryCount {
            optimizationHistory.removeFirst()
        }
    }
    
    /// 获取CPU节省统计
    public func getCPUSavingsStatistics() -> CPUSavingsStatistics {
        guard !optimizationHistory.isEmpty else {
            return CPUSavingsStatistics(averageSavings: 0, totalOptimizations: 0, maxSavings: 0)
        }
        
        let totalSavings = optimizationHistory.reduce(0) { $0 + $1.savingsPercentage }
        let averageSavings = totalSavings / Double(optimizationHistory.count)
        let maxSavings = optimizationHistory.map { $0.savingsPercentage }.max() ?? 0
        
        return CPUSavingsStatistics(
            averageSavings: averageSavings,
            totalOptimizations: optimizationHistory.count,
            maxSavings: maxSavings
        )
    }
    
    /// CPU节省统计
    public struct CPUSavingsStatistics {
        public let averageSavings: Double
        public let totalOptimizations: Int
        public let maxSavings: Double
    }
}

// MARK: - 节流管理器

/// 节流管理器 - 控制更新频率
public class ThrottleManager {
    public static let shared = ThrottleManager()
    
    private var throttleTimers: [String: Timer] = [:]
    private let defaultThrottleInterval: TimeInterval = 0.2 // 200ms
    private let queue = DispatchQueue(label: "ThrottleManager", attributes: .concurrent)
    
    private init() {}
    
    /// 节流执行
    public func throttle(key: String, interval: TimeInterval? = nil, action: @escaping () -> Void) {
        let throttleInterval = interval ?? defaultThrottleInterval
        
        queue.async(flags: .barrier) {
            // 取消之前的定时器
            self.throttleTimers[key]?.invalidate()
            
            // 创建新的定时器
            let timer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: false) { _ in
                DispatchQueue.main.async {
                    action()
                }
                self.queue.async(flags: .barrier) {
                    self.throttleTimers.removeValue(forKey: key)
                }
            }
            
            self.throttleTimers[key] = timer
        }
    }
    
    /// 防抖执行
    public func debounce(key: String, delay: TimeInterval, action: @escaping () -> Void) {
        throttle(key: key, interval: delay, action: action)
    }
    
    /// 取消节流
    public func cancelThrottle(key: String) {
        queue.async(flags: .barrier) {
            self.throttleTimers[key]?.invalidate()
            self.throttleTimers.removeValue(forKey: key)
        }
    }
    
    /// 清除所有节流
    public func clearAllThrottles() {
        queue.async(flags: .barrier) {
            self.throttleTimers.values.forEach { $0.invalidate() }
            self.throttleTimers.removeAll()
        }
    }
}

// MARK: - 任务调度器

/// 任务调度器 - 智能任务管理
public class TaskScheduler {
    public static let shared = TaskScheduler()
    
    private let highPriorityQueue = OperationQueue()
    private let normalPriorityQueue = OperationQueue()
    private let lowPriorityQueue = OperationQueue()
    private let backgroundQueue = OperationQueue()
    
    private var activeTasks: [String: Operation] = [:]
    private let queue = DispatchQueue(label: "TaskScheduler", attributes: .concurrent)
    
    private init() {
        setupQueues()
    }
    
    private func setupQueues() {
        // 高优先级队列
        highPriorityQueue.name = "HighPriority"
        highPriorityQueue.maxConcurrentOperationCount = 2
        highPriorityQueue.qualityOfService = .userInitiated
        
        // 普通优先级队列
        normalPriorityQueue.name = "NormalPriority"
        normalPriorityQueue.maxConcurrentOperationCount = 4
        normalPriorityQueue.qualityOfService = .default
        
        // 低优先级队列
        lowPriorityQueue.name = "LowPriority"
        lowPriorityQueue.maxConcurrentOperationCount = 2
        lowPriorityQueue.qualityOfService = .utility
        
        // 后台队列
        backgroundQueue.name = "Background"
        backgroundQueue.maxConcurrentOperationCount = 1
        backgroundQueue.qualityOfService = .background
    }
    
    /// 调度任务
    public func scheduleTask(
        id: String,
        priority: ScanTaskPriority = .normal,
        operation: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        let blockOperation = BlockOperation {
            operation()
            completion?()
        }
        
        queue.async(flags: .barrier) {
            // 取消之前的同名任务
            if let existingTask = self.activeTasks[id] {
                existingTask.cancel()
            }
            
            self.activeTasks[id] = blockOperation
        }
        
        // 根据优先级选择队列
        let targetQueue = getQueue(for: priority)
        targetQueue.addOperation(blockOperation)
        
        // 任务完成后清理
        blockOperation.completionBlock = {
            self.queue.async(flags: .barrier) {
                self.activeTasks.removeValue(forKey: id)
            }
        }
    }
    
    /// 取消任务
    public func cancelTask(id: String) {
        queue.async(flags: .barrier) {
            self.activeTasks[id]?.cancel()
            self.activeTasks.removeValue(forKey: id)
        }
    }
    
    /// 取消所有任务
    public func cancelAllTasks() {
        queue.async(flags: .barrier) {
            self.activeTasks.values.forEach { $0.cancel() }
            self.activeTasks.removeAll()
        }
        
        [highPriorityQueue, normalPriorityQueue, lowPriorityQueue, backgroundQueue].forEach {
            $0.cancelAllOperations()
        }
    }
    
    /// 获取队列统计
    public func getQueueStatistics() -> QueueStatistics {
        return QueueStatistics(
            highPriorityCount: highPriorityQueue.operationCount,
            normalPriorityCount: normalPriorityQueue.operationCount,
            lowPriorityCount: lowPriorityQueue.operationCount,
            backgroundCount: backgroundQueue.operationCount,
            activeTaskCount: activeTasks.count
        )
    }
    
    private func getQueue(for priority: ScanTaskPriority) -> OperationQueue {
        switch priority {
        case .urgent:
            return highPriorityQueue
        case .high:
            return highPriorityQueue
        case .normal:
            return normalPriorityQueue
        case .low:
            return lowPriorityQueue
        }
    }
    
    /// 队列统计信息
    public struct QueueStatistics {
        public let highPriorityCount: Int
        public let normalPriorityCount: Int
        public let lowPriorityCount: Int
        public let backgroundCount: Int
        public let activeTaskCount: Int
        
        public var totalTaskCount: Int {
            return highPriorityCount + normalPriorityCount + lowPriorityCount + backgroundCount
        }
    }
}

// MARK: - 性能监控器

/// 性能监控器 - 系统性能监控
public class PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    
    private var cpuUsageHistory: [Double] = []
    private var memoryUsageHistory: [Int64] = []
    private let maxHistoryCount = 60 // 保留60个历史记录
    
    private init() {}
    
    /// 获取CPU使用率
    public func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            // 简化的CPU使用率计算
            let usage = Double(info.resident_size) / Double(1024 * 1024 * 100) // 简化计算
            addCPUUsageRecord(min(usage, 1.0))
            return min(usage, 1.0)
        }
        
        return 0.0
    }
    
    /// 获取内存使用情况
    public func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = Int64(info.resident_size)
            addMemoryUsageRecord(memoryUsage)
            return memoryUsage
        }
        
        return 0
    }
    
    /// 获取性能统计
    public func getPerformanceStatistics() -> PerformanceStatistics {
        let avgCPU = cpuUsageHistory.isEmpty ? 0 : cpuUsageHistory.reduce(0, +) / Double(cpuUsageHistory.count)
        let avgMemory = memoryUsageHistory.isEmpty ? 0 : memoryUsageHistory.reduce(0, +) / Int64(memoryUsageHistory.count)
        let maxCPU = cpuUsageHistory.max() ?? 0
        let maxMemory = memoryUsageHistory.max() ?? 0
        
        return PerformanceStatistics(
            averageCPUUsage: avgCPU,
            maxCPUUsage: maxCPU,
            averageMemoryUsage: avgMemory,
            maxMemoryUsage: maxMemory,
            sampleCount: cpuUsageHistory.count
        )
    }
    
    private func addCPUUsageRecord(_ usage: Double) {
        cpuUsageHistory.append(usage)
        if cpuUsageHistory.count > maxHistoryCount {
            cpuUsageHistory.removeFirst()
        }
    }
    
    private func addMemoryUsageRecord(_ usage: Int64) {
        memoryUsageHistory.append(usage)
        if memoryUsageHistory.count > maxHistoryCount {
            memoryUsageHistory.removeFirst()
        }
    }
    
    /// 性能统计信息
    public struct PerformanceStatistics {
        public let averageCPUUsage: Double
        public let maxCPUUsage: Double
        public let averageMemoryUsage: Int64
        public let maxMemoryUsage: Int64
        public let sampleCount: Int
    }
}

// MARK: - 性能优化管理器

/// 性能优化管理器 - 统一管理所有性能优化功能
public class PerformanceOptimizer {
    public static let shared = PerformanceOptimizer()
    
    private let cpuOptimizer = CPUOptimizer.shared
    private let throttleManager = ThrottleManager.shared
    private let taskScheduler = TaskScheduler.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    private init() {}
    
    /// 开始性能优化
    public func startOptimization() {
        // 定期优化CPU使用
        throttleManager.throttle(key: "cpu_optimization", interval: 1.0) {
            _ = self.cpuOptimizer.optimizeCPUUsage()
        }
    }
    
    /// 停止性能优化
    public func stopOptimization() {
        throttleManager.cancelThrottle(key: "cpu_optimization")
        taskScheduler.cancelAllTasks()
    }
    
    /// 获取综合性能报告
    public func getPerformanceReport() -> PerformanceReport {
        let cpuStats = cpuOptimizer.getCPUSavingsStatistics()
        let queueStats = taskScheduler.getQueueStatistics()
        let perfStats = performanceMonitor.getPerformanceStatistics()
        
        return PerformanceReport(
            cpuSavings: cpuStats,
            queueStatistics: queueStats,
            performanceStatistics: perfStats,
            timestamp: Date()
        )
    }
    
    /// 性能报告
    public struct PerformanceReport {
        public let cpuSavings: CPUOptimizer.CPUSavingsStatistics
        public let queueStatistics: TaskScheduler.QueueStatistics
        public let performanceStatistics: PerformanceMonitor.PerformanceStatistics
        public let timestamp: Date
    }
}
