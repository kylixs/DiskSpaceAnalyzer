import Foundation
import AppKit
import CoreGraphics

/// 交互反馈模块 - 统一的交互反馈管理接口
public class InteractionFeedback {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = InteractionFeedback()
    
    /// 鼠标交互处理器
    public let mouseHandler: MouseInteractionHandler
    
    /// Tooltip管理器
    public let tooltipManager: TooltipManager
    
    /// 高亮渲染器
    public let highlightRenderer: HighlightRenderer
    
    /// 上下文菜单管理器
    public let contextMenuManager: ContextMenuManager
    
    /// 当前目标视图
    public weak var targetView: NSView? {
        didSet {
            if let view = targetView {
                setupInteractionHandling(for: view)
            }
        }
    }
    
    /// 交互配置
    public struct InteractionConfiguration {
        public let enableTooltips: Bool
        public let enableHighlights: Bool
        public let enableContextMenu: Bool
        public let debounceDelay: TimeInterval
        public let tooltipDelay: TimeInterval
        
        public init(enableTooltips: Bool = true, enableHighlights: Bool = true, enableContextMenu: Bool = true, debounceDelay: TimeInterval = 0.3, tooltipDelay: TimeInterval = 0.3) {
            self.enableTooltips = enableTooltips
            self.enableHighlights = enableHighlights
            self.enableContextMenu = enableContextMenu
            self.debounceDelay = debounceDelay
            self.tooltipDelay = tooltipDelay
        }
    }
    
    /// 当前配置
    private var configuration: InteractionConfiguration
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = InteractionConfiguration()
        self.mouseHandler = MouseInteractionHandler(targetView: nil)
        self.tooltipManager = TooltipManager.shared
        self.highlightRenderer = HighlightRenderer.shared
        self.contextMenuManager = ContextMenuManager.shared
        
