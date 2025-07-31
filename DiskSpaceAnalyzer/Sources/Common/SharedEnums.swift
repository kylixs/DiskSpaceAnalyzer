import Foundation
import AppKit

// MARK: - 共享枚举定义
// 这个文件包含所有模块共享的枚举类型，避免重复定义

/// 错误严重程度 - 统一定义
public enum ErrorSeverity: String, Codable, CaseIterable, Comparable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    case fatal = "fatal"
    
    public static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        let order: [ErrorSeverity] = [.info, .warning, .error, .critical, .fatal]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
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

/// 扫描状态 - 统一定义
public enum ScanStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case preparing = "preparing"
    case scanning = "scanning"
    case processing = "processing"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .pending: return "等待中"
        case .preparing: return "准备中"
        case .scanning: return "扫描中"
        case .processing: return "处理中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .failed: return "失败"
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .scanning, .processing, .preparing:
            return true
        default:
            return false
        }
    }
    
    public var isFinished: Bool {
        switch self {
        case .completed, .cancelled, .failed:
            return true
        default:
            return false
        }
    }
}

/// 系统状态 - 统一定义
public enum SystemStatus: String, Codable, CaseIterable {
    case normal = "normal"
    case busy = "busy"
    case warning = "warning"
    case error = "error"
    case maintenance = "maintenance"
    
    public var displayName: String {
        switch self {
        case .normal: return "正常"
        case .busy: return "繁忙"
        case .warning: return "警告"
        case .error: return "错误"
        case .maintenance: return "维护中"
        }
    }
    
    public var color: NSColor {
        switch self {
        case .normal: return .systemGreen
        case .busy: return .systemYellow
        case .warning: return .systemOrange
        case .error: return .systemRed
        case .maintenance: return .systemBlue
        }
    }
}

/// 主题模式 - 统一定义
public enum Theme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

/// 错误类别 - 统一定义
public enum ErrorCategory: String, Codable, CaseIterable {
    case system = "system"
    case permission = "permission"
    case fileSystem = "fileSystem"
    case network = "network"
    case memory = "memory"
    case disk = "disk"
    case user = "user"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .system: return "系统错误"
        case .permission: return "权限错误"
        case .fileSystem: return "文件系统错误"
        case .network: return "网络错误"
        case .memory: return "内存错误"
        case .disk: return "磁盘错误"
        case .user: return "用户错误"
        case .unknown: return "未知错误"
        }
    }
    
    public var icon: String {
        switch self {
        case .system: return "gear"
        case .permission: return "lock"
        case .fileSystem: return "folder"
        case .network: return "network"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .user: return "person"
        case .unknown: return "questionmark"
        }
    }
}

/// 文件类型 - 统一定义
public enum FileType: String, Codable, CaseIterable {
    case directory = "directory"
    case regularFile = "regularFile"
    case symbolicLink = "symbolicLink"
    case hardLink = "hardLink"
    case socket = "socket"
    case characterDevice = "characterDevice"
    case blockDevice = "blockDevice"
    case fifo = "fifo"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .directory: return "目录"
        case .regularFile: return "文件"
        case .symbolicLink: return "符号链接"
        case .hardLink: return "硬链接"
        case .socket: return "套接字"
        case .characterDevice: return "字符设备"
        case .blockDevice: return "块设备"
        case .fifo: return "管道"
        case .unknown: return "未知"
        }
    }
    
    public var icon: String {
        switch self {
        case .directory: return "folder"
        case .regularFile: return "doc"
        case .symbolicLink: return "link"
        case .hardLink: return "link.badge.plus"
        case .socket: return "network"
        case .characterDevice: return "keyboard"
        case .blockDevice: return "externaldrive"
        case .fifo: return "pipe"
        case .unknown: return "questionmark"
        }
    }
}

/// 扫描任务优先级 - 统一定义
public enum ScanTaskPriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    public static func < (lhs: ScanTaskPriority, rhs: ScanTaskPriority) -> Bool {
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

/// 排序方式 - 统一定义
public enum SortOrder: String, Codable, CaseIterable {
    case name = "name"
    case size = "size"
    case type = "type"
    case dateModified = "dateModified"
    case dateCreated = "dateCreated"
    
    public var description: String {
        switch self {
        case .name: return "Name"
        case .size: return "Size"
        case .type: return "Type"
        case .dateModified: return "Date Modified"
        case .dateCreated: return "Date Created"
        }
    }
    
    public var isDateBased: Bool {
        switch self {
        case .dateModified, .dateCreated:
            return true
        default:
            return false
        }
    }
}

/// 视图模式 - 统一定义
public enum ViewMode: String, Codable, CaseIterable {
    case treemap = "treemap"
    case list = "list"
    case tree = "tree"
    case sunburst = "sunburst"
    
    public var description: String {
        switch self {
        case .treemap: return "TreeMap"
        case .list: return "List"
        case .tree: return "Tree"
        case .sunburst: return "Sunburst"
        }
    }
    
    public var supportsZoom: Bool {
        switch self {
        case .treemap, .tree, .sunburst:
            return true
        case .list:
            return false
        }
    }
    
    public var isHierarchical: Bool {
        switch self {
        case .treemap, .tree, .sunburst:
            return true
        case .list:
            return false
        }
    }
}

/// 日志级别 - 统一定义
public enum LogLevel: String, Codable, CaseIterable, Comparable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
    
    public func shouldLog(at level: LogLevel) -> Bool {
        return self >= level
    }
}
