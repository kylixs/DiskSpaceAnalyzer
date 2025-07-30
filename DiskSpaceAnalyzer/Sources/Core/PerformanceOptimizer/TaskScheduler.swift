import Foundation
import Dispatch

/// 任务优先级
public enum TaskPriority: Int, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var qosClass: DispatchQoS.QoSClass {
        switch self {
        case .low:
            return .background
        case .normal:
            return .default
        case .high:
            return .userInitiated
        case .critical:
            return .userInteractive
        }
    }
    
    public var operationQueueQoS: QualityOfService {
        switch self {
        case .low:
            return .background
        case .normal:
            return .default
        case .high:
            return .userInitiated
        case .critical:
            return .userInteractive
        }
    }
}

/// 任务状态
public enum TaskStatus {
    case pending    // 等待执行
    case running    // 正在执行
    case completed  // 已完成
    case cancelled  // 已取消
    case failed     // 执行失败
}

/// 调度任务
public class ScheduledTask {
    public let id: String
    public let priority: TaskPriority
    public let createdAt: Date
    public let estimatedDuration: TimeInterval?
    public let dependencies: [String]
    public let action: () throws -> Void
    
    public private(set) var status: TaskStatus = .pending
    public private(set) var startedAt: Date?
    public private(set) var completedAt: Date?
    public private(set) var error: Error?
    
    private let statusLock = NSLock()
    
    public init(id: String, priority: TaskPriority = .normal, estimatedDuration: TimeInterval? = nil, dependencies: [String] = [], action: @escaping () throws -> Void) {
        self.id = id
        self.priority = priority
        self.createdAt = Date()
        self.estimatedDuration = estimatedDuration
        self.dependencies = dependencies
        self.action = action
    }
    
    /// 更新任务状态
    internal func updateStatus(_ newStatus: TaskStatus, error: Error? = nil) {
        statusLock.lock()
        defer { statusLock.unlock() }
        
        self.status = newStatus
        self.error = error
        
        switch newStatus {
        case .running:
            startedAt = Date()
        case .completed, .cancelled, .failed:
            completedAt = Date()
        default:
            break
        }
    }
    
    /// 获取任务执行时长
    public var executionDuration: TimeInterval? {
        guard let startTime = startedAt else { return nil }
        let endTime = completedAt ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 获取任务等待时长
    public var waitingDuration: TimeInterval {
        let startTime = startedAt ?? Date()
        return startTime.timeIntervalSince(createdAt)
    }
}

/// 调度统计信息
public struct SchedulerStats {
    public let totalTasks: Int
    public let pendingTasks: Int
    public let runningTasks: Int
    public let completedTasks: Int
    public let cancelledTasks: Int
    public let failedTasks: Int
    public let averageWaitTime: TimeInterval
    public let averageExecutionTime: TimeInterval
    public let throughput: Double  // 任务/秒
    
    public init(totalTasks: Int, pendingTasks: Int, runningTasks: Int, completedTasks: Int, cancelledTasks: Int, failedTasks: Int, averageWaitTime: TimeInterval, averageExecutionTime: TimeInterval, throughput: Double) {
        self.totalTasks = totalTasks
        self.pendingTasks = pendingTasks
        self.runningTasks = runningTasks
        self.completedTasks = completedTasks
        self.cancelledTasks = cancelledTasks
        self.failedTasks = failedTasks
        self.averageWaitTime = averageWaitTime
        self.averageExecutionTime = averageExecutionTime
        self.throughput = throughput
    }
}

/// 任务调度器 - 智能任务调度系统，支持优先级和依赖管理
public class TaskScheduler {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = TaskScheduler()
    
    /// 任务队列（按优先级分组）
    private var taskQueues: [TaskPriority: [ScheduledTask]] = [:]
    
    /// 所有任务字典
    private var allTasks: [String: ScheduledTask] = [:]
    
    /// 正在运行的任务
    private var runningTasks: Set<String> = []
    
    /// 调度队列
    private let schedulerQueue = DispatchQueue(label: "TaskScheduler", qos: .userInitiated)
    
    /// 执行队列组
    private var executionQueues: [TaskPriority: OperationQueue] = [:]
    
    /// 访问锁
    private let accessLock = NSLock()
    
    /// 最大并发数
    public var maxConcurrentTasks: Int = 4 {
        didSet {
            updateConcurrencyLimits()
        }
    }
    
    /// 是否启用调度
    public var isSchedulingEnabled: Bool = true
    
    /// 任务完成回调
    public var taskCompletionCallback: ((ScheduledTask) -> Void)?
    
    /// 任务失败回调
    public var taskFailureCallback: ((ScheduledTask, Error) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupExecutionQueues()
        startScheduling()
    }
    
    // MARK: - Public Methods
    
    /// 添加任务
    public func addTask(_ task: ScheduledTask) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        // 检查任务ID是否已存在
        guard allTasks[task.id] == nil else {
            print("Warning: Task with id '\(task.id)' already exists")
            return
        }
        
        allTasks[task.id] = task
        
        // 添加到对应优先级队列
        if taskQueues[task.priority] == nil {
            taskQueues[task.priority] = []
        }
        taskQueues[task.priority]?.append(task)
        
