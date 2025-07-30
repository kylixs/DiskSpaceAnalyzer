import Foundation
import AppKit

/// 错误处理器 - 统一管理应用程序中的错误处理
public class ErrorHandler {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ErrorHandler()
    
    /// 错误历史记录
    private var errorHistory: [AppScanError] = []
    
    /// 最大错误历史记录数量
    private let maxHistoryCount = 1000
    
    /// 错误处理回调
    public var errorCallback: ((AppScanError) -> Void)?
    
    /// 严重错误回调
    public var criticalErrorCallback: ((AppScanError) -> Void)?
    
    /// 错误统计
    private var errorCounts: [ErrorSeverity: Int] = [:]
    
    /// 线程安全队列
    private let queue = DispatchQueue(label: "ErrorHandler", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        setupErrorCounts()
    }
    
    // MARK: - Public Methods
    
    /// 处理错误
    public func handleError(_ error: Error, severity: ErrorSeverity = .error, category: ErrorCategory = .unknown, context: [String: Any] = [:]) {
        let appError: AppScanError
        
        if let scanError = error as? AppScanError {
            appError = scanError
        } else {
            appError = AppScanError(
                code: AppErrorCodes.unknownError,
                severity: severity,
                category: category,
                title: "未知错误",
                message: error.localizedDescription,
                context: context.compactMapValues { "\($0)" }
            )
        }
        
        processError(appError)
    }
    
    /// 处理应用程序错误
    public func handleAppError(code: Int, severity: ErrorSeverity, category: ErrorCategory, title: String, message: String, context: [String: Any] = [:]) {
        let appError = AppScanError(
            code: code,
            severity: severity,
            category: category,
            title: title,
            message: message,
            context: context.compactMapValues { "\($0)" }
        )
        
        processError(appError)
    }
    
    /// 获取错误历史
    public func getErrorHistory() -> [AppScanError] {
        return queue.sync {
            return Array(errorHistory)
        }
    }
    
    /// 获取错误统计
    public func getErrorStatistics() -> [ErrorSeverity: Int] {
        return queue.sync {
            return errorCounts
        }
    }
    
    /// 清除错误历史
    public func clearErrorHistory() {
        queue.async(flags: .barrier) {
            self.errorHistory.removeAll()
            self.setupErrorCounts()
        }
    }
    
    /// 获取特定严重程度的错误数量
    public func getErrorCount(for severity: ErrorSeverity) -> Int {
        return queue.sync {
            return errorCounts[severity] ?? 0
        }
    }
    
    /// 获取总错误数量
    public func getTotalErrorCount() -> Int {
        return queue.sync {
            return errorCounts.values.reduce(0, +)
        }
    }
    
    /// 是否有严重错误
    public func hasCriticalErrors() -> Bool {
        return queue.sync {
            return (errorCounts[.critical] ?? 0) > 0 || (errorCounts[.fatal] ?? 0) > 0
        }
    }
    
    /// 导出错误报告
    public func exportErrorReport() -> String {
        return queue.sync {
            var report = "=== 错误报告 ===\n\n"
            report += "生成时间: \(Date())\n"
            report += "总错误数: \(getTotalErrorCount())\n\n"
            
            // 错误统计
            report += "=== 错误统计 ===\n"
            for severity in ErrorSeverity.allCases {
                let count = errorCounts[severity] ?? 0
                if count > 0 {
                    report += "\(severity.displayName): \(count)\n"
                }
            }
            report += "\n"
            
            // 错误详情
            report += "=== 错误详情 ===\n"
            for (index, error) in errorHistory.enumerated() {
                report += "\n[\(index + 1)] \(error.title)\n"
                report += "时间: \(error.timestamp)\n"
                report += "严重程度: \(error.severity.displayName)\n"
                report += "类别: \(error.category.displayName)\n"
                report += "消息: \(error.message)\n"
                
                if let filePath = error.filePath {
                    report += "文件: \(filePath)\n"
                }
                
                if !error.context.isEmpty {
                    report += "上下文: \(error.context)\n"
                }
                
                report += "---\n"
            }
            
            return report
        }
    }
    
    // MARK: - Private Methods
    
    /// 处理错误
    private func processError(_ error: AppScanError) {
        queue.async(flags: .barrier) {
            // 添加到历史记录
            self.errorHistory.append(error)
            
            // 限制历史记录数量
            if self.errorHistory.count > self.maxHistoryCount {
                self.errorHistory.removeFirst(self.errorHistory.count - self.maxHistoryCount)
            }
            
            // 更新统计
            self.errorCounts[error.severity, default: 0] += 1
            
            // 记录日志
            self.logError(error)
            
            // 触发回调
            DispatchQueue.main.async {
                self.errorCallback?(error)
                
                if error.severity >= .critical {
                    self.criticalErrorCallback?(error)
                }
            }
            
            // 发送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: AppNotificationNames.errorDidOccur,
                    object: error
                )
            }
        }
    }
    
    /// 设置错误计数器
    private func setupErrorCounts() {
        for severity in ErrorSeverity.allCases {
            errorCounts[severity] = 0
        }
    }
    
    /// 记录错误日志
    private func logError(_ error: AppScanError) {
        let logMessage = "[\(error.severity.displayName)] \(error.title): \(error.message)"
        
        switch error.severity {
        case .info:
            print("ℹ️ \(logMessage)")
        case .warning:
            print("⚠️ \(logMessage)")
        case .error:
            print("❌ \(logMessage)")
        case .critical:
            print("🚨 \(logMessage)")
        case .fatal:
            print("💀 \(logMessage)")
        }
        
        // 如果有文件路径，也记录下来
        if let filePath = error.filePath {
            print("   文件: \(filePath)")
        }
        
        // 如果有上下文信息，也记录下来
        if !error.context.isEmpty {
            print("   上下文: \(error.context)")
        }
    }
}

// MARK: - 全局错误处理函数

/// 全局错误处理函数
public func handleError(_ error: Error, severity: ErrorSeverity = .error, category: ErrorCategory = .unknown, context: [String: Any] = [:]) {
    ErrorHandler.shared.handleError(error, severity: severity, category: category, context: context)
}

/// 处理文件系统错误
public func handleFileSystemError(_ error: Error, path: String) {
    let context = ["path": path]
    ErrorHandler.shared.handleError(error, severity: .warning, category: .fileSystem, context: context)
}

/// 处理权限错误
public func handlePermissionError(path: String) {
    let error = AppScanError.permissionDenied(path: path)
    ErrorHandler.shared.handleAppError(
        code: error.code,
        severity: error.severity,
        category: error.category,
        title: error.title,
        message: error.message,
        context: ["path": path]
    )
}

/// 处理内存警告
public func handleMemoryWarning() {
    ErrorHandler.shared.handleAppError(
        code: AppErrorCodes.memoryWarning,
        severity: .warning,
        category: .memory,
        title: "内存警告",
        message: "应用程序内存使用过高，建议释放一些资源"
    )
}

/// 处理扫描取消
public func handleScanCancellation() {
    let error = AppScanError.scanCancelled()
    ErrorHandler.shared.handleAppError(
        code: error.code,
        severity: error.severity,
        category: error.category,
        title: error.title,
        message: error.message
    )
}
