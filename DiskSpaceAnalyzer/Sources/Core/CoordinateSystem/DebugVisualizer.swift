import Foundation
import CoreGraphics
import AppKit

/// 调试信息类型
public enum DebugInfoType {
    case coordinate
    case transform
    case display
    case interaction
    case performance
}

/// 调试信息项
public struct DebugInfoItem {
    public let type: DebugInfoType
    public let title: String
    public let value: String
    public let timestamp: Date
    
    public init(type: DebugInfoType, title: String, value: String, timestamp: Date = Date()) {
        self.type = type
        self.title = title
        self.value = value
        self.timestamp = timestamp
    }
}

/// 坐标变换日志项
public struct CoordinateTransformLog {
    public let sourcePoint: CGPoint
    public let targetPoint: CGPoint
    public let sourceSpace: CoordinateSpace
    public let targetSpace: CoordinateSpace
    public let accuracy: Double
    public let timestamp: Date
    public let duration: TimeInterval
    
    public init(sourcePoint: CGPoint, targetPoint: CGPoint, sourceSpace: CoordinateSpace, targetSpace: CoordinateSpace, accuracy: Double, timestamp: Date = Date(), duration: TimeInterval) {
        self.sourcePoint = sourcePoint
        self.targetPoint = targetPoint
        self.sourceSpace = sourceSpace
        self.targetSpace = targetSpace
        self.accuracy = accuracy
        self.timestamp = timestamp
        self.duration = duration
    }
}

/// 调试可视化器 - 提供坐标系统的可视化调试工具
public class DebugVisualizer {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = DebugVisualizer()
    
    /// 调试窗口
    private var debugWindow: NSWindow?
    
    /// 调试视图
    private var debugView: DebugOverlayView?
    
    /// 是否启用调试模式
    public var isDebugEnabled: Bool = false {
        didSet {
            if isDebugEnabled {
                showDebugOverlay()
            } else {
                hideDebugOverlay()
            }
        }
    }
    
    /// 调试信息列表
    private var debugInfoItems: [DebugInfoItem] = []
    
    /// 坐标变换日志
    private var transformLogs: [CoordinateTransformLog] = []
    
    /// 最大日志数量
    private let maxLogCount = 1000
    
    /// 调试信息锁
    private let debugLock = NSLock()
    
    /// 当前鼠标位置
    internal var currentMousePosition: CGPoint = .zero
    
    /// 坐标变换器引用
    private let coordinateTransformer = CoordinateTransformer()
    
    /// HiDPI管理器引用
    private let hiDPIManager = HiDPIManager.shared
    
    /// 多显示器处理器引用
    private let multiDisplayHandler = MultiDisplayHandler.shared
    
    // MARK: - Initialization
    
    private init() {
        setupMouseTracking()
    }
    
    // MARK: - Public Methods
    
    /// 显示调试覆盖层
    public func showDebugOverlay() {
        guard debugWindow == nil else { return }
        
        // 创建调试窗口
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        debugWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        debugWindow?.level = .floating
        debugWindow?.backgroundColor = NSColor.clear
        debugWindow?.isOpaque = false
        debugWindow?.ignoresMouseEvents = true
        debugWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // 创建调试视图
        debugView = DebugOverlayView(frame: screenFrame)
        debugView?.debugVisualizer = self
        debugWindow?.contentView = debugView
        
        debugWindow?.orderFront(nil)
    }
    
    /// 隐藏调试覆盖层
    public func hideDebugOverlay() {
        debugWindow?.close()
        debugWindow = nil
        debugView = nil
    }
    
    /// 添加调试信息
    public func addDebugInfo(type: DebugInfoType, title: String, value: String) {
        debugLock.lock()
        defer { debugLock.unlock() }
        
        let item = DebugInfoItem(type: type, title: title, value: value)
        debugInfoItems.append(item)
        
        // 限制数量
        if debugInfoItems.count > maxLogCount {
            debugInfoItems.removeFirst(debugInfoItems.count - maxLogCount)
        }
        
        // 更新调试视图
        DispatchQueue.main.async { [weak self] in
            self?.debugView?.needsDisplay = true
        }
    }
    
    /// 记录坐标变换日志
    public func logCoordinateTransform(sourcePoint: CGPoint, targetPoint: CGPoint, sourceSpace: CoordinateSpace, targetSpace: CoordinateSpace, accuracy: Double, duration: TimeInterval) {
        debugLock.lock()
        defer { debugLock.unlock() }
        
        let log = CoordinateTransformLog(
            sourcePoint: sourcePoint,
            targetPoint: targetPoint,
            sourceSpace: sourceSpace,
            targetSpace: targetSpace,
            accuracy: accuracy,
            duration: duration
        )
        
        transformLogs.append(log)
        
        // 限制数量
        if transformLogs.count > maxLogCount {
            transformLogs.removeFirst(transformLogs.count - maxLogCount)
        }
        
        // 添加到调试信息
        addDebugInfo(
            type: .transform,
            title: "Transform \(sourceSpace) → \(targetSpace)",
            value: String(format: "(%.1f,%.1f) → (%.1f,%.1f) [%.3f%%] %.2fms", 
                         sourcePoint.x, sourcePoint.y,
                         targetPoint.x, targetPoint.y,
                         accuracy * 100, duration * 1000)
        )
    }
    
    /// 更新鼠标位置
    public func updateMousePosition(_ position: CGPoint) {
        currentMousePosition = position
        
        // 记录坐标信息
        addDebugInfo(
            type: .coordinate,
            title: "Mouse Position",
            value: String(format: "(%.1f, %.1f)", position.x, position.y)
        )
        
        // 分析坐标变换
        analyzeCoordinateTransforms(at: position)
        
        // 更新调试视图
        DispatchQueue.main.async { [weak self] in
            self?.debugView?.needsDisplay = true
        }
    }
    
