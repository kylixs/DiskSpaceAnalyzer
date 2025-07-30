import Foundation
import Dispatch

/// 节流类型
public enum ThrottleType {
    case leading    // 首次立即执行，后续节流
    case trailing   // 延迟执行，取最后一次
    case both       // 首次立即执行，最后一次延迟执行
}

/// 节流任务
public class ThrottleTask {
    public let id: String
    public let interval: TimeInterval
    public let type: ThrottleType
    public let action: () -> Void
    
    private var lastExecutionTime: Date?
    private var pendingWorkItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let lock = NSLock()
    
    public init(id: String, interval: TimeInterval, type: ThrottleType = .trailing, queue: DispatchQueue = .main, action: @escaping () -> Void) {
        self.id = id
        self.interval = interval
        self.type = type
        self.action = action
        self.queue = queue
    }
    
    /// 执行节流任务
    public func execute() {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        
        switch type {
        case .leading:
            executeLeading(at: now)
        case .trailing:
            executeTrailing(at: now)
        case .both:
            executeBoth(at: now)
        }
    }
    
    /// 取消待执行的任务
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }
    
    private func executeLeading(at now: Date) {
        if let lastTime = lastExecutionTime {
            let timeSinceLastExecution = now.timeIntervalSince(lastTime)
            if timeSinceLastExecution >= interval {
                performAction(at: now)
            }
        } else {
            performAction(at: now)
        }
    }
    
    private func executeTrailing(at now: Date) {
        // 取消之前的待执行任务
        pendingWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.performAction(at: Date())
        }
        
        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
    
    private func executeBoth(at now: Date) {
        if let lastTime = lastExecutionTime {
            let timeSinceLastExecution = now.timeIntervalSince(lastTime)
            if timeSinceLastExecution >= interval {
                // 立即执行
                performAction(at: now)
            } else {
                // 延迟执行
                executeTrailing(at: now)
            }
        } else {
            // 首次立即执行
            performAction(at: now)
        }
    }
    
    private func performAction(at time: Date) {
        lastExecutionTime = time
        action()
    }
}

/// 节流统计信息
public struct ThrottleStats {
    public let taskId: String
    public let totalCalls: Int
    public let actualExecutions: Int
    public let throttledCalls: Int
    public let throttleRate: Double
    public let averageInterval: TimeInterval
    public let lastExecutionTime: Date?
    
    public init(taskId: String, totalCalls: Int, actualExecutions: Int, throttledCalls: Int, throttleRate: Double, averageInterval: TimeInterval, lastExecutionTime: Date?) {
        self.taskId = taskId
        self.totalCalls = totalCalls
        self.actualExecutions = actualExecutions
        self.throttledCalls = throttledCalls
        self.throttleRate = throttleRate
        self.averageInterval = averageInterval
        self.lastExecutionTime = lastExecutionTime
    }
}

/// 节流管理器 - 实现200ms节流机制，优化更新频率
public class ThrottleManager {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ThrottleManager()
    
    /// 节流任务字典
    private var throttleTasks: [String: ThrottleTask] = [:]
    
    /// 统计信息
    private var statistics: [String: (totalCalls: Int, actualExecutions: Int, executionTimes: [Date])] = [:]
    
    /// 访问锁
    private let accessLock = NSLock()
    
    /// 默认节流间隔
    public let defaultThrottleInterval: TimeInterval = 0.2  // 200ms
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 注册节流任务
    public func registerThrottleTask(id: String, interval: TimeInterval? = nil, type: ThrottleType = .trailing, queue: DispatchQueue = .main, action: @escaping () -> Void) {
        let throttleInterval = interval ?? defaultThrottleInterval
        
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let task = ThrottleTask(id: id, interval: throttleInterval, type: type, queue: queue, action: action)
        throttleTasks[id] = task
        
        // 初始化统计信息
        if statistics[id] == nil {
            statistics[id] = (totalCalls: 0, actualExecutions: 0, executionTimes: [])
        }
    }
    
    /// 执行节流任务
    public func executeThrottledTask(id: String) {
        accessLock.lock()
        let task = throttleTasks[id]
        
        // 更新统计信息
        if var stats = statistics[id] {
            stats.totalCalls += 1
            statistics[id] = stats
        }
        
        accessLock.unlock()
        
        guard let throttleTask = task else {
            print("Warning: Throttle task with id '\(id)' not found")
            return
        }
        
        throttleTask.execute()
        
        // 记录执行时间
        recordExecution(for: id)
    }
    
