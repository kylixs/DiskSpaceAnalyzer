import Foundation
import AppKit
import CoreGraphics
import QuartzCore

/// 高亮类型
public enum HighlightType {
    case hover      // 悬停高亮
    case selection  // 选中高亮
    case focus      // 焦点高亮
}

/// 高亮配置
public struct HighlightConfiguration {
    public let brightnessIncrease: CGFloat
    public let borderWidth: CGFloat
    public let borderColor: NSColor
    public let animationDuration: TimeInterval
    public let cornerRadius: CGFloat
    
    public init(brightnessIncrease: CGFloat = 0.2, borderWidth: CGFloat = 2.0, borderColor: NSColor = NSColor.controlAccentColor, animationDuration: TimeInterval = 0.1, cornerRadius: CGFloat = 4.0) {
        self.brightnessIncrease = brightnessIncrease
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.animationDuration = animationDuration
        self.cornerRadius = cornerRadius
    }
}

/// 高亮状态
public struct HighlightState {
    public let rect: TreeMapRect
    public let type: HighlightType
    public let layer: CALayer
    public let startTime: Date
    
    public init(rect: TreeMapRect, type: HighlightType, layer: CALayer, startTime: Date = Date()) {
        self.rect = rect
        self.type = type
        self.layer = layer
        self.startTime = startTime
    }
}

/// 高亮渲染器 - 渲染方块的悬停高亮效果
public class HighlightRenderer {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = HighlightRenderer()
    
    /// 高亮配置
    public var configuration: HighlightConfiguration
    
    /// 当前高亮状态
    private var highlightStates: [UUID: HighlightState] = [:]
    
    /// 高亮层容器
    private weak var containerLayer: CALayer?
    
    /// 状态锁
    private let stateLock = NSLock()
    
