import Foundation
import CoreGraphics
import AppKit

/// 坐标系统模块 - 统一的坐标系统管理接口
public class CoordinateSystem {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = CoordinateSystem()
    
    /// 坐标变换器
    public let transformer: CoordinateTransformer
    
    /// HiDPI管理器
    public let hiDPIManager: HiDPIManager
    
    /// 多显示器处理器
    public let multiDisplayHandler: MultiDisplayHandler
    
    /// 调试可视化器
    public let debugVisualizer: DebugVisualizer
    
    /// 是否启用调试模式
    public var isDebugEnabled: Bool {
        get { debugVisualizer.isDebugEnabled }
        set { debugVisualizer.isDebugEnabled = newValue }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.transformer = CoordinateTransformer()
        self.hiDPIManager = HiDPIManager.shared
        self.multiDisplayHandler = MultiDisplayHandler.shared
        self.debugVisualizer = DebugVisualizer.shared
        
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// 配置坐标系统
    public func configure(window: NSWindow?, containerView: NSView?, canvasView: NSView?) {
        transformer.updateViews(window: window, containerView: containerView, canvasView: canvasView)
    }
    
    /// 坐标变换
    public func transform(point: CGPoint, from sourceSpace: CoordinateSpace, to targetSpace: CoordinateSpace) -> TransformResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = transformer.transform(point: point, from: sourceSpace, to: targetSpace)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // 记录调试日志
        if isDebugEnabled {
            debugVisualizer.logCoordinateTransform(
                sourcePoint: point,
                targetPoint: result.point,
                sourceSpace: sourceSpace,
                targetSpace: targetSpace,
                accuracy: result.accuracy,
                duration: duration
            )
        }
        
        return result
    }
    
    /// 批量坐标变换
    public func transformBatch(points: [CGPoint], from sourceSpace: CoordinateSpace, to targetSpace: CoordinateSpace) -> [TransformResult] {
        return transformer.transformBatch(points: points, from: sourceSpace, to: targetSpace)
    }
    
    /// 应用HiDPI缩放
    public func applyHiDPIScaling(to point: CGPoint, for window: NSWindow? = nil) -> CGPoint {
        let scaleFactor = window != nil ? hiDPIManager.getScaleFactor(for: window!) : hiDPIManager.getMainDisplayScaleFactor()
        return hiDPIManager.applyHiDPIScaling(to: point, scaleFactor: scaleFactor)
    }
    
    /// 像素对齐
    public func pixelAlign(_ point: CGPoint, for window: NSWindow? = nil) -> CGPoint {
        let scaleFactor = window != nil ? hiDPIManager.getScaleFactor(for: window!) : hiDPIManager.getMainDisplayScaleFactor()
        return hiDPIManager.pixelAlign(point, scaleFactor: scaleFactor)
    }
    
    /// 跨显示器坐标转换
    public func transformAcrossDisplays(point: CGPoint, from sourceDisplayID: CGDirectDisplayID, to targetDisplayID: CGDirectDisplayID) -> CrossDisplayTransformResult? {
        return multiDisplayHandler.transformAcrossDisplays(point: point, from: sourceDisplayID, to: targetDisplayID)
    }
    
    /// 获取性能统计
    public func getPerformanceStats() -> (cacheHits: Int, cacheMisses: Int, hitRate: Double) {
        let stats = transformer.getCacheStats()
        return (cacheHits: stats.hits, cacheMisses: stats.misses, hitRate: stats.hitRate)
    }
    
    /// 清除缓存
    public func clearCache() {
        transformer.clearCache()
    }
    
    /// 导出调试日志
    public func exportDebugLog() -> String {
        return debugVisualizer.exportDebugLog()
    }
    
    // MARK: - Private Methods
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        // 监听HiDPI变化
        NotificationCenter.default.addObserver(
            forName: HiDPIManager.scaleFactorDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleScaleFactorChange(notification)
        }
        
        // 监听显示器配置变化
        NotificationCenter.default.addObserver(
            forName: MultiDisplayHandler.displayConfigurationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleDisplayConfigurationChange(notification)
        }
    }
    
    /// 处理缩放因子变化
    private func handleScaleFactorChange(_ notification: Notification) {
        // 清除缓存，因为缩放因子变化会影响坐标变换
        clearCache()
        
        if isDebugEnabled {
            debugVisualizer.addDebugInfo(
                type: .display,
                title: "Scale Factor Changed",
                value: "Cache cleared"
            )
        }
    }
    
    /// 处理显示器配置变化
    private func handleDisplayConfigurationChange(_ notification: Notification) {
        // 清除缓存，因为显示器配置变化会影响坐标变换
        clearCache()
        
        if isDebugEnabled {
            debugVisualizer.addDebugInfo(
                type: .display,
                title: "Display Configuration Changed",
                value: "Cache cleared"
            )
        }
    }
}

// MARK: - Convenience Extensions

extension CoordinateSystem {
    
    /// 鼠标事件坐标转换
    public func transformMouseEvent(_ event: NSEvent, to targetSpace: CoordinateSpace) -> CGPoint? {
        let screenPoint = NSEvent.mouseLocation
        let result = transform(point: screenPoint, from: .screen, to: targetSpace)
        return result.point
    }
    
    /// 视图坐标转换
    public func transformViewCoordinate(_ point: CGPoint, from sourceView: NSView, to targetSpace: CoordinateSpace) -> CGPoint? {
        // 将视图坐标转换为窗口坐标
        let windowPoint = sourceView.convert(point, to: nil)
        let result = transform(point: windowPoint, from: .window, to: targetSpace)
        return result.point
    }
    
    /// 检查坐标精度
    public func checkCoordinateAccuracy(point: CGPoint, expectedPoint: CGPoint, tolerance: CGFloat = 0.1) -> Bool {
        let dx = abs(point.x - expectedPoint.x)
        let dy = abs(point.y - expectedPoint.y)
        return dx <= tolerance && dy <= tolerance
    }
}
