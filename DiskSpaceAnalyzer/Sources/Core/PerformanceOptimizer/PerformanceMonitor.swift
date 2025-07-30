import Foundation
import Darwin

/// 性能指标类型
public enum PerformanceMetricType {
    case cpu
    case memory
    case disk
    case network
    case custom(String)
    
    public var displayName: String {
        switch self {
        case .cpu:
            return "CPU"
        case .memory:
            return "Memory"
        case .disk:
            return "Disk"
        case .network:
            return "Network"
        case .custom(let name):
            return name
        }
    }
}

/// 性能指标数据点
public struct PerformanceDataPoint {
    public let timestamp: Date
    public let value: Double
    public let unit: String
    public let metadata: [String: Any]
    
    public init(timestamp: Date = Date(), value: Double, unit: String, metadata: [String: Any] = [:]) {
        self.timestamp = timestamp
        self.value = value
        self.unit = unit
        self.metadata = metadata
    }
}

/// 性能指标
public struct PerformanceMetric {
    public let type: PerformanceMetricType
    public let name: String
    public let dataPoints: [PerformanceDataPoint]
    public let threshold: Double?
    
    public init(type: PerformanceMetricType, name: String, dataPoints: [PerformanceDataPoint] = [], threshold: Double? = nil) {
        self.type = type
        self.name = name
        self.dataPoints = dataPoints
        self.threshold = threshold
    }
    
    /// 获取最新值
    public var latestValue: Double? {
        return dataPoints.last?.value
    }
    
    /// 获取平均值
    public var averageValue: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map { $0.value }.reduce(0, +) / Double(dataPoints.count)
    }
    
    /// 获取最大值
    public var maxValue: Double {
        return dataPoints.map { $0.value }.max() ?? 0
    }
    
    /// 获取最小值
    public var minValue: Double {
        return dataPoints.map { $0.value }.min() ?? 0
    }
    
    /// 检查是否超过阈值
    public var isThresholdExceeded: Bool {
        guard let threshold = threshold, let latest = latestValue else { return false }
        return latest > threshold
    }
}

/// 性能警报
public struct PerformanceAlert {
    public let id: String
    public let metricType: PerformanceMetricType
    public let metricName: String
    public let threshold: Double
    public let currentValue: Double
    public let severity: AlertSeverity
    public let timestamp: Date
    public let message: String
    
    public enum AlertSeverity {
        case info
        case warning
        case critical
        
        public var displayName: String {
            switch self {
            case .info:
                return "Info"
            case .warning:
                return "Warning"
            case .critical:
                return "Critical"
            }
        }
    }
    
    public init(id: String, metricType: PerformanceMetricType, metricName: String, threshold: Double, currentValue: Double, severity: AlertSeverity, timestamp: Date = Date(), message: String) {
        self.id = id
        self.metricType = metricType
        self.metricName = metricName
        self.threshold = threshold
        self.currentValue = currentValue
        self.severity = severity
        self.timestamp = timestamp
        self.message = message
    }
}

/// 性能监控器 - 实时监控系统性能指标
public class PerformanceMonitor {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = PerformanceMonitor()
    
    /// 性能指标字典
    private var metrics: [String: PerformanceMetric] = [:]
    
    /// 性能警报列表
    private var alerts: [PerformanceAlert] = []
    
    /// 监控定时器
    private var monitoringTimer: Timer?
    
    /// 数据访问锁
    private let dataLock = NSLock()
    
    /// 监控间隔
    public var monitoringInterval: TimeInterval = 1.0
    
    /// 数据保留时长
    public var dataRetentionDuration: TimeInterval = 3600  // 1小时
    
    /// 最大数据点数量
    public var maxDataPoints: Int = 3600
    
