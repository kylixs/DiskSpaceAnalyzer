import Foundation
import AppKit
import CoreGraphics

/// 鼠标交互事件类型
public enum MouseInteractionEvent {
    case hover(TreeMapRect)
    case click(TreeMapRect)
    case doubleClick(TreeMapRect)
    case rightClick(TreeMapRect)
    case dragStart(TreeMapRect)
    case dragEnd(TreeMapRect)
    case exit
}

/// 交互状态
public enum InteractionState {
    case idle
    case hovering(TreeMapRect)
    case clicking(TreeMapRect)
    case dragging(TreeMapRect)
}

/// 鼠标交互处理器 - 捕获和处理所有鼠标事件
public class MouseInteractionHandler: NSObject {
    
    // MARK: - Properties
    
    /// 目标视图
    public weak var targetView: NSView?
    
    /// 当前TreeMap矩形数据
    public var treeMapRects: [TreeMapRect] = [] {
        didSet {
            updateTrackingAreas()
        }
    }
    
    /// 坐标转换器
    private let coordinateTransformer: CoordinateTransformer
    
    /// 当前交互状态
    public private(set) var currentState: InteractionState = .idle
    
    /// 跟踪区域
    private var trackingAreas: [NSTrackingArea] = []
    
    /// 防抖定时器
    private var debounceTimer: Timer?
    
    /// 防抖延迟（毫秒）
    public var debounceDelay: TimeInterval = 0.3
    
    /// 双击检测定时器
    private var doubleClickTimer: Timer?
    
    /// 双击间隔
    public var doubleClickInterval: TimeInterval = 0.5
    
    /// 上次点击时间
    private var lastClickTime: Date?
    
    /// 上次点击的矩形
    private var lastClickedRect: TreeMapRect?
    
    /// 事件回调
    public var eventCallback: ((MouseInteractionEvent) -> Void)?
    
    /// 状态变化回调
    public var stateChangeCallback: ((InteractionState) -> Void)?
    
    // MARK: - Initialization
    
    public init(targetView: NSView, coordinateTransformer: CoordinateTransformer = CoordinateTransformer.shared) {
        self.targetView = targetView
        self.coordinateTransformer = coordinateTransformer
        super.init()
        
        setupEventHandling()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// 更新TreeMap数据
    public func updateTreeMapData(_ rects: [TreeMapRect]) {
        self.treeMapRects = rects
    }
    
    /// 获取指定位置的矩形
    public func getRect(at point: CGPoint) -> TreeMapRect? {
        // 转换坐标到TreeMap坐标系
        let transformedPoint = coordinateTransformer.transformPoint(point, from: .screen, to: .canvas)
        
        // 查找包含该点的矩形
        return treeMapRects.first { rect in
            rect.rect.contains(transformedPoint)
        }
    }
    
    /// 强制更新状态
    public func updateState(_ newState: InteractionState) {
        let oldState = currentState
        currentState = newState
        
        if case .idle = oldState, case .idle = newState {
            // 状态没有变化，不触发回调
            return
        }
        
        stateChangeCallback?(newState)
    }
    
    /// 清理资源
    public func cleanup() {
        debounceTimer?.invalidate()
        doubleClickTimer?.invalidate()
        removeTrackingAreas()
    }
    
    // MARK: - Private Methods
    
    /// 设置事件处理
    private func setupEventHandling() {
        guard let view = targetView else { return }
        
        // 设置视图接受鼠标事件
        view.wantsLayer = true
        
        // 添加手势识别器
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        clickGesture.numberOfClicksRequired = 1
        view.addGestureRecognizer(clickGesture)
        
        let rightClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleRightClick(_:)))
        rightClickGesture.buttonMask = 0x2 // 右键
        view.addGestureRecognizer(rightClickGesture)
    }
    
    /// 更新跟踪区域
    private func updateTrackingAreas() {
        guard let view = targetView else { return }
        
        // 移除旧的跟踪区域
        removeTrackingAreas()
        
        // 为每个矩形创建跟踪区域
        for rect in treeMapRects {
            let trackingArea = NSTrackingArea(
                rect: rect.rect,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow],
                owner: self,
                userInfo: ["rectId": rect.id.uuidString]
            )
            
            view.addTrackingArea(trackingArea)
            trackingAreas.append(trackingArea)
        }
    }
    
    /// 移除跟踪区域
    private func removeTrackingAreas() {
        guard let view = targetView else { return }
        
        for trackingArea in trackingAreas {
            view.removeTrackingArea(trackingArea)
        }
        trackingAreas.removeAll()
    }
    
    /// 处理点击事件
    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        let point = gesture.location(in: targetView)
        
        guard let rect = getRect(at: point) else {
            handleExitEvent()
            return
        }
        
        let now = Date()
        
        // 检查双击
        if let lastClick = lastClickTime,
           let lastRect = lastClickedRect,
           now.timeIntervalSince(lastClick) < doubleClickInterval,
           lastRect.id == rect.id {
            
            // 双击事件
            doubleClickTimer?.invalidate()
            handleDoubleClickEvent(rect)
            lastClickTime = nil
            lastClickedRect = nil
            
        } else {
            // 单击事件（延迟处理以检测双击）
            lastClickTime = now
            lastClickedRect = rect
            
            doubleClickTimer?.invalidate()
            doubleClickTimer = Timer.scheduledTimer(withTimeInterval: doubleClickInterval, repeats: false) { [weak self] _ in
                self?.handleClickEvent(rect)
            }
        }
    }
    
    /// 处理右键点击事件
    @objc private func handleRightClick(_ gesture: NSClickGestureRecognizer) {
        let point = gesture.location(in: targetView)
        
        guard let rect = getRect(at: point) else { return }
        
        handleRightClickEvent(rect)
    }
    
    /// 处理悬停事件
    private func handleHoverEvent(_ rect: TreeMapRect) {
        // 防抖处理
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            self?.processHoverEvent(rect)
        }
    }
    
    /// 处理悬停事件（防抖后）
    private func processHoverEvent(_ rect: TreeMapRect) {
        updateState(.hovering(rect))
        eventCallback?(.hover(rect))
    }
    
    /// 处理点击事件
    private func handleClickEvent(_ rect: TreeMapRect) {
        updateState(.clicking(rect))
        eventCallback?(.click(rect))
    }
    
    /// 处理双击事件
    private func handleDoubleClickEvent(_ rect: TreeMapRect) {
        updateState(.clicking(rect))
        eventCallback?(.doubleClick(rect))
    }
    
    /// 处理右键点击事件
    private func handleRightClickEvent(_ rect: TreeMapRect) {
        updateState(.clicking(rect))
        eventCallback?(.rightClick(rect))
    }
    
    /// 处理退出事件
    private func handleExitEvent() {
        debounceTimer?.invalidate()
        updateState(.idle)
        eventCallback?(.exit)
    }
}

