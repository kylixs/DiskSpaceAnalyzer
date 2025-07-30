import Foundation
import Dispatch
/// 扫描任务状态
public enum ScanTaskStatus {
    case pending    // 等待执行
    case running    // 正在执行
    case paused     // 已暂停
    case completed  // 已完成
    case cancelled  // 已取消
    case failed     // 执行失败
}

/// 扫描任务
public class ScanTask {
    public let id: String
    public let rootPath: String
    public let priority: ScanTaskPriority
    public let configuration: ScanConfiguration
    public let createdAt: Date
    
    public private(set) var status: ScanTaskStatus = .pending
    public private(set) var startedAt: Date?
    public private(set) var completedAt: Date?
    public private(set) var error: Error?
    public private(set) var progress: Double = 0.0
    
    /// 文件系统扫描器
    public let scanner: FileSystemScanner
    
    /// 进度管理器
    public let progressManager: ScanProgressManager
    
    /// 文件过滤器
    public let fileFilter: FileFilter
    
    /// 任务回调
    public var completionCallback: ((ScanTask) -> Void)?
    public var progressCallback: ((ScanTask, Double) -> Void)?
    public var errorCallback: ((ScanTask, Error) -> Void)?
    
    private let statusLock = NSLock()
    
    public init(id: String = UUID().uuidString, rootPath: String, priority: ScanTaskPriority = .normal, configuration: ScanConfiguration = ScanConfiguration()) {
        self.id = id
        self.rootPath = rootPath
        self.priority = priority
        self.configuration = configuration
        self.createdAt = Date()
        
        self.scanner = FileSystemScanner(configuration: configuration)
        self.progressManager = ScanProgressManager()
        self.fileFilter = FileFilter()
        
        setupCallbacks()
    }
    
    /// 更新任务状态
    internal func updateStatus(_ newStatus: ScanTaskStatus, error: Error? = nil) {
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
    
    /// 更新进度
    internal func updateProgress(_ newProgress: Double) {
        statusLock.lock()
        defer { statusLock.unlock() }
        
        self.progress = max(0.0, min(1.0, newProgress))
        progressCallback?(self, self.progress)
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
    
    private func setupCallbacks() {
        // 设置扫描器回调
        scanner.stateChangeCallback = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .scanning:
                self.updateStatus(.running)
            case .completed:
                self.updateStatus(.completed)
                self.completionCallback?(self)
            case .cancelled:
                self.updateStatus(.cancelled)
            case .error:
                self.updateStatus(.failed)
            default:
                break
            }
        }
        
        scanner.progressCallback = { [weak self] statistics in
            guard let self = self else { return }
            self.updateProgress(statistics.progress)
        }
        
        scanner.errorCallback = { [weak self] error in
            guard let self = self else { return }
            self.errorCallback?(self, error)
        }
    }
}

/// 任务管理统计信息
public struct TaskManagerStatistics {
    public let totalTasks: Int
    public let pendingTasks: Int
    public let runningTasks: Int
    public let completedTasks: Int
    public let cancelledTasks: Int
    public let failedTasks: Int
    public let averageExecutionTime: TimeInterval
    public let averageWaitTime: TimeInterval
    public let throughput: Double  // 任务/小时
    
    public init(totalTasks: Int, pendingTasks: Int, runningTasks: Int, completedTasks: Int, cancelledTasks: Int, failedTasks: Int, averageExecutionTime: TimeInterval, averageWaitTime: TimeInterval, throughput: Double) {
        self.totalTasks = totalTasks
        self.pendingTasks = pendingTasks
        self.runningTasks = runningTasks
        self.completedTasks = completedTasks
        self.cancelledTasks = cancelledTasks
        self.failedTasks = failedTasks
        self.averageExecutionTime = averageExecutionTime
        self.averageWaitTime = averageWaitTime
        self.throughput = throughput
    }
}

/// 扫描任务管理器 - 管理扫描任务的生命周期
public class ScanTaskManager {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ScanTaskManager()
    
    /// 任务队列（按优先级分组）
    private var taskQueues: [ScanTaskPriority: [ScanTask]] = [:]
    
    /// 所有任务字典
    private var allTasks: [String: ScanTask] = [:]
    
    /// 正在运行的任务
    private var runningTasks: Set<String> = []
    
    /// 任务管理队列
    private let managerQueue = DispatchQueue(label: "ScanTaskManager", qos: .userInitiated)
    
    /// 执行队列
    private let executionQueue = OperationQueue()
    