    /// 是否启用监控
    public var isMonitoringEnabled: Bool = false {
        didSet {
            if isMonitoringEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    /// 警报回调
    public var alertCallback: ((PerformanceAlert) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultMetrics()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 添加自定义指标
    public func addMetric(name: String, type: PerformanceMetricType, threshold: Double? = nil) {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        let metric = PerformanceMetric(type: type, name: name, threshold: threshold)
        metrics[name] = metric
    }
    
    /// 记录指标数据点
    public func recordDataPoint(metricName: String, value: Double, unit: String, metadata: [String: Any] = [:]) {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        guard let metric = metrics[metricName] else {
            print("Warning: Metric '\(metricName)' not found")
            return
        }
        
        let dataPoint = PerformanceDataPoint(value: value, unit: unit, metadata: metadata)
        var newDataPoints = metric.dataPoints + [dataPoint]
        
        // 限制数据点数量
        if newDataPoints.count > maxDataPoints {
            newDataPoints.removeFirst(newDataPoints.count - maxDataPoints)
        }
        
        // 清理过期数据
        let cutoffTime = Date().addingTimeInterval(-dataRetentionDuration)
        newDataPoints = newDataPoints.filter { $0.timestamp > cutoffTime }
        
        let updatedMetric = PerformanceMetric(
            type: metric.type,
            name: metric.name,
            dataPoints: newDataPoints,
            threshold: metric.threshold
        )
        
        metrics[metricName] = updatedMetric
        
        // 检查阈值
        checkThreshold(for: updatedMetric)
    }
    
    /// 获取指标
    public func getMetric(name: String) -> PerformanceMetric? {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        return metrics[name]
    }
    
    /// 获取所有指标
    public func getAllMetrics() -> [PerformanceMetric] {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        return Array(metrics.values)
    }
    
    /// 获取指定类型的指标
    public func getMetrics(ofType type: PerformanceMetricType) -> [PerformanceMetric] {
        return getAllMetrics().filter { 
            switch (type, $0.type) {
            case (.cpu, .cpu), (.memory, .memory), (.disk, .disk), (.network, .network):
                return true
            case (.custom(let name1), .custom(let name2)):
                return name1 == name2
            default:
                return false
            }
        }
    }
    
    /// 获取警报
    public func getAlerts(severity: PerformanceAlert.AlertSeverity? = nil) -> [PerformanceAlert] {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        if let severity = severity {
            return alerts.filter { $0.severity == severity }
        } else {
            return alerts
        }
    }
    
    /// 清除警报
    public func clearAlerts() {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        alerts.removeAll()
    }
    
    /// 清除指标数据
    public func clearMetricData(metricName: String) {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        guard let metric = metrics[metricName] else { return }
        
        let clearedMetric = PerformanceMetric(
            type: metric.type,
            name: metric.name,
            dataPoints: [],
            threshold: metric.threshold
        )
        
        metrics[metricName] = clearedMetric
    }
    
    /// 清除所有数据
    public func clearAllData() {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        for (name, metric) in metrics {
            let clearedMetric = PerformanceMetric(
                type: metric.type,
                name: metric.name,
                dataPoints: [],
                threshold: metric.threshold
            )
            metrics[name] = clearedMetric
        }
        
        alerts.removeAll()
    }
    
    /// 获取性能摘要
    public func getPerformanceSummary() -> [String: Any] {
        let allMetrics = getAllMetrics()
        
        var summary: [String: Any] = [:]
        
        // CPU指标
        let cpuMetrics = getMetrics(ofType: .cpu)
        if let cpuUsage = cpuMetrics.first(where: { $0.name == "CPU Usage" }) {
            summary["cpuUsage"] = cpuUsage.latestValue
            summary["cpuAverage"] = cpuUsage.averageValue
        }
        
        // 内存指标
        let memoryMetrics = getMetrics(ofType: .memory)
        if let memoryUsage = memoryMetrics.first(where: { $0.name == "Memory Usage" }) {
            summary["memoryUsage"] = memoryUsage.latestValue
            summary["memoryAverage"] = memoryUsage.averageValue
        }
        
        // 总体统计
        summary["totalMetrics"] = allMetrics.count
        summary["activeAlerts"] = alerts.count
        summary["criticalAlerts"] = getAlerts(severity: .critical).count
        summary["monitoringEnabled"] = isMonitoringEnabled
        summary["dataRetentionHours"] = dataRetentionDuration / 3600
        
        return summary
    }
    
    // MARK: - Private Methods
    
    /// 设置默认指标
    private func setupDefaultMetrics() {
        addMetric(name: "CPU Usage", type: .cpu, threshold: 80.0)
        addMetric(name: "Memory Usage", type: .memory, threshold: 80.0)
        addMetric(name: "Memory Pressure", type: .memory, threshold: 70.0)
        addMetric(name: "Thread Count", type: .custom("System"), threshold: 100.0)
    }
    
    /// 开始监控
    private func startMonitoring() {
        guard monitoringTimer == nil else { return }
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.collectSystemMetrics()
        }
    }
    
    /// 停止监控
    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// 收集系统指标
    private func collectSystemMetrics() {
        // 收集CPU使用率
        if let cpuUsage = getCPUUsage() {
            recordDataPoint(metricName: "CPU Usage", value: cpuUsage * 100, unit: "%")
        }
        
        // 收集内存使用率
        let memoryInfo = getMemoryInfo()
        recordDataPoint(metricName: "Memory Usage", value: memoryInfo.usagePercentage, unit: "%")
        recordDataPoint(metricName: "Memory Pressure", value: memoryInfo.pressure, unit: "%")
        
        // 收集线程数
        let threadCount = getThreadCount()
        recordDataPoint(metricName: "Thread Count", value: Double(threadCount), unit: "threads")
    }
    
    /// 获取CPU使用率
    private func getCPUUsage() -> Double? {
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
        return totalTime > 0 ? (userTime + systemTime) / totalTime : 0
    }
    
    /// 获取内存信息
    private func getMemoryInfo() -> (usagePercentage: Double, pressure: Double) {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0, 0)
        }
        
        let usedMemory = Double(info.resident_size)
        let usagePercentage = (usedMemory / Double(physicalMemory)) * 100
        
        // 简化的内存压力计算
        let pressure = min(100, usagePercentage * 1.2)
        
        return (usagePercentage, pressure)
    }
    
