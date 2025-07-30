import Foundation
import Combine

/// 会话管理模块 - 统一的会话管理接口
public class SessionManager: ObservableObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = SessionManager()
    
    /// 会话控制器
    public let sessionController: SessionController
    
    /// 错误处理器
    public let errorHandler: ErrorHandler
    
    /// 日志管理器
    public let logManager: LogManager
    
    /// 进度对话框管理器
    public let progressDialogManager: ProgressDialogManager
    
    /// 应用程序委托
    public let appDelegate: AppDelegate
    
    /// 当前活动会话
    @Published public var currentSession: ScanSession?
    
    /// 会话历史
    @Published public var sessionHistory: [ScanSession] = []
    
    /// 系统状态
    @Published public var systemStatus: SystemStatus = .idle
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.sessionController = SessionController.shared
        self.errorHandler = ErrorHandler.shared
        self.logManager = LogManager.shared
        self.progressDialogManager = ProgressDialogManager.shared
        self.appDelegate = AppDelegate()
        
        setupBindings()
        setupIntegration()
    }
    
    // MARK: - Public Methods
    
    /// 开始新的扫描会话
    public func startScanSession(rootPath: String, priority: SessionPriority = .normal) -> ScanSession {
        logManager.info("Starting new scan session for: \(rootPath)", category: "SessionManager")
        
        let session = sessionController.createSession(rootPath: rootPath, priority: priority)
        
        // 显示进度对话框
        progressDialogManager.showProgressDialog(for: session)
        
        return session
    }
    
    /// 获取系统状态报告
    public func getSystemStatusReport() -> String {
        var report = "=== System Status Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "System Status: \(systemStatus)\n"
        report += "Current Session: \(currentSession?.id.uuidString ?? "None")\n\n"
        
        // 会话统计
        report += sessionController.exportSessionReport()
        report += "\n"
        
        // 错误统计
        let errorStats = errorHandler.getErrorStatistics()
        report += "=== Error Statistics ===\n"
        report += "Total Errors: \(errorStats["totalErrors"] ?? 0)\n"
        report += "Recent Errors: \(errorStats["recentErrors"] ?? 0)\n\n"
        
        // 日志统计
        report += logManager.exportLogReport()
        
        return report
    }
    
    /// 获取性能指标
    public func getPerformanceMetrics() -> [String: Any] {
        var metrics: [String: Any] = [:]
        
        // 会话指标
        metrics["sessionMetrics"] = sessionController.getSessionStatistics()
        
        // 错误指标
        metrics["errorMetrics"] = errorHandler.getErrorStatistics()
        
        // 日志指标
        metrics["logMetrics"] = logManager.getLogStatistics()
        
        // 系统指标
        metrics["systemMetrics"] = [
            "memoryUsage": getMemoryUsage(),
            "cpuUsage": getCPUUsage(),
            "diskUsage": getDiskUsage()
        ]
        
        return metrics
    }
    
    /// 导出完整报告
    public func exportFullReport() -> String {
        var report = "=== DiskSpaceAnalyzer Full Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        report += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n\n"
        
        // 系统状态
        report += getSystemStatusReport()
        report += "\n"
        
        // 性能指标
        let metrics = getPerformanceMetrics()
        report += "=== Performance Metrics ===\n"
        report += "Memory Usage: \(metrics["systemMetrics"] as? [String: Any] ?? [:])\n"
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置数据绑定
    private func setupBindings() {
        // 绑定当前会话
        sessionController.$currentSession
            .assign(to: \.currentSession, on: self)
            .store(in: &cancellables)
        
        // 绑定会话历史
        sessionController.$sessionHistory
            .assign(to: \.sessionHistory, on: self)
            .store(in: &cancellables)
        
        // 监听会话状态变化
        sessionController.$currentSession
            .map { session in
                if let session = session {
                    switch session.state {
                    case .scanning:
                        return SystemStatus.scanning
                    case .processing:
                        return SystemStatus.processing
                    case .completed, .cancelled, .failed:
                        return SystemStatus.idle
                    default:
                        return SystemStatus.preparing
                    }
                } else {
                    return SystemStatus.idle
                }
            }
            .assign(to: \.systemStatus, on: self)
            .store(in: &cancellables)
    }
    
    /// 设置模块集成
    private func setupIntegration() {
        logManager.info("Setting up SessionManager integration", category: "SessionManager")
        
        // 这里可以设置各模块间的集成逻辑
        setupErrorIntegration()
        setupLoggingIntegration()
    }
    
    /// 设置错误集成
    private func setupErrorIntegration() {
        // 将会话错误转发到错误处理器
        sessionController.sessionFailureCallback = { [weak self] session, error in
            self?.errorHandler.handleError(error, severity: .error, category: .fileSystem, context: [
                "sessionId": session.id.uuidString,
                "rootPath": session.rootPath
            ])
        }
    }
    
    /// 设置日志集成
    private func setupLoggingIntegration() {
        // 记录重要的会话事件
        sessionController.sessionCompletionCallback = { [weak self] session in
            let duration = session.executionDuration ?? 0
            self?.logManager.info("Session completed in \(String(format: "%.2f", duration))s: \(session.rootPath)", category: "SessionManager")
        }
    }
    
    /// 获取内存使用情况
    private func getMemoryUsage() -> [String: Any] {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return [
                "resident": info.resident_size,
                "virtual": info.virtual_size
            ]
        } else {
            return [:]
        }
    }
    
    /// 获取CPU使用情况
    private func getCPUUsage() -> Double {
        // 简化实现，实际项目中可以使用更精确的方法
        return 0.0
    }
    
    /// 获取磁盘使用情况
    private func getDiskUsage() -> [String: Any] {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let freeSize = attributes[.systemFreeSize] as? NSNumber
            let totalSize = attributes[.systemSize] as? NSNumber
            
            return [
                "free": freeSize?.int64Value ?? 0,
                "total": totalSize?.int64Value ?? 0
            ]
        } catch {
            return [:]
        }
    }
}

/// 系统状态
public enum SystemStatus {
    case idle       // 空闲
    case preparing  // 准备中
    case scanning   // 扫描中
    case processing // 处理中
    case error      // 错误状态
}

// MARK: - Global Convenience Functions

/// 全局会话管理器访问函数
public func getSessionManager() -> SessionManager {
    return SessionManager.shared
}

/// 开始扫描会话
public func startScan(at path: String, priority: SessionPriority = .normal) -> ScanSession {
    return SessionManager.shared.startScanSession(rootPath: path, priority: priority)
}

/// 获取当前会话
public func getCurrentSession() -> ScanSession? {
    return SessionManager.shared.currentSession
}

/// 获取系统状态
public func getSystemStatus() -> SystemStatus {
    return SessionManager.shared.systemStatus
}
