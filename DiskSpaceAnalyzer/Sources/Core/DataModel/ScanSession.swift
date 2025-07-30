import Foundation

/// 扫描会话数据模型
/// 记录扫描的完整生命周期状态，包括进度、统计信息和错误记录
public class ScanSession: ObservableObject, Identifiable, Codable {
    
    // MARK: - Properties
    
    /// 会话唯一标识符
    public let id: UUID
    
    /// 扫描路径
    public let scanPath: String
    
    /// 扫描开始时间
    public let startTime: Date
    
    /// 扫描结束时间
    @Published public var endTime: Date?
    
    /// 扫描状态
    @Published public var status: ScanStatus
    
    /// 扫描进度
    @Published public var progress: ScanProgress
    
    /// 扫描统计信息
    @Published public var statistics: ScanStatistics
    
    /// 根节点
    @Published public var rootNode: FileNode?
    
    /// 错误记录
    @Published public var errors: [ScanError] = []
    
    /// 会话配置
    public let configuration: ScanConfiguration
    
    // MARK: - Computed Properties
    
    /// 扫描持续时间
    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    /// 是否正在进行中
    public var isActive: Bool {
        switch status {
        case .running, .paused:
            return true
        default:
            return false
        }
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        switch status {
        case .completed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化扫描会话
    /// - Parameters:
    ///   - scanPath: 扫描路径
    ///   - configuration: 扫描配置
    public init(scanPath: String, configuration: ScanConfiguration = ScanConfiguration()) {
        self.id = UUID()
        self.scanPath = scanPath
        self.startTime = Date()
        self.status = .preparing
        self.progress = ScanProgress()
        self.statistics = ScanStatistics()
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// 开始扫描
    public func start() {
        guard status == .preparing else { return }
        status = .running
        progress.startTime = Date()
    }
    
    /// 暂停扫描
    public func pause() {
        guard status == .running else { return }
        status = .paused
        progress.pausedTime = Date()
    }
    
    /// 恢复扫描
    public func resume() {
        guard status == .paused else { return }
        status = .running
        if let pausedTime = progress.pausedTime {
            progress.totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        progress.pausedTime = nil
    }
    
    /// 取消扫描
    public func cancel() {
        guard isActive else { return }
        status = .cancelled
        endTime = Date()
    }
    
    /// 完成扫描
    /// - Parameter rootNode: 扫描结果根节点
    public func complete(with rootNode: FileNode?) {
        guard status == .running else { return }
        self.rootNode = rootNode
        status = .completed
        endTime = Date()
        progress.percentage = 1.0
    }
    
    /// 标记扫描失败
    /// - Parameter error: 错误信息
    public func fail(with error: ScanError) {
        status = .failed(error)
        endTime = Date()
        addError(error)
    }
    
    /// 更新进度
    /// - Parameter newProgress: 新的进度信息
    public func updateProgress(_ newProgress: ScanProgress) {
        progress = newProgress
    }
    
    /// 更新统计信息
    /// - Parameter newStatistics: 新的统计信息
    public func updateStatistics(_ newStatistics: ScanStatistics) {
        statistics = newStatistics
    }
    
    /// 添加错误记录
    /// - Parameter error: 错误信息
    public func addError(_ error: ScanError) {
        errors.append(error)
    }
    
    /// 清除错误记录
    public func clearErrors() {
        errors.removeAll()
    }
    
    /// 获取会话摘要
    /// - Returns: 会话摘要信息
    public func getSummary() -> SessionSummary {
        return SessionSummary(
            id: id,
            scanPath: scanPath,
            status: status,
            duration: duration,
            totalFiles: statistics.totalFiles,
            totalDirectories: statistics.totalDirectories,
            totalSize: statistics.totalSize,
            errorCount: errors.count
        )
    }
    
    // MARK: - Codable Support
    
    private enum CodingKeys: String, CodingKey {
        case id, scanPath, startTime, endTime, status
        case progress, statistics, rootNode, errors, configuration
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        scanPath = try container.decode(String.self, forKey: .scanPath)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        status = try container.decode(ScanStatus.self, forKey: .status)
        progress = try container.decode(ScanProgress.self, forKey: .progress)
        statistics = try container.decode(ScanStatistics.self, forKey: .statistics)
        rootNode = try container.decodeIfPresent(FileNode.self, forKey: .rootNode)
        errors = try container.decode([ScanError].self, forKey: .errors)
        configuration = try container.decode(ScanConfiguration.self, forKey: .configuration)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(scanPath, forKey: .scanPath)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(status, forKey: .status)
        try container.encode(progress, forKey: .progress)
        try container.encode(statistics, forKey: .statistics)
        try container.encodeIfPresent(rootNode, forKey: .rootNode)
        try container.encode(errors, forKey: .errors)
        try container.encode(configuration, forKey: .configuration)
    }
}

// MARK: - Supporting Types

/// 扫描状态
public enum ScanStatus: Codable {
    case preparing
    case running
    case paused
    case completed
    case cancelled
    case failed(ScanError)
    
    public var description: String {
        switch self {
        case .preparing:
            return "准备中"
        case .running:
            return "扫描中"
        case .paused:
            return "已暂停"
        case .completed:
            return "已完成"
        case .cancelled:
            return "已取消"
        case .failed:
            return "扫描失败"
        }
    }
}

/// 扫描进度
public struct ScanProgress: Codable {
    /// 进度百分比 (0.0 - 1.0)
    public var percentage: Double = 0.0
    
    /// 已处理文件数
    public var processedFiles: Int = 0
    
    /// 总文件数（预估）
    public var totalFiles: Int?
    
    /// 当前扫描路径
    public var currentPath: String = ""
    
    /// 已处理字节数
    public var bytesProcessed: Int64 = 0
    
    /// 预估剩余时间（秒）
    public var estimatedTimeRemaining: TimeInterval?
    
    /// 扫描速度（文件/秒）
    public var scanSpeed: Double = 0.0
    
    /// 开始时间
    public var startTime: Date?
    
    /// 暂停时间
    public var pausedTime: Date?
    
    /// 总暂停时长
    public var totalPausedDuration: TimeInterval = 0.0
    
    public init() {}
    
    /// 实际扫描时长（排除暂停时间）
    public var actualScanDuration: TimeInterval {
        guard let startTime = startTime else { return 0 }
        let now = Date()
        let totalDuration = now.timeIntervalSince(startTime)
        return totalDuration - totalPausedDuration
    }
}

/// 扫描统计信息
public struct ScanStatistics: Codable {
    /// 总文件数
    public var totalFiles: Int = 0
    
    /// 总目录数
    public var totalDirectories: Int = 0
    
    /// 总大小（字节）
    public var totalSize: Int64 = 0
    
    /// 最大深度
    public var maxDepth: Int = 0
    
    /// 最大文件大小
    public var maxFileSize: Int64 = 0
    
    /// 平均文件大小
    public var averageFileSize: Int64 {
        return totalFiles > 0 ? totalSize / Int64(totalFiles) : 0
    }
    
    /// 文件类型分布
    public var fileTypeDistribution: [String: Int] = [:]
    
    /// 大小分布
    public var sizeDistribution: SizeDistribution = SizeDistribution()
    
    public init() {}
    
    /// 格式化的总大小
    public var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

/// 大小分布统计
public struct SizeDistribution: Codable {
    public var tiny: Int = 0      // < 1KB
    public var small: Int = 0     // 1KB - 1MB
    public var medium: Int = 0    // 1MB - 100MB
    public var large: Int = 0     // 100MB - 1GB
    public var huge: Int = 0      // > 1GB
    
    public init() {}
    
    /// 更新分布统计
    /// - Parameter size: 文件大小
    public mutating func update(with size: Int64) {
        switch size {
        case 0..<1024:
            tiny += 1
        case 1024..<(1024*1024):
            small += 1
        case (1024*1024)..<(100*1024*1024):
            medium += 1
        case (100*1024*1024)..<(1024*1024*1024):
            large += 1
        default:
            huge += 1
        }
    }
}

/// 扫描错误
public struct ScanError: Codable, Error, Identifiable, Equatable {
    public let id: UUID
    public let path: String
    public let message: String
    public let errorCode: Int
    public let timestamp: Date
    public let severity: ErrorSeverity
    
    public init(
        path: String,
        message: String,
        errorCode: Int = 0,
        severity: ErrorSeverity = .warning
    ) {
        self.id = UUID()
        self.path = path
        self.message = message
        self.errorCode = errorCode
        self.timestamp = Date()
        self.severity = severity
    }
    
    public static func == (lhs: ScanError, rhs: ScanError) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 错误严重程度
public enum ErrorSeverity: String, Codable, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    public var description: String {
        switch self {
        case .info:
            return "信息"
        case .warning:
            return "警告"
        case .error:
            return "错误"
        case .critical:
            return "严重错误"
        }
    }
}

/// 扫描配置
public struct ScanConfiguration: Codable {
    /// 是否跟随符号链接
    public let followSymlinks: Bool
    
    /// 是否包含隐藏文件
    public let includeHiddenFiles: Bool
    
    /// 最大扫描深度
    public let maxDepth: Int?
    
    /// 排除模式
    public let excludePatterns: [String]
    
    /// 包含模式
    public let includePatterns: [String]
    
    /// 是否启用文件过滤
    public let enableFileFiltering: Bool
    
    public init(
        followSymlinks: Bool = false,
        includeHiddenFiles: Bool = false,
        maxDepth: Int? = nil,
        excludePatterns: [String] = [],
        includePatterns: [String] = [],
        enableFileFiltering: Bool = true
    ) {
        self.followSymlinks = followSymlinks
        self.includeHiddenFiles = includeHiddenFiles
        self.maxDepth = maxDepth
        self.excludePatterns = excludePatterns
        self.includePatterns = includePatterns
        self.enableFileFiltering = enableFileFiltering
    }
}

/// 会话摘要
public struct SessionSummary: Identifiable {
    public let id: UUID
    public let scanPath: String
    public let status: ScanStatus
    public let duration: TimeInterval
    public let totalFiles: Int
    public let totalDirectories: Int
    public let totalSize: Int64
    public let errorCount: Int
    
    /// 格式化的持续时间
    public var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    /// 格式化的总大小
    public var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// 添加ScanStatus的Equatable实现
extension ScanStatus: Equatable {
    public static func == (lhs: ScanStatus, rhs: ScanStatus) -> Bool {
        switch (lhs, rhs) {
        case (.preparing, .preparing),
             (.running, .running),
             (.paused, .paused),
             (.completed, .completed),
             (.cancelled, .cancelled):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
