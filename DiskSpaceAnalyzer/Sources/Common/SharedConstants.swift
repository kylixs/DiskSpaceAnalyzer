import Foundation
import AppKit

// MARK: - 共享常量定义
// 这个文件包含所有模块共享的常量，避免重复定义

/// 应用程序常量
public struct AppConstants {
    /// 应用程序信息
    public static let appName = "DiskSpaceAnalyzer"
    public static let appVersion = "1.0.0"
    public static let appBundleId = "com.diskspaceanalyzer.app"
    public static let appDisplayName = "磁盘空间分析器"
    
    /// 窗口尺寸
    public static let defaultWindowWidth: CGFloat = 1200
    public static let defaultWindowHeight: CGFloat = 800
    public static let minWindowWidth: CGFloat = 800
    public static let minWindowHeight: CGFloat = 600
    
    /// 界面布局
    public static let toolbarHeight: CGFloat = 44
    public static let progressBarHeight: CGFloat = 32
    public static let statusBarHeight: CGFloat = 28
    public static let splitViewLeftRatio: CGFloat = 0.3
    public static let splitViewRightRatio: CGFloat = 0.7
    
    /// 文件系统
    public static let maxPathLength = 4096
    public static let maxFileNameLength = 255
    public static let defaultScanTimeout: TimeInterval = 300 // 5分钟
    
    /// 性能参数
    public static let maxConcurrentScans = 4
    public static let defaultUpdateInterval: TimeInterval = 0.5
    public static let maxMemoryUsage: Int64 = 200 * 1024 * 1024 // 200MB
    public static let maxCacheSize = 10000
    
    /// TreeMap参数
    public static let minRectSize: CGFloat = 16
    public static let maxRectSize: CGFloat = 1000
    public static let rectBorderWidth: CGFloat = 1
    public static let rectCornerRadius: CGFloat = 2
    
    /// 动画参数
    public static let defaultAnimationDuration: TimeInterval = 0.3
    public static let fastAnimationDuration: TimeInterval = 0.15
    public static let slowAnimationDuration: TimeInterval = 0.6
    
    /// 颜色透明度
    public static let normalAlpha: CGFloat = 1.0
    public static let dimmedAlpha: CGFloat = 0.6
    public static let highlightAlpha: CGFloat = 0.8
    public static let disabledAlpha: CGFloat = 0.4
}

/// 用户偏好设置键
public struct UserDefaultsKeys {
    public static let theme = "AppTheme"
    public static let windowFrame = "MainWindowFrame"
    public static let splitViewPosition = "SplitViewPosition"
    public static let recentPaths = "RecentPaths"
    public static let scanConfiguration = "ScanConfiguration"
    public static let showHiddenFiles = "ShowHiddenFiles"
    public static let followSymlinks = "FollowSymlinks"
    public static let maxScanDepth = "MaxScanDepth"
    public static let updateInterval = "UpdateInterval"
    public static let enableAnimations = "EnableAnimations"
    public static let enableSounds = "EnableSounds"
    public static let logLevel = "LogLevel"
}

/// 通知名称
public struct NotificationNames {
    public static let themeDidChange = NSNotification.Name("ThemeDidChange")
    public static let scanDidStart = NSNotification.Name("ScanDidStart")
    public static let scanDidComplete = NSNotification.Name("ScanDidComplete")
    public static let scanDidFail = NSNotification.Name("ScanDidFail")
    public static let scanProgressDidUpdate = NSNotification.Name("ScanProgressDidUpdate")
    public static let treeMapDidUpdate = NSNotification.Name("TreeMapDidUpdate")
    public static let directoryTreeDidUpdate = NSNotification.Name("DirectoryTreeDidUpdate")
    public static let selectionDidChange = NSNotification.Name("SelectionDidChange")
    public static let errorDidOccur = NSNotification.Name("ErrorDidOccur")
    public static let memoryWarning = NSNotification.Name("MemoryWarning")
}

/// 文件扩展名分类
public struct FileExtensions {
    public static let documents = Set([
        "txt", "rtf", "doc", "docx", "pages", "pdf", "md", "markdown",
        "odt", "ods", "odp", "xls", "xlsx", "ppt", "pptx", "key", "numbers"
    ])
    