        // 触发调度
        scheduleNextTasks()
    }
    
    /// 添加任务（便捷方法）
    public func addTask(id: String, priority: TaskPriority = .normal, estimatedDuration: TimeInterval? = nil, dependencies: [String] = [], action: @escaping () throws -> Void) {
        let task = ScheduledTask(id: id, priority: priority, estimatedDuration: estimatedDuration, dependencies: dependencies, action: action)
        addTask(task)
    }
    
    /// 取消任务
    public func cancelTask(id: String) -> Bool {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let task = allTasks[id] else { return false }
        
        // 如果任务正在运行，无法取消
        if runningTasks.contains(id) {
            return false
        }
        
        // 从队列中移除
        if let queue = taskQueues[task.priority] {
            taskQueues[task.priority] = queue.filter { $0.id != id }
        }
        
        task.updateStatus(.cancelled)
        return true
    }
    
    /// 获取任务状态
    public func getTaskStatus(id: String) -> TaskStatus? {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return allTasks[id]?.status
    }
    
    /// 获取任务
    public func getTask(id: String) -> ScheduledTask? {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return allTasks[id]
    }
    
    /// 获取所有任务
    public func getAllTasks() -> [ScheduledTask] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return Array(allTasks.values)
    }
    
    /// 获取指定状态的任务
    public func getTasks(withStatus status: TaskStatus) -> [ScheduledTask] {
        return getAllTasks().filter { $0.status == status }
    }
    
    /// 获取调度统计信息
    public func getSchedulerStats() -> SchedulerStats {
        let allTasksList = getAllTasks()
        
        let totalTasks = allTasksList.count
        let pendingTasks = allTasksList.filter { $0.status == .pending }.count
        let runningTasks = allTasksList.filter { $0.status == .running }.count
        let completedTasks = allTasksList.filter { $0.status == .completed }.count
        let cancelledTasks = allTasksList.filter { $0.status == .cancelled }.count
        let failedTasks = allTasksList.filter { $0.status == .failed }.count
        
        // 计算平均等待时间
        let waitTimes = allTasksList.compactMap { $0.waitingDuration }
        let averageWaitTime = waitTimes.isEmpty ? 0 : waitTimes.reduce(0, +) / Double(waitTimes.count)
        
        // 计算平均执行时间
        let executionTimes = allTasksList.compactMap { $0.executionDuration }
        let averageExecutionTime = executionTimes.isEmpty ? 0 : executionTimes.reduce(0, +) / Double(executionTimes.count)
        
        // 计算吞吐量
        let completedTasksInLastMinute = allTasksList.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Date().timeIntervalSince(completedAt) <= 60
        }.count
        let throughput = Double(completedTasksInLastMinute) / 60.0
        
        return SchedulerStats(
            totalTasks: totalTasks,
            pendingTasks: pendingTasks,
            runningTasks: runningTasks,
            completedTasks: completedTasks,
            cancelledTasks: cancelledTasks,
            failedTasks: failedTasks,
            averageWaitTime: averageWaitTime,
            averageExecutionTime: averageExecutionTime,
            throughput: throughput
        )
    }
    
    /// 清除已完成的任务
    public func clearCompletedTasks() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let completedTaskIds = allTasks.values.filter { 
            $0.status == .completed || $0.status == .cancelled || $0.status == .failed 
        }.map { $0.id }
        
        for taskId in completedTaskIds {
            allTasks.removeValue(forKey: taskId)
        }
        
        // 清理队列
        for priority in TaskPriority.allCases {
            taskQueues[priority] = taskQueues[priority]?.filter { !completedTaskIds.contains($0.id) }
        }
    }
    
    /// 暂停调度
    public func pauseScheduling() {
        isSchedulingEnabled = false
    }
    
    /// 恢复调度
    public func resumeScheduling() {
        isSchedulingEnabled = true
        scheduleNextTasks()
    }
    
    // MARK: - Private Methods
    
    /// 设置执行队列
    private func setupExecutionQueues() {
        for priority in TaskPriority.allCases {
            let queue = OperationQueue()
            queue.name = "TaskScheduler-\(priority)"
            queue.qualityOfService = priority.operationQueueQoS
            queue.maxConcurrentOperationCount = maxConcurrentTasks / TaskPriority.allCases.count
            executionQueues[priority] = queue
        }
    }
    
    /// 更新并发限制
    private func updateConcurrencyLimits() {
        let concurrencyPerPriority = max(1, maxConcurrentTasks / TaskPriority.allCases.count)
        
        for (priority, queue) in executionQueues {
            // 高优先级任务获得更多并发数
            let multiplier = priority == .critical ? 2 : (priority == .high ? 1.5 : 1.0)
            queue.maxConcurrentOperationCount = Int(Double(concurrencyPerPriority) * multiplier)
        }
    }
    
    /// 开始调度
    private func startScheduling() {
        schedulerQueue.async { [weak self] in
            self?.schedulingLoop()
        }
    }
    
    /// 调度循环
    private func schedulingLoop() {
        while true {
            if isSchedulingEnabled {
                scheduleNextTasks()
            }
            
            // 每100ms检查一次
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    
    /// 调度下一批任务
    private func scheduleNextTasks() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        // 按优先级从高到低处理
        for priority in TaskPriority.allCases.reversed() {
            guard let queue = taskQueues[priority], !queue.isEmpty else { continue }
            guard let executionQueue = executionQueues[priority] else { continue }
            
            // 找到可以执行的任务（依赖已满足）
            let readyTasks = queue.filter { task in
                task.status == .pending && areDependenciesSatisfied(task.dependencies)
            }
            
            // 执行准备好的任务
            for task in readyTasks {
                if runningTasks.count < maxConcurrentTasks {
                    executeTask(task, on: executionQueue)
                } else {
                    break  // 达到并发限制
                }
            }
        }
    }
    
    /// 检查依赖是否满足
    private func areDependenciesSatisfied(_ dependencies: [String]) -> Bool {
        for dependencyId in dependencies {
            guard let dependencyTask = allTasks[dependencyId] else { return false }
            if dependencyTask.status != .completed {
                return false
            }
        }
        return true
    }
    
    /// 执行任务
    private func executeTask(_ task: ScheduledTask, on queue: OperationQueue) {
        runningTasks.insert(task.id)
        task.updateStatus(.running)
        
        queue.addOperation { [weak self] in
            do {
                try task.action()
                task.updateStatus(.completed)
                self?.taskCompletionCallback?(task)
            } catch {
                task.updateStatus(.failed, error: error)
                self?.taskFailureCallback?(task, error)
            }
            
            self?.accessLock.lock()
            self?.runningTasks.remove(task.id)
            self?.accessLock.unlock()
            
            // 触发下一轮调度
            self?.scheduleNextTasks()
        }
    }
}