// MARK: - NSTrackingArea Delegate

extension MouseInteractionHandler {
    
    public override func mouseEntered(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo,
              let rectIdString = userInfo["rectId"] as? String,
              let rectId = UUID(uuidString: rectIdString),
              let rect = treeMapRects.first(where: { $0.id == rectId }) else {
            return
        }
        
        handleHoverEvent(rect)
    }
    
    public override func mouseExited(with event: NSEvent) {
        handleExitEvent()
    }
    
    public override func mouseMoved(with event: NSEvent) {
        let point = event.locationInWindow
        
        guard let view = targetView else { return }
        let localPoint = view.convert(point, from: nil)
        
        if let rect = getRect(at: localPoint) {
            handleHoverEvent(rect)
        } else {
            handleExitEvent()
        }
    }
}

// MARK: - Extensions

extension MouseInteractionHandler {
    
    /// 获取交互统计信息
    public func getInteractionStatistics() -> [String: Any] {
        return [
            "currentState": String(describing: currentState),
            "trackedRects": treeMapRects.count,
            "trackingAreas": trackingAreas.count,
            "debounceDelay": debounceDelay,
            "doubleClickInterval": doubleClickInterval
        ]
    }
    
    /// 导出交互报告
    public func exportInteractionReport() -> String {
        var report = "=== Mouse Interaction Handler Report ===\n\n"
        
        let stats = getInteractionStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Current State: \(stats["currentState"] ?? "Unknown")\n"
        report += "Tracked Rectangles: \(stats["trackedRects"] ?? 0)\n"
        report += "Tracking Areas: \(stats["trackingAreas"] ?? 0)\n"
        report += "Debounce Delay: \(stats["debounceDelay"] ?? 0)ms\n"
        report += "Double Click Interval: \(stats["doubleClickInterval"] ?? 0)ms\n\n"
        
        report += "=== Configuration ===\n"
        report += "Target View: \(targetView?.className ?? "None")\n"
        report += "Coordinate Transformer: \(coordinateTransformer)\n\n"
        
        return report
    }
}
