import Foundation

/// 扫描会话数据模型
/// 记录扫描的完整生命周期状态，包括进度、统计信息和错误记录
public class ScanSession: ObservableObject, Identifiable, Codable {
    
    // MARK: - Properties
    
    /// 会话唯一标识符
    public let id: String
    
    /// 扫描根路径
    public let rootPath: String
    
    /// 扫描配置
    public let configuration: AppScanConfiguration
    
    /// 扫描开始时间
    public let startTime: Date
    
    /// 扫描结束时间
    @Published public var endTime: Date?
    
    /// 扫描状态
    @Published public var state: AppScanStatus
    
    /// 扫描进度 (0.0 - 1.0)
    @Published public var progress: Double
    
    /// 当前扫描路径
    @Published public var currentPath: String
    
    /// 扫描统计信息
    @Published public var statistics: AppScanStatistics?
    
    /// 根节点
    @Published public var rootNode: FileNode?
    
    /// 扫描错误列表
    @Published public var errors: [AppScanError]
    
    /// 是否已取消
    @Published public var isCancelled: Bool
    
    // MARK: - Computed Properties
    
    /// 扫描用时
    public var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    /// 是否正在进行
    public var isActive: Bool {
        return state.isActive
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        return state == .completed
    }
    
    /// 是否有错误
    public var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    /// 严重错误数量
    public var criticalErrorCount: Int {
        return errors.filter { $0.severity >= .critical }.count
    }
    
    // MARK: - Initialization
    
    public init(id: String, rootPath: String, configuration: AppScanConfiguration) {
        self.id = id
        self.rootPath = rootPath
        self.configuration = configuration
        self.startTime = Date()
        self.endTime = nil
        self.state = .preparing
        self.progress = 0.0
        self.currentPath = rootPath
        self.statistics = nil
        self.rootNode = nil
        self.errors = []
        self.isCancelled = false
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, rootPath, configuration, startTime, endTime
        case state, progress, currentPath, statistics
        case errors, isCancelled
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        rootPath = try container.decode(String.self, forKey: .rootPath)
        configuration = try container.decode(AppScanConfiguration.self, forKey: .configuration)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        state = try container.decode(AppScanStatus.self, forKey: .state)
        progress = try container.decode(Double.self, forKey: .progress)
        currentPath = try container.decode(String.self, forKey: .currentPath)
        statistics = try container.decodeIfPresent(AppScanStatistics.self, forKey: .statistics)
        errors = try container.decode([AppScanError].self, forKey: .errors)
        isCancelled = try container.decode(Bool.self, forKey: .isCancelled)
        
        // rootNode 不参与序列化，需要重新构建
        rootNode = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(rootPath, forKey: .rootPath)
        try container.encode(configuration, forKey: .configuration)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(state, forKey: .state)
        try container.encode(progress, forKey: .progress)
        try container.encode(currentPath, forKey: .currentPath)
        try container.encodeIfPresent(statistics, forKey: .statistics)
        try container.encode(errors, forKey: .errors)
        try container.encode(isCancelled, forKey: .isCancelled)
    }
    
    // MARK: - Public Methods
    
    /// 开始扫描
    public func start() {
        state = .scanning
        progress = 0.0
        currentPath = rootPath
        isCancelled = false
        
        // 初始化统计信息
        statistics = AppScanStatistics()
        
        print("🚀 扫描会话开始: \(rootPath)")
    }
    
    /// 更新进度
    public func updateProgress(_ newProgress: Double, currentPath: String) {
        progress = max(0.0, min(1.0, newProgress))
        self.currentPath = currentPath
        
        // 更新统计信息的时间
        statistics?.endTime = Date()
    }
    
    /// 更新统计信息
    public func updateStatistics(_ newStatistics: AppScanStatistics) {
        statistics = newStatistics
    }
    
    /// 添加错误
    public func addError(_ error: AppScanError) {
        errors.append(error)
        
        // 如果是严重错误，考虑暂停扫描
        if error.severity >= .critical {
            print("🚨 严重错误: \(error.message)")
        }
    }
    
    /// 暂停扫描
    public func pause() {
        guard state == .scanning else { return }
        state = .paused
        print("⏸️ 扫描会话暂停: \(rootPath)")
    }
    
    /// 恢复扫描
    public func resume() {
        guard state == .paused else { return }
        state = .scanning
        print("▶️ 扫描会话恢复: \(rootPath)")
    }
    
    /// 取消扫描
    public func cancel() {
        isCancelled = true
        state = .cancelled
        endTime = Date()
        
        // 添加取消错误
        let cancelError = AppScanError.scanCancelled()
        addError(cancelError)
        
        print("⏹️ 扫描会话取消: \(rootPath)")
    }
    
