import Foundation
import Combine

/// 会话优先级
public enum SessionPriority: Int, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    public static func < (lhs: SessionPriority, rhs: SessionPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
}

/// 会话状态
public enum SessionState: String, CaseIterable {
    case created = "created"
    case queued = "queued"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .created: return "已创建"
        case .queued: return "队列中"
        case .running: return "运行中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .running, .queued:
            return true
        default:
            return false
        }
    }
}

/// 会话控制器 - 管理扫描会话的生命周期
public class SessionController: ObservableObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = SessionController()
    
    /// 活动会话列表
    @Published public private(set) var activeSessions: [ScanSession] = []
    
    /// 会话历史
    @Published public private(set) var sessionHistory: [ScanSession] = []
    
    /// 最大并发会话数
    public let maxConcurrentSessions: Int
    
    /// 会话队列
    private var sessionQueue: [ScanSession] = []
    
    /// 线程安全队列
    private let queue = DispatchQueue(label: "SessionController", qos: .userInitiated)
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.maxConcurrentSessions = AppConstants.maxConcurrentScans
        setupSessionMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 创建新会话
    public func createSession(rootPath: String, configuration: AppScanConfiguration = .default, priority: SessionPriority = .normal) -> ScanSession {
        return queue.sync {
            let session = ScanSession(
                id: UUID().uuidString,
                rootPath: rootPath,
                configuration: configuration
            )
            
            // 添加到队列
            sessionQueue.append(session)
            
            // 尝试启动会话
            processSessionQueue()
            
            print("📝 创建扫描会话: \(rootPath)")
            return session
        }
    }
    
    /// 启动会话
    public func startSession(_ session: ScanSession) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否可以启动
            if self.activeSessions.count < self.maxConcurrentSessions {
                self.activeSessions.append(session)
                
                DispatchQueue.main.async {
                    session.start()
                }
                
                print("🚀 启动扫描会话: \(session.rootPath)")
            } else {
                print("⏳ 会话加入队列: \(session.rootPath)")
            }
        }
    }
    
    /// 暂停会话
    public func pauseSession(_ session: ScanSession) {
        queue.async {
            DispatchQueue.main.async {
                session.pause()
            }
            print("⏸️ 暂停扫描会话: \(session.rootPath)")
        }
    }
    
    /// 恢复会话
    public func resumeSession(_ session: ScanSession) {
        queue.async {
            DispatchQueue.main.async {
                session.resume()
            }
            print("▶️ 恢复扫描会话: \(session.rootPath)")
        }
    }
    
    /// 取消会话
    public func cancelSession(_ session: ScanSession) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                session.cancel()
            }
            
            // 从活动会话中移除
            self.activeSessions.removeAll { $0.id == session.id }
            
            // 添加到历史
            self.sessionHistory.append(session)
            
            // 处理队列中的下一个会话
            self.processSessionQueue()
            
            print("⏹️ 取消扫描会话: \(session.rootPath)")
        }
    }
    
    /// 完成会话
    public func completeSession(_ session: ScanSession, rootNode: FileNode?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                session.complete(rootNode: rootNode)
            }
            
            // 从活动会话中移除
            self.activeSessions.removeAll { $0.id == session.id }
            
            // 添加到历史
            self.sessionHistory.append(session)
            
            // 处理队列中的下一个会话
            self.processSessionQueue()
            
            print("✅ 完成扫描会话: \(session.rootPath)")
        }
    }
    
    /// 会话失败
    public func failSession(_ session: ScanSession, error: AppScanError) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                session.fail(error: error)
            }
            
            // 从活动会话中移除
            self.activeSessions.removeAll { $0.id == session.id }
            
            // 添加到历史
            self.sessionHistory.append(session)
            
            // 处理队列中的下一个会话
            self.processSessionQueue()
            
            print("❌ 会话失败: \(session.rootPath) - \(error.message)")
        }
    }
    
    /// 获取会话
    public func getSession(id: String) -> ScanSession? {
        return queue.sync {
            return activeSessions.first { $0.id == id } ?? 
                   sessionHistory.first { $0.id == id }
        }
    }
    
    /// 获取活动会话数量
    public func getActiveSessionCount() -> Int {
        return queue.sync { activeSessions.count }
    }
    
    /// 获取队列中的会话数量
    public func getQueuedSessionCount() -> Int {
        return queue.sync { sessionQueue.count }
    }
    
    /// 清理历史会话
    public func clearHistory() {
        queue.async { [weak self] in
            DispatchQueue.main.async {
                self?.sessionHistory.removeAll()
            }
            print("🧹 清理会话历史")
        }
    }
    
    /// 取消所有会话
    public func cancelAllSessions() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 取消活动会话
            for session in self.activeSessions {
                DispatchQueue.main.async {
                    session.cancel()
                }
            }
            
            // 清空队列
            self.sessionQueue.removeAll()
            
            // 移动到历史
            self.sessionHistory.append(contentsOf: self.activeSessions)
            self.activeSessions.removeAll()
            
            print("🛑 取消所有扫描会话")
        }
    }
    
    /// 导出会话报告
    public func exportSessionReport() -> String {
        return queue.sync {
            var report = "=== 会话控制器报告 ===\n\n"
            
            report += "生成时间: \(Date())\n"
            report += "活动会话数: \(activeSessions.count)\n"
            report += "队列会话数: \(sessionQueue.count)\n"
            report += "历史会话数: \(sessionHistory.count)\n"
            report += "最大并发数: \(maxConcurrentSessions)\n\n"
            
            // 活动会话
            if !activeSessions.isEmpty {
                report += "=== 活动会话 ===\n"
                for session in activeSessions {
                    report += "\n\(session.getSummary())\n"
                }
            }
            
            // 队列会话
            if !sessionQueue.isEmpty {
                report += "=== 队列会话 ===\n"
                for session in sessionQueue {
                    report += "\n\(session.getSummary())\n"
                }
            }
            
            // 最近的历史会话
            if !sessionHistory.isEmpty {
                report += "=== 最近历史会话 ===\n"
                let recentHistory = Array(sessionHistory.suffix(5))
                for session in recentHistory {
                    report += "\n\(session.getSummary())\n"
                }
            }
            
            return report
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置会话监控
    private func setupSessionMonitoring() {
        // 监控内存使用
        NotificationCenter.default.publisher(for: AppNotificationNames.memoryWarning)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    /// 处理会话队列
    private func processSessionQueue() {
        while activeSessions.count < maxConcurrentSessions && !sessionQueue.isEmpty {
            let nextSession = sessionQueue.removeFirst()
            activeSessions.append(nextSession)
            
            DispatchQueue.main.async {
                nextSession.start()
            }
            
            print("🎯 从队列启动会话: \(nextSession.rootPath)")
        }
    }
    
    /// 处理内存警告
    private func handleMemoryWarning() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 暂停低优先级的会话
            let lowPrioritySessions = self.activeSessions.filter { session in
                // 这里需要根据实际的优先级属性来判断
                // 暂时使用简单的逻辑
                return self.activeSessions.count > 1
            }
            
            for session in lowPrioritySessions.prefix(1) {
                DispatchQueue.main.async {
                    session.pause()
                }
                print("⚠️ 内存警告，暂停会话: \(session.rootPath)")
            }
        }
    }
}