    /// 获取线程数
    private func getThreadCount() -> Int {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        
        let result = task_threads(mach_task_self_, &threadList, &threadCount)
        
        if result == KERN_SUCCESS {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.size))
            return Int(threadCount)
        }
        
        return 0
    }
    
    /// 检查阈值
    private func checkThreshold(for metric: PerformanceMetric) {
        guard let threshold = metric.threshold,
              let latestValue = metric.latestValue,
              latestValue > threshold else { return }
        
        let severity: PerformanceAlert.AlertSeverity
        let exceedPercentage = (latestValue - threshold) / threshold
        
        if exceedPercentage > 0.5 {
            severity = .critical
        } else if exceedPercentage > 0.2 {
            severity = .warning
        } else {
            severity = .info
        }
        
        let alert = PerformanceAlert(
            id: UUID().uuidString,
            metricType: metric.type,
            metricName: metric.name,
            threshold: threshold,
            currentValue: latestValue,
            severity: severity,
            message: "\(metric.name) exceeded threshold: \(String(format: "%.2f", latestValue)) > \(String(format: "%.2f", threshold))"
        )
        
        alerts.append(alert)
        
        // 限制警报数量
        if alerts.count > 100 {
            alerts.removeFirst(alerts.count - 100)
        }
        
        // 触发回调
        alertCallback?(alert)
    }
}

// MARK: - Extensions

extension PerformanceMonitor {
    
    /// 导出性能报告
    public func exportPerformanceReport() -> String {
        var report = "=== Performance Monitor Report ===\n\n"
        
        let summary = getPerformanceSummary()
        
        report += "Generated: \(Date())\n"
        report += "Monitoring Enabled: \(isMonitoringEnabled)\n"
        report += "Monitoring Interval: \(monitoringInterval)s\n"
        report += "Data Retention: \(String(format: "%.1f hours", dataRetentionDuration / 3600))\n\n"
        
        report += "=== Performance Summary ===\n"
        for (key, value) in summary {
            report += "\(key): \(value)\n"
        }
        report += "\n"
        
        // 指标详情
        report += "=== Metrics Details ===\n"
        let allMetrics = getAllMetrics().sorted { $0.name < $1.name }
        
        for metric in allMetrics {
            report += "\(metric.name) (\(metric.type.displayName)):\n"
            if let latest = metric.latestValue {
                report += "  Current: \(String(format: "%.2f", latest))\n"
            }
            report += "  Average: \(String(format: "%.2f", metric.averageValue))\n"
            report += "  Min: \(String(format: "%.2f", metric.minValue))\n"
            report += "  Max: \(String(format: "%.2f", metric.maxValue))\n"
            if let threshold = metric.threshold {
                report += "  Threshold: \(String(format: "%.2f", threshold))\n"
                report += "  Threshold Exceeded: \(metric.isThresholdExceeded)\n"
            }
            report += "  Data Points: \(metric.dataPoints.count)\n\n"
        }
        
        // 警报信息
        let recentAlerts = getAlerts().suffix(10)
        report += "=== Recent Alerts ===\n"
        for alert in recentAlerts {
            report += "[\(alert.timestamp)] \(alert.severity.displayName): \(alert.message)\n"
        }
        
        return report
    }
}
