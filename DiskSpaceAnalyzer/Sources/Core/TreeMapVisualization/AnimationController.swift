import Foundation
import CoreGraphics
import QuartzCore

/// 动画类型
public enum AnimationType {
    case position
    case size
    case color
    case opacity
}

/// 动画配置
public struct AnimationConfiguration {
    public let duration: TimeInterval
    public let timingFunction: CAMediaTimingFunction
    public let animationTypes: Set<AnimationType>
    
    public init(duration: TimeInterval = 0.3, timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut), animationTypes: Set<AnimationType> = [.position, .size]) {
        self.duration = duration
        self.timingFunction = timingFunction
        self.animationTypes = animationTypes
    }
}

/// 动画控制器 - 管理TreeMap布局变化的平滑动画效果
public class AnimationController {
    
    // MARK: - Properties
    
    /// 动画配置
    public var configuration: AnimationConfiguration
    
    /// 当前动画组
    private var currentAnimationGroup: CAAnimationGroup?
    
    /// 动画完成回调
    public var animationCompletionCallback: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(configuration: AnimationConfiguration = AnimationConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// 开始动画
    public func animateLayoutChange(from oldRects: [TreeMapRect], to newRects: [TreeMapRect], in layer: CALayer) {
        guard !oldRects.isEmpty && !newRects.isEmpty else { return }
        
        // 取消当前动画
        cancelCurrentAnimation()
        
        // 创建动画组
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = configuration.duration
        animationGroup.timingFunction = configuration.timingFunction
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false
        
        var animations: [CAAnimation] = []
        
        // 为每个矩形创建动画
        for (index, newRect) in newRects.enumerated() {
            if index < oldRects.count {
                let oldRect = oldRects[index]
                
                // 位置动画
                if configuration.animationTypes.contains(.position) {
                    let positionAnimation = createPositionAnimation(from: oldRect.rect, to: newRect.rect)
                    animations.append(positionAnimation)
                }
                
                // 大小动画
                if configuration.animationTypes.contains(.size) {
                    let sizeAnimation = createSizeAnimation(from: oldRect.rect, to: newRect.rect)
                    animations.append(sizeAnimation)
                }
                
                // 颜色动画
                if configuration.animationTypes.contains(.color) {
                    let colorAnimation = createColorAnimation(from: oldRect.color, to: newRect.color)
                    animations.append(colorAnimation)
                }
            }
        }
        
        animationGroup.animations = animations
        
        // 设置代理
        animationGroup.delegate = self
        
        // 开始动画
        layer.add(animationGroup, forKey: "layoutAnimation")
        currentAnimationGroup = animationGroup
    }
    
    /// 取消当前动画
    public func cancelCurrentAnimation() {
        currentAnimationGroup?.delegate = nil
        currentAnimationGroup = nil
    }
    
    /// 暂停动画
    public func pauseAnimation(in layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    /// 恢复动画
    public func resumeAnimation(in layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    // MARK: - Private Methods
    
    /// 创建位置动画
    private func createPositionAnimation(from oldRect: CGRect, to newRect: CGRect) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(cgPoint: CGPoint(x: oldRect.midX, y: oldRect.midY))
        animation.toValue = NSValue(cgPoint: CGPoint(x: newRect.midX, y: newRect.midY))
        return animation
    }
    
    /// 创建大小动画
    private func createSizeAnimation(from oldRect: CGRect, to newRect: CGRect) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "bounds")
        animation.fromValue = NSValue(cgRect: CGRect(origin: .zero, size: oldRect.size))
        animation.toValue = NSValue(cgRect: CGRect(origin: .zero, size: newRect.size))
        return animation
    }
    
    /// 创建颜色动画
    private func createColorAnimation(from oldColor: CGColor, to newColor: CGColor) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = oldColor
        animation.toValue = newColor
        return animation
    }
}

// MARK: - CAAnimationDelegate

extension AnimationController: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            animationCompletionCallback?()
        }
        currentAnimationGroup = nil
    }
}
