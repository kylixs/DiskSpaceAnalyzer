import Foundation
import AppKit

// MARK: - Common Module
// 这个模块包含所有共享的枚举、结构体、常量和工具类

/// Common模块信息
public struct CommonModule {
    public static let version = "1.0.0"
    public static let description = "共享的枚举、结构体、常量和工具类"
    
    public static func initialize() {
        print("🔧 Common模块初始化")
        print("📋 包含: 枚举、结构体、常量、工具类")
        print("📊 版本: \(version)")
    }
}

// 重新导出所有公共接口，方便其他模块使用
// 这样其他模块只需要 import Common 就可以使用所有共享类型

// 从SharedEnums.swift导出
public typealias AppErrorSeverity = ErrorSeverity
public typealias AppScanStatus = ScanStatus
public typealias AppSystemStatus = SystemStatus
public typealias AppTheme = Theme
public typealias AppErrorCategory = ErrorCategory
public typealias AppFileType = FileType
public typealias AppScanTaskPriority = ScanTaskPriority

// 从SharedStructs.swift导出
public typealias AppScanStatistics = ScanStatistics
public typealias AppScanConfiguration = ScanConfiguration
public typealias AppScanError = ScanError
public typealias AppPoint = Point
public typealias AppSize = Size
public typealias AppRect = Rect
public typealias AppColorInfo = ColorInfo

// 从SharedConstants.swift导出
public typealias AppConstants = AppConstants
public typealias AppUserDefaultsKeys = UserDefaultsKeys
public typealias AppNotificationNames = NotificationNames
public typealias AppFileExtensions = FileExtensions
public typealias AppErrorCodes = ErrorCodes
public typealias AppLogLevel = LogLevel
public typealias AppPerformanceThresholds = PerformanceThresholds

// 从SharedUtilities.swift导出
public typealias AppByteFormatter = ByteFormatter
public typealias AppNumberFormatter = NumberFormatter
public typealias AppTimeFormatter = TimeFormatter
public typealias AppPathUtilities = PathUtilities
public typealias AppColorUtilities = ColorUtilities
public typealias AppGeometryUtilities = GeometryUtilities
public typealias AppPerformanceMonitor = PerformanceMonitor
public typealias AppThreadSafeCounter = ThreadSafeCounter
