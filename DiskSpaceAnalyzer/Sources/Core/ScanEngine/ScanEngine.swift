import Foundation

/// 扫描引擎模块 - 统一的文件系统扫描管理接口
public class ScanEngine {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ScanEngine()
    
    /// 文件系统扫描器
    public let fileSystemScanner: FileSystemScanner
    
    /// 进度管理器
    public let progressManager: ScanProgressManager
    
    /// 文件过滤器
    public let fileFilter: FileFilter
    
    /// 任务管理器
    public let taskManager: ScanTaskManager
    
    /// 扫描配置
    public struct ScanEngineConfiguration {
        public let maxConcurrency: Int
        public let followSymlinks: Bool
        public let includeHiddenFiles: Bool
        public let maxDepth: Int?
        public let enableProgressTracking: Bool
        public let enableFileFiltering: Bool
        public let updateInterval: TimeInterval
        
        public init(maxConcurrency: Int = 4, followSymlinks: Bool = false, includeHiddenFiles: Bool = false, maxDepth: Int? = nil, enableProgressTracking: Bool = true, enableFileFiltering: Bool = true, updateInterval: TimeInterval = 0.1) {
            self.maxConcurrency = maxConcurrency
            self.followSymlinks = followSymlinks
            self.includeHiddenFiles = includeHiddenFiles
            self.maxDepth = maxDepth
            self.enableProgressTracking = enableProgressTracking
            self.enableFileFiltering = enableFileFiltering
            self.updateInterval = updateInterval
        }
    }
    
    /// 当前配置
    private var configuration: ScanEngineConfiguration
    
    /// 扫描结果回调
    public var scanResultCallback: ((FileNode) -> Void)?
    
    /// 扫描完成回调
    public var scanCompletionCallback: ((ScanStatistics) -> Void)?
    
    /// 扫描错误回调
    public var scanErrorCallback: ((ScanError) -> Void)?
    
    /// 进度更新回调
    public var progressUpdateCallback: ((ProgressStatistics) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = ScanEngineConfiguration()
        
        let scanConfig = ScanConfiguration(
            maxConcurrency: configuration.maxConcurrency,
            followSymlinks: configuration.followSymlinks,
            includeHiddenFiles: configuration.includeHiddenFiles,
            maxDepth: configuration.maxDepth
        )
        
        self.fileSystemScanner = FileSystemScanner(configuration: scanConfig)
        self.progressManager = ScanProgressManager()
        self.fileFilter = FileFilter()
        self.taskManager = ScanTaskManager.shared
        
        setupIntegration()
    }
    
    // MARK: - Public Methods
    
    /// 配置扫描引擎
    public func configure(with config: ScanEngineConfiguration) {
        self.configuration = config
        
        // 更新扫描器配置
        let scanConfig = ScanConfiguration(
            maxConcurrency: config.maxConcurrency,
            followSymlinks: config.followSymlinks,
            includeHiddenFiles: config.includeHiddenFiles,
            maxDepth: config.maxDepth
        )
        fileSystemScanner.configuration = scanConfig
        
        // 更新任务管理器配置
        taskManager.maxConcurrentTasks = config.maxConcurrency
        
        // 更新进度管理器状态
        if config.enableProgressTracking {
            progressManager.isEnabled = true
        } else {
            progressManager.stopTracking()
        }
    }
    
    /// 开始扫描
    public func startScan(at rootPath: String, priority: ScanTaskPriority = .normal) -> String {
        let scanConfig = ScanConfiguration(
            maxConcurrency: configuration.maxConcurrency,
            followSymlinks: configuration.followSymlinks,
            includeHiddenFiles: configuration.includeHiddenFiles,
            maxDepth: configuration.maxDepth
        )
        
        let taskId = taskManager.createScanTask(
            rootPath: rootPath,
            priority: priority,
            configuration: scanConfig
        )
        
        // 如果启用进度跟踪，开始跟踪
        if configuration.enableProgressTracking {
            progressManager.startTracking()
        }
        
        return taskId
    }
    
