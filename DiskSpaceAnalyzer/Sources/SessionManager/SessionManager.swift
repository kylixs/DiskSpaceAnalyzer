import Foundation
import AppKit
import Common
import DataModel
import PerformanceOptimizer
import ScanEngine

// MARK: - SessionManager Module
// 会话管理模块 - 提供完整的会话管理系统

/// SessionManager模块信息
public struct SessionManagerModule {
    public static let version = "1.0.0"
    public static let description = "会话管理系统"
    
    public static func initialize() {
        print("📋 SessionManager模块初始化")
        print("📋 包含: SessionController、ErrorHandler、PreferencesManager、RecentPathsManager")
        print("📊 版本: \(version)")
        print("✅ SessionManager模块初始化完成")
    }
}

// MARK: - 会话状态

/// 会话状态枚举
public enum SessionState {
    case created        // 已创建
    case scanning       // 扫描中
    case completed      // 已完成
    case paused         // 已暂停
    case cancelled      // 已取消
    case error          // 错误状态
}

/// 会话类型
public enum SessionType {
    case fullScan       // 完整扫描
    case quickScan      // 快速扫描
    case incrementalScan // 增量扫描
}

// MARK: - 扫描会话

/// 扫描会话 - 表示一次完整的扫描过程
public class ScanSession {
    public let id: UUID
    public let type: SessionType
    public let rootPath: String
    public let createdAt: Date
    
    public private(set) var state: SessionState = .created
    public private(set) var progress: Double = 0.0
    public private(set) var rootNode: FileNode?
    public private(set) var error: Error?
    public private(set) var completedAt: Date?
    
    // 统计信息
    public private(set) var totalFiles: Int = 0
    public private(set) var totalDirectories: Int = 0
    public private(set) var totalSize: Int64 = 0
    public private(set) var scanDuration: TimeInterval = 0
    
    public init(type: SessionType, rootPath: String) {
        self.id = UUID()
        self.type = type
        self.rootPath = rootPath
        self.createdAt = Date()
    }
    
    /// 更新会话状态
    internal func updateState(_ newState: SessionState) {
        state = newState
        if newState == .completed || newState == .cancelled || newState == .error {
            completedAt = Date()
            scanDuration = completedAt!.timeIntervalSince(createdAt)
        }
    }
    
    /// 更新进度
    internal func updateProgress(_ newProgress: Double) {
        progress = max(0.0, min(1.0, newProgress))
    }
    
    /// 设置扫描结果
    internal func setResult(_ node: FileNode) {
        rootNode = node
        updateStatistics(from: node)
    }
    
    /// 设置错误
    internal func setError(_ error: Error) {
        self.error = error
        updateState(.error)
    }
    
    private func updateStatistics(from node: FileNode) {
        var fileCount = 0
        var dirCount = 0
        var totalBytes: Int64 = 0
        
        func traverse(_ node: FileNode) {
            if node.isDirectory {
                dirCount += 1
                for child in node.children {
                    traverse(child)
                }
            } else {
                fileCount += 1
                totalBytes += node.size
            }
        }
        
        traverse(node)
        
        totalFiles = fileCount
        totalDirectories = dirCount
        totalSize = totalBytes
    }
    
    /// 获取会话摘要
    public func getSummary() -> String {
        let stateText = getStateText()
        let progressText = String(format: "%.1f%%", progress * 100)
        let sizeText = SharedUtilities.formatFileSize(totalSize)
        
        return "\(rootPath) - \(stateText) (\(progressText)) - \(totalFiles)个文件, \(sizeText)"
    }
    
    private func getStateText() -> String {
        switch state {
        case .created: return "已创建"
        case .scanning: return "扫描中"
        case .completed: return "已完成"
        case .paused: return "已暂停"
        case .cancelled: return "已取消"
        case .error: return "错误"
        }
    }
}

// MARK: - 会话控制器

/// 会话控制器 - 管理扫描会话的完整生命周期
public class SessionController {
    public static let shared = SessionController()
    
    // 会话管理
    private var sessions: [UUID: ScanSession] = [:]
    private var activeSessions: [UUID] = []
    private let maxConcurrentSessions = 3
    
    // 扫描引擎
    private let scanEngine = FileSystemScanner.shared
    
    // 队列管理
    private let sessionQueue = DispatchQueue(label: "SessionController", attributes: .concurrent)
    private let stateQueue = DispatchQueue(label: "SessionState")
    
