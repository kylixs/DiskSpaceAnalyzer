import Foundation
import Combine

/// 会话状态
public enum SessionState {
    case created        // 已创建
    case preparing      // 准备中
    case scanning       // 扫描中
    case processing     // 处理中
    case completed      // 已完成
    case paused         // 已暂停
    case cancelled      // 已取消
    case failed         // 失败
}

/// 会话优先级
public enum SessionPriority: Int, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    public static func < (lhs: SessionPriority, rhs: SessionPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// 扫描会话
public class ScanSession: ObservableObject, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let rootPath: String
    public let priority: SessionPriority
    public let createdAt: Date
    
    @Published public private(set) var state: SessionState = .created
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var currentPath: String = ""
    @Published public private(set) var statistics: ScanStatistics?
    @Published public private(set) var error: Error?
    
    public var startedAt: Date?
    public var completedAt: Date?
    
    /// 会话数据
    public var rootNode: FileNode?
    public var treeMapLayout: TreeMapLayoutResult?
    
    /// 执行时长
    public var executionDuration: TimeInterval? {
        guard let startTime = startedAt else { return nil }
        let endTime = completedAt ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 等待时长
    public var waitingDuration: TimeInterval {
        let startTime = startedAt ?? Date()
        return startTime.timeIntervalSince(createdAt)
    }
    
    // MARK: - Initialization
    
    public init(id: UUID = UUID(), rootPath: String, priority: SessionPriority = .normal) {
        self.id = id
        self.rootPath = rootPath
        self.priority = priority
        self.createdAt = Date()
    }
    
    // MARK: - Public Methods
    
    /// 更新状态
    internal func updateState(_ newState: SessionState) {
        DispatchQueue.main.async {
            self.state = newState
            
            switch newState {
            case .scanning:
                if self.startedAt == nil {
                    self.startedAt = Date()
                }
            case .completed, .cancelled, .failed:
                if self.completedAt == nil {
                    self.completedAt = Date()
                }
            default:
                break
            }
        }
    }
    
    /// 更新进度
    internal func updateProgress(_ newProgress: Double, currentPath: String = "") {
        DispatchQueue.main.async {
            self.progress = max(0.0, min(1.0, newProgress))
            self.currentPath = currentPath
        }
    }
    
    /// 更新统计信息
    internal func updateStatistics(_ stats: ScanStatistics) {
        DispatchQueue.main.async {
            self.statistics = stats
        }
    }
    
    /// 设置错误
    internal func setError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.state = .failed
        }
    }
}