    /// 颜色管理器
    private let colorManager: ColorManager
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = HighlightConfiguration()
        self.colorManager = ColorManager()
    }
    
    // MARK: - Public Methods
    
    /// 配置高亮渲染器
    public func configure(with config: HighlightConfiguration) {
        self.configuration = config
    }
    
    /// 设置容器层
    public func setContainerLayer(_ layer: CALayer) {
        self.containerLayer = layer
    }
    
    /// 添加高亮
    public func addHighlight(for rect: TreeMapRect, type: HighlightType = .hover) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        // 移除已存在的高亮
        removeHighlight(for: rect.id)
        
        // 创建高亮层
        let highlightLayer = createHighlightLayer(for: rect, type: type)
        
        // 添加到容器
        containerLayer?.addSublayer(highlightLayer)
        
        // 记录状态
        let state = HighlightState(rect: rect, type: type, layer: highlightLayer)
        highlightStates[rect.id] = state
        
        // 执行动画
        animateHighlightIn(highlightLayer)
    }
    
    /// 移除高亮
    public func removeHighlight(for rectId: UUID) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard let state = highlightStates[rectId] else { return }
        
        // 执行动画
        animateHighlightOut(state.layer) { [weak self] in
            state.layer.removeFromSuperlayer()
            self?.highlightStates.removeValue(forKey: rectId)
        }
    }
    
    /// 移除所有高亮
    public func removeAllHighlights() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        for (_, state) in highlightStates {
            animateHighlightOut(state.layer) {
                state.layer.removeFromSuperlayer()
            }
        }
        
        highlightStates.removeAll()
    }
    
    /// 更新高亮位置
    public func updateHighlight(for rectId: UUID, newRect: TreeMapRect) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard let state = highlightStates[rectId] else { return }
        
        // 更新层位置和大小
        CATransaction.begin()
        CATransaction.setAnimationDuration(configuration.animationDuration)
        
        state.layer.frame = newRect.rect
        
        CATransaction.commit()
        
        // 更新状态
        let newState = HighlightState(rect: newRect, type: state.type, layer: state.layer, startTime: state.startTime)
        highlightStates[rectId] = newState
    }
    
    /// 获取当前高亮数量
    public func getHighlightCount() -> Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return highlightStates.count
    }
    
    /// 检查是否有高亮
    public func hasHighlight(for rectId: UUID) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        return highlightStates[rectId] != nil
    }
    
    // MARK: - Private Methods
    
    /// 创建高亮层
    private func createHighlightLayer(for rect: TreeMapRect, type: HighlightType) -> CALayer {
        let layer = CALayer()
        
        // 设置基本属性
        layer.frame = rect.rect
        layer.cornerRadius = configuration.cornerRadius
        layer.masksToBounds = true
        
        // 根据类型设置样式
        switch type {
        case .hover:
            setupHoverHighlight(layer, for: rect)
        case .selection:
            setupSelectionHighlight(layer, for: rect)
        case .focus:
            setupFocusHighlight(layer, for: rect)
        }
        
        return layer
    }
    
    /// 设置悬停高亮
    private func setupHoverHighlight(_ layer: CALayer, for rect: TreeMapRect) {
        // 增加亮度
        let originalColor = rect.color
        let highlightColor = increaseBrightness(originalColor, by: configuration.brightnessIncrease)
        
        layer.backgroundColor = highlightColor
        layer.borderColor = configuration.borderColor.cgColor
        layer.borderWidth = configuration.borderWidth
        
        // 添加阴影效果
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.2
    }
    
    /// 设置选中高亮
    private func setupSelectionHighlight(_ layer: CALayer, for rect: TreeMapRect) {
        layer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
        layer.borderColor = NSColor.controlAccentColor.cgColor
        layer.borderWidth = configuration.borderWidth * 1.5
        
        // 添加脉冲动画
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.7
        pulseAnimation.duration = 1.0
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.autoreverses = true
        
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    /// 设置焦点高亮
    private func setupFocusHighlight(_ layer: CALayer, for rect: TreeMapRect) {
        layer.backgroundColor = NSColor.clear.cgColor
        layer.borderColor = NSColor.keyboardFocusIndicatorColor.cgColor
        layer.borderWidth = configuration.borderWidth
        
        // 添加虚线边框 (CALayer没有lineDashPattern，需要使用CAShapeLayer)
        if let shapeLayer = layer as? CAShapeLayer {
            shapeLayer.lineDashPattern = [4, 2]
        }
    }
    
    /// 增加颜色亮度
    private func increaseBrightness(_ color: CGColor, by amount: CGFloat) -> CGColor {
        guard let nsColor = NSColor(cgColor: color) else { return color }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = min(1.0, brightness + amount)
        let newColor = NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
        
        return newColor.cgColor
    }
    
    /// 高亮淡入动画
    private func animateHighlightIn(_ layer: CALayer) {
        layer.opacity = 0
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = configuration.animationDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "fadeIn")
        layer.opacity = 1
    }
    
    /// 高亮淡出动画
    private func animateHighlightOut(_ layer: CALayer, completion: @escaping () -> Void) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = layer.opacity
        animation.toValue = 0
        animation.duration = configuration.animationDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // 设置动画完成回调
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        layer.add(animation, forKey: "fadeOut")
        layer.opacity = 0
        
        CATransaction.commit()
    }
}

// MARK: - Extensions

extension HighlightRenderer {
    
    /// 获取高亮统计信息
    public func getHighlightStatistics() -> [String: Any] {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        let typeCount = highlightStates.values.reduce(into: [String: Int]()) { result, state in
            let typeName = String(describing: state.type)
            result[typeName, default: 0] += 1
        }
        
        return [
            "totalHighlights": highlightStates.count,
            "typeBreakdown": typeCount,
            "hasContainer": containerLayer != nil,
            "animationDuration": configuration.animationDuration
        ]
    }
    
    /// 导出高亮报告
    public func exportHighlightReport() -> String {
        var report = "=== Highlight Renderer Report ===\n\n"
        
        let stats = getHighlightStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Total Highlights: \(stats["totalHighlights"] ?? 0)\n"
        report += "Has Container: \(stats["hasContainer"] ?? false)\n"
        report += "Animation Duration: \(stats["animationDuration"] ?? 0)s\n\n"
        
        if let typeBreakdown = stats["typeBreakdown"] as? [String: Int] {
            report += "=== Type Breakdown ===\n"
            for (type, count) in typeBreakdown {
                report += "\(type): \(count)\n"
            }
            report += "\n"
        }
        
        report += "=== Configuration ===\n"
        report += "Brightness Increase: \(configuration.brightnessIncrease)\n"
        report += "Border Width: \(configuration.borderWidth)pt\n"
        report += "Border Color: \(configuration.borderColor)\n"
        report += "Corner Radius: \(configuration.cornerRadius)pt\n\n"
        
        return report
    }
}