    // 回调
    public var onSessionCreated: ((ScanSession) -> Void)?
    public var onSessionStateChanged: ((ScanSession, SessionState, SessionState) -> Void)?
    public var onSessionProgressUpdated: ((ScanSession, Double) -> Void)?
    public var onSessionCompleted: ((ScanSession) -> Void)?
    public var onSessionError: ((ScanSession, Error) -> Void)?
    
    private init() {
        setupScanEngineCallbacks()
    }
    
    private func setupScanEngineCallbacks() {
        // 设置扫描引擎回调
        scanEngine.onProgress = { [weak self] progress in
            // 简化的进度计算，基于已扫描的项目数
            let progressValue = Double(progress.totalItemsScanned) / 1000.0 // 简化计算
            self?.handleScanProgress(min(progressValue, 1.0))
        }
        
        scanEngine.onCompleted = { [weak self] result in
            self?.handleScanCompleted(result.rootNode)
        }
        
        scanEngine.onError = { [weak self] error in
            self?.handleScanError(error)
        }
    }
    
    /// 创建新会话
    public func createSession(type: SessionType = .fullScan, rootPath: String) -> ScanSession {
        let session = ScanSession(type: type, rootPath: rootPath)
        
        stateQueue.sync {
            sessions[session.id] = session
        }
        
        onSessionCreated?(session)
        return session
    }
    