    /// 访问锁
    private let accessLock = NSLock()
    
    /// 最大并发任务数
    public var maxConcurrentTasks: Int = 2 {
        didSet {
            executionQueue.maxConcurrentOperationCount = maxConcurrentTasks
        }
    }
    
    /// 是否启用任务调度
    public var isSchedulingEnabled: Bool = true
    
    /// 任务完成回调
    public var taskCompletionCallback: ((ScanTask) -> Void)?
    
    /// 任务失败回调
    public var taskFailureCallback: ((ScanTask, Error) -> Void)?
    
    /// 任务进度回调
    public var taskProgressCallback: ((ScanTask, Double) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupExecutionQueue()
        startTaskScheduling()
    }
    
    // MARK: - Public Methods
    
    /// 添加扫描任务
    public func addScanTask(_ task: ScanTask) {
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
        
        // 设置任务回调
        setupTaskCallbacks(task)
        
        // 触发调度
        scheduleNextTasks()
    }
    
    /// 创建并添加扫描任务
    public func createScanTask(rootPath: String, priority: ScanTaskPriority = .normal, configuration: ScanConfiguration = ScanConfiguration()) -> String {
        let task = ScanTask(rootPath: rootPath, priority: priority, configuration: configuration)
        addScanTask(task)
        return task.id
    }
    
    /// 暂停任务
    public func pauseTask(id: String) -> Bool {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let task = allTasks[id], task.status == .running else { return false }
        
        task.scanner.pauseScan()
        task.updateStatus(.paused)
        return true
    }
    
    /// 恢复任务
    public func resumeTask(id: String) -> Bool {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let task = allTasks[id], task.status == .paused else { return false }
        
        task.scanner.resumeScan()
        task.updateStatus(.running)
        return true
    }
    
    /// 取消任务
    public func cancelTask(id: String) -> Bool {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let task = allTasks[id] else { return false }
        
        if runningTasks.contains(id) {
            task.scanner.cancelScan()
        } else {
            // 从队列中移除
            if let queue = taskQueues[task.priority] {
                taskQueues[task.priority] = queue.filter { $0.id != id }
            }
            task.updateStatus(.cancelled)
        }
        
        return true
    }
    
    /// 获取任务
    public func getTask(id: String) -> ScanTask? {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return allTasks[id]
    }
    
