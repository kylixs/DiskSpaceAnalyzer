import Foundation
import AppKit

/// 错误严重程度
public enum ErrorSeverity: Int, CaseIterable, Comparable {
    case info = 0       // 信息
    case warning = 1    // 警告
    case error = 2      // 错误
    case critical = 3   // 严重错误
    case fatal = 4      // 致命错误
    
    public static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .info: return "信息"
        case .warning: return "警告"
        case .error: return "错误"
        case .critical: return "严重错误"
        case .fatal: return "致命错误"
        }
    }
    
    public var color: NSColor {
        switch self {
        case .info: return .systemBlue
        case .warning: return .systemOrange
        case .error: return .systemRed
        case .critical: return .systemPurple
        case .fatal: return .systemPink
        }
    }
}

/// 错误类别
public enum ErrorCategory {
    case fileSystem     // 文件系统错误
    case permission     // 权限错误
    case memory         // 内存错误
    case network        // 网络错误
    case ui             // 界面错误
    case data           // 数据错误
    case system         // 系统错误
    case unknown        // 未知错误
    
    public var displayName: String {
        switch self {
        case .fileSystem: return "文件系统"
        case .permission: return "权限"
        case .memory: return "内存"
        case .network: return "网络"
        case .ui: return "界面"
        case .data: return "数据"
        case .system: return "系统"
        case .unknown: return "未知"
        }
    }
}

/// 应用程序错误
public struct AppError: Error, Identifiable {
    public let id: UUID
    public let code: Int
    public let severity: ErrorSeverity
    public let category: ErrorCategory
    public let title: String
    public let message: String
    public let underlyingError: Error?
    public let context: [String: Any]
    public let timestamp: Date
    public let stackTrace: String?
    
    public init(code: Int, severity: ErrorSeverity, category: ErrorCategory, title: String, message: String, underlyingError: Error? = nil, context: [String: Any] = [:], stackTrace: String? = nil) {
        self.id = UUID()
        self.code = code
        self.severity = severity
        self.category = category
        self.title = title
        self.message = message
        self.underlyingError = underlyingError
        self.context = context
        self.timestamp = Date()
        self.stackTrace = stackTrace ?? Thread.callStackSymbols.joined(separator: "\n")
    }
    
    public var localizedDescription: String {
        return "\(title): \(message)"
    }
}

/// 错误恢复策略
public enum ErrorRecoveryStrategy {
    case ignore         // 忽略错误
    case retry          // 重试操作
    case fallback       // 使用备用方案
    case userAction     // 需要用户操作
    case restart        // 重启应用
    case none           // 无恢复策略
}

/// 错误处理器 - 统一处理系统中的各种错误和异常
public class ErrorHandler {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ErrorHandler()
    
    /// 错误历史
    private var errorHistory: [AppError] = []
    
    /// 错误计数
    private var errorCounts: [ErrorCategory: Int] = [:]
    
    /// 访问锁
    private let accessLock = NSLock()
    
    /// 日志管理器
    private let logManager: LogManager
    
    /// 最大错误历史数量
    public var maxErrorHistory: Int = 1000
    
    /// 自动重试次数
    public var maxRetryAttempts: Int = 3
    
    /// 重试间隔
    public var retryInterval: TimeInterval = 1.0
    
    /// 错误通知回调
    public var errorNotificationCallback: ((AppError) -> Void)?
    
    /// 错误恢复回调
    public var errorRecoveryCallback: ((AppError, ErrorRecoveryStrategy) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        self.logManager = LogManager.shared
        setupErrorCategories()
    }
    
    // MARK: - Public Methods
    
    /// 处理错误
    public func handleError(_ error: Error, severity: ErrorSeverity = .error, category: ErrorCategory = .unknown, context: [String: Any] = [:]) {
        let appError: AppError
        
        if let existingAppError = error as? AppError {
            appError = existingAppError
        } else {
            appError = AppError(
                code: (error as NSError).code,
                severity: severity,
                category: category,
                title: "\(category.displayName)错误",
                message: error.localizedDescription,
                underlyingError: error,
                context: context
            )
        }
        
        processError(appError)
    }
    
    /// 创建并处理应用错误
    public func handleAppError(code: Int, severity: ErrorSeverity, category: ErrorCategory, title: String, message: String, context: [String: Any] = [:]) {
        let appError = AppError(
            code: code,
            severity: severity,
            category: category,
            title: title,
            message: message,
            context: context
        )
        
        processError(appError)
    }
    
    /// 处理致命错误
    public func handleFatalError(_ message: String, file: String = #file, line: Int = #line) {
        let appError = AppError(
            code: 9999,
            severity: .fatal,
            category: .system,
            title: "致命错误",
            message: message,
            context: [
                "file": file,
                "line": line
            ]
        )
        
        processError(appError)
        
        // 致命错误需要终止应用
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
    
    /// 获取错误历史
    public func getErrorHistory(limit: Int = 100) -> [AppError] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let sortedErrors = errorHistory.sorted { $0.timestamp > $1.timestamp }
        return Array(sortedErrors.prefix(limit))
    }
    
    /// 获取错误统计
    public func getErrorStatistics() -> [String: Any] {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        let totalErrors = errorHistory.count
        let severityCounts = Dictionary(grouping: errorHistory, by: { $0.severity })
            .mapValues { $0.count }
        
        let recentErrors = errorHistory.filter { 
            Date().timeIntervalSince($0.timestamp) < 3600 // 最近1小时
        }.count
        
        return [
            "totalErrors": totalErrors,
            "recentErrors": recentErrors,
            "severityCounts": severityCounts.mapKeys { $0.displayName },
            "categoryCounts": errorCounts.mapKeys { $0.displayName },
            "maxHistorySize": maxErrorHistory
        ]
    }
    