    /// 开始扫描会话
    public func startSession(_ session: ScanSession) {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查并发限制
            if self.activeSessions.count >= self.maxConcurrentSessions {
                // 加入等待队列
                return
            }
            
            // 更新状态
            let oldState = session.state
            session.updateState(.scanning)
            self.activeSessions.append(session.id)
            
            // 通知状态变化
            DispatchQueue.main.async {
                self.onSessionStateChanged?(session, oldState, .scanning)
            }
            
            // 开始扫描
            self.sessionQueue.async {
                self.performScan(for: session)
            }
        }
    }
    
    /// 暂停会话
    public func pauseSession(_ session: ScanSession) {
        stateQueue.async { [weak self] in
            guard session.state == .scanning else { return }
            
            let oldState = session.state
            session.updateState(.paused)
            
            // 从活跃会话中移除
            if let index = self?.activeSessions.firstIndex(of: session.id) {
                self?.activeSessions.remove(at: index)
            }
            
            DispatchQueue.main.async {
                self?.onSessionStateChanged?(session, oldState, .paused)
            }
        }
    }
    
    /// 取消会话
    public func cancelSession(_ session: ScanSession) {
        stateQueue.async { [weak self] in
            let oldState = session.state
            session.updateState(.cancelled)
            
            // 从活跃会话中移除
            if let index = self?.activeSessions.firstIndex(of: session.id) {
                self?.activeSessions.remove(at: index)
            }
            
            DispatchQueue.main.async {
                self?.onSessionStateChanged?(session, oldState, .cancelled)
            }
        }
    }
    
    /// 删除会话
    public func deleteSession(_ session: ScanSession) {
        stateQueue.async { [weak self] in
            // 如果正在运行，先取消
            if session.state == .scanning {
                self?.cancelSession(session)
            }
            
            // 从会话列表中移除
            self?.sessions.removeValue(forKey: session.id)
        }
    }
    
    /// 获取所有会话
    public func getAllSessions() -> [ScanSession] {
        return stateQueue.sync {
            return Array(sessions.values).sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    /// 获取活跃会话
    public func getActiveSessions() -> [ScanSession] {
        return stateQueue.sync {
            return activeSessions.compactMap { sessions[$0] }
        }
    }
    
    /// 获取会话
    public func getSession(id: UUID) -> ScanSession? {
        return stateQueue.sync {
            return sessions[id]
        }
    }
    
    private func performScan(for session: ScanSession) {
        Task {
            do {
                // 开始扫描
                try await scanEngine.startScan(at: session.rootPath)
                
            } catch {
                handleScanError(error, for: session)
            }
        }
    }
    
    // 简化的扫描选项结构（内部使用）
    private struct SimpleScanOptions {
        let includeHiddenFiles: Bool
        let followSymlinks: Bool
        let maxDepth: Int?
        
        init(includeHiddenFiles: Bool = true, followSymlinks: Bool = false, maxDepth: Int? = nil) {
            self.includeHiddenFiles = includeHiddenFiles
            self.followSymlinks = followSymlinks
            self.maxDepth = maxDepth
        }
    }
    
    private func createScanOptions(for type: SessionType) -> SimpleScanOptions {
        switch type {
        case .fullScan:
            return SimpleScanOptions(
                includeHiddenFiles: true,
                followSymlinks: false,
                maxDepth: nil
            )
        case .quickScan:
            return SimpleScanOptions(
                includeHiddenFiles: false,
                followSymlinks: false,
                maxDepth: 5
            )
        case .incrementalScan:
            return SimpleScanOptions(
                includeHiddenFiles: true,
                followSymlinks: false,
                maxDepth: nil
            )
        }
    }
    
    private func handleScanProgress(_ progress: Double) {
        // 找到当前活跃的会话
        guard let activeSession = getActiveSessions().first else { return }
        
        activeSession.updateProgress(progress)
        
        DispatchQueue.main.async { [weak self] in
            self?.onSessionProgressUpdated?(activeSession, progress)
        }
    }
    
    private func handleScanCompleted(_ rootNode: FileNode) {
        // 找到当前活跃的会话
        guard let activeSession = getActiveSessions().first else { return }
        
        stateQueue.async { [weak self] in
            let oldState = activeSession.state
            activeSession.setResult(rootNode)
            activeSession.updateState(.completed)
            
            // 从活跃会话中移除
            if let index = self?.activeSessions.firstIndex(of: activeSession.id) {
                self?.activeSessions.remove(at: index)
            }
            
            DispatchQueue.main.async {
                self?.onSessionStateChanged?(activeSession, oldState, .completed)
                self?.onSessionCompleted?(activeSession)
            }
        }
    }
    
    private func handleScanError(_ error: Error, for session: ScanSession? = nil) {
        let targetSession = session ?? getActiveSessions().first
        guard let activeSession = targetSession else { return }
        
        stateQueue.async { [weak self] in
            let oldState = activeSession.state
            activeSession.setError(error)
            
            // 从活跃会话中移除
            if let index = self?.activeSessions.firstIndex(of: activeSession.id) {
                self?.activeSessions.remove(at: index)
            }
            
            DispatchQueue.main.async {
                self?.onSessionStateChanged?(activeSession, oldState, .error)
                self?.onSessionError?(activeSession, error)
            }
        }
    }
}

// MARK: - 错误处理器

/// 应用错误类型
public enum AppError: Error, LocalizedError {
    case scanError(String)
    case fileSystemError(String)
    case permissionDenied(String)
    case diskSpaceInsufficient
    case networkError(String)
    case dataCorruption(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .scanError(let message):
            return "扫描错误: \(message)"
        case .fileSystemError(let message):
            return "文件系统错误: \(message)"
        case .permissionDenied(let path):
            return "权限不足: 无法访问 \(path)"
        case .diskSpaceInsufficient:
            return "磁盘空间不足"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .dataCorruption(let message):
            return "数据损坏: \(message)"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .scanError:
            return "请检查路径是否存在并重试"
        case .fileSystemError:
            return "请检查文件系统状态"
        case .permissionDenied:
            return "请检查文件访问权限"
        case .diskSpaceInsufficient:
            return "请清理磁盘空间后重试"
        case .networkError:
            return "请检查网络连接"
        case .dataCorruption:
            return "请重新扫描或恢复数据"
        case .unknownError:
            return "请重启应用程序或联系技术支持"
        }
    }
}

/// 错误处理器 - 统一的错误处理系统
public class ErrorHandler {
    public static let shared = ErrorHandler()
    
    // 错误记录
    private var errorHistory: [ErrorRecord] = []
    private let maxErrorHistory = 100
    
    // 错误统计
    private var errorCounts: [String: Int] = [:]
    
    // 回调
    public var onErrorOccurred: ((AppError) -> Void)?
    public var onCriticalError: ((AppError) -> Void)?
    
    private init() {}
    
    /// 处理错误
    public func handleError(_ error: Error, context: String = "") {
        let appError = convertToAppError(error)
        let record = ErrorRecord(error: appError, context: context, timestamp: Date())
        
        // 记录错误
        recordError(record)
        
        // 更新统计
        updateErrorStatistics(appError)
        
        // 通知错误
        onErrorOccurred?(appError)
        
        // 检查是否为严重错误
        if isCriticalError(appError) {
            onCriticalError?(appError)
        }
        
        // 记录日志
        logError(record)
    }
    
