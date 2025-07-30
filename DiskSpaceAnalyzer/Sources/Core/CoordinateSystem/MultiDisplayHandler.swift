import Foundation
import CoreGraphics
import AppKit

/// 显示器配置信息
public struct DisplayConfiguration {
    public let displayID: CGDirectDisplayID
    public let frame: CGRect
    public let scaleFactor: CGFloat
    public let isMain: Bool
    public let relativePosition: CGPoint
    public let colorSpace: CGColorSpace?
    
    public init(displayID: CGDirectDisplayID, frame: CGRect, scaleFactor: CGFloat, isMain: Bool, relativePosition: CGPoint, colorSpace: CGColorSpace? = nil) {
        self.displayID = displayID
        self.frame = frame
        self.scaleFactor = scaleFactor
        self.isMain = isMain
        self.relativePosition = relativePosition
        self.colorSpace = colorSpace
    }
}

/// 跨屏坐标转换结果
public struct CrossDisplayTransformResult {
    public let point: CGPoint
    public let sourceDisplayID: CGDirectDisplayID
    public let targetDisplayID: CGDirectDisplayID
    public let scalingApplied: Bool
    
    public init(point: CGPoint, sourceDisplayID: CGDirectDisplayID, targetDisplayID: CGDirectDisplayID, scalingApplied: Bool) {
        self.point = point
        self.sourceDisplayID = sourceDisplayID
        self.targetDisplayID = targetDisplayID
        self.scalingApplied = scalingApplied
    }
}

/// 多显示器处理器 - 管理多显示器环境下的坐标转换
public class MultiDisplayHandler {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = MultiDisplayHandler()
    
    /// 显示器配置映射
    private var displayConfigurations: [CGDirectDisplayID: DisplayConfiguration] = [:]
    
    /// 显示器配置变化通知
    public static let displayConfigurationDidChangeNotification = Notification.Name("MultiDisplayHandler.displayConfigurationDidChange")
    
    /// 观察者
    private var observers: [NSObjectProtocol] = []
    
    /// 配置更新锁
    private let configurationLock = NSLock()
    
    /// HiDPI管理器引用
    private let hiDPIManager = HiDPIManager.shared
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
        updateDisplayConfigurations()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Public Methods
    
    /// 获取所有显示器配置
    public func getAllDisplayConfigurations() -> [DisplayConfiguration] {
        configurationLock.lock()
        defer { configurationLock.unlock() }
        return Array(displayConfigurations.values)
    }
    
    /// 获取指定显示器配置
    public func getDisplayConfiguration(for displayID: CGDirectDisplayID) -> DisplayConfiguration? {
        configurationLock.lock()
        defer { configurationLock.unlock() }
        return displayConfigurations[displayID]
    }
    
    /// 获取主显示器配置
    public func getMainDisplayConfiguration() -> DisplayConfiguration? {
        return getAllDisplayConfigurations().first { $0.isMain }
    }
    
    /// 获取点所在的显示器ID
    public func getDisplayID(for point: CGPoint) -> CGDirectDisplayID? {
        let configurations = getAllDisplayConfigurations()
        
        for config in configurations {
            if config.frame.contains(point) {
                return config.displayID
            }
        }
        
        // 如果没有找到，返回主显示器ID
        return getMainDisplayConfiguration()?.displayID
    }
    
    /// 获取窗口所在的显示器ID
    public func getDisplayID(for window: NSWindow) -> CGDirectDisplayID? {
        guard let screen = window.screen else {
            return getMainDisplayConfiguration()?.displayID
        }
        
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return getMainDisplayConfiguration()?.displayID
        }
        
