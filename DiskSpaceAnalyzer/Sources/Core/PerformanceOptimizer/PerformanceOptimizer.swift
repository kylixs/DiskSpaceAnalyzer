import Foundation

/// 性能优化模块 - 统一的性能优化管理接口
public class PerformanceOptimizer {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = PerformanceOptimizer()
    
    /// CPU优化器
    public let cpuOptimizer: CPUOptimizer
    
    /// 节流管理器
    public let throttleManager: ThrottleManager
    
    /// 任务调度器
    public let taskScheduler: TaskScheduler
    
    /// 性能监控器
    public let performanceMonitor: PerformanceMonitor
    
    /// 是否启用全局优化
    public var isOptimizationEnabled: Bool = false {
        didSet {
            updateOptimizationState()
        }
    }
    
    /// 优化配置
    public struct OptimizationConfig {
        public let enableCPUOptimization: Bool
        public let enableThrottling: Bool
        public let enableTaskScheduling: Bool
        public let enablePerformanceMonitoring: Bool
        public let maxConcurrentTasks: Int
        public let throttleInterval: TimeInterval
        public let monitoringInterval: TimeInterval
        
        public init(enableCPUOptimization: Bool = true, enableThrottling: Bool = true, enableTaskScheduling: Bool = true, enablePerformanceMonitoring: Bool = true, maxConcurrentTasks: Int = 4, throttleInterval: TimeInterval = 0.2, monitoringInterval: TimeInterval = 1.0) {
            self.enableCPUOptimization = enableCPUOptimization
            self.enableThrottling = enableThrottling
            self.enableTaskScheduling = enableTaskScheduling
            self.enablePerformanceMonitoring = enablePerformanceMonitoring
            self.maxConcurrentTasks = maxConcurrentTasks
            self.throttleInterval = throttleInterval
            self.monitoringInterval = monitoringInterval
        }
    }
    
    /// 当前配置
    private var config: OptimizationConfig
    
    // MARK: - Initialization
    
    private init() {
        self.cpuOptimizer = CPUOptimizer.shared
        self.throttleManager = ThrottleManager.shared
        self.taskScheduler = TaskScheduler.shared
        self.performanceMonitor = PerformanceMonitor.shared
        self.config = OptimizationConfig()
        
        setupIntegration()
    }
    
    // MARK: - Public Methods
    
    /// 配置性能优化
    public func configure(with config: OptimizationConfig) {
        self.config = config
        
        // 应用配置
        taskScheduler.maxConcurrentTasks = config.maxConcurrentTasks
        performanceMonitor.monitoringInterval = config.monitoringInterval
        
        if isOptimizationEnabled {
            updateOptimizationState()
        }
    }
    
    /// 开始优化
    public func startOptimization() {
        isOptimizationEnabled = true
    }
    
    /// 停止优化
    public func stopOptimization() {
        isOptimizationEnabled = false
    }
    
    /// 获取综合性能报告
    public func getComprehensiveReport() -> String {
        var report = "=== Comprehensive Performance Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Optimization Enabled: \(isOptimizationEnabled)\n\n"
        
        // CPU优化报告
        if config.enableCPUOptimization {
            report += "=== CPU Optimization ===\n"
            if let cpuReport = cpuOptimizer.getOptimizationReport() {
                report += "CPU Savings: \(String(format: "%.2f%%", cpuReport.cpuSavings))\n"
                report += "Current Concurrency: \(cpuReport.optimizedConcurrency)\n"
                report += "Total Adjustments: \(cpuReport.totalAdjustments)\n"
            }
            report += "\n"
        }
        
        // 节流报告
        if config.enableThrottling {
            report += "=== Throttling Performance ===\n"
            let throttleMetrics = throttleManager.getPerformanceMetrics()
            report += "Active Tasks: \(throttleMetrics["activeTasks"] ?? 0)\n"
            report += "Performance Savings: \(String(format: "%.2f%%", (throttleMetrics["performanceSavings"] as? Double) ?? 0))\n"
            report += "\n"
        }
        
        // 任务调度报告
        if config.enableTaskScheduling {
            report += "=== Task Scheduling ===\n"
            let schedulerMetrics = taskScheduler.getPerformanceMetrics()
            report += "Total Tasks: \(schedulerMetrics["totalTasks"] ?? 0)\n"
            report += "Completion Rate: \(String(format: "%.2f%%", ((schedulerMetrics["completionRate"] as? Double) ?? 0) * 100))\n"
            report += "Throughput: \(String(format: "%.2f tasks/sec", (schedulerMetrics["throughput"] as? Double) ?? 0))\n"
            report += "\n"
        }
        
        // 性能监控报告
        if config.enablePerformanceMonitoring {
            report += "=== Performance Monitoring ===\n"
            let monitoringSummary = performanceMonitor.getPerformanceSummary()
            if let cpuUsage = monitoringSummary["cpuUsage"] as? Double {
                report += "Current CPU Usage: \(String(format: "%.2f%%", cpuUsage))\n"
            }
            if let memoryUsage = monitoringSummary["memoryUsage"] as? Double {
                report += "Current Memory Usage: \(String(format: "%.2f%%", memoryUsage))\n"
            }
            report += "Active Alerts: \(monitoringSummary["activeAlerts"] ?? 0)\n"
            report += "\n"
        }
        
        return report
    }
    