        setupEventHandling()
    }
    
    // MARK: - Public Methods
    
    /// 配置交互反馈
    public func configure(with config: InteractionConfiguration) {
        self.configuration = config
        
        // 更新子组件配置
        mouseHandler.debounceDelay = config.debounceDelay
        
        let tooltipConfig = TooltipConfiguration(showDelay: config.tooltipDelay)
        tooltipManager.configure(with: tooltipConfig)
    }
    
    /// 设置目标视图和TreeMap数据
    public func setupInteraction(for view: NSView, with rects: [TreeMapRect], containerLayer: CALayer) {
        targetView = view
        
        // 更新各组件
        mouseHandler.targetView = view
        mouseHandler.updateTreeMapData(rects)
        
        highlightRenderer.setContainerLayer(containerLayer)
    }
    
    /// 更新TreeMap数据
    public func updateTreeMapData(_ rects: [TreeMapRect]) {
        mouseHandler.updateTreeMapData(rects)
        
        // 清除所有高亮
        highlightRenderer.removeAllHighlights()
    }
    
    /// 获取交互统计信息
    public func getInteractionStatistics() -> [String: Any] {
        var stats: [String: Any] = [:]
        
        stats["mouseHandler"] = mouseHandler.getInteractionStatistics()
        stats["tooltipManager"] = tooltipManager.getTooltipStatistics()
        stats["highlightRenderer"] = highlightRenderer.getHighlightStatistics()
        stats["contextMenuManager"] = contextMenuManager.getMenuStatistics()
        
        stats["configuration"] = [
            "enableTooltips": configuration.enableTooltips,
            "enableHighlights": configuration.enableHighlights,
            "enableContextMenu": configuration.enableContextMenu,
            "debounceDelay": configuration.debounceDelay,
            "tooltipDelay": configuration.tooltipDelay
        ]
        
        return stats
    }
    
    /// 导出交互报告
    public func exportInteractionReport() -> String {
        var report = "=== Interaction Feedback Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Target View: \(targetView?.className ?? "None")\n\n"
        
        report += "=== Configuration ===\n"
        report += "Tooltips Enabled: \(configuration.enableTooltips)\n"
        report += "Highlights Enabled: \(configuration.enableHighlights)\n"
        report += "Context Menu Enabled: \(configuration.enableContextMenu)\n"
        report += "Debounce Delay: \(configuration.debounceDelay)s\n"
        report += "Tooltip Delay: \(configuration.tooltipDelay)s\n\n"
        
        // 添加子组件报告
        report += mouseHandler.exportInteractionReport()
        report += "\n"
        report += tooltipManager.exportTooltipReport()
        report += "\n"
        report += highlightRenderer.exportHighlightReport()
        report += "\n"
        report += contextMenuManager.exportMenuReport()
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置交互处理
    private func setupInteractionHandling(for view: NSView) {
        // 这里可以添加视图特定的设置
        view.wantsLayer = true
    }
    
    /// 设置事件处理
    private func setupEventHandling() {
        // 设置鼠标事件回调
        mouseHandler.eventCallback = { [weak self] event in
            self?.handleMouseEvent(event)
        }
        
        mouseHandler.stateChangeCallback = { [weak self] state in
            self?.handleStateChange(state)
        }
    }
    
    /// 处理鼠标事件
    private func handleMouseEvent(_ event: MouseInteractionEvent) {
        switch event {
        case .hover(let rect):
            handleHoverEvent(rect)
            
        case .click(let rect):
            handleClickEvent(rect)
            
        case .doubleClick(let rect):
            handleDoubleClickEvent(rect)
            
        case .rightClick(let rect):
            handleRightClickEvent(rect)
            
        case .exit:
            handleExitEvent()
            
        default:
            break
        }
    }
    
    /// 处理悬停事件
    private func handleHoverEvent(_ rect: TreeMapRect) {
        guard let view = targetView else { return }
        
        // 显示高亮
        if configuration.enableHighlights {
            highlightRenderer.addHighlight(for: rect, type: .hover)
        }
        
        // 显示tooltip
        if configuration.enableTooltips {
            let mouseLocation = NSEvent.mouseLocation
            let viewLocation = view.convert(view.convert(mouseLocation, from: nil), from: view.window?.contentView)
            tooltipManager.showTooltip(for: rect, at: viewLocation, in: view)
        }
    }
    
    /// 处理点击事件
    private func handleClickEvent(_ rect: TreeMapRect) {
        // 添加选中高亮
        if configuration.enableHighlights {
            highlightRenderer.addHighlight(for: rect, type: .selection)
        }
        
        // 发送选中通知
        NotificationCenter.default.post(
            name: NSNotification.Name("TreeMapRectSelected"),
            object: rect
        )
    }
    
    /// 处理双击事件
    private func handleDoubleClickEvent(_ rect: TreeMapRect) {
        // 发送双击通知
        NotificationCenter.default.post(
            name: NSNotification.Name("TreeMapRectDoubleClicked"),
            object: rect
        )
    }
    
    /// 处理右键事件
    private func handleRightClickEvent(_ rect: TreeMapRect) {
        guard let view = targetView, configuration.enableContextMenu else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let viewLocation = view.convert(view.convert(mouseLocation, from: nil), from: view.window?.contentView)
        
        contextMenuManager.showContextMenu(for: rect, at: viewLocation, in: view)
    }
    
    /// 处理退出事件
    private func handleExitEvent() {
        // 隐藏tooltip
        if configuration.enableTooltips {
            tooltipManager.hideTooltip()
        }
        
        // 移除悬停高亮
        if configuration.enableHighlights {
            highlightRenderer.removeAllHighlights()
        }
    }
    
    /// 处理状态变化
    private func handleStateChange(_ state: InteractionState) {
        // 发送状态变化通知
        NotificationCenter.default.post(
            name: NSNotification.Name("InteractionStateChanged"),
            object: state
        )
    }
}

// MARK: - Global Convenience Functions

/// 全局交互反馈访问函数
public func getInteractionFeedback() -> InteractionFeedback {
    return InteractionFeedback.shared
}

/// 设置交互目标
public func setupInteraction(for view: NSView, with rects: [TreeMapRect], containerLayer: CALayer) {
    InteractionFeedback.shared.setupInteraction(for: view, with: rects, containerLayer: containerLayer)
}

/// 更新交互数据
public func updateInteractionData(_ rects: [TreeMapRect]) {
    InteractionFeedback.shared.updateTreeMapData(rects)
}
