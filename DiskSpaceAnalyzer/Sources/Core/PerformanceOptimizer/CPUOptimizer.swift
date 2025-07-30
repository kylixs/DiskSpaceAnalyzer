import Foundation
import Darwin

/// CPU使用统计信息
public struct CPUUsageStats {
    public let userTime: Double
    public let systemTime: Double
    public let idleTime: Double
    public let totalUsage: Double
    public let timestamp: Date
    
    public init(userTime: Double, systemTime: Double, idleTime: Double, totalUsage: Double, timestamp: Date = Date()) {
        self.userTime = userTime
        self.systemTime = systemTime
        self.idleTime = idleTime
        self.totalUsage = totalUsage
        self.timestamp = timestamp
    }
}

/// CPU优化配置
public struct CPUOptimizationConfig {
    public let maxCPUUsage: Double          // 最大CPU使用率阈值
    public let minConcurrency: Int          // 最小并发数
    public let maxConcurrency: Int          // 最大并发数
    public let adaptiveThreshold: Double    // 自适应调整阈值
    public let monitoringInterval: TimeInterval  // 监控间隔
    
    public init(maxCPUUsage: Double = 0.8, minConcurrency: Int = 1, maxConcurrency: Int = 8, adaptiveThreshold: Double = 0.1, monitoringInterval: TimeInterval = 0.1) {
        self.maxCPUUsage = maxCPUUsage
        self.minConcurrency = minConcurrency
        self.maxConcurrency = maxConcurrency
        self.adaptiveThreshold = adaptiveThreshold
        self.monitoringInterval = monitoringInterval
    }
}

/// CPU优化报告
public struct CPUOptimizationReport {
    public let originalCPUUsage: Double
    public let optimizedCPUUsage: Double
    public let cpuSavings: Double
    public let originalConcurrency: Int
    public let optimizedConcurrency: Int
    public let optimizationDuration: TimeInterval
    public let totalAdjustments: Int
    
    public init(originalCPUUsage: Double, optimizedCPUUsage: Double, cpuSavings: Double, originalConcurrency: Int, optimizedConcurrency: Int, optimizationDuration: TimeInterval, totalAdjustments: Int) {
        self.originalCPUUsage = originalCPUUsage
        self.optimizedCPUUsage = optimizedCPUUsage
        self.cpuSavings = cpuSavings
        self.originalConcurrency = originalConcurrency
        self.optimizedConcurrency = optimizedConcurrency
        self.optimizationDuration = optimizationDuration
        self.totalAdjustments = totalAdjustments
    }
}

/// CPU优化器 - 智能CPU优化系统，动态调整系统负载
public class CPUOptimizer {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = CPUOptimizer()
    
    /// 优化配置
    private var config: CPUOptimizationConfig
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// CPU使用历史
    private var cpuUsageHistory: [CPUUsageStats] = []
    
    /// 历史数据锁
    private let historyLock = NSLock()
    
    /// 当前并发度
    private var currentConcurrency: Int
    
    /// 原始并发度
    private let originalConcurrency: Int
    
    /// 优化开始时间
    private var optimizationStartTime: Date?
    
    /// 调整次数
    private var adjustmentCount: Int = 0
    
    /// 自适应学习数据
    private var learningData: [(cpuUsage: Double, concurrency: Int, performance: Double)] = []
    
    /// 是否启用优化
    public var isOptimizationEnabled: Bool = false {
        didSet {
            if isOptimizationEnabled {
                startOptimization()
            } else {
                stopOptimization()
            }
        }
    }
    
    /// 优化回调
    public var optimizationCallback: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    private init(config: CPUOptimizationConfig = CPUOptimizationConfig()) {
        self.config = config
        self.currentConcurrency = config.maxConcurrency
        self.originalConcurrency = config.maxConcurrency
    }
    
    deinit {
        stopOptimization()
    }
    
    // MARK: - Public Methods
    
    /// 更新配置
    public func updateConfig(_ newConfig: CPUOptimizationConfig) {
        self.config = newConfig
        
        if isOptimizationEnabled {
            stopOptimization()
            startOptimization()
        }
    }
    
    /// 获取当前CPU使用率
    public func getCurrentCPUUsage() -> CPUUsageStats? {
        return getCPUUsage()
    }
    
    /// 获取CPU使用历史
    public func getCPUUsageHistory(limit: Int = 100) -> [CPUUsageStats] {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        let startIndex = max(0, cpuUsageHistory.count - limit)
        return Array(cpuUsageHistory[startIndex...])
    }
    
