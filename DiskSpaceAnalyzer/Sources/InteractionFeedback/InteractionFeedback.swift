import Foundation
import AppKit
import Common
import CoordinateSystem
import DirectoryTreeView
import TreeMapVisualization
import PerformanceOptimizer

// MARK: - InteractionFeedback Module
// 交互反馈模块 - 提供完整的用户交互反馈系统

/// InteractionFeedback模块信息
public struct InteractionFeedbackModule {
    public static let version = "1.0.0"
    public static let description = "交互反馈系统"
    
    public static func initialize() {
        print("🖱️ InteractionFeedback模块初始化")
        print("📋 包含: MouseInteractionHandler、TooltipManager、HighlightRenderer、ContextMenuManager")
        print("📊 版本: \(version)")
        print("✅ InteractionFeedback模块初始化完成")
    }
}

// MARK: - 交互状态

/// 交互状态枚举
public enum InteractionState {
    case idle           // 空闲状态
    case hovering       // 悬停状态
    case clicking       // 点击状态
    case dragging       // 拖拽状态
    case contextMenu    // 右键菜单状态
}

/// 交互事件类型
public enum InteractionEventType {
    case mouseEnter
    case mouseMove
    case mouseExit
    case leftClick
    case doubleClick
    case rightClick
    case dragStart
    case dragMove
    case dragEnd
}

/// 交互事件
public struct InteractionEvent {
    public let type: InteractionEventType
    public let location: CGPoint
    public let timestamp: Date
    public let modifierFlags: NSEvent.ModifierFlags
    
    public init(type: InteractionEventType, location: CGPoint, modifierFlags: NSEvent.ModifierFlags = []) {
        self.type = type
        self.location = location
        self.timestamp = Date()
        self.modifierFlags = modifierFlags
    }
}

// MARK: - 鼠标交互处理器

/// 鼠标交互处理器 - 精确的鼠标交互处理系统
public class MouseInteractionHandler {
    public static let shared = MouseInteractionHandler()
    
    // 状态管理
    private var currentState: InteractionState = .idle
    private var lastEvent: InteractionEvent?
    private var clickCount = 0
    private var lastClickTime: Date?
    
    // 防抖和节流
    private let debounceInterval: TimeInterval = 0.3
    private let throttleManager = ThrottleManager.shared
    
    // 坐标变换（暂时移除，后续如需要可以通过其他方式获取）
    // private let coordinateTransformer = CoordinateTransformer()
    
    // 回调
    public var onInteractionEvent: ((InteractionEvent, InteractionState) -> Void)?
    public var onStateChanged: ((InteractionState, InteractionState) -> Void)?
    
    private init() {}
    
    /// 处理鼠标事件
    public func handleMouseEvent(_ event: NSEvent, in view: NSView) {
        let location = view.convert(event.locationInWindow, from: nil)
        let interactionEvent = createInteractionEvent(from: event, location: location)
        
        // 防抖处理
        if shouldDebounce(interactionEvent) {
            return
        }
        
        // 更新状态
        let oldState = currentState
        updateState(for: interactionEvent)
        
        // 通知状态变化
        if oldState != currentState {
            onStateChanged?(oldState, currentState)
        }
        
        // 通知交互事件
        onInteractionEvent?(interactionEvent, currentState)
        
        // 记录事件
        lastEvent = interactionEvent
    }
    
    private func createInteractionEvent(from event: NSEvent, location: CGPoint) -> InteractionEvent {
        let eventType: InteractionEventType
        
        switch event.type {
        case .mouseEntered:
            eventType = .mouseEnter
        case .mouseMoved:
            eventType = .mouseMove
        case .mouseExited:
            eventType = .mouseExit
        case .leftMouseDown:
            eventType = handleClickEvent(event)
        case .rightMouseDown:
            eventType = .rightClick
        case .leftMouseDragged:
            eventType = currentState == .dragging ? .dragMove : .dragStart
        case .leftMouseUp:
            eventType = currentState == .dragging ? .dragEnd : .leftClick
        default:
            eventType = .mouseMove
        }
        
        return InteractionEvent(
            type: eventType,
            location: location,
            modifierFlags: event.modifierFlags
        )
    }
    
    private func handleClickEvent(_ event: NSEvent) -> InteractionEventType {
        let now = Date()
        
        // 检查双击
        if let lastClick = lastClickTime,
           now.timeIntervalSince(lastClick) < 0.5 {
            clickCount += 1
        } else {
            clickCount = 1
        }
        
        lastClickTime = now
        
        return clickCount >= 2 ? .doubleClick : .leftClick
    }
    