        return displayID
    }
    
    /// 跨显示器坐标转换
    public func transformAcrossDisplays(point: CGPoint, from sourceDisplayID: CGDirectDisplayID, to targetDisplayID: CGDirectDisplayID) -> CrossDisplayTransformResult? {
        guard let sourceConfig = getDisplayConfiguration(for: sourceDisplayID),
              let targetConfig = getDisplayConfiguration(for: targetDisplayID) else {
            return nil
        }
        
        // 如果是同一个显示器，直接返回
        if sourceDisplayID == targetDisplayID {
            return CrossDisplayTransformResult(
                point: point,
                sourceDisplayID: sourceDisplayID,
                targetDisplayID: targetDisplayID,
                scalingApplied: false
            )
        }
        
        // 转换到全局坐标系
        let globalPoint = CGPoint(
            x: point.x + sourceConfig.frame.origin.x,
            y: point.y + sourceConfig.frame.origin.y
        )
        
        // 转换到目标显示器坐标系
        var targetPoint = CGPoint(
            x: globalPoint.x - targetConfig.frame.origin.x,
            y: globalPoint.y - targetConfig.frame.origin.y
        )
        
        // 应用缩放差异
        var scalingApplied = false
        if sourceConfig.scaleFactor != targetConfig.scaleFactor {
            let scaleRatio = targetConfig.scaleFactor / sourceConfig.scaleFactor
            targetPoint = CGPoint(x: targetPoint.x * scaleRatio, y: targetPoint.y * scaleRatio)
            scalingApplied = true
        }
        
        return CrossDisplayTransformResult(
            point: targetPoint,
            sourceDisplayID: sourceDisplayID,
            targetDisplayID: targetDisplayID,
            scalingApplied: scalingApplied
        )
    }
    
    /// 计算显示器间的相对偏移
    public func getRelativeOffset(from sourceDisplayID: CGDirectDisplayID, to targetDisplayID: CGDirectDisplayID) -> CGPoint? {
        guard let sourceConfig = getDisplayConfiguration(for: sourceDisplayID),
              let targetConfig = getDisplayConfiguration(for: targetDisplayID) else {
            return nil
        }
        
        return CGPoint(
            x: targetConfig.frame.origin.x - sourceConfig.frame.origin.x,
            y: targetConfig.frame.origin.y - sourceConfig.frame.origin.y
        )
    }
    
    /// 获取显示器总边界
    public func getTotalDisplayBounds() -> CGRect {
        let configurations = getAllDisplayConfigurations()
        guard !configurations.isEmpty else {
            return CGRect.zero
        }
        
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        
        for config in configurations {
            minX = min(minX, config.frame.minX)
            minY = min(minY, config.frame.minY)
            maxX = max(maxX, config.frame.maxX)
            maxY = max(maxY, config.frame.maxY)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// 检查是否为多显示器环境
    public func isMultiDisplayEnvironment() -> Bool {
        return getAllDisplayConfigurations().count > 1
    }
    
    /// 获取最接近的显示器
    public func getNearestDisplay(to point: CGPoint) -> DisplayConfiguration? {
        let configurations = getAllDisplayConfigurations()
        guard !configurations.isEmpty else { return nil }
        
        var nearestConfig: DisplayConfiguration?
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for config in configurations {
            let distance = distanceToRect(from: point, to: config.frame)
            if distance < minDistance {
                minDistance = distance
                nearestConfig = config
            }
        }
        
        return nearestConfig
    }
    
    /// 窗口跨显示器移动处理
    public func handleWindowMovedAcrossDisplays(window: NSWindow, from oldDisplayID: CGDirectDisplayID?, to newDisplayID: CGDirectDisplayID) {
        guard let oldDisplayID = oldDisplayID,
              oldDisplayID != newDisplayID else { return }
        
        // 发送跨显示器移动通知
        NotificationCenter.default.post(
            name: NSNotification.Name("WindowMovedAcrossDisplays"),
            object: self,
            userInfo: [
                "window": window,
                "oldDisplayID": oldDisplayID,
                "newDisplayID": newDisplayID
            ]
        )
    }
    
    // MARK: - Private Methods
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        let observer1 = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayConfigurationChange()
        }
        
        observers.append(observer1)
    }
    
    /// 处理显示器配置变化
    private func handleDisplayConfigurationChange() {
        updateDisplayConfigurations()
        
        // 发送配置变化通知
        NotificationCenter.default.post(
            name: Self.displayConfigurationDidChangeNotification,
            object: self,
            userInfo: ["configurations": getAllDisplayConfigurations()]
        )
    }
    
    /// 更新显示器配置
    private func updateDisplayConfigurations() {
        configurationLock.lock()
        defer { configurationLock.unlock() }
        
        displayConfigurations.removeAll()
        
        let mainScreen = NSScreen.main
        
        for screen in NSScreen.screens {
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }
            
            let isMain = screen == mainScreen
            let relativePosition = calculateRelativePosition(for: screen, relativeTo: mainScreen)
            
            let configuration = DisplayConfiguration(
                displayID: displayID,
                frame: screen.frame,
                scaleFactor: screen.backingScaleFactor,
                isMain: isMain,
                relativePosition: relativePosition,
                colorSpace: screen.colorSpace?.cgColorSpace
            )
            
            displayConfigurations[displayID] = configuration
        }
    }
    
    /// 计算相对位置
    private func calculateRelativePosition(for screen: NSScreen, relativeTo mainScreen: NSScreen?) -> CGPoint {
        guard let mainScreen = mainScreen else {
            return CGPoint.zero
        }
        
        return CGPoint(
            x: screen.frame.origin.x - mainScreen.frame.origin.x,
            y: screen.frame.origin.y - mainScreen.frame.origin.y
        )
    }
    
    /// 计算点到矩形的距离
    private func distanceToRect(from point: CGPoint, to rect: CGRect) -> CGFloat {
        if rect.contains(point) {
            return 0
        }
        
        let dx = max(0, max(rect.minX - point.x, point.x - rect.maxX))
        let dy = max(0, max(rect.minY - point.y, point.y - rect.maxY))
        
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Extensions

extension NSWindow {
    /// 获取窗口所在的显示器ID
    public var displayID: CGDirectDisplayID? {
        return MultiDisplayHandler.shared.getDisplayID(for: self)
    }
    
    /// 获取窗口所在的显示器配置
    public var displayConfiguration: DisplayConfiguration? {
        guard let displayID = displayID else { return nil }
        return MultiDisplayHandler.shared.getDisplayConfiguration(for: displayID)
    }
}

extension CGPoint {
    /// 获取点所在的显示器ID
    public var displayID: CGDirectDisplayID? {
        return MultiDisplayHandler.shared.getDisplayID(for: self)
    }
    
    /// 转换到指定显示器坐标系
    public func transformed(to displayID: CGDirectDisplayID) -> CGPoint? {
        guard let sourceDisplayID = self.displayID else { return nil }
        
        let result = MultiDisplayHandler.shared.transformAcrossDisplays(
            point: self,
            from: sourceDisplayID,
            to: displayID
        )
        
        return result?.point
    }
}