    /// 获取当前并发度
    public func getCurrentConcurrency() -> Int {
        return currentConcurrency
    }
    
    /// 获取优化报告
    public func getOptimizationReport() -> CPUOptimizationReport? {
        guard let startTime = optimizationStartTime else { return nil }
        
        let recentHistory = getCPUUsageHistory(limit: 10)
        guard !recentHistory.isEmpty else { return nil }
        
        let originalUsage = recentHistory.first?.totalUsage ?? 0.0
        let currentUsage = recentHistory.last?.totalUsage ?? 0.0
        let cpuSavings = max(0, (originalUsage - currentUsage) / originalUsage * 100)
        
        return CPUOptimizationReport(
            originalCPUUsage: originalUsage,
            optimizedCPUUsage: currentUsage,
            cpuSavings: cpuSavings,
            originalConcurrency: originalConcurrency,
            optimizedConcurrency: currentConcurrency,
            optimizationDuration: Date().timeIntervalSince(startTime),
            totalAdjustments: adjustmentCount
        )
    }
    
    /// 手动调整并发度
    public func adjustConcurrency(to newConcurrency: Int) {
        let clampedConcurrency = max(config.minConcurrency, min(config.maxConcurrency, newConcurrency))
        
        if clampedConcurrency != currentConcurrency {
            currentConcurrency = clampedConcurrency
            adjustmentCount += 1
            
            // 通知回调
            optimizationCallback?(currentConcurrency)
        }
    }
    
    /// 清除历史数据
    public func clearHistory() {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        cpuUsageHistory.removeAll()
        learningData.removeAll()
        adjustmentCount = 0
    }
    
    // MARK: - Private Methods
    
    /// 开始优化
    private func startOptimization() {
        guard monitoringTimer == nil else { return }
        
        optimizationStartTime = Date()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: config.monitoringInterval, repeats: true) { [weak self] _ in
            self?.performOptimizationCycle()
        }
    }
    
    /// 停止优化
    private func stopOptimization() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// 执行优化周期
    private func performOptimizationCycle() {
        guard let cpuStats = getCPUUsage() else { return }
        
        // 记录CPU使用历史
        recordCPUUsage(cpuStats)
        
        // 执行自适应调整
        performAdaptiveAdjustment(cpuStats)
    }
    
    /// 记录CPU使用情况
    private func recordCPUUsage(_ stats: CPUUsageStats) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        cpuUsageHistory.append(stats)
        
        // 限制历史数据大小
        if cpuUsageHistory.count > 1000 {
            cpuUsageHistory.removeFirst(cpuUsageHistory.count - 1000)
        }
    }
    
    /// 执行自适应调整
    private func performAdaptiveAdjustment(_ cpuStats: CPUUsageStats) {
        let targetConcurrency = calculateOptimalConcurrency(cpuStats)
        
        if abs(targetConcurrency - currentConcurrency) >= 1 {
            adjustConcurrency(to: targetConcurrency)
            
            // 记录学习数据
            recordLearningData(cpuUsage: cpuStats.totalUsage, concurrency: targetConcurrency)
        }
    }
    
    /// 计算最优并发度
    private func calculateOptimalConcurrency(_ cpuStats: CPUUsageStats) -> Int {
        let cpuUsage = cpuStats.totalUsage
        
        // 基于当前CPU使用率的基础调整
        var targetConcurrency = currentConcurrency
        
        if cpuUsage > config.maxCPUUsage {
            // CPU使用率过高，减少并发度
            targetConcurrency = max(config.minConcurrency, currentConcurrency - 1)
        } else if cpuUsage < config.maxCPUUsage - config.adaptiveThreshold {
            // CPU使用率较低，可以增加并发度
            targetConcurrency = min(config.maxConcurrency, currentConcurrency + 1)
        }
        
        // 应用自适应学习
        targetConcurrency = applyAdaptiveLearning(cpuUsage: cpuUsage, baseConcurrency: targetConcurrency)
        
        return targetConcurrency
    }
    
    /// 应用自适应学习
    private func applyAdaptiveLearning(cpuUsage: Double, baseConcurrency: Int) -> Int {
        guard learningData.count >= 5 else { return baseConcurrency }
        
        // 找到相似的CPU使用率情况
        let similarData = learningData.filter { abs($0.cpuUsage - cpuUsage) < 0.1 }
        
        if !similarData.isEmpty {
            // 计算平均最优并发度
            let avgConcurrency = similarData.map { $0.concurrency }.reduce(0, +) / similarData.count
            let avgPerformance = similarData.map { $0.performance }.reduce(0, +) / Double(similarData.count)
            
            // 如果历史数据显示更好的性能，采用历史建议
            if avgPerformance > 0.8 {  // 性能阈值
                return avgConcurrency
            }
        }
        
        return baseConcurrency
    }
    
    /// 记录学习数据
    private func recordLearningData(cpuUsage: Double, concurrency: Int) {
        // 计算性能指标（简化版，实际应用中可能需要更复杂的指标）
        let performance = 1.0 - cpuUsage  // 简单的性能指标
        
        learningData.append((cpuUsage: cpuUsage, concurrency: concurrency, performance: performance))
        
        // 限制学习数据大小
        if learningData.count > 100 {
            learningData.removeFirst(learningData.count - 100)
        }
    }
    
    /// 获取CPU使用率
    private func getCPUUsage() -> CPUUsageStats? {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        guard result == KERN_SUCCESS else { return nil }
        
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.size))
        }
        
        var userTime: Double = 0
        var systemTime: Double = 0
        var idleTime: Double = 0
        var niceTime: Double = 0
        
        for i in 0..<Int(numCpus) {
            let cpuLoadInfo = cpuInfo.advanced(by: i * Int(CPU_STATE_MAX))
            
            userTime += Double(cpuLoadInfo[Int(CPU_STATE_USER)])
            systemTime += Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
            idleTime += Double(cpuLoadInfo[Int(CPU_STATE_IDLE)])
            niceTime += Double(cpuLoadInfo[Int(CPU_STATE_NICE)])
        }
        
        let totalTime = userTime + systemTime + idleTime + niceTime
        let totalUsage = totalTime > 0 ? (userTime + systemTime) / totalTime : 0
        
        return CPUUsageStats(
            userTime: userTime / totalTime,
            systemTime: systemTime / totalTime,
            idleTime: idleTime / totalTime,
            totalUsage: totalUsage
        )
    }
}