    public static let images = Set([
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "svg", "webp",
        "ico", "psd", "ai", "eps", "raw", "cr2", "nef", "arw", "dng"
    ])
    
    public static let videos = Set([
        "mp4", "avi", "mov", "mkv", "wmv", "flv", "webm", "m4v", "3gp",
        "mpg", "mpeg", "m2v", "vob", "ts", "mts", "m2ts", "f4v"
    ])
    
    public static let audios = Set([
        "mp3", "wav", "aac", "flac", "ogg", "wma", "m4a", "aiff", "au",
        "ra", "mka", "opus", "ape", "ac3", "dts", "amr"
    ])
    
    public static let codes = Set([
        "swift", "py", "js", "ts", "html", "css", "scss", "sass", "less",
        "java", "cpp", "c", "h", "hpp", "cs", "php", "rb", "go", "rs",
        "kt", "scala", "clj", "hs", "ml", "fs", "vb", "pas", "pl", "sh",
        "bat", "ps1", "sql", "json", "xml", "yaml", "yml", "toml", "ini"
    ])
    
    public static let archives = Set([
        "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "lz", "lzma", "z",
        "cab", "iso", "dmg", "pkg", "deb", "rpm", "msi", "exe", "app"
    ])
    
    public static let system = Set([
        "DS_Store", "localized", "plist", "nib", "xib", "storyboard",
        "xcodeproj", "xcworkspace", "pbxproj", "entitlements", "mobileprovision"
    ])
}

/// 错误代码
public struct ErrorCodes {
    // 文件系统错误 (1000-1999)
    public static let fileNotFound = 1001
    public static let permissionDenied = 1002
    public static let pathTooLong = 1003
    public static let diskFull = 1004
    public static let ioError = 1005
    
    // 扫描错误 (2000-2999)
    public static let scanCancelled = 2001
    public static let scanTimeout = 2002
    public static let scanFailed = 2003
    public static let invalidPath = 2004
    public static let tooManyFiles = 2005
    
    // 内存错误 (3000-3999)
    public static let outOfMemory = 3001
    public static let memoryWarning = 3002
    public static let cacheOverflow = 3003
    
    // UI错误 (4000-4999)
    public static let windowCreationFailed = 4001
    public static let renderingFailed = 4002
    public static let animationFailed = 4003
    
    // 数据错误 (5000-5999)
    public static let dataCorrupted = 5001
    public static let serializationFailed = 5002
    public static let deserializationFailed = 5003
    
    // 系统错误 (9000-9999)
    public static let unknownError = 9001
    public static let systemError = 9002
    public static let configurationError = 9003
}

/// 日志级别
public enum LogLevel: String, CaseIterable, Comparable {
    case verbose = "verbose"
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case fatal = "fatal"
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.verbose, .debug, .info, .warning, .error, .fatal]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    public var displayName: String {
        switch self {
        case .verbose: return "详细"
        case .debug: return "调试"
        case .info: return "信息"
        case .warning: return "警告"
        case .error: return "错误"
        case .fatal: return "致命"
        }
    }
    
    public var emoji: String {
        switch self {
        case .verbose: return "💬"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        }
    }
}

/// 性能阈值
public struct PerformanceThresholds {
    /// UI响应时间阈值（毫秒）
    public static let uiResponseTime: TimeInterval = 0.1
    
    /// 扫描速度阈值（文件/秒）
    public static let minScanSpeed: Double = 100
    public static let maxScanSpeed: Double = 10000
    
    /// 内存使用阈值
    public static let memoryWarningThreshold: Int64 = 150 * 1024 * 1024 // 150MB
    public static let memoryCriticalThreshold: Int64 = 200 * 1024 * 1024 // 200MB
    
    /// CPU使用率阈值
    public static let cpuWarningThreshold: Double = 0.7 // 70%
    public static let cpuCriticalThreshold: Double = 0.9 // 90%
    
    /// 文件数量阈值
    public static let largeDirectoryThreshold = 1000
    public static let hugeDirectoryThreshold = 10000
    
    /// 文件大小阈值
    public static let largeFileThreshold: Int64 = 100 * 1024 * 1024 // 100MB
    public static let hugeFileThreshold: Int64 = 1024 * 1024 * 1024 // 1GB
}
