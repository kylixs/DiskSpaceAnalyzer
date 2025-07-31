import Foundation
import Combine

/// 扫描会话数据模型
/// 记录扫描的完整生命周期和状态信息
public class ScanSession: ObservableObject, Identifiable, Codable {
    
    // MARK: - Properties
    
    /// 会话唯一标识符
    public let id: UUID
    
    /// 扫描路径
    @Published public var scanPath: String
    
    /// 会话名称
    @Published public var name: String
    
    /// 创建时间
    public let createdAt: Date
    
    /// 开始时间
    @Published public var startedAt: Date?
    
    /// 完成时间
    @Published public var completedAt: Date?
    
    /// 暂停时间
    @Published public var pausedAt: Date?
    
    /// 恢复时间
    @Published public var resumedAt: Date?
    
    /// 扫描状态
    @Published public var status: AppScanStatus = .pending
    
    /// 扫描配置
    @Published public var configuration: AppScanConfiguration
    
    /// 扫描统计信息
    @Published public var statistics: AppScanStatistics
    
    /// 错误列表
    @Published public var errors: [AppScanError] = []
    
    /// 当前扫描的文件路径
    @Published public var currentPath: String = ""
    
    /// 扫描进度（0.0 - 1.0）
    @Published public var progress: Double = 0.0
    
    /// 预估剩余时间（秒）
    @Published public var estimatedTimeRemaining: TimeInterval = 0
    
    /// 扫描速度（文件/秒）
    @Published public var scanSpeed: Double = 0
    
    /// 目录树数据
    @Published public var directoryTree: DirectoryTree?
    
    /// 会话标签
    @Published public var tags: Set<String> = []
    
    /// 用户备注
    @Published public var notes: String = ""
    
    /// 是否为收藏会话
    @Published public var isFavorite: Bool = false
    
    // MARK: - Computed Properties
    
    /// 扫描持续时间
    public var duration: TimeInterval {
        guard let startTime = startedAt else { return 0 }
        
        if let endTime = completedAt {
            return endTime.timeIntervalSince(startTime)
        } else if status == .scanning {
            return Date().timeIntervalSince(startTime)
        }
        
        return 0
    }
    
    /// 是否可以恢复
    public var canResume: Bool {
        return status == .paused
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        return status == .completed || status == .cancelled || status == .failed
    }
    
    /// 是否正在运行
    public var isRunning: Bool {
        return status == .scanning
    }
    
    // MARK: - Initialization
    
    /// 初始化扫描会话
    public init(scanPath: String, name: String? = nil, configuration: AppScanConfiguration = AppScanConfiguration()) {
        self.id = UUID()
        self.scanPath = scanPath
        self.name = name ?? URL(fileURLWithPath: scanPath).lastPathComponent
        self.createdAt = Date()
        self.configuration = configuration
        self.statistics = AppScanStatistics()
        self.directoryTree = DirectoryTree()
    }
    
    // MARK: - Session Control
    
    /// 开始扫描
    public func start() {
        guard status == .pending || status == .paused else { return }
        
        if status == .pending {
            startedAt = Date()
            statistics.reset()
        } else if status == .paused {
            resumedAt = Date()
        }
        
        status = .scanning
        pausedAt = nil
    }
    
    /// 暂停扫描
    public func pause() {
        guard status == .scanning else { return }
        
        status = .paused
        pausedAt = Date()
    }
    
    /// 完成扫描
    public func complete(success: Bool = true) {
        guard status == .scanning else { return }
        
        status = success ? .completed : .failed
        completedAt = Date()
    }
    
    /// 更新扫描进度
    public func updateProgress(currentPath: String, progress: Double, speed: Double, estimatedTime: TimeInterval) {
        self.currentPath = currentPath
        self.progress = min(1.0, max(0.0, progress))
        self.scanSpeed = speed
        self.estimatedTimeRemaining = estimatedTime
    }
    
    /// 添加错误
    public func addError(_ error: AppScanError) {
        errors.append(error)
    }
    
    // MARK: - Codable Support
    
    private enum CodingKeys: String, CodingKey {
        case id, scanPath, name, createdAt, startedAt, completedAt, pausedAt, resumedAt
        case status, configuration, statistics, errors, currentPath, progress
        case estimatedTimeRemaining, scanSpeed, tags, notes, isFavorite
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        scanPath = try container.decode(String.self, forKey: .scanPath)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
        resumedAt = try container.decodeIfPresent(Date.self, forKey: .resumedAt)
        status = try container.decode(AppScanStatus.self, forKey: .status)
        configuration = try container.decode(AppScanConfiguration.self, forKey: .configuration)
        statistics = try container.decode(AppScanStatistics.self, forKey: .statistics)
        errors = try container.decode([AppScanError].self, forKey: .errors)
        currentPath = try container.decode(String.self, forKey: .currentPath)
        progress = try container.decode(Double.self, forKey: .progress)
        estimatedTimeRemaining = try container.decode(TimeInterval.self, forKey: .estimatedTimeRemaining)
        scanSpeed = try container.decode(Double.self, forKey: .scanSpeed)
        tags = try container.decode(Set<String>.self, forKey: .tags)
        notes = try container.decode(String.self, forKey: .notes)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        
        directoryTree = DirectoryTree()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(scanPath, forKey: .scanPath)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
        try container.encodeIfPresent(resumedAt, forKey: .resumedAt)
        try container.encode(status, forKey: .status)
        try container.encode(configuration, forKey: .configuration)
        try container.encode(statistics, forKey: .statistics)
        try container.encode(errors, forKey: .errors)
        try container.encode(currentPath, forKey: .currentPath)
        try container.encode(progress, forKey: .progress)
        try container.encode(estimatedTimeRemaining, forKey: .estimatedTimeRemaining)
        try container.encode(scanSpeed, forKey: .scanSpeed)
        try container.encode(tags, forKey: .tags)
        try container.encode(notes, forKey: .notes)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}

extension ScanSession: Equatable {
    public static func == (lhs: ScanSession, rhs: ScanSession) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ScanSession: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
