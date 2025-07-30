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
    case idle = "idle"
    case preparing = "preparing"
    case scanning = "scanning"
    case processing = "processing"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .idle: return "空闲"
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
}

/// 系统状态 - 统一定义
public enum SystemStatus: String, Codable, CaseIterable {
    case idle = "idle"
    case scanning = "scanning"
    case processing = "processing"
    case error = "error"
    case maintenance = "maintenance"
    
    public var displayName: String {
        switch self {
        case .idle: return "就绪"
        case .scanning: return "扫描中"
        case .processing: return "处理中"
        case .error: return "错误"
        case .maintenance: return "维护中"
        }
    }
}

/// 主题类型 - 统一定义
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
    case fileSystem = "fileSystem"
    case permission = "permission"
    case memory = "memory"
    case network = "network"
    case ui = "ui"
    case data = "data"
    case system = "system"
    case unknown = "unknown"
    
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

/// 文件类型 - 统一定义
public enum FileType: String, Codable, CaseIterable {
    case document = "document"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case code = "code"
    case archive = "archive"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .document: return "文档"
        case .image: return "图片"
        case .video: return "视频"
        case .audio: return "音频"
        case .code: return "代码"
        case .archive: return "压缩包"
        case .other: return "其他"
        }
    }
    
    public var extensions: [String] {
        switch self {
        case .document:
            return ["txt", "doc", "docx", "pdf", "rtf", "pages", "md"]
        case .image:
            return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "svg", "webp"]
        case .video:
            return ["mp4", "avi", "mov", "mkv", "wmv", "flv", "webm", "m4v"]
        case .audio:
            return ["mp3", "wav", "aac", "flac", "ogg", "wma", "m4a"]
        case .code:
            return ["swift", "py", "js", "html", "css", "java", "cpp", "c", "h"]
        case .archive:
            return ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
        case .other:
            return []
        }
    }
    
    public static func from(extension ext: String) -> FileType {
        let lowercased = ext.lowercased()
        for type in FileType.allCases {
            if type.extensions.contains(lowercased) {
                return type
            }
        }
        return .other
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
