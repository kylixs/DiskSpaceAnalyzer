import Foundation
import Dispatch

/// 进度更新事件
public struct ProgressEvent {
    public let timestamp: Date
    public let filesProcessed: Int
    public let directoriesProcessed: Int
    public let bytesProcessed: Int64
    public let currentPath: String
    public let estimatedTotalFiles: Int
    public let estimatedTotalSize: Int64
    
    public init(timestamp: Date = Date(), filesProcessed: Int, directoriesProcessed: Int, bytesProcessed: Int64, currentPath: String, estimatedTotalFiles: Int = 0, estimatedTotalSize: Int64 = 0) {
        self.timestamp = timestamp
        self.filesProcessed = filesProcessed
        self.directoriesProcessed = directoriesProcessed
        self.bytesProcessed = bytesProcessed
        self.currentPath = currentPath
        self.estimatedTotalFiles = estimatedTotalFiles
        self.estimatedTotalSize = estimatedTotalSize
    }
}

/// 进度统计信息
public struct ProgressStatistics {
    public let progressPercentage: Double
    public let estimatedTimeRemaining: TimeInterval
    public let processingSpeed: Double  // 文件/秒
    public let throughput: Double       // 字节/秒
    public let elapsedTime: TimeInterval
    public let averageFileSize: Double
    
    public init(progressPercentage: Double, estimatedTimeRemaining: TimeInterval, processingSpeed: Double, throughput: Double, elapsedTime: TimeInterval, averageFileSize: Double) {
        self.progressPercentage = progressPercentage
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.processingSpeed = processingSpeed
        self.throughput = throughput
        self.elapsedTime = elapsedTime
        self.averageFileSize = averageFileSize
    }
}

/// 扫描进度管理器 - 实现100ms高频更新的进度管理系统
public class ScanProgressManager {
    
    // MARK: - Properties
    
    /// 更新间隔 (100ms)
    public static let updateInterval: TimeInterval = 0.1
    
    /// 进度事件队列
    private var eventQueue: [ProgressEvent] = []
    
    /// 事件队列锁
    private let eventLock = NSLock()
    
    /// 更新定时器
    private var updateTimer: Timer?
    
    /// 开始时间
    private var startTime: Date?
    
    /// 上次更新时间
    private var lastUpdateTime: Date?
    
    /// 历史进度数据
    private var progressHistory: [ProgressStatistics] = []
    
    /// 是否启用进度更新
    public var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
        }
    }
    
    /// 进度更新回调
    public var progressUpdateCallback: ((ProgressStatistics) -> Void)?
    
    /// 详细进度回调
    public var detailedProgressCallback: ((ProgressEvent, ProgressStatistics) -> Void)?
    
    // MARK: - Initialization
    
    public init() {}
    
    deinit {
        stopProgressUpdates()
    }
    
    // MARK: - Public Methods
    
    /// 开始进度跟踪
    public func startTracking() {
        startTime = Date()
        lastUpdateTime = startTime
        progressHistory.removeAll()
        isEnabled = true
    }
    
    /// 停止进度跟踪
    public func stopTracking() {
        isEnabled = false
        startTime = nil
        lastUpdateTime = nil
    }
    
    /// 添加进度事件
    public func addProgressEvent(_ event: ProgressEvent) {
        eventLock.lock()
        defer { eventLock.unlock() }
        
        eventQueue.append(event)
        
        // 限制队列大小
        if eventQueue.count > 1000 {
            eventQueue.removeFirst(eventQueue.count - 1000)
        }
    }
    
    /// 获取当前进度统计
    public func getCurrentStatistics() -> ProgressStatistics? {
        return progressHistory.last
    }
    
    /// 获取进度历史
    public func getProgressHistory(limit: Int = 100) -> [ProgressStatistics] {
        let startIndex = max(0, progressHistory.count - limit)
        return Array(progressHistory[startIndex...])
    }
    
    /// 清除历史数据
    public func clearHistory() {
        eventLock.lock()
        defer { eventLock.unlock() }
        
        eventQueue.removeAll()
        progressHistory.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// 开始进度更新
    private func startProgressUpdates() {
        guard updateTimer == nil else { return }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) { [weak self] _ in
            self?.processProgressUpdates()
        }
    }
    
    /// 停止进度更新
    private func stopProgressUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// 处理进度更新
    private func processProgressUpdates() {
        guard let startTime = startTime else { return }
        
        eventLock.lock()
        let currentEvents = eventQueue
        eventQueue.removeAll()
        eventLock.unlock()
        
        guard !currentEvents.isEmpty else { return }
        
        // 获取最新事件
        let latestEvent = currentEvents.last!
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startTime)
        
        // 计算统计信息
        let statistics = calculateStatistics(event: latestEvent, elapsedTime: elapsedTime)
        
        // 记录历史
        progressHistory.append(statistics)
        
        // 限制历史数据大小
        if progressHistory.count > 1000 {
            progressHistory.removeFirst(progressHistory.count - 1000)
        }
        
        // 触发回调
        progressUpdateCallback?(statistics)
        detailedProgressCallback?(latestEvent, statistics)
        
        lastUpdateTime = now
    }
    
    /// 计算统计信息
    private func calculateStatistics(event: ProgressEvent, elapsedTime: TimeInterval) -> ProgressStatistics {
        let totalItems = event.filesProcessed + event.directoriesProcessed
        let estimatedTotal = event.estimatedTotalFiles
        
        // 计算进度百分比
        let progressPercentage = estimatedTotal > 0 ? Double(totalItems) / Double(estimatedTotal) : 0.0
        
        // 计算处理速度
        let processingSpeed = elapsedTime > 0 ? Double(totalItems) / elapsedTime : 0.0
        
        // 计算吞吐量
        let throughput = elapsedTime > 0 ? Double(event.bytesProcessed) / elapsedTime : 0.0
        
        // 计算预估剩余时间
        let remainingItems = max(0, estimatedTotal - totalItems)
        let estimatedTimeRemaining = processingSpeed > 0 ? Double(remainingItems) / processingSpeed : 0.0
        
        // 计算平均文件大小
        let averageFileSize = totalItems > 0 ? Double(event.bytesProcessed) / Double(totalItems) : 0.0
        
        return ProgressStatistics(
            progressPercentage: min(1.0, max(0.0, progressPercentage)),
            estimatedTimeRemaining: estimatedTimeRemaining,
            processingSpeed: processingSpeed,
            throughput: throughput,
            elapsedTime: elapsedTime,
            averageFileSize: averageFileSize
        )
    }
}