    /// 获取所有任务
    public func getAllTasks() -> [ScanTask] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return Array(allTasks.values)
    }
    
    /// 获取指定状态的任务
    public func getTasks(withStatus status: ScanTaskStatus) -> [ScanTask] {
        return getAllTasks().filter { $0.status == status }
    }
    
    /// 获取指定优先级的任务
    public func getTasks(withPriority priority: ScanTaskPriority) -> [ScanTask] {
        return getAllTasks().filter { $0.priority == priority }
    }
    
    /// 获取任务管理统计信息
    public func getStatistics() -> TaskManagerStatistics {
        let allTasksList = getAllTasks()
        
        let totalTasks = allTasksList.count
        let pendingTasks = allTasksList.filter { $0.status == .pending }.count
        let runningTasks = allTasksList.filter { $0.status == .running }.count
        let completedTasks = allTasksList.filter { $0.status == .completed }.count
        let cancelledTasks = allTasksList.filter { $0.status == .cancelled }.count
        let failedTasks = allTasksList.filter { $0.status == .failed }.count
        
        // 计算平均执行时间
        let executionTimes = allTasksList.compactMap { $0.executionDuration }
        let averageExecutionTime = executionTimes.isEmpty ? 0 : executionTimes.reduce(0, +) / Double(executionTimes.count)
        
        // 计算平均等待时间
        let waitTimes = allTasksList.map { $0.waitingDuration }
        let averageWaitTime = waitTimes.isEmpty ? 0 : waitTimes.reduce(0, +) / Double(waitTimes.count)
        
        // 计算吞吐量（任务/小时）
        let completedInLastHour = allTasksList.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return Date().timeIntervalSince(completedAt) <= 3600
        }.count
        let throughput = Double(completedInLastHour)
        
        return TaskManagerStatistics(
            totalTasks: totalTasks,
            pendingTasks: pendingTasks,
            runningTasks: runningTasks,
            completedTasks: completedTasks,
            cancelledTasks: cancelledTasks,
            failedTasks: failedTasks,
            averageExecutionTime: averageExecutionTime,
            averageWaitTime: averageWaitTime,
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
        for priority in ScanTaskPriority.allCases {
            taskQueues[priority] = taskQueues[priority]?.filter { !completedTaskIds.contains($0.id) }
        }
    }
    
    /// 暂停所有任务调度
    public func pauseScheduling() {
        isSchedulingEnabled = false
    }
    
    /// 恢复任务调度
    public func resumeScheduling() {
        isSchedulingEnabled = true
        scheduleNextTasks()
    }
    
    // MARK: - Private Methods
    
    /// 设置执行队列
    private func setupExecutionQueue() {
        executionQueue.name = "ScanTaskManager.ExecutionQueue"
        executionQueue.qualityOfService = .userInitiated
        executionQueue.maxConcurrentOperationCount = maxConcurrentTasks
    }
    
    /// 开始任务调度
    private func startTaskScheduling() {
        managerQueue.async { [weak self] in
            self?.schedulingLoop()
        }
    }
    
    /// 调度循环
    private func schedulingLoop() {
        while true {
            if isSchedulingEnabled {
                scheduleNextTasks()
            }
            
            // 每500ms检查一次
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// 调度下一批任务
    private func scheduleNextTasks() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        // 检查是否有可用的执行槽位
        guard runningTasks.count < maxConcurrentTasks else { return }
        
        // 按优先级从高到低处理
        for priority in ScanTaskPriority.allCases.reversed() {
            guard let queue = taskQueues[priority], !queue.isEmpty else { continue }
            
            // 找到待执行的任务
            let pendingTasks = queue.filter { $0.status == .pending }
            
            for task in pendingTasks {
                if runningTasks.count < maxConcurrentTasks {
                    executeTask(task)
                } else {
                    break
                }
            }
        }
    }
    
    /// 执行任务
    private func executeTask(_ task: ScanTask) {
        runningTasks.insert(task.id)
        
        executionQueue.addOperation { [weak self] in
            task.scanner.startScan(at: task.rootPath)
            
            // 任务完成后从运行集合中移除
            self?.accessLock.lock()
            self?.runningTasks.remove(task.id)
            self?.accessLock.unlock()
            
            // 触发下一轮调度
            self?.scheduleNextTasks()
        }
    }
    
    /// 设置任务回调
    private func setupTaskCallbacks(_ task: ScanTask) {
        task.completionCallback = { [weak self] completedTask in
            self?.taskCompletionCallback?(completedTask)
        }
        
        task.progressCallback = { [weak self] progressTask, progress in
            self?.taskProgressCallback?(progressTask, progress)
        }
        
        task.errorCallback = { [weak self] errorTask, error in
            self?.taskFailureCallback?(errorTask, error)
        }
    }
}

// MARK: - Extensions

extension ScanTaskManager {
    
    /// 导出任务管理报告
    public func exportTaskManagerReport() -> String {
        var report = "=== Scan Task Manager Report ===\n\n"
        
        let stats = getStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Scheduling Enabled: \(isSchedulingEnabled)\n"
        report += "Max Concurrent Tasks: \(maxConcurrentTasks)\n"
        report += "Currently Running: \(runningTasks.count)\n\n"
        
        report += "=== Statistics ===\n"
        report += "Total Tasks: \(stats.totalTasks)\n"
        report += "Pending Tasks: \(stats.pendingTasks)\n"
        report += "Running Tasks: \(stats.runningTasks)\n"
        report += "Completed Tasks: \(stats.completedTasks)\n"
        report += "Cancelled Tasks: \(stats.cancelledTasks)\n"
        report += "Failed Tasks: \(stats.failedTasks)\n"
        report += "Average Execution Time: \(String(format: "%.2f seconds", stats.averageExecutionTime))\n"
        report += "Average Wait Time: \(String(format: "%.2f seconds", stats.averageWaitTime))\n"
        report += "Throughput: \(String(format: "%.2f tasks/hour", stats.throughput))\n\n"
        
        // 按优先级分组的任务统计
        report += "=== Tasks by Priority ===\n"
        for priority in ScanTaskPriority.allCases.reversed() {
            let tasksForPriority = getTasks(withPriority: priority)
            report += "\(priority): \(tasksForPriority.count) tasks\n"
        }
        report += "\n"
        
        // 最近完成的任务
        let recentTasks = getAllTasks()
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
            .prefix(5)
        
        report += "=== Recent Completed Tasks ===\n"
        for task in recentTasks {
            let duration = task.executionDuration ?? 0
            report += "\(task.id) (\(task.priority)): \(task.rootPath) - \(String(format: "%.2fs", duration))\n"
        }
        
        return report
    }
}