    private func shouldDebounce(_ event: InteractionEvent) -> Bool {
        guard let lastEvent = lastEvent else { return false }
        
        // 对于移动事件进行节流
        if event.type == .mouseMove && lastEvent.type == .mouseMove {
            let timeDiff = event.timestamp.timeIntervalSince(lastEvent.timestamp)
            return timeDiff < 0.016 // 60fps
        }
        
        // 对于点击事件进行防抖
        if event.type == .leftClick && lastEvent.type == .leftClick {
            let timeDiff = event.timestamp.timeIntervalSince(lastEvent.timestamp)
            return timeDiff < debounceInterval
        }
        
        return false
    }
    
    private func updateState(for event: InteractionEvent) {
        switch event.type {
        case .mouseEnter, .mouseMove:
            if currentState == .idle {
                currentState = .hovering
            }
        case .mouseExit:
            currentState = .idle
        case .leftClick:
            currentState = .clicking
        case .rightClick:
            currentState = .contextMenu
        case .dragStart:
            currentState = .dragging
        case .dragEnd:
            currentState = .hovering
        default:
            break
        }
    }
    
    /// 获取当前状态
    public func getCurrentState() -> InteractionState {
        return currentState
    }
    
    /// 重置状态
    public func resetState() {
        let oldState = currentState
        currentState = .idle
        lastEvent = nil
        clickCount = 0
        lastClickTime = nil
        
        if oldState != currentState {
            onStateChanged?(oldState, currentState)
        }
    }
}

// MARK: - Tooltip管理器

/// Tooltip管理器 - 智能tooltip显示系统
public class TooltipManager {
    public static let shared = TooltipManager()
    
    // UI组件
    private var tooltipWindow: NSWindow?
    private var tooltipView: NSTextField?
    
    // 显示控制
    private var showTimer: Timer?
    private var hideTimer: Timer?
    private let showDelay: TimeInterval = 0.5
    private let hideDelay: TimeInterval = 0.1
    
    // 位置管理
    private var lastMouseLocation: CGPoint = .zero
    private let edgeMargin: CGFloat = 10
    
    private init() {}
    
    /// 显示tooltip
    public func showTooltip(_ text: String, at location: CGPoint, in view: NSView) {
        // 取消之前的定时器
        hideTimer?.invalidate()
        hideTimer = nil
        
        // 延迟显示
        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: showDelay, repeats: false) { [weak self] _ in
            self?.displayTooltip(text, at: location, in: view)
        }
    }
    
    /// 隐藏tooltip
    public func hideTooltip() {
        showTimer?.invalidate()
        showTimer = nil
        
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
            self?.dismissTooltip()
        }
    }
    
    /// 更新tooltip位置
    public func updateTooltipPosition(_ location: CGPoint, in view: NSView) {
        lastMouseLocation = location
        
        guard let window = tooltipWindow else { return }
        
        let screenLocation = view.window?.convertPoint(toScreen: view.convert(location, to: nil)) ?? location
        let adjustedLocation = adjustLocationForScreenEdges(screenLocation, windowSize: window.frame.size)
        
        window.setFrameOrigin(adjustedLocation)
    }
    
    private func displayTooltip(_ text: String, at location: CGPoint, in view: NSView) {
        // 创建tooltip窗口
        if tooltipWindow == nil {
            createTooltipWindow()
        }
        
        guard let window = tooltipWindow, let textField = tooltipView else { return }
        
        // 设置文本
        textField.stringValue = text
        
        // 计算大小
        let textSize = textField.sizeThatFits(NSSize(width: 300, height: 100))
        let windowSize = NSSize(width: textSize.width + 16, height: textSize.height + 8)
        
        // 设置窗口大小
        window.setContentSize(windowSize)
        textField.frame = NSRect(origin: NSPoint(x: 8, y: 4), size: textSize)
        
        // 计算位置
        let screenLocation = view.window?.convertPoint(toScreen: view.convert(location, to: nil)) ?? location
        let adjustedLocation = adjustLocationForScreenEdges(screenLocation, windowSize: windowSize)
        
        // 显示窗口
        window.setFrameOrigin(adjustedLocation)
        window.orderFront(nil)
    }
    
    private func dismissTooltip() {
        tooltipWindow?.orderOut(nil)
    }
    
    private func createTooltipWindow() {
        // 创建窗口
        tooltipWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 50),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        guard let window = tooltipWindow else { return }
        
        window.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95)
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        
        // 创建文本字段
        tooltipView = NSTextField()
        guard let textField = tooltipView else { return }
        
        textField.isBordered = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        textField.font = NSFont.systemFont(ofSize: 11)
        textField.textColor = NSColor.labelColor
        
        window.contentView?.addSubview(textField)
    }
    
    private func adjustLocationForScreenEdges(_ location: CGPoint, windowSize: NSSize) -> CGPoint {
        guard let screen = NSScreen.main else { return location }
        
        let screenFrame = screen.visibleFrame
        var adjustedLocation = location
        
        // 调整X坐标
        if adjustedLocation.x + windowSize.width > screenFrame.maxX {
            adjustedLocation.x = screenFrame.maxX - windowSize.width - edgeMargin
        }
        if adjustedLocation.x < screenFrame.minX {
            adjustedLocation.x = screenFrame.minX + edgeMargin
        }
        
        // 调整Y坐标
        if adjustedLocation.y - windowSize.height < screenFrame.minY {
            adjustedLocation.y = location.y + 20 // 显示在鼠标下方
        } else {
            adjustedLocation.y = location.y - windowSize.height - 10 // 显示在鼠标上方
        }
        
        return adjustedLocation
    }
}