    /// 获取性能指标摘要
    public func getPerformanceMetrics() -> [String: Any] {
        var metrics: [String: Any] = [:]
        
        metrics["optimizationEnabled"] = isOptimizationEnabled
        
        if config.enableCPUOptimization {
            if let cpuReport = cpuOptimizer.getOptimizationReport() {
                metrics["cpuSavings"] = cpuReport.cpuSavings
                metrics["cpuConcurrency"] = cpuReport.optimizedConcurrency
            }
        }
        
        if config.enableThrottling {
            let throttleMetrics = throttleManager.getPerformanceMetrics()
            metrics["throttlePerformanceSavings"] = throttleMetrics["performanceSavings"]
        }
        
        if config.enableTaskScheduling {
            let schedulerMetrics = taskScheduler.getPerformanceMetrics()
            metrics["taskCompletionRate"] = schedulerMetrics["completionRate"]
            metrics["taskThroughput"] = schedulerMetrics["throughput"]
        }
        
        if config.enablePerformanceMonitoring {
            let monitoringSummary = performanceMonitor.getPerformanceSummary()
            metrics["currentCpuUsage"] = monitoringSummary["cpuUsage"]
            metrics["currentMemoryUsage"] = monitoringSummary["memoryUsage"]
            metrics["activeAlerts"] = monitoringSummary["activeAlerts"]
        }
        
        return metrics
    }
    
    /// 重置所有优化器
    public func resetAll() {
        cpuOptimizer.clearHistory()
        throttleManager.clearStatistics()
        taskScheduler.clearCompletedTasks()
        performanceMonitor.clearAllData()
    }
    
    /// 导出完整日志
    public func exportFullLog() -> String {
        var log = "=== Performance Optimizer Full Log ===\n\n"
        
        log += getComprehensiveReport()
        log += "\n"
        
        if config.enableCPUOptimization {
            log += cpuOptimizer.exportOptimizationLog()
            log += "\n"
        }
        
        if config.enableThrottling {
            log += throttleManager.exportThrottleReport()
            log += "\n"
        }
        
        if config.enableTaskScheduling {
            log += taskScheduler.exportSchedulerReport()
            log += "\n"
        }
        
        if config.enablePerformanceMonitoring {
            log += performanceMonitor.exportPerformanceReport()
            log += "\n"
        }
        
        return log
    }
    
    // MARK: - Private Methods
    
    /// 更新优化状态
    private func updateOptimizationState() {
        if isOptimizationEnabled {
            if config.enableCPUOptimization {
                cpuOptimizer.isOptimizationEnabled = true
            }
            
            if config.enableTaskScheduling {
                taskScheduler.resumeScheduling()
            }
            
            if config.enablePerformanceMonitoring {
                performanceMonitor.isMonitoringEnabled = true
            }
        } else {
            cpuOptimizer.isOptimizationEnabled = false
            taskScheduler.pauseScheduling()
            performanceMonitor.isMonitoringEnabled = false
        }
    }
    
    /// 设置组件间集成
    private func setupIntegration() {
        // CPU优化器回调 - 调整任务调度器并发度
        cpuOptimizer.optimizationCallback = { [weak self] newConcurrency in
            self?.taskScheduler.maxConcurrentTasks = newConcurrency
        }
        
        // 性能监控器警报回调 - 触发优化调整
        performanceMonitor.alertCallback = { [weak self] alert in
            self?.handlePerformanceAlert(alert)
        }
        
        // 任务调度器完成回调 - 记录性能指标
        taskScheduler.taskCompletionCallback = { [weak self] task in
            if let duration = task.executionDuration {
                self?.performanceMonitor.recordDataPoint(
                    metricName: "Task Execution Time",
                    value: duration,
                    unit: "seconds",
                    metadata: ["taskId": task.id, "priority": task.priority.rawValue]
                )
            }
        }
    }
    
    /// 处理性能警报
    private func handlePerformanceAlert(_ alert: PerformanceAlert) {
        switch alert.metricType {
        case .cpu:
            if alert.severity == .critical {
                // CPU使用率过高，降低并发度
                let currentConcurrency = taskScheduler.maxConcurrentTasks
                let newConcurrency = max(1, currentConcurrency - 1)
                taskScheduler.maxConcurrentTasks = newConcurrency
            }
            
        case .memory:
            if alert.severity == .critical {
                // 内存使用率过高，清理缓存
                throttleManager.clearStatistics()
                taskScheduler.clearCompletedTasks()
            }
            
        default:
            break
        }
    }
}

// MARK: - Global Convenience Functions

/// 全局性能优化启动
public func startPerformanceOptimization() {
    PerformanceOptimizer.shared.startOptimization()
}

/// 全局性能优化停止
public func stopPerformanceOptimization() {
    PerformanceOptimizer.shared.stopOptimization()
}

/// 获取性能指标
public func getPerformanceMetrics() -> [String: Any] {
    return PerformanceOptimizer.shared.getPerformanceMetrics()
}