/// 会话控制器 - 管理扫描会话的完整生命周期
public class SessionController: ObservableObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = SessionController()
    
    /// 活动会话
    @Published public private(set) var activeSessions: [ScanSession] = []
    
    /// 会话历史
    @Published public private(set) var sessionHistory: [ScanSession] = []
    
    /// 当前会话
    @Published public private(set) var currentSession: ScanSession?
    
    /// 最大并发会话数
    public var maxConcurrentSessions: Int = 2
    
    /// 会话队列
    private var sessionQueue: [ScanSession] = []
    
    /// 访问锁
    private let accessLock = NSLock()
    
    /// 扫描引擎
    private let scanEngine: ScanEngine
    
    /// TreeMap可视化
    private let treeMapVisualization: TreeMapVisualization
    
    /// 目录树视图
    private let directoryTreeView: DirectoryTreeView
    
    /// 数据持久化
    private let dataPersistence: DataPersistence
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /// 会话完成回调
    public var sessionCompletionCallback: ((ScanSession) -> Void)?
    
    /// 会话失败回调
    public var sessionFailureCallback: ((ScanSession, Error) -> Void)?
    
    /// 会话进度回调
    public var sessionProgressCallback: ((ScanSession, Double) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        self.scanEngine = ScanEngine.shared
        self.treeMapVisualization = TreeMapVisualization.shared
        self.directoryTreeView = DirectoryTreeView.shared
        self.dataPersistence = DataPersistence()
        
        setupIntegration()
        loadSessionHistory()
    }
    
    // MARK: - Public Methods
    
    /// 创建新会话
    public func createSession(rootPath: String, priority: SessionPriority = .normal) -> ScanSession {
        let session = ScanSession(rootPath: rootPath, priority: priority)
        
        accessLock.lock()
        sessionQueue.append(session)
        sessionQueue.sort { $0.priority > $1.priority }
        accessLock.unlock()
        
        scheduleNextSession()
        
        return session
    }
    
    /// 开始会话
    public func startSession(_ session: ScanSession) {
        guard session.state == .created else { return }
        
        session.updateState(.preparing)
        
        // 检查路径有效性
        guard FileManager.default.fileExists(atPath: session.rootPath) else {
            let error = NSError(domain: "SessionController", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "指定的路径不存在: \(session.rootPath)"
            ])
            session.setError(error)
            sessionFailureCallback?(session, error)
            return
        }
        
        // 添加到活动会话
        accessLock.lock()
        activeSessions.append(session)
        currentSession = session
        accessLock.unlock()
        
        // 开始扫描
        session.updateState(.scanning)
        
        let taskId = scanEngine.startScan(at: session.rootPath, priority: .normal)
        
        // 监听扫描进度
        scanEngine.progressUpdateCallback = { [weak self, weak session] stats in
            guard let session = session else { return }
            session.updateProgress(stats.progressPercentage, currentPath: "")
            self?.sessionProgressCallback?(session, stats.progressPercentage)
        }
        
        // 监听扫描完成
        scanEngine.scanCompletionCallback = { [weak self, weak session] stats in
            guard let session = session else { return }
            self?.handleScanCompletion(session: session, statistics: stats)
        }
        
        // 监听扫描错误
        scanEngine.scanErrorCallback = { [weak self, weak session] error in
            guard let session = session else { return }
            self?.handleScanError(session: session, error: error)
        }
    }
    
    /// 暂停会话
    public func pauseSession(_ session: ScanSession) -> Bool {
        guard session.state == .scanning else { return false }
        
        session.updateState(.paused)
        // 这里可以暂停扫描引擎
        return true
    }
    
    /// 恢复会话
    public func resumeSession(_ session: ScanSession) -> Bool {
        guard session.state == .paused else { return false }
        
        session.updateState(.scanning)
        // 这里可以恢复扫描引擎
        return true
    }
    
    /// 取消会话
    public func cancelSession(_ session: ScanSession) -> Bool {
        guard session.state == .scanning || session.state == .paused else { return false }
        
        session.updateState(.cancelled)
        
        // 从活动会话中移除
        accessLock.lock()
        activeSessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        accessLock.unlock()
        
        // 添加到历史
        addToHistory(session)
        
        // 调度下一个会话
        scheduleNextSession()
        
        return true
    }
    
    /// 获取会话
    public func getSession(id: UUID) -> ScanSession? {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return activeSessions.first { $0.id == id } ?? sessionHistory.first { $0.id == id }
    }
    
    /// 获取活动会话
    public func getActiveSessions() -> [ScanSession] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        return activeSessions
    }
    
    /// 获取会话历史
    public func getSessionHistory(limit: Int = 50) -> [ScanSession] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let sortedHistory = sessionHistory.sorted { $0.createdAt > $1.createdAt }
        return Array(sortedHistory.prefix(limit))
    }
    
    /// 清除会话历史
    public func clearSessionHistory() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        sessionHistory.removeAll()
        saveSessionHistory()
    }
    
    /// 保存会话
    public func saveSession(_ session: ScanSession) {
        guard let rootNode = session.rootNode else { return }
        
        let fileName = "session_\(session.id.uuidString).json"
        
        do {
            try dataPersistence.saveData(rootNode, to: fileName)
        } catch {
            LogManager.shared.log("Failed to save session: \(error)", level: .error)
        }
    }
    
    /// 加载会话
    public func loadSession(id: UUID) -> ScanSession? {
        let fileName = "session_\(id.uuidString).json"
        
        do {
            let rootNode: FileNode = try dataPersistence.loadData(from: fileName)
            
            // 创建会话并设置数据
            let session = ScanSession(id: id, rootPath: rootNode.path)
            session.rootNode = rootNode
            session.updateState(.completed)
            
            return session
        } catch {
            LogManager.shared.log("Failed to load session: \(error)", level: .error)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置模块集成
    private func setupIntegration() {
        // 这里可以设置各模块间的集成逻辑
    }
    
    /// 调度下一个会话
    private func scheduleNextSession() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        // 检查是否有空闲槽位
        guard activeSessions.count < maxConcurrentSessions else { return }
        
        // 获取下一个待执行的会话
        guard let nextSession = sessionQueue.first(where: { $0.state == .created }) else { return }
        
        // 从队列中移除
        sessionQueue.removeAll { $0.id == nextSession.id }
        
        // 开始执行
        startSession(nextSession)
    }
    
    /// 处理扫描完成
    private func handleScanCompletion(session: ScanSession, statistics: ScanStatistics) {
        session.updateStatistics(statistics)
        session.updateState(.processing)
        
        // 这里可以进行数据处理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 模拟数据处理
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                session.updateState(.completed)
                self?.completeSession(session)
            }
        }
    }
    
    /// 处理扫描错误
    private func handleScanError(session: ScanSession, error: Error) {
        session.setError(error)
        
        // 从活动会话中移除
        accessLock.lock()
        activeSessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        accessLock.unlock()
        
        // 添加到历史
        addToHistory(session)
        
        // 通知错误
        sessionFailureCallback?(session, error)
        
        // 调度下一个会话
        scheduleNextSession()
    }
    
    /// 完成会话
    private func completeSession(_ session: ScanSession) {
        // 保存会话数据
        saveSession(session)
        
        // 从活动会话中移除
        accessLock.lock()
        activeSessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        accessLock.unlock()
        
        // 添加到历史
        addToHistory(session)
        
        // 通知完成
        sessionCompletionCallback?(session)
        
        // 调度下一个会话
        scheduleNextSession()
    }
    
    /// 添加到历史
    private func addToHistory(_ session: ScanSession) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        sessionHistory.append(session)
        
        // 限制历史数量
        if sessionHistory.count > 100 {
            sessionHistory.removeFirst(sessionHistory.count - 100)
        }
        
        saveSessionHistory()
    }
    
    /// 保存会话历史
    private func saveSessionHistory() {
        // 简化实现，实际项目中可以保存到文件
        UserDefaults.standard.set(sessionHistory.count, forKey: "SessionHistoryCount")
    }
    
    /// 加载会话历史
    private func loadSessionHistory() {
        // 简化实现，实际项目中可以从文件加载
        let count = UserDefaults.standard.integer(forKey: "SessionHistoryCount")
        LogManager.shared.log("Loaded \(count) sessions from history", level: .info)
    }
}