// MARK: - 高亮渲染器

/// 高亮渲染器 - 管理高亮效果的渲染
public class HighlightRenderer {
    public static let shared = HighlightRenderer()
    
    // 高亮状态
    private var highlightedRect: TreeMapRect?
    private var highlightLayer: CALayer?
    
    // 动画
    private var highlightAnimation: CABasicAnimation?
    private let animationDuration: TimeInterval = 0.2
    
    private init() {}
    
    /// 设置高亮矩形
    public func setHighlight(_ rect: TreeMapRect?, in view: NSView) {
        // 移除之前的高亮
        removeHighlight()
        
        guard let rect = rect else { return }
        
        highlightedRect = rect
        createHighlightLayer(for: rect, in: view)
    }
    
    /// 移除高亮
    public func removeHighlight() {
        highlightLayer?.removeAnimation(forKey: "highlight")
        highlightLayer?.removeFromSuperlayer()
        highlightLayer = nil
        highlightedRect = nil
        highlightAnimation = nil
    }
    
    private func createHighlightLayer(for rect: TreeMapRect, in view: NSView) {
        if !view.wantsLayer {
            view.wantsLayer = true
        }
        
        // 创建高亮图层
        let layer = CALayer()
        layer.frame = rect.rect
        layer.backgroundColor = NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor
        layer.borderColor = NSColor.selectedControlColor.cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = 4.0
        
        // 添加到视图
        view.layer?.addSublayer(layer)
        highlightLayer = layer
        
        // 添加动画
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(animation, forKey: "highlight")
        highlightAnimation = animation
    }
    
    /// 获取当前高亮矩形
    public func getCurrentHighlight() -> TreeMapRect? {
        return highlightedRect
    }
}

// MARK: - 上下文菜单管理器

/// 上下文菜单管理器 - 管理右键菜单
public class ContextMenuManager {
    public static let shared = ContextMenuManager()
    
    // 菜单项回调
    public var onOpenInFinder: ((TreeMapRect) -> Void)?
    public var onSelectInTree: ((TreeMapRect) -> Void)?
    public var onCopyPath: ((TreeMapRect) -> Void)?
    public var onShowInfo: ((TreeMapRect) -> Void)?
    
    private init() {}
    