    /// 获取调试信息
    public func getDebugInfoItems(type: DebugInfoType? = nil) -> [DebugInfoItem] {
        debugLock.lock()
        defer { debugLock.unlock() }
        
        if let type = type {
            return debugInfoItems.filter { $0.type == type }
        } else {
            return debugInfoItems
        }
    }
    
    /// 获取坐标变换日志
    public func getTransformLogs() -> [CoordinateTransformLog] {
        debugLock.lock()
        defer { debugLock.unlock() }
        return transformLogs
    }
    
    /// 清除调试信息
    public func clearDebugInfo() {
        debugLock.lock()
        defer { debugLock.unlock() }
        debugInfoItems.removeAll()
        transformLogs.removeAll()
        
        DispatchQueue.main.async { [weak self] in
            self?.debugView?.needsDisplay = true
        }
    }
    
    /// 导出调试日志
    public func exportDebugLog() -> String {
        debugLock.lock()
        defer { debugLock.unlock() }
        
        var log = "=== Coordinate System Debug Log ===\n\n"
        
        // 基本信息
        log += "Generated: \(Date())\n"
        log += "Debug Items: \(debugInfoItems.count)\n"
        log += "Transform Logs: \(transformLogs.count)\n\n"
        
        // 显示器信息
        log += "=== Display Information ===\n"
        let displayConfigs = multiDisplayHandler.getAllDisplayConfigurations()
        for config in displayConfigs {
            log += "Display \(config.displayID): \(config.frame) Scale: \(config.scaleFactor) Main: \(config.isMain)\n"
        }
        log += "\n"
        
        // 调试信息
        log += "=== Debug Information ===\n"
        for item in debugInfoItems.suffix(100) {  // 最近100条
            log += "[\(item.timestamp)] \(item.type): \(item.title) = \(item.value)\n"
        }
        log += "\n"
        
        // 变换日志
        log += "=== Transform Logs ===\n"
        for transformLog in transformLogs.suffix(50) {  // 最近50条
            log += "[\(transformLog.timestamp)] \(transformLog.sourceSpace) → \(transformLog.targetSpace): "
            log += "(%.1f,%.1f) → (%.1f,%.1f) Accuracy: %.3f%% Duration: %.2fms\n"
        }
        
        return log
    }
    
    // MARK: - Private Methods
    
    /// 设置鼠标跟踪
    private func setupMouseTracking() {
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateMousePosition(event.locationInWindow)
        }
    }
    
    /// 分析坐标变换
    private func analyzeCoordinateTransforms(at position: CGPoint) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 测试各种坐标变换
        let spaces: [CoordinateSpace] = [.screen, .window, .container, .canvas]
        
        for sourceSpace in spaces {
            for targetSpace in spaces {
                if sourceSpace != targetSpace {
                    let result = coordinateTransformer.transform(
                        point: position,
                        from: sourceSpace,
                        to: targetSpace
                    )
                    
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    
                    logCoordinateTransform(
                        sourcePoint: position,
                        targetPoint: result.point,
                        sourceSpace: sourceSpace,
                        targetSpace: targetSpace,
                        accuracy: result.accuracy,
                        duration: duration
                    )
                }
            }
        }
        
        // 分析HiDPI信息
        let scaleFactor = hiDPIManager.getScaleFactor(for: position)
        addDebugInfo(
            type: .display,
            title: "Scale Factor",
            value: String(format: "%.2fx", scaleFactor)
        )
        
        // 分析显示器信息
        if let displayID = multiDisplayHandler.getDisplayID(for: position) {
            addDebugInfo(
                type: .display,
                title: "Display ID",
                value: "\(displayID)"
            )
        }
    }
}

// MARK: - Debug Overlay View

private class DebugOverlayView: NSView {
    
    weak var debugVisualizer: DebugVisualizer?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext,
              let _ = debugVisualizer else { return }
        
        // 绘制十字线
        drawCrosshair(in: context)
        
        // 绘制调试信息面板
        drawDebugPanel(in: context)
    }
    
    private func drawCrosshair(in context: CGContext) {
        guard let debugVisualizer = debugVisualizer else { return }
        
        let mousePos = debugVisualizer.currentMousePosition
        let bounds = self.bounds
        
        context.setStrokeColor(NSColor.red.cgColor)
        context.setLineWidth(1.0)
        
        // 垂直线
        context.move(to: CGPoint(x: mousePos.x, y: 0))
        context.addLine(to: CGPoint(x: mousePos.x, y: bounds.height))
        
        // 水平线
        context.move(to: CGPoint(x: 0, y: mousePos.y))
        context.addLine(to: CGPoint(x: bounds.width, y: mousePos.y))
        
        context.strokePath()
    }
    
    private func drawDebugPanel(in context: CGContext) {
        guard let debugVisualizer = debugVisualizer else { return }
        
        let panelRect = CGRect(x: 10, y: bounds.height - 200, width: 300, height: 180)
        
        // 绘制背景
        context.setFillColor(NSColor.black.withAlphaComponent(0.8).cgColor)
        context.fill(panelRect)
        
        // 绘制边框
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1.0)
        context.stroke(panelRect)
        
        // 绘制调试信息
        let debugItems = debugVisualizer.getDebugInfoItems()
        let recentItems = Array(debugItems.suffix(8))  // 显示最近8条
        
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let textColor = NSColor.white
        
        for (index, item) in recentItems.enumerated() {
            let text = "\(item.title): \(item.value)"
            let textRect = CGRect(
                x: panelRect.origin.x + 5,
                y: panelRect.origin.y + panelRect.height - 20 - CGFloat(index) * 15,
                width: panelRect.width - 10,
                height: 15
            )
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