    /// 完成扫描
    public func complete(rootNode: FileNode?) {
        state = .completed
        endTime = Date()
        progress = 1.0
        self.rootNode = rootNode
        
        // 完成统计信息
        statistics?.complete()
        
        print("✅ 扫描会话完成: \(rootPath)")
        print("📊 统计: \(statistics?.totalFiles ?? 0) 文件, \(AppByteFormatter.shared.string(fromByteCount: statistics?.totalSize ?? 0))")
    }
    
    /// 标记为失败
    public func fail(error: AppScanError) {
        state = .failed
        endTime = Date()
        addError(error)
        
        print("❌ 扫描会话失败: \(rootPath) - \(error.message)")
    }
    
    /// 获取会话摘要
    public func getSummary() -> String {
        var summary = "扫描会话摘要\n"
        summary += "ID: \(id)\n"
        summary += "路径: \(rootPath)\n"
        summary += "状态: \(state.displayName)\n"
        summary += "进度: \(String(format: "%.1f%%", progress * 100))\n"
        summary += "用时: \(AppTimeFormatter.shared.string(from: duration))\n"
        
        if let stats = statistics {
            summary += "文件数: \(AppNumberFormatter.shared.string(from: stats.totalFiles))\n"
            summary += "文件夹数: \(AppNumberFormatter.shared.string(from: stats.totalDirectories))\n"
            summary += "总大小: \(AppByteFormatter.shared.string(fromByteCount: stats.totalSize))\n"
        }
        
        if hasErrors {
            summary += "错误数: \(errors.count) (严重: \(criticalErrorCount))\n"
        }
        
        return summary
    }
    
    /// 导出详细报告
    public func exportDetailedReport() -> String {
        var report = "=== 扫描会话详细报告 ===\n\n"
        
        report += "会话信息:\n"
        report += "ID: \(id)\n"
        report += "扫描路径: \(rootPath)\n"
        report += "开始时间: \(startTime)\n"
        if let endTime = endTime {
            report += "结束时间: \(endTime)\n"
        }
        report += "状态: \(state.displayName)\n"
        report += "进度: \(String(format: "%.2f%%", progress * 100))\n"
        report += "用时: \(AppTimeFormatter.shared.string(from: duration))\n"
        report += "是否取消: \(isCancelled ? "是" : "否")\n\n"
        
        // 配置信息
        report += "扫描配置:\n"
        report += "跟随符号链接: \(configuration.followSymlinks ? "是" : "否")\n"
        report += "包含隐藏文件: \(configuration.includeHiddenFiles ? "是" : "否")\n"
        report += "最大深度: \(configuration.maxDepth == 0 ? "无限制" : "\(configuration.maxDepth)")\n"
        report += "最小文件大小: \(AppByteFormatter.shared.string(fromByteCount: configuration.minFileSize))\n"
        if configuration.maxFileSize > 0 {
            report += "最大文件大小: \(AppByteFormatter.shared.string(fromByteCount: configuration.maxFileSize))\n"
        }
        report += "排除扩展名: \(configuration.excludedExtensions.isEmpty ? "无" : Array(configuration.excludedExtensions).joined(separator: ", "))\n"
        report += "排除目录: \(configuration.excludedDirectories.isEmpty ? "无" : Array(configuration.excludedDirectories).joined(separator: ", "))\n\n"
        
        // 统计信息
        if let stats = statistics {
            report += "统计信息:\n"
            report += "总文件数: \(AppNumberFormatter.shared.string(from: stats.totalFiles))\n"
            report += "总文件夹数: \(AppNumberFormatter.shared.string(from: stats.totalDirectories))\n"
            report += "总大小: \(AppByteFormatter.shared.string(fromByteCount: stats.totalSize))\n"
            report += "平均文件大小: \(AppByteFormatter.shared.string(fromByteCount: stats.averageFileSize))\n"
            report += "最大文件大小: \(AppByteFormatter.shared.string(fromByteCount: stats.maxFileSize))\n"
            report += "最大深度: \(stats.maxDepth)\n"
            report += "扫描速度: \(String(format: "%.1f", stats.scanSpeed)) 文件/秒\n\n"
        }
        
        // 错误信息
        if hasErrors {
            report += "错误信息 (\(errors.count) 个):\n"
            for (index, error) in errors.enumerated() {
                report += "\n[\(index + 1)] \(error.title)\n"
                report += "严重程度: \(error.severity.displayName)\n"
                report += "类别: \(error.category.displayName)\n"
                report += "消息: \(error.message)\n"
                if let filePath = error.filePath {
                    report += "文件: \(filePath)\n"
                }
                report += "时间: \(error.timestamp)\n"
            }
            report += "\n"
        }
        
        return report
    }
}

// MARK: - Equatable

extension ScanSession: Equatable {
    public static func == (lhs: ScanSession, rhs: ScanSession) -> Bool {
        return lhs.id == rhs.id
    }
}