    /// 显示上下文菜单
    public func showContextMenu(for rect: TreeMapRect, at location: CGPoint, in view: NSView) {
        let menu = createContextMenu(for: rect)
        
        // 显示菜单
        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: view)
    }
    
    private func createContextMenu(for rect: TreeMapRect) -> NSMenu {
        let menu = NSMenu()
        
        // 在Finder中显示
        let openInFinderItem = NSMenuItem(
            title: "在Finder中显示",
            action: #selector(openInFinderAction(_:)),
            keyEquivalent: ""
        )
        openInFinderItem.target = self
        openInFinderItem.representedObject = rect
        menu.addItem(openInFinderItem)
        
        // 在目录树中选择
        let selectInTreeItem = NSMenuItem(
            title: "在目录树中选择",
            action: #selector(selectInTreeAction(_:)),
            keyEquivalent: ""
        )
        selectInTreeItem.target = self
        selectInTreeItem.representedObject = rect
        menu.addItem(selectInTreeItem)
        
        menu.addItem(.separator())
        
        // 复制路径
        let copyPathItem = NSMenuItem(
            title: "复制路径",
            action: #selector(copyPathAction(_:)),
            keyEquivalent: "c"
        )
        copyPathItem.target = self
        copyPathItem.representedObject = rect
        menu.addItem(copyPathItem)
        
        // 显示信息
        let showInfoItem = NSMenuItem(
            title: "显示信息",
            action: #selector(showInfoAction(_:)),
            keyEquivalent: "i"
        )
        showInfoItem.target = self
        showInfoItem.representedObject = rect
        menu.addItem(showInfoItem)
        
        return menu
    }
    
    @objc private func openInFinderAction(_ sender: NSMenuItem) {
        guard let rect = sender.representedObject as? TreeMapRect else { return }
        onOpenInFinder?(rect)
    }
    
    @objc private func selectInTreeAction(_ sender: NSMenuItem) {
        guard let rect = sender.representedObject as? TreeMapRect else { return }
        onSelectInTree?(rect)
    }
    
    @objc private func copyPathAction(_ sender: NSMenuItem) {
        guard let rect = sender.representedObject as? TreeMapRect else { return }
        onCopyPath?(rect)
    }
    
    @objc private func showInfoAction(_ sender: NSMenuItem) {
        guard let rect = sender.representedObject as? TreeMapRect else { return }
        onShowInfo?(rect)
    }
}

// MARK: - 交互协调器

/// 交互协调器 - 协调各种交互组件
public class InteractionCoordinator {
    public static let shared = InteractionCoordinator()
    
    // 组件
    private let mouseHandler = MouseInteractionHandler.shared
    private let tooltipManager = TooltipManager.shared
    private let highlightRenderer = HighlightRenderer.shared
    private let contextMenuManager = ContextMenuManager.shared
    
    // 视图引用
    public weak var treeMapView: TreeMapView?
    public weak var directoryTreeView: DirectoryTreeView?
    
    // 当前交互对象
    private var currentRect: TreeMapRect?
    
    private init() {
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        // 鼠标交互事件
        mouseHandler.onInteractionEvent = { [weak self] event, state in
            self?.handleInteractionEvent(event, state: state)
        }
        
        // 状态变化事件
        mouseHandler.onStateChanged = { [weak self] oldState, newState in
            self?.handleStateChange(from: oldState, to: newState)
        }
        
        // 上下文菜单回调
        contextMenuManager.onOpenInFinder = { [weak self] rect in
            self?.openInFinder(rect)
        }
        
        contextMenuManager.onSelectInTree = { [weak self] rect in
            self?.selectInTree(rect)
        }
        
        contextMenuManager.onCopyPath = { [weak self] rect in
            self?.copyPath(rect)
        }
        
        contextMenuManager.onShowInfo = { [weak self] rect in
            self?.showInfo(rect)
        }
    }
    
    /// 处理交互事件
    private func handleInteractionEvent(_ event: InteractionEvent, state: InteractionState) {
        guard let treeMapView = treeMapView else { return }
        
        // 查找目标矩形
        let targetRect = findRect(at: event.location, in: treeMapView)
        
        switch event.type {
        case .mouseMove:
            handleMouseMove(targetRect, at: event.location, in: treeMapView)
        case .leftClick:
            handleLeftClick(targetRect)
        case .doubleClick:
            handleDoubleClick(targetRect)
        case .rightClick:
            handleRightClick(targetRect, at: event.location, in: treeMapView)
        case .mouseExit:
            handleMouseExit()
        default:
            break
        }
    }
    
    /// 处理状态变化
    private func handleStateChange(from oldState: InteractionState, to newState: InteractionState) {
        switch newState {
        case .idle:
            tooltipManager.hideTooltip()
            highlightRenderer.removeHighlight()
        case .hovering:
            // 悬停状态已在handleMouseMove中处理
            break
        case .clicking:
            tooltipManager.hideTooltip()
        case .contextMenu:
            tooltipManager.hideTooltip()
        default:
            break
        }
    }
    
    private func handleMouseMove(_ rect: TreeMapRect?, at location: CGPoint, in view: NSView) {
        if let rect = rect {
            // 更新高亮
            if currentRect?.node.id != rect.node.id {
                highlightRenderer.setHighlight(rect, in: view)
                currentRect = rect
                
                // 显示tooltip
                let tooltipText = createTooltipText(for: rect)
                tooltipManager.showTooltip(tooltipText, at: location, in: view)
            } else {
                // 更新tooltip位置
                tooltipManager.updateTooltipPosition(location, in: view)
            }
        } else {
            // 移除高亮和tooltip
            if currentRect != nil {
                highlightRenderer.removeHighlight()
                tooltipManager.hideTooltip()
                currentRect = nil
            }
        }
    }
    