// MARK: - Extensions

extension ScanProgressManager {
    
    /// 导出进度报告
    public func exportProgressReport() -> String {
        var report = "=== Scan Progress Report ===\n\n"
        
        if let startTime = startTime {
            report += "Start Time: \(startTime)\n"
            report += "Elapsed Time: \(String(format: "%.2f seconds", Date().timeIntervalSince(startTime)))\n"
        }
        
        report += "Progress Updates Enabled: \(isEnabled)\n"
        report += "Update Interval: \(Self.updateInterval * 1000)ms\n"
        report += "History Records: \(progressHistory.count)\n\n"
        
        if let currentStats = getCurrentStatistics() {
            report += "=== Current Statistics ===\n"
            report += "Progress: \(String(format: "%.2f%%", currentStats.progressPercentage * 100))\n"
            report += "Processing Speed: \(String(format: "%.2f files/sec", currentStats.processingSpeed))\n"
            report += "Throughput: \(String(format: "%.2f MB/sec", currentStats.throughput / 1024 / 1024))\n"
            report += "Estimated Time Remaining: \(String(format: "%.2f seconds", currentStats.estimatedTimeRemaining))\n"
            report += "Average File Size: \(String(format: "%.2f KB", currentStats.averageFileSize / 1024))\n\n"
        }
        
        // 最近的进度历史
        let recentHistory = getProgressHistory(limit: 10)
        report += "=== Recent Progress History ===\n"
        for (index, stats) in recentHistory.enumerated() {
            report += "[\(index + 1)] Progress: \(String(format: "%.1f%%", stats.progressPercentage * 100)) "
            report += "Speed: \(String(format: "%.1f files/sec", stats.processingSpeed))\n"
        }
        
        return report
    }
    
    /// 获取性能指标
    public func getPerformanceMetrics() -> [String: Any] {
        guard let currentStats = getCurrentStatistics() else {
            return ["enabled": isEnabled, "hasData": false]
        }
        
        return [
            "enabled": isEnabled,
            "hasData": true,
            "progressPercentage": currentStats.progressPercentage,
            "processingSpeed": currentStats.processingSpeed,
            "throughput": currentStats.throughput,
            "estimatedTimeRemaining": currentStats.estimatedTimeRemaining,
            "elapsedTime": currentStats.elapsedTime,
            "averageFileSize": currentStats.averageFileSize,
            "historyCount": progressHistory.count
        ]
    }
}