    /// 显示错误对话框
    public func showErrorDialog(_ error: AppError, in window: NSWindow? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "发生错误"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            
            if error.recoverySuggestion != nil {
                alert.addButton(withTitle: "查看建议")
            }
            
            let response = alert.runModal()
            
            if response == .alertSecondButtonReturn, let suggestion = error.recoverySuggestion {
                self.showRecoverySuggestion(suggestion, in: window)
            }
        }
    }
    
    /// 获取错误历史
    public func getErrorHistory() -> [ErrorRecord] {
        return errorHistory
    }
    
    /// 获取错误统计
    public func getErrorStatistics() -> [String: Int] {
        return errorCounts
    }
    
    /// 清除错误历史
    public func clearErrorHistory() {
        errorHistory.removeAll()
        errorCounts.removeAll()
    }
    
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // 根据错误类型转换
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSCocoaErrorDomain:
            if nsError.code == NSFileReadNoPermissionError {
                return .permissionDenied(nsError.localizedDescription)
            } else if nsError.code == NSFileReadNoSuchFileError {
                return .fileSystemError("文件不存在")
            }
        case NSPOSIXErrorDomain:
            if nsError.code == EACCES {
                return .permissionDenied("访问被拒绝")
            } else if nsError.code == ENOSPC {
                return .diskSpaceInsufficient
            }
        default:
            break
        }
        
        return .unknownError(error.localizedDescription)
    }
    
    private func recordError(_ record: ErrorRecord) {
        errorHistory.append(record)
        
        // 限制历史记录数量
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
    }
    
    private func updateErrorStatistics(_ error: AppError) {
        let errorType = String(describing: error)
        errorCounts[errorType, default: 0] += 1
    }
    
    private func isCriticalError(_ error: AppError) -> Bool {
        switch error {
        case .diskSpaceInsufficient, .dataCorruption:
            return true
        default:
            return false
        }
    }
    
    private func logError(_ record: ErrorRecord) {
        let timestamp = DateFormatter.localizedString(from: record.timestamp, dateStyle: .short, timeStyle: .medium)
        let logMessage = "[\(timestamp)] ERROR: \(record.error.localizedDescription)"
        
        if !record.context.isEmpty {
            print("\(logMessage) (Context: \(record.context))")
        } else {
            print(logMessage)
        }
    }
    
    private func showRecoverySuggestion(_ suggestion: String, in window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = "恢复建议"
        alert.informativeText = suggestion
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

/// 错误记录
public struct ErrorRecord {
    public let error: AppError
    public let context: String
    public let timestamp: Date
    
    public init(error: AppError, context: String, timestamp: Date) {
        self.error = error
        self.context = context
        self.timestamp = timestamp
    }
}

// MARK: - 偏好设置管理器

/// 偏好设置管理器 - 管理应用程序设置
public class PreferencesManager {
    public static let shared = PreferencesManager()
    
    private let userDefaults = UserDefaults.standard
    
    // 设置键
    private enum Keys {
        static let scanIncludeHiddenFiles = "scanIncludeHiddenFiles"
        static let scanFollowSymlinks = "scanFollowSymlinks"
        static let scanMaxDepth = "scanMaxDepth"
        static let uiShowFileExtensions = "uiShowFileExtensions"
        static let uiColorScheme = "uiColorScheme"
        static let uiTreeMapAnimation = "uiTreeMapAnimation"
        static let performanceMaxConcurrentScans = "performanceMaxConcurrentScans"
        static let performanceCacheSize = "performanceCacheSize"
        static let windowFrame = "windowFrame"
        static let windowSplitterPosition = "windowSplitterPosition"
    }
    
    private init() {
        registerDefaults()
    }
    
    private func registerDefaults() {
        let defaults: [String: Any] = [
            Keys.scanIncludeHiddenFiles: false,
            Keys.scanFollowSymlinks: false,
            Keys.scanMaxDepth: 0, // 0表示无限制
            Keys.uiShowFileExtensions: true,
            Keys.uiColorScheme: "auto",
            Keys.uiTreeMapAnimation: true,
            Keys.performanceMaxConcurrentScans: 3,
            Keys.performanceCacheSize: 100
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    // MARK: - 扫描设置
    
    public var scanIncludeHiddenFiles: Bool {
        get { userDefaults.bool(forKey: Keys.scanIncludeHiddenFiles) }
        set { userDefaults.set(newValue, forKey: Keys.scanIncludeHiddenFiles) }
    }
    
    public var scanFollowSymlinks: Bool {
        get { userDefaults.bool(forKey: Keys.scanFollowSymlinks) }
        set { userDefaults.set(newValue, forKey: Keys.scanFollowSymlinks) }
    }
    
    public var scanMaxDepth: Int {
        get { userDefaults.integer(forKey: Keys.scanMaxDepth) }
        set { userDefaults.set(newValue, forKey: Keys.scanMaxDepth) }
    }
    
    // MARK: - 界面设置
    
    public var uiShowFileExtensions: Bool {
        get { userDefaults.bool(forKey: Keys.uiShowFileExtensions) }
        set { userDefaults.set(newValue, forKey: Keys.uiShowFileExtensions) }
    }
    
    public var uiColorScheme: String {
        get { userDefaults.string(forKey: Keys.uiColorScheme) ?? "auto" }
        set { userDefaults.set(newValue, forKey: Keys.uiColorScheme) }
    }
    
    public var uiTreeMapAnimation: Bool {
        get { userDefaults.bool(forKey: Keys.uiTreeMapAnimation) }
        set { userDefaults.set(newValue, forKey: Keys.uiTreeMapAnimation) }
    }
    
    // MARK: - 性能设置
    
    public var performanceMaxConcurrentScans: Int {
        get { userDefaults.integer(forKey: Keys.performanceMaxConcurrentScans) }
        set { userDefaults.set(newValue, forKey: Keys.performanceMaxConcurrentScans) }
    }
    
    public var performanceCacheSize: Int {
        get { userDefaults.integer(forKey: Keys.performanceCacheSize) }
        set { userDefaults.set(newValue, forKey: Keys.performanceCacheSize) }
    }
    
    // MARK: - 窗口状态
    
    public var windowFrame: NSRect? {
        get {
            let frameString = userDefaults.string(forKey: Keys.windowFrame)
            return frameString.map { NSRectFromString($0) }
        }
        set {
            if let frame = newValue {
                userDefaults.set(NSStringFromRect(frame), forKey: Keys.windowFrame)
            } else {
                userDefaults.removeObject(forKey: Keys.windowFrame)
            }
        }
    }
    
    public var windowSplitterPosition: Double? {
        get {
            let position = userDefaults.double(forKey: Keys.windowSplitterPosition)
            return position > 0 ? position : nil
        }
        set {
            if let position = newValue {
                userDefaults.set(position, forKey: Keys.windowSplitterPosition)
            } else {
                userDefaults.removeObject(forKey: Keys.windowSplitterPosition)
            }
        }
    }
    
    /// 重置所有设置
    public func resetToDefaults() {
        let keys = [
            Keys.scanIncludeHiddenFiles,
            Keys.scanFollowSymlinks,
            Keys.scanMaxDepth,
            Keys.uiShowFileExtensions,
            Keys.uiColorScheme,
            Keys.uiTreeMapAnimation,
            Keys.performanceMaxConcurrentScans,
            Keys.performanceCacheSize,
            Keys.windowFrame,
            Keys.windowSplitterPosition
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// 导出设置
    public func exportSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        
        settings["scanIncludeHiddenFiles"] = scanIncludeHiddenFiles
        settings["scanFollowSymlinks"] = scanFollowSymlinks
        settings["scanMaxDepth"] = scanMaxDepth
        settings["uiShowFileExtensions"] = uiShowFileExtensions
        settings["uiColorScheme"] = uiColorScheme
        settings["uiTreeMapAnimation"] = uiTreeMapAnimation
        settings["performanceMaxConcurrentScans"] = performanceMaxConcurrentScans
        settings["performanceCacheSize"] = performanceCacheSize
        
        return settings
    }
    
    /// 导入设置
    public func importSettings(_ settings: [String: Any]) {
        for (key, value) in settings {
            userDefaults.set(value, forKey: key)
        }
    }
}

// MARK: - 最近路径管理器

/// 最近路径管理器 - 管理最近扫描的路径
public class RecentPathsManager {
    public static let shared = RecentPathsManager()
    
    private let userDefaults = UserDefaults.standard
    private let recentPathsKey = "recentPaths"
    private let maxRecentPaths = 10
    
    private init() {}
    
    /// 添加最近路径
    public func addRecentPath(_ path: String) {
        var recentPaths = getRecentPaths()
        
        // 移除已存在的路径
        recentPaths.removeAll { $0 == path }
        
        // 添加到开头
        recentPaths.insert(path, at: 0)
        
        // 限制数量
        if recentPaths.count > maxRecentPaths {
            recentPaths = Array(recentPaths.prefix(maxRecentPaths))
        }
        
        // 保存
        userDefaults.set(recentPaths, forKey: recentPathsKey)
    }
    
    /// 获取最近路径
    public func getRecentPaths() -> [String] {
        return userDefaults.stringArray(forKey: recentPathsKey) ?? []
    }
    
    /// 移除最近路径
    public func removeRecentPath(_ path: String) {
        var recentPaths = getRecentPaths()
        recentPaths.removeAll { $0 == path }
        userDefaults.set(recentPaths, forKey: recentPathsKey)
    }
    
    /// 清除所有最近路径
    public func clearRecentPaths() {
        userDefaults.removeObject(forKey: recentPathsKey)
    }
    
    /// 检查路径是否存在
    public func validateRecentPaths() {
        let recentPaths = getRecentPaths()
        let validPaths = recentPaths.filter { path in
            FileManager.default.fileExists(atPath: path)
        }
        
        if validPaths.count != recentPaths.count {
            userDefaults.set(validPaths, forKey: recentPathsKey)
        }
    }
}

// MARK: - 会话管理器

/// 会话管理器 - 统一管理所有会话相关功能
public class SessionManager {
    public static let shared = SessionManager()
    
    private let sessionController = SessionController.shared
    private let errorHandler = ErrorHandler.shared
    private let preferencesManager = PreferencesManager.shared
    private let recentPathsManager = RecentPathsManager.shared
    
    private init() {
        setupErrorHandling()
    }
    
    private func setupErrorHandling() {
        // 设置错误处理回调
        errorHandler.onErrorOccurred = { [weak self] error in
            self?.handleApplicationError(error)
        }
        
        errorHandler.onCriticalError = { [weak self] error in
            self?.handleCriticalError(error)
        }
    }
    
    /// 创建并开始新的扫描会话
    public func startNewScan(path: String, type: SessionType = .fullScan) -> ScanSession {
        // 添加到最近路径
        recentPathsManager.addRecentPath(path)
        
        // 创建会话
        let session = sessionController.createSession(type: type, rootPath: path)
        
        // 开始扫描
        sessionController.startSession(session)
        
        return session
    }
    
    /// 获取所有会话
    public func getAllSessions() -> [ScanSession] {
        return sessionController.getAllSessions()
    }
    
    /// 获取活跃会话
    public func getActiveSessions() -> [ScanSession] {
        return sessionController.getActiveSessions()
    }
    
    /// 暂停会话
    public func pauseSession(_ session: ScanSession) {
        sessionController.pauseSession(session)
    }
    
    /// 恢复会话
    public func resumeSession(_ session: ScanSession) {
        sessionController.startSession(session)
    }
    
    /// 取消会话
    public func cancelSession(_ session: ScanSession) {
        sessionController.cancelSession(session)
    }
    
    /// 删除会话
    public func deleteSession(_ session: ScanSession) {
        sessionController.deleteSession(session)
    }
    
    /// 获取最近路径
    public func getRecentPaths() -> [String] {
        recentPathsManager.validateRecentPaths()
        return recentPathsManager.getRecentPaths()
    }
    
    /// 清除最近路径
    public func clearRecentPaths() {
        recentPathsManager.clearRecentPaths()
    }
    
    /// 获取偏好设置
    public func getPreferences() -> PreferencesManager {
        return preferencesManager
    }
    
    /// 获取错误历史
    public func getErrorHistory() -> [ErrorRecord] {
        return errorHandler.getErrorHistory()
    }
    
    /// 清除错误历史
    public func clearErrorHistory() {
        errorHandler.clearErrorHistory()
    }
    
    /// 显示错误对话框
    public func showError(_ error: Error, in window: NSWindow? = nil) {
        let appError = error as? AppError ?? AppError.unknownError(error.localizedDescription)
        errorHandler.showErrorDialog(appError, in: window)
    }
    
    private func handleApplicationError(_ error: AppError) {
        // 记录应用程序级别的错误处理
        print("应用程序错误: \(error.localizedDescription)")
    }
    
    private func handleCriticalError(_ error: AppError) {
        // 处理严重错误
        print("严重错误: \(error.localizedDescription)")
        
        // 可能需要显示紧急对话框或执行恢复操作
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "严重错误"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}
