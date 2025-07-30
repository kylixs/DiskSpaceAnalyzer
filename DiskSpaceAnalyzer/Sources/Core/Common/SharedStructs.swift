import Foundation
import AppKit

// MARK: - 共享结构体定义
// 这个文件包含所有模块共享的结构体类型，避免重复定义

/// 扫描统计信息 - 统一定义
public struct ScanStatistics: Codable, Equatable {
    /// 总文件数
    public var totalFiles: Int = 0
    
    /// 总文件夹数
    public var totalDirectories: Int = 0
    
    /// 总大小（字节）
    public var totalSize: Int64 = 0
    
    /// 平均文件大小
    public var averageFileSize: Int64 = 0
    
    /// 最大文件大小
    public var maxFileSize: Int64 = 0
    
    /// 最深目录层级
    public var maxDepth: Int = 0
    
    /// 扫描开始时间
    public var startTime: Date = Date()
    
    /// 扫描结束时间
    public var endTime: Date?
    
    /// 扫描用时（秒）
    public var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    /// 扫描速度（文件/秒）
    public var scanSpeed: Double {
        let duration = self.duration
        return duration > 0 ? Double(totalFiles) / duration : 0
    }
    
    public init() {}
    
    public init(totalFiles: Int, totalDirectories: Int, totalSize: Int64, maxDepth: Int = 0, startTime: Date = Date()) {
        self.totalFiles = totalFiles
        self.totalDirectories = totalDirectories
        self.totalSize = totalSize
        self.maxDepth = maxDepth
        self.startTime = startTime
        self.averageFileSize = totalFiles > 0 ? totalSize / Int64(totalFiles) : 0
    }
    
    /// 更新统计信息
    public mutating func update(files: Int, directories: Int, size: Int64, depth: Int = 0) {
        self.totalFiles += files
        self.totalDirectories += directories
        self.totalSize += size
        self.maxDepth = max(self.maxDepth, depth)
        self.averageFileSize = totalFiles > 0 ? totalSize / Int64(totalFiles) : 0
    }
    
    /// 完成扫描
    public mutating func complete() {
        self.endTime = Date()
    }
}

/// 扫描配置 - 统一定义
public struct ScanConfiguration: Codable, Equatable {
    /// 是否跟随符号链接
    public let followSymlinks: Bool
    
    /// 是否包含隐藏文件
    public let includeHiddenFiles: Bool
    
    /// 最大扫描深度（0表示无限制）
    public let maxDepth: Int
    
    /// 文件大小过滤器（最小大小，字节）
    public let minFileSize: Int64
    
    /// 文件大小过滤器（最大大小，字节，0表示无限制）
    public let maxFileSize: Int64
    
    /// 排除的文件扩展名
    public let excludedExtensions: Set<String>
    
    /// 排除的目录名
    public let excludedDirectories: Set<String>
    
    /// 扫描超时时间（秒，0表示无限制）
    public let timeoutSeconds: TimeInterval
    
    public init(
        followSymlinks: Bool = false,
        includeHiddenFiles: Bool = false,
        maxDepth: Int = 0,
        minFileSize: Int64 = 0,
        maxFileSize: Int64 = 0,
        excludedExtensions: Set<String> = [],
        excludedDirectories: Set<String> = [".git", ".svn", "node_modules", ".DS_Store"],
        timeoutSeconds: TimeInterval = 0
    ) {
        self.followSymlinks = followSymlinks
        self.includeHiddenFiles = includeHiddenFiles
        self.maxDepth = maxDepth
        self.minFileSize = minFileSize
        self.maxFileSize = maxFileSize
        self.excludedExtensions = excludedExtensions
        self.excludedDirectories = excludedDirectories
        self.timeoutSeconds = timeoutSeconds
    }
    
    /// 默认配置
    public static let `default` = ScanConfiguration()
    
    /// 快速扫描配置
    public static let fast = ScanConfiguration(
        maxDepth: 5,
        excludedDirectories: [".git", ".svn", "node_modules", ".DS_Store", "Library", "Cache"]
    )
    
    /// 深度扫描配置
    public static let deep = ScanConfiguration(
        followSymlinks: true,
        includeHiddenFiles: true
    )
}

/// 扫描错误信息 - 统一定义
public struct ScanError: Error, Codable, Equatable {
    /// 错误代码
    public let code: Int
    
    /// 错误严重程度
    public let severity: ErrorSeverity
    
    /// 错误类别
    public let category: ErrorCategory
    
    /// 错误标题
    public let title: String
    
    /// 错误消息
    public let message: String
    
    /// 相关文件路径
    public let filePath: String?
    
    /// 错误发生时间
    public let timestamp: Date
    
    /// 上下文信息
    public let context: [String: String]
    
    public init(
        code: Int,
        severity: ErrorSeverity,
        category: ErrorCategory,
        title: String,
        message: String,
        filePath: String? = nil,
        context: [String: String] = [:]
    ) {
        self.code = code
        self.severity = severity
        self.category = category
        self.title = title
        self.message = message
        self.filePath = filePath
        self.timestamp = Date()
        self.context = context
    }
    
    /// 常见错误类型
    public static func fileNotFound(path: String) -> ScanError {
        return ScanError(
            code: 404,
            severity: .warning,
            category: .fileSystem,
            title: "文件未找到",
            message: "无法找到指定的文件或目录",
            filePath: path
        )
    }
    
    public static func permissionDenied(path: String) -> ScanError {
        return ScanError(
            code: 403,
            severity: .warning,
            category: .permission,
            title: "权限不足",
            message: "没有访问该文件或目录的权限",
            filePath: path
        )
    }
    
    public static func scanCancelled() -> ScanError {
        return ScanError(
            code: 499,
            severity: .info,
            category: .system,
            title: "扫描已取消",
            message: "用户取消了扫描操作"
        )
    }
    
    public static func unknownError(description: String) -> ScanError {
        return ScanError(
            code: 500,
            severity: .error,
            category: .unknown,
            title: "未知错误",
            message: description
        )
    }
}

/// 坐标点 - 统一定义
public struct Point: Codable, Equatable {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public static let zero = Point(x: 0, y: 0)
}

/// 尺寸 - 统一定义
public struct Size: Codable, Equatable {
    public let width: Double
    public let height: Double
    
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    public static let zero = Size(width: 0, height: 0)
    
    public var area: Double {
        return width * height
    }
}

/// 矩形 - 统一定义
public struct Rect: Codable, Equatable {
    public let origin: Point
    public let size: Size
    
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    public static let zero = Rect(origin: .zero, size: .zero)
    
    public var minX: Double { return origin.x }
    public var minY: Double { return origin.y }
    public var maxX: Double { return origin.x + size.width }
    public var maxY: Double { return origin.y + size.height }
    public var midX: Double { return origin.x + size.width / 2 }
    public var midY: Double { return origin.y + size.height / 2 }
    
    public func contains(_ point: Point) -> Bool {
        return point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}

/// 颜色信息 - 统一定义
public struct ColorInfo: Codable, Equatable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public var nsColor: NSColor {
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public static let clear = ColorInfo(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = ColorInfo(red: 0, green: 0, blue: 0)
    public static let white = ColorInfo(red: 1, green: 1, blue: 1)
    public static let red = ColorInfo(red: 1, green: 0, blue: 0)
    public static let green = ColorInfo(red: 0, green: 1, blue: 0)
    public static let blue = ColorInfo(red: 0, green: 0, blue: 1)
}