// MARK: - Extensions

extension CPUOptimizer {
    
    /// 获取系统信息
    public func getSystemInfo() -> [String: Any] {
        var systemInfo: [String: Any] = [:]
        
        // CPU核心数
        systemInfo["cpuCores"] = ProcessInfo.processInfo.processorCount
        
        // 活跃CPU核心数
        systemInfo["activeCpuCores"] = ProcessInfo.processInfo.activeProcessorCount
        
        // 物理内存
        systemInfo["physicalMemory"] = ProcessInfo.processInfo.physicalMemory
        
        // 当前CPU使用率
        if let cpuStats = getCurrentCPUUsage() {
            systemInfo["currentCpuUsage"] = cpuStats.totalUsage
        }
        
        // 当前并发度
        systemInfo["currentConcurrency"] = currentConcurrency
        
        return systemInfo
    }
    
    /// 导出优化日志
    public func exportOptimizationLog() -> String {
        var log = "=== CPU Optimization Log ===\n\n"
        
        // 基本信息
        log += "Generated: \(Date())\n"
        log += "Optimization Enabled: \(isOptimizationEnabled)\n"
        log += "Current Concurrency: \(currentConcurrency)\n"
        log += "Original Concurrency: \(originalConcurrency)\n"
        log += "Total Adjustments: \(adjustmentCount)\n\n"
        
        // 系统信息
        let systemInfo = getSystemInfo()
        log += "=== System Information ===\n"
        for (key, value) in systemInfo {
            log += "\(key): \(value)\n"
        }
        log += "\n"
        
        // 优化报告
        if let report = getOptimizationReport() {
            log += "=== Optimization Report ===\n"
            log += "Original CPU Usage: \(String(format: "%.2f%%", report.originalCPUUsage * 100))\n"
            log += "Optimized CPU Usage: \(String(format: "%.2f%%", report.optimizedCPUUsage * 100))\n"
            log += "CPU Savings: \(String(format: "%.2f%%", report.cpuSavings))\n"
            log += "Optimization Duration: \(String(format: "%.2f seconds", report.optimizationDuration))\n\n"
        }
        
        // CPU使用历史
        let history = getCPUUsageHistory(limit: 20)
        log += "=== CPU Usage History (Recent 20) ===\n"
        for stats in history {
            log += "[\(stats.timestamp)] CPU: \(String(format: "%.2f%%", stats.totalUsage * 100)) "
            log += "User: \(String(format: "%.2f%%", stats.userTime * 100)) "
            log += "System: \(String(format: "%.2f%%", stats.systemTime * 100))\n"
        }
        
        return log
    }
}