    private func handleLeftClick(_ rect: TreeMapRect?) {
        guard let rect = rect else { return }
        
        // 通知TreeMap视图
        treeMapView?.onRectClicked?(rect)
    }
    
    private func handleDoubleClick(_ rect: TreeMapRect?) {
        guard let rect = rect else { return }
        
        // 双击导航到目录
        if rect.node.isDirectory {
            treeMapView?.setData(rect.node)
        }
    }
    
    private func handleRightClick(_ rect: TreeMapRect?, at location: CGPoint, in view: NSView) {
        guard let rect = rect else { return }
        
        contextMenuManager.showContextMenu(for: rect, at: location, in: view)
    }
    
    private func handleMouseExit() {
        highlightRenderer.removeHighlight()
        tooltipManager.hideTooltip()
        currentRect = nil
    }
    
    private func findRect(at location: CGPoint, in view: TreeMapView) -> TreeMapRect? {
        // 这里需要访问TreeMapView的内部数据
        // 由于TreeMapView的treeMapRects是私有的，我们需要添加一个公共方法
        return nil // 占位实现
    }
    
    private func createTooltipText(for rect: TreeMapRect) -> String {
        let name = rect.node.name
        let size = SharedUtilities.formatFileSize(rect.node.size)
        let path = rect.node.path
        let type = rect.node.isDirectory ? "目录" : "文件"
        
        return "\(name)\n类型: \(type)\n大小: \(size)\n路径: \(path)"
    }
    
    // MARK: - 菜单动作实现
    
    private func openInFinder(_ rect: TreeMapRect) {
        let url = URL(fileURLWithPath: rect.node.path)
        NSWorkspace.shared.selectFile(rect.node.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
    
    private func selectInTree(_ rect: TreeMapRect) {
        // 这里需要与DirectoryTreeView交互
        // 由于模块依赖关系，我们通过回调实现
        print("选择在目录树中: \(rect.node.path)")
    }
    
    private func copyPath(_ rect: TreeMapRect) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(rect.node.path, forType: .string)
    }
    
    private func showInfo(_ rect: TreeMapRect) {
        let alert = NSAlert()
        alert.messageText = "文件信息"
        alert.informativeText = createTooltipText(for: rect)
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

// MARK: - 交互反馈管理器

/// 交互反馈管理器 - 统一管理所有交互反馈功能
public class InteractionFeedback {
    public static let shared = InteractionFeedback()
    
    private let coordinator = InteractionCoordinator.shared
    private let mouseHandler = MouseInteractionHandler.shared
    private let tooltipManager = TooltipManager.shared
    private let highlightRenderer = HighlightRenderer.shared
    private let contextMenuManager = ContextMenuManager.shared
    
    private init() {}
    
    /// 设置TreeMap视图
    public func setTreeMapView(_ view: TreeMapView) {
        coordinator.treeMapView = view
    }
    
    /// 设置目录树视图
    public func setDirectoryTreeView(_ view: DirectoryTreeView) {
        coordinator.directoryTreeView = view
    }
    
    /// 处理鼠标事件
    public func handleMouseEvent(_ event: NSEvent, in view: NSView) {
        mouseHandler.handleMouseEvent(event, in: view)
    }
    
    /// 显示tooltip
    public func showTooltip(_ text: String, at location: CGPoint, in view: NSView) {
        tooltipManager.showTooltip(text, at: location, in: view)
    }
    
    /// 隐藏tooltip
    public func hideTooltip() {
        tooltipManager.hideTooltip()
    }
    
    /// 设置高亮
    public func setHighlight(_ rect: TreeMapRect?, in view: NSView) {
        highlightRenderer.setHighlight(rect, in: view)
    }
    
    /// 显示上下文菜单
    public func showContextMenu(for rect: TreeMapRect, at location: CGPoint, in view: NSView) {
        contextMenuManager.showContextMenu(for: rect, at: location, in: view)
    }
    
    /// 获取当前交互状态
    public func getCurrentState() -> InteractionState {
        return mouseHandler.getCurrentState()
    }
    
    /// 重置交互状态
    public func resetState() {
        mouseHandler.resetState()
        tooltipManager.hideTooltip()
        highlightRenderer.removeHighlight()
    }
}