// MARK: - Extensions

extension TaskScheduler {
    
    /// 导出调度报告
    public func exportSchedulerReport() -> String {
        var report = "=== Task Scheduler Report ===\n\n"
        
        let stats = getSchedulerStats()
        
        report += "Generated: \(Date())\n"
        report += "Scheduling Enabled: \(isSchedulingEnabled)\n"
        report += "Max Concurrent Tasks: \(maxConcurrentTasks)\n\n"
        
        report += "=== Statistics ===\n"
        report += "Total Tasks: \(stats.totalTasks)\n"
        report += "Pending Tasks: \(stats.pendingTasks)\n"
        report += "Running Tasks: \(stats.runningTasks)\n"
        report += "Completed Tasks: \(stats.completedTasks)\n"
        report += "Cancelled Tasks: \(stats.cancelledTasks)\n"
        report += "Failed Tasks: \(stats.failedTasks)\n"
        report += "Average Wait Time: \(String(format: "%.2f seconds", stats.averageWaitTime))\n"
        report += "Average Execution Time: \(String(format: "%.2f seconds", stats.averageExecutionTime))\n"
        report += "Throughput: \(String(format: "%.2f tasks/second", stats.throughput))\n\n"
        
        // 按优先级分组的任务统计
        report += "=== Tasks by Priority ===\n"
        for priority in TaskPriority.allCases.reversed() {
            let tasksForPriority = getAllTasks().filter { $0.priority == priority }
            report += "\(priority): \(tasksForPriority.count) tasks\n"
        }
        report += "\n"
        
        // 最近完成的任务
        let recentTasks = getAllTasks()
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
            .prefix(10)
        
        report += "=== Recent Completed Tasks ===\n"
        for task in recentTasks {
            let duration = task.executionDuration ?? 0
            report += "\(task.id) (\(task.priority)): \(String(format: "%.2fs", duration))\n"
        }
        
        return report
    }
    
    /// 获取性能指标
    public func getPerformanceMetrics() -> [String: Any] {
        let stats = getSchedulerStats()
        
        return [
            "totalTasks": stats.totalTasks,
            "activeTasks": stats.pendingTasks + stats.runningTasks,
            "completionRate": stats.totalTasks > 0 ? Double(stats.completedTasks) / Double(stats.totalTasks) : 0.0,
            "averageWaitTime": stats.averageWaitTime,
            "averageExecutionTime": stats.averageExecutionTime,
            "throughput": stats.throughput,
            "concurrencyUtilization": Double(stats.runningTasks) / Double(maxConcurrentTasks)
        ]
    }
}

// MARK: - Global Convenience Functions

/// 全局任务调度函数
public func scheduleTask(id: String, priority: TaskPriority = .normal, dependencies: [String] = [], action: @escaping () throws -> Void) {
    TaskScheduler.shared.addTask(id: id, priority: priority, dependencies: dependencies, action: action)
}

/// 全局高优先级任务调度
public func scheduleHighPriorityTask(id: String, dependencies: [String] = [], action: @escaping () throws -> Void) {
    scheduleTask(id: id, priority: .high, dependencies: dependencies, action: action)
}

/// 全局关键任务调度
public func scheduleCriticalTask(id: String, dependencies: [String] = [], action: @escaping () throws -> Void) {
    scheduleTask(id: id, priority: .critical, dependencies: dependencies, action: action)
}
