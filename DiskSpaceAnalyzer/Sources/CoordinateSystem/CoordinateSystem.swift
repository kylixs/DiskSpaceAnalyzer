import Foundation
import AppKit
import Common

// MARK: - CoordinateSystem Module
// 坐标系统模块 - 提供多层坐标系统和精确交互功能

/// CoordinateSystem模块信息
public struct CoordinateSystemModule {
    public static let version = "1.0.0"
    public static let description = "多层坐标系统和精确交互功能"
    
    public static func initialize() {
        print("📐 CoordinateSystem模块初始化")
        print("📋 包含: CoordinateTransformer、HiDPIManager、MultiDisplayHandler、DebugVisualizer")
        print("📊 版本: \(version)")
        
        // 初始化HiDPI管理器
        HiDPIManager.shared.initialize()
        
        // 初始化多显示器处理器
        MultiDisplayHandler.shared.initialize()
        
        print("✅ CoordinateSystem模块初始化完成")
    }
}

// MARK: - 坐标系统类型定义

/// 坐标系统类型
public enum CoordinateSystemType: String, CaseIterable {
    case screen = "screen"       // 屏幕坐标系
    case window = "window"       // 窗口坐标系
    case container = "container" // 容器坐标系
    case canvas = "canvas"       // 画布坐标系
    
    public var displayName: String {
        switch self {
        case .screen: return "屏幕坐标"
        case .window: return "窗口坐标"
        case .container: return "容器坐标"
        case .canvas: return "画布坐标"
        }
    }
}

/// 坐标变换信息
public struct CoordinateTransform {
    public let sourceType: CoordinateSystemType
    public let targetType: CoordinateSystemType
    public let transform: CGAffineTransform
    public let scaleFactor: CGFloat
    public let offset: CGPoint
    
    public init(sourceType: CoordinateSystemType, targetType: CoordinateSystemType, transform: CGAffineTransform, scaleFactor: CGFloat = 1.0, offset: CGPoint = .zero) {
        self.sourceType = sourceType
        self.targetType = targetType
        self.transform = transform
        self.scaleFactor = scaleFactor
        self.offset = offset
    }
}

/// 显示器信息
public struct DisplayInfo {
    public let screen: NSScreen
    public let scaleFactor: CGFloat
    public let frame: CGRect
    public let visibleFrame: CGRect
    public let identifier: String
    
    public init(screen: NSScreen) {
        self.screen = screen
        self.scaleFactor = screen.backingScaleFactor
        self.frame = screen.frame
        self.visibleFrame = screen.visibleFrame
        self.identifier = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? String ?? UUID().uuidString
    }
}

/// 调试信息
public struct DebugInfo {
    public let mousePosition: CGPoint
    public let coordinateSystem: CoordinateSystemType
    public let timestamp: Date
    public let additionalInfo: [String: Any]
    
    public init(mousePosition: CGPoint, coordinateSystem: CoordinateSystemType, additionalInfo: [String: Any] = [:]) {
        self.mousePosition = mousePosition
        self.coordinateSystem = coordinateSystem
        self.timestamp = Date()
        self.additionalInfo = additionalInfo
    }
}