    /// 暂停扫描
    public func pauseScan(taskId: String) -> Bool {
        return taskManager.pauseTask(id: taskId)
    }
    
    /// 恢复扫描
    public func resumeScan(taskId: String) -> Bool {
        return taskManager.resumeTask(id: taskId)
    }
    
    /// 取消扫描
    public func cancelScan(taskId: String) -> Bool {
        return taskManager.cancelTask(id: taskId)
    }
    
    /// 获取扫描任务
    public func getScanTask(id: String) -> ScanTask? {
        return taskManager.getTask(id: id)
    }
    
    /// 获取所有扫描任务
    public func getAllScanTasks() -> [ScanTask] {
        return taskManager.getAllTasks()
    }
    
    /// 获取正在运行的扫描任务
    public func getActiveScanTasks() -> [ScanTask] {
        return taskManager.getTasks(withStatus: .running)
    }
    
    /// 获取扫描统计信息
    public func getScanStatistics(for taskId: String) -> ScanStatistics? {
        guard let task = taskManager.getTask(id: taskId) else { return nil }
        return task.scanner.getStatistics()
    }
    
    /// 获取进度统计信息
    public func getProgressStatistics() -> ProgressStatistics? {
        return progressManager.getCurrentStatistics()
    }
    
    /// 获取过滤统计信息
    public func getFilterStatistics() -> FilterStatistics {
        return fileFilter.getStatistics()
    }
    
    /// 获取任务管理统计信息
    public func getTaskManagerStatistics() -> TaskManagerStatistics {
        return taskManager.getStatistics()
    }
    
    /// 添加文件过滤规则
    public func addFilterRule(_ rule: FilterRule) {
        fileFilter.addFilterRule(rule)
    }
    
    /// 移除文件过滤规则
    public func removeFilterRule(id: String) {
        fileFilter.removeFilterRule(id: id)
    }
    
    /// 获取所有过滤规则
    public func getAllFilterRules() -> [FilterRule] {
        return fileFilter.getAllFilterRules()
    }
    
    /// 清除已完成的任务
    public func clearCompletedTasks() {
        taskManager.clearCompletedTasks()
    }
    
    /// 重置所有统计信息
    public func resetStatistics() {
        fileFilter.resetStatistics()
        progressManager.clearHistory()
    }
    
    /// 获取综合扫描报告
    public func getComprehensiveReport() -> String {
        var report = "=== Scan Engine Comprehensive Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Configuration:\n"
        report += "  Max Concurrency: \(configuration.maxConcurrency)\n"
        report += "  Follow Symlinks: \(configuration.followSymlinks)\n"
        report += "  Include Hidden Files: \(configuration.includeHiddenFiles)\n"
        report += "  Max Depth: \(configuration.maxDepth?.description ?? "Unlimited")\n"
        report += "  Progress Tracking: \(configuration.enableProgressTracking)\n"
        report += "  File Filtering: \(configuration.enableFileFiltering)\n\n"
        
        // 任务管理统计
        let taskStats = getTaskManagerStatistics()
        report += "=== Task Management ===\n"
        report += "Total Tasks: \(taskStats.totalTasks)\n"
        report += "Running Tasks: \(taskStats.runningTasks)\n"
        report += "Completed Tasks: \(taskStats.completedTasks)\n"
        report += "Average Execution Time: \(String(format: "%.2f seconds", taskStats.averageExecutionTime))\n"
        report += "Throughput: \(String(format: "%.2f tasks/hour", taskStats.throughput))\n\n"
        
        // 过滤统计
        let filterStats = getFilterStatistics()
        report += "=== File Filtering ===\n"
        report += "Total Files Processed: \(filterStats.totalFilesProcessed)\n"
        report += "Files Included: \(filterStats.filesIncluded)\n"
        report += "Files Excluded: \(filterStats.filesExcluded)\n"
        report += "Filter Rate: \(String(format: "%.2f%%", filterStats.filterRate * 100))\n"
        report += "Zero Size Files Filtered: \(filterStats.zeroSizeFilesFiltered)\n"
        report += "Symbolic Links Filtered: \(filterStats.symbolicLinksFiltered)\n"
        report += "Hard Links Filtered: \(filterStats.hardLinksFiltered)\n\n"
        
        // 进度统计
        if let progressStats = getProgressStatistics() {
            report += "=== Progress Tracking ===\n"
            report += "Progress: \(String(format: "%.2f%%", progressStats.progressPercentage * 100))\n"
            report += "Processing Speed: \(String(format: "%.2f files/sec", progressStats.processingSpeed))\n"
            report += "Throughput: \(String(format: "%.2f MB/sec", progressStats.throughput / 1024 / 1024))\n"
            report += "Estimated Time Remaining: \(String(format: "%.2f seconds", progressStats.estimatedTimeRemaining))\n"
            report += "Elapsed Time: \(String(format: "%.2f seconds", progressStats.elapsedTime))\n\n"
        }
        
        return report
    }
    