// MARK: - Extensions

extension SessionController {
    
    /// 获取会话统计信息
    public func getSessionStatistics() -> [String: Any] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let totalSessions = activeSessions.count + sessionHistory.count
        let completedSessions = sessionHistory.filter { $0.state == .completed }.count
        let failedSessions = sessionHistory.filter { $0.state == .failed }.count
        let cancelledSessions = sessionHistory.filter { $0.state == .cancelled }.count
        
        return [
            "totalSessions": totalSessions,
            "activeSessions": activeSessions.count,
            "completedSessions": completedSessions,
            "failedSessions": failedSessions,
            "cancelledSessions": cancelledSessions,
            "queuedSessions": sessionQueue.count,
            "maxConcurrentSessions": maxConcurrentSessions
        ]
    }
    
    /// 导出会话报告
    public func exportSessionReport() -> String {
        var report = "=== Session Controller Report ===\n\n"
        
        let stats = getSessionStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Total Sessions: \(stats["totalSessions"] ?? 0)\n"
        report += "Active Sessions: \(stats["activeSessions"] ?? 0)\n"
        report += "Completed Sessions: \(stats["completedSessions"] ?? 0)\n"
        report += "Failed Sessions: \(stats["failedSessions"] ?? 0)\n"
        report += "Cancelled Sessions: \(stats["cancelledSessions"] ?? 0)\n"
        report += "Queued Sessions: \(stats["queuedSessions"] ?? 0)\n"
        report += "Max Concurrent: \(stats["maxConcurrentSessions"] ?? 0)\n\n"
        
        // 活动会话详情
        if !activeSessions.isEmpty {
            report += "=== Active Sessions ===\n"
            for session in activeSessions {
                report += "[\(session.id)] \(session.rootPath) - \(session.state) (\(String(format: "%.1f%%", session.progress * 100)))\n"
            }
            report += "\n"
        }
        
        // 最近完成的会话
        let recentSessions = getSessionHistory(limit: 5)
        if !recentSessions.isEmpty {
            report += "=== Recent Sessions ===\n"
            for session in recentSessions {
                let duration = session.executionDuration ?? 0
                report += "[\(session.id)] \(session.rootPath) - \(session.state) (\(String(format: "%.2fs", duration)))\n"
            }
        }
        
        return report
    }
}