    /// 清除错误历史
    public func clearErrorHistory() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        errorHistory.removeAll()
        errorCounts.removeAll()
        setupErrorCategories()
    }
    
    /// 重试操作
    public func retryOperation<T>(_ operation: @escaping () throws -> T, maxAttempts: Int? = nil) -> T? {
        let attempts = maxAttempts ?? maxRetryAttempts
        
        for attempt in 1...attempts {
            do {
                return try operation()
            } catch {
                if attempt == attempts {
                    handleError(error, severity: .error, category: .system, context: [
                        "retryAttempt": attempt,
                        "maxAttempts": attempts
                    ])
                    return nil
                } else {
                    logManager.log("Retry attempt \(attempt) failed: \(error)", level: .warning)
                    Thread.sleep(forTimeInterval: retryInterval)
                }
            }
        }
        
        return nil
    }
    
    /// 异步重试操作
    public func retryOperationAsync<T>(_ operation: @escaping () async throws -> T, maxAttempts: Int? = nil) async -> T? {
        let attempts = maxAttempts ?? maxRetryAttempts
        
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                if attempt == attempts {
                    handleError(error, severity: .error, category: .system, context: [
                        "retryAttempt": attempt,
                        "maxAttempts": attempts
                    ])
                    return nil
                } else {
                    logManager.log("Async retry attempt \(attempt) failed: \(error)", level: .warning)
                    try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    /// 处理错误
    private func processError(_ error: AppError) {
        // 记录错误
        recordError(error)
        
        // 记录日志
        logError(error)
        
        // 确定恢复策略
        let strategy = determineRecoveryStrategy(for: error)
        
        // 通知错误
        notifyError(error, strategy: strategy)
        
        // 执行恢复策略
        executeRecoveryStrategy(error, strategy: strategy)
    }
    
    /// 记录错误
    private func recordError(_ error: AppError) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        errorHistory.append(error)
        errorCounts[error.category, default: 0] += 1
        
        // 限制历史大小
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistory)
        }
    }
    
    /// 记录错误日志
    private func logError(_ error: AppError) {
        let logLevel: LogLevel
        switch error.severity {
        case .info:
            logLevel = .info
        case .warning:
            logLevel = .warning
        case .error:
            logLevel = .error
        case .critical, .fatal:
            logLevel = .fatal
        }
        
        var logMessage = "[\(error.category.displayName)] \(error.title): \(error.message)"
        
        if !error.context.isEmpty {
            logMessage += " | Context: \(error.context)"
        }
        
        if let underlyingError = error.underlyingError {
            logMessage += " | Underlying: \(underlyingError.localizedDescription)"
        }
        
        logManager.log(logMessage, level: logLevel)
        
        // 对于严重错误，记录堆栈跟踪
        if error.severity >= .critical, let stackTrace = error.stackTrace {
            logManager.log("Stack trace:\n\(stackTrace)", level: logLevel)
        }
    }
    
    /// 确定恢复策略
    private func determineRecoveryStrategy(for error: AppError) -> ErrorRecoveryStrategy {
        switch error.severity {
        case .info:
            return .ignore
        case .warning:
            return .ignore
        case .error:
            switch error.category {
            case .fileSystem, .permission:
                return .userAction
            case .memory:
                return .fallback
            case .network:
                return .retry
            default:
                return .none
            }
        case .critical:
            return .userAction
        case .fatal:
            return .restart
        }
    }
    
    /// 通知错误
    private func notifyError(_ error: AppError, strategy: ErrorRecoveryStrategy) {
        DispatchQueue.main.async { [weak self] in
            self?.errorNotificationCallback?(error)
            
            // 对于需要用户注意的错误，显示通知
            if error.severity >= .error {
                self?.showErrorNotification(error, strategy: strategy)
            }
        }
    }
    
    /// 显示错误通知
    private func showErrorNotification(_ error: AppError, strategy: ErrorRecoveryStrategy) {
        // 在状态栏显示非阻塞的错误提示
        let notification = NSUserNotification()
        notification.title = error.title
        notification.informativeText = error.message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    /// 执行恢复策略
    private func executeRecoveryStrategy(_ error: AppError, strategy: ErrorRecoveryStrategy) {
        switch strategy {
        case .ignore:
            break
        case .retry:
            // 重试逻辑已在retryOperation中实现
            break
        case .fallback:
            // 使用备用方案
            logManager.log("Using fallback strategy for error: \(error.title)", level: .info)
        case .userAction:
            // 通知需要用户操作
            errorRecoveryCallback?(error, strategy)
        case .restart:
            // 重启应用
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSApp.terminate(nil)
            }
        case .none:
            break
        }
    }
    
    /// 设置错误类别
    private func setupErrorCategories() {
        for category in ErrorCategory.allCases {
            errorCounts[category] = 0
        }
    }
}

// MARK: - Extensions

extension ErrorCategory: CaseIterable {
    public static var allCases: [ErrorCategory] {
        return [.fileSystem, .permission, .memory, .network, .ui, .data, .system, .unknown]
    }
}

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}

// MARK: - Global Error Handling Functions

/// 全局错误处理函数
public func handleError(_ error: Error, severity: ErrorSeverity = .error, category: ErrorCategory = .unknown, context: [String: Any] = [:]) {
    ErrorHandler.shared.handleError(error, severity: severity, category: category, context: context)
}

/// 全局致命错误处理函数
public func fatalError(_ message: String, file: String = #file, line: Int = #line) -> Never {
    ErrorHandler.shared.handleFatalError(message, file: file, line: line)
    Swift.fatalError(message, file: file, line: line)
}