    /// 取消节流任务
    public func cancelThrottleTask(id: String) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        throttleTasks[id]?.cancel()
    }
    
    /// 移除节流任务
    public func removeThrottleTask(id: String) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        throttleTasks[id]?.cancel()
        throttleTasks.removeValue(forKey: id)
        statistics.removeValue(forKey: id)
    }
    
    /// 获取节流统计信息
    public func getThrottleStats(for id: String) -> ThrottleStats? {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let stats = statistics[id] else { return nil }
        
        let throttledCalls = stats.totalCalls - stats.actualExecutions
        let throttleRate = stats.totalCalls > 0 ? Double(throttledCalls) / Double(stats.totalCalls) : 0.0
        
        // 计算平均执行间隔
        var averageInterval: TimeInterval = 0
        if stats.executionTimes.count > 1 {
            let intervals = zip(stats.executionTimes.dropFirst(), stats.executionTimes).map { $0.timeIntervalSince($1) }
            averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        }
        
        return ThrottleStats(
            taskId: id,
            totalCalls: stats.totalCalls,
            actualExecutions: stats.actualExecutions,
            throttledCalls: throttledCalls,
            throttleRate: throttleRate,
            averageInterval: averageInterval,
            lastExecutionTime: stats.executionTimes.last
        )
    }
    
    /// 获取所有任务的统计信息
    public func getAllThrottleStats() -> [ThrottleStats] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return statistics.keys.compactMap { getThrottleStats(for: $0) }
    }
    
    /// 清除统计信息
    public func clearStatistics() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        for key in statistics.keys {
            statistics[key] = (totalCalls: 0, actualExecutions: 0, executionTimes: [])
        }
    }
    
    /// 清除所有任务
    public func clearAllTasks() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        for task in throttleTasks.values {
            task.cancel()
        }
        
        throttleTasks.removeAll()
        statistics.removeAll()
    }
    
    // MARK: - Convenience Methods
    
    /// 节流执行闭包（一次性使用）
    public func throttle(id: String, interval: TimeInterval? = nil, type: ThrottleType = .trailing, action: @escaping () -> Void) {
        let throttleInterval = interval ?? defaultThrottleInterval
        
        // 如果任务不存在，先注册
        if throttleTasks[id] == nil {
            registerThrottleTask(id: id, interval: throttleInterval, type: type, action: action)
        }
        
        executeThrottledTask(id: id)
    }
    
    /// 防抖执行（debounce）
    public func debounce(id: String, interval: TimeInterval? = nil, action: @escaping () -> Void) {
        throttle(id: id, interval: interval, type: .trailing, action: action)
    }
    
    /// 立即执行一次，后续节流
    public func throttleLeading(id: String, interval: TimeInterval? = nil, action: @escaping () -> Void) {
        throttle(id: id, interval: interval, type: .leading, action: action)
    }
    
    // MARK: - Private Methods
    
    /// 记录执行时间
    private func recordExecution(for id: String) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard var stats = statistics[id] else { return }
        
        stats.actualExecutions += 1
        stats.executionTimes.append(Date())
        
        // 限制执行时间记录数量
        if stats.executionTimes.count > 100 {
            stats.executionTimes.removeFirst(stats.executionTimes.count - 100)
        }
        
        statistics[id] = stats
    }
}

// MARK: - Extensions

extension ThrottleManager {
    
    /// 导出节流统计报告
    public func exportThrottleReport() -> String {
        var report = "=== Throttle Manager Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Default Throttle Interval: \(defaultThrottleInterval * 1000)ms\n"
        report += "Active Tasks: \(throttleTasks.count)\n\n"
        
        let allStats = getAllThrottleStats()
        
        report += "=== Task Statistics ===\n"
        for stats in allStats.sorted(by: { $0.taskId < $1.taskId }) {
            report += "Task: \(stats.taskId)\n"
            report += "  Total Calls: \(stats.totalCalls)\n"
            report += "  Actual Executions: \(stats.actualExecutions)\n"
            report += "  Throttled Calls: \(stats.throttledCalls)\n"
            report += "  Throttle Rate: \(String(format: "%.2f%%", stats.throttleRate * 100))\n"
            report += "  Average Interval: \(String(format: "%.0fms", stats.averageInterval * 1000))\n"
            if let lastExecution = stats.lastExecutionTime {
                report += "  Last Execution: \(lastExecution)\n"
            }
            report += "\n"
        }
        
        // 总体统计
        let totalCalls = allStats.reduce(0) { $0 + $1.totalCalls }
        let totalExecutions = allStats.reduce(0) { $0 + $1.actualExecutions }
        let totalThrottled = totalCalls - totalExecutions
        let overallThrottleRate = totalCalls > 0 ? Double(totalThrottled) / Double(totalCalls) : 0.0
        
        report += "=== Overall Statistics ===\n"
        report += "Total Calls: \(totalCalls)\n"
        report += "Total Executions: \(totalExecutions)\n"
        report += "Total Throttled: \(totalThrottled)\n"
        report += "Overall Throttle Rate: \(String(format: "%.2f%%", overallThrottleRate * 100))\n"
        
        return report
    }
    
    /// 获取性能指标
    public func getPerformanceMetrics() -> [String: Any] {
        let allStats = getAllThrottleStats()
        
        let totalCalls = allStats.reduce(0) { $0 + $1.totalCalls }
        let totalExecutions = allStats.reduce(0) { $0 + $1.actualExecutions }
        let averageThrottleRate = allStats.isEmpty ? 0.0 : allStats.map { $0.throttleRate }.reduce(0, +) / Double(allStats.count)
        
        return [
            "activeTasks": throttleTasks.count,
            "totalCalls": totalCalls,
            "totalExecutions": totalExecutions,
            "averageThrottleRate": averageThrottleRate,
            "defaultInterval": defaultThrottleInterval,
            "performanceSavings": averageThrottleRate * 100  // 性能节省百分比
        ]
    }
}

// MARK: - Global Convenience Functions

/// 全局节流函数
public func throttle(id: String, interval: TimeInterval = 0.2, type: ThrottleType = .trailing, action: @escaping () -> Void) {
    ThrottleManager.shared.throttle(id: id, interval: interval, type: type, action: action)
}

/// 全局防抖函数
public func debounce(id: String, interval: TimeInterval = 0.2, action: @escaping () -> Void) {
    ThrottleManager.shared.debounce(id: id, interval: interval, action: action)
}

/// 全局立即节流函数
public func throttleLeading(id: String, interval: TimeInterval = 0.2, action: @escaping () -> Void) {
    ThrottleManager.shared.throttleLeading(id: id, interval: interval, action: action)
}