    /// 导出完整日志
    public func exportFullLog() -> String {
        var log = "=== Scan Engine Full Log ===\n\n"
        
        log += getComprehensiveReport()
        log += "\n"
        
        log += taskManager.exportTaskManagerReport()
        log += "\n"
        
        log += fileFilter.exportFilterReport()
        log += "\n"
        
        log += progressManager.exportProgressReport()
        log += "\n"
        
        return log
    }
    
    // MARK: - Private Methods
    
    /// 设置组件间集成
    private func setupIntegration() {
        // 设置任务管理器回调
        taskManager.taskCompletionCallback = { [weak self] task in
            let statistics = task.scanner.getStatistics()
            self?.scanCompletionCallback?(statistics)
        }
        
        taskManager.taskFailureCallback = { [weak self] task, error in
            if let scanError = error as? ScanError {
                self?.scanErrorCallback?(scanError)
            }
        }
        
        taskManager.taskProgressCallback = { [weak self] task, progress in
            // 更新进度管理器
            let event = ProgressEvent(
                filesProcessed: task.scanner.getStatistics().scannedFiles,
                directoriesProcessed: task.scanner.getStatistics().scannedDirectories,
                bytesProcessed: task.scanner.getStatistics().scannedSize,
                currentPath: task.rootPath,
                estimatedTotalFiles: task.scanner.getStatistics().totalFiles
            )
            self?.progressManager.addProgressEvent(event)
        }
        
        // 设置进度管理器回调
        progressManager.progressUpdateCallback = { [weak self] statistics in
            self?.progressUpdateCallback?(statistics)
        }
        
        // 设置文件系统扫描器回调
        fileSystemScanner.fileDiscoveredCallback = { [weak self] fileNode in
            // 应用文件过滤
            if self?.configuration.enableFileFiltering == true {
                let filterResult = self?.fileFilter.filterFile(at: fileNode.path)
                if filterResult?.shouldInclude == true {
                    self?.scanResultCallback?(fileNode)
                }
            } else {
                self?.scanResultCallback?(fileNode)
            }
        }
        
        fileSystemScanner.errorCallback = { [weak self] error in
            self?.scanErrorCallback?(error)
        }
    }
}

// MARK: - Global Convenience Functions

/// 全局扫描启动函数
public func startFileScan(at rootPath: String, priority: ScanTaskPriority = .normal) -> String {
    return ScanEngine.shared.startScan(at: rootPath, priority: priority)
}

/// 全局扫描取消函数
public func cancelFileScan(taskId: String) -> Bool {
    return ScanEngine.shared.cancelScan(taskId: taskId)
}

/// 获取扫描进度
public func getScanProgress() -> ProgressStatistics? {
    return ScanEngine.shared.getProgressStatistics()
}
