import Foundation
import AppKit

// MARK: - 共享结构体定义
// 这个文件包含所有模块共享的结构体类型，避免重复定义

/// 扫描统计信息 - 统一定义
public struct ScanStatistics: Codable, Equatable {
    /// 已扫描文件数
    public var filesScanned: Int = 0
    
    /// 已扫描目录数
    public var directoriesScanned: Int = 0
    
    /// 已扫描总字节数
    public var totalBytesScanned: Int64 = 0
    
    /// 扫描开始时间
    public var startTime: Date?
    
    /// 最后更新时间
    public var lastUpdated: Date = Date()
    
    /// 扫描速度（文件/秒）
    public var scanSpeed: Double = 0.0
    
    /// 错误数量
    public var errorCount: Int = 0
    
    /// 跳过的文件数
    public var skippedFiles: Int = 0
    
    public init() {}
    
    public init(filesScanned: Int, directoriesScanned: Int, totalBytesScanned: Int64) {
        self.filesScanned = filesScanned
        self.directoriesScanned = directoriesScanned
        self.totalBytesScanned = totalBytesScanned
        self.lastUpdated = Date()
    }
    
    /// 重置统计信息
    public mutating func reset() {
        filesScanned = 0
        directoriesScanned = 0
        totalBytesScanned = 0
        startTime = nil
        lastUpdated = Date()
        scanSpeed = 0.0
        errorCount = 0
        skippedFiles = 0
    }
    
    /// 总扫描项目数
    public var totalItemsScanned: Int {
        return filesScanned + directoriesScanned
    }
    
    /// 扫描持续时间
    public var duration: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
}

/// 扫描配置 - 统一定义
public struct ScanConfiguration: Codable, Equatable {
    /// 是否包含隐藏文件
    public var includeHiddenFiles: Bool = false
    
    /// 是否跟随符号链接
    public var followSymbolicLinks: Bool = false
    
    /// 最大扫描深度（0表示无限制）
    public var maxDepth: Int = 0
    
    /// 文件大小过滤器（最小大小，字节）
    public var minFileSize: Int64 = 0
    
    /// 文件大小过滤器（最大大小，字节，0表示无限制）
    public var maxFileSize: Int64 = 0
    
    /// 文件扩展名过滤器（空数组表示不过滤）
    public var fileExtensionFilter: [String] = []
    
    /// 排除的目录名称
    public var excludedDirectories: Set<String> = [".git", ".svn", "node_modules", ".DS_Store"]
    
    /// 排除的文件名称
    public var excludedFiles: Set<String> = [".DS_Store", "Thumbs.db", "desktop.ini"]
    
    /// 是否在严重错误时停止扫描
    public var stopOnCriticalError: Bool = false
    
    /// 扫描线程数
    public var threadCount: Int = 4
    
    /// 进度更新间隔（毫秒）
    public var progressUpdateInterval: Int = 100
    
    public init() {}
    
    /// 创建默认配置
    public static func `default`() -> ScanConfiguration {
        return ScanConfiguration()
    }
    
    /// 创建快速扫描配置
    public static func fastScan() -> ScanConfiguration {
        var config = ScanConfiguration()
        config.includeHiddenFiles = false
        config.followSymbolicLinks = false
        config.maxDepth = 10
        config.threadCount = 8
        config.progressUpdateInterval = 200
        return config
    }
    
    /// 创建深度扫描配置
    public static func deepScan() -> ScanConfiguration {
        var config = ScanConfiguration()
        config.includeHiddenFiles = true
        config.followSymbolicLinks = true
        config.maxDepth = 0
        config.threadCount = 2
        config.progressUpdateInterval = 50
        return config
    }
}

/// 扫描错误 - 统一定义
public struct ScanError: Codable, Equatable, Identifiable {
    public let id: UUID
    public var message: String
    public var path: String
    public var category: ErrorCategory
    public var severity: ErrorSeverity
    public var timestamp: Date
    public var underlyingError: String?
    
    public init() {
        self.id = UUID()
        self.message = ""
        self.path = ""
        self.category = .unknown
        self.severity = .info
        self.timestamp = Date()
        self.underlyingError = nil
    }
    
    public init(message: String, path: String, category: ErrorCategory, severity: ErrorSeverity, underlyingError: Error? = nil) {
        self.id = UUID()
        self.message = message
        self.path = path
        self.category = category
        self.severity = severity
        self.timestamp = Date()
        self.underlyingError = underlyingError?.localizedDescription
    }
    
    /// 格式化的错误描述
    public var formattedDescription: String {
        let timeStr = DateFormatter.shortTime.string(from: timestamp)
        return "[\(timeStr)] \(severity.displayName): \(message) (\(path))"
    }
}

/// 点坐标 - 统一定义
public struct Point: Codable, Equatable, Hashable {
    public var x: Double
    public var y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public static let zero = Point(x: 0, y: 0)
    
    /// 转换为CGPoint
    public var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    /// 从CGPoint创建
    public init(_ cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
    }
    
    /// 距离计算
    public func distance(to other: Point) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

/// 尺寸 - 统一定义
public struct Size: Codable, Equatable, Hashable {
    public var width: Double
    public var height: Double
    
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    public static let zero = Size(width: 0, height: 0)
    
    /// 转换为CGSize
    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
    
    /// 从CGSize创建
    public init(_ cgSize: CGSize) {
        self.width = Double(cgSize.width)
        self.height = Double(cgSize.height)
    }
    
    /// 面积
    public var area: Double {
        return width * height
    }
    
    /// 是否为空
    public var isEmpty: Bool {
        return width <= 0 || height <= 0
    }
}

/// 矩形 - 统一定义
public struct Rect: Codable, Equatable, Hashable {
    public var origin: Point
    public var size: Size
    
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    public static let zero = Rect(origin: .zero, size: .zero)
    
    /// 转换为CGRect
    public var cgRect: CGRect {
        return CGRect(origin: origin.cgPoint, size: size.cgSize)
    }
    
    /// 从CGRect创建
    public init(_ cgRect: CGRect) {
        self.origin = Point(cgRect.origin)
        self.size = Size(cgRect.size)
    }
    
    /// 中心点
    public var center: Point {
        return Point(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }
    
    /// 最大X坐标
    public var maxX: Double {
        return origin.x + size.width
    }
    
    /// 最大Y坐标
    public var maxY: Double {
        return origin.y + size.height
    }
    
    /// 是否包含点
    public func contains(_ point: Point) -> Bool {
        return point.x >= origin.x && point.x <= maxX &&
               point.y >= origin.y && point.y <= maxY
    }
    
    /// 是否与另一个矩形相交
    public func intersects(_ other: Rect) -> Bool {
        return !(maxX < other.origin.x || origin.x > other.maxX ||
                maxY < other.origin.y || origin.y > other.maxY)
    }
}

/// 颜色信息 - 统一定义
public struct ColorInfo: Codable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    /// 转换为NSColor
    public var nsColor: NSColor {
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 从NSColor创建
    public init(_ nsColor: NSColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    /// 常用颜色
    public static let clear = ColorInfo(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = ColorInfo(red: 0, green: 0, blue: 0)
    public static let white = ColorInfo(red: 1, green: 1, blue: 1)
    public static let red = ColorInfo(red: 1, green: 0, blue: 0)
    public static let green = ColorInfo(red: 0, green: 1, blue: 0)
    public static let blue = ColorInfo(red: 0, green: 0, blue: 1)
}

// MARK: - 扩展

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
