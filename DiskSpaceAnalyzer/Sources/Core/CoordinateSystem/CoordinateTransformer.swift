import Foundation
import CoreGraphics
import AppKit

/// 坐标系统层次枚举
public enum CoordinateSpace {
    case screen     // 屏幕坐标系
    case window     // 窗口坐标系
    case container  // 容器坐标系
    case canvas     // 画布坐标系
}

/// 坐标变换结果
public struct TransformResult {
    public let point: CGPoint
    public let space: CoordinateSpace
    public let accuracy: Double
    
    public init(point: CGPoint, space: CoordinateSpace, accuracy: Double = 1.0) {
        self.point = point
        self.space = space
        self.accuracy = accuracy
    }
}

/// 坐标变换器 - 实现多层坐标系统的精确变换
public class CoordinateTransformer {
    
    // MARK: - Properties
    
    /// 变换矩阵缓存
    private var transformCache: [String: CGAffineTransform] = [:]
    
    /// 缓存锁
    private let cacheLock = NSLock()
    
    /// 窗口引用
    private weak var window: NSWindow?
    
    /// 容器视图引用
    private weak var containerView: NSView?
    
    /// 画布视图引用
    private weak var canvasView: NSView?
    
    /// 缓存命中统计
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    // MARK: - Initialization
    
    public init(window: NSWindow? = nil, containerView: NSView? = nil, canvasView: NSView? = nil) {
        self.window = window
        self.containerView = containerView
        self.canvasView = canvasView
    }
    
    // MARK: - Public Methods
    
    /// 更新视图引用
    public func updateViews(window: NSWindow?, containerView: NSView?, canvasView: NSView?) {
        self.window = window
        self.containerView = containerView
        self.canvasView = canvasView
        clearCache()
    }
    
    /// 多层坐标变换
    public func transform(point: CGPoint, from sourceSpace: CoordinateSpace, to targetSpace: CoordinateSpace) -> TransformResult {
        // 如果源和目标相同，直接返回
        if sourceSpace == targetSpace {
            return TransformResult(point: point, space: targetSpace, accuracy: 1.0)
        }
        
        var currentPoint = point
        var accuracy = 1.0
        
        // 转换到屏幕坐标系作为中间坐标
        switch sourceSpace {
        case .screen:
            break
        case .window:
            currentPoint = windowToScreen(currentPoint)
        case .container:
            currentPoint = containerToScreen(currentPoint)
            accuracy *= 0.99
        case .canvas:
            currentPoint = canvasToScreen(currentPoint)
            accuracy *= 0.98
        }
        
        // 从屏幕坐标系转换到目标坐标系
        switch targetSpace {
        case .screen:
            break
        case .window:
            currentPoint = screenToWindow(currentPoint)
        case .container:
            currentPoint = screenToContainer(currentPoint)
            accuracy *= 0.99
        case .canvas:
            currentPoint = screenToCanvas(currentPoint)
            accuracy *= 0.98
        }
        
        return TransformResult(point: currentPoint, space: targetSpace, accuracy: accuracy)
    }
    
    /// 批量坐标变换
    public func transformBatch(points: [CGPoint], from sourceSpace: CoordinateSpace, to targetSpace: CoordinateSpace) -> [TransformResult] {
        return points.map { transform(point: $0, from: sourceSpace, to: targetSpace) }
    }
    
    /// 获取缓存统计信息
    public func getCacheStats() -> (hits: Int, misses: Int, hitRate: Double) {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0.0
        return (cacheHits, cacheMisses, hitRate)
    }
    
    /// 清除缓存
    public func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        transformCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
    }
    
    // MARK: - Private Transform Methods
    
    /// 屏幕坐标到窗口坐标
    private func screenToWindow(_ screenPoint: CGPoint) -> CGPoint {
        guard let window = window else { return screenPoint }
        
        let cacheKey = "screenToWindow_\(window.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return screenPoint.applying(cachedTransform)
        }
        
        // 计算变换矩阵
        let windowFrame = window.frame
        let transform = CGAffineTransform(translationX: -windowFrame.origin.x, y: -windowFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return screenPoint.applying(transform)
    }
    
    /// 窗口坐标到屏幕坐标
    private func windowToScreen(_ windowPoint: CGPoint) -> CGPoint {
        guard let window = window else { return windowPoint }
        
        let cacheKey = "windowToScreen_\(window.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return windowPoint.applying(cachedTransform)
        }
        
        // 计算变换矩阵
        let windowFrame = window.frame
        let transform = CGAffineTransform(translationX: windowFrame.origin.x, y: windowFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return windowPoint.applying(transform)
    }
    
    /// 屏幕坐标到容器坐标
    private func screenToContainer(_ screenPoint: CGPoint) -> CGPoint {
        let windowPoint = screenToWindow(screenPoint)
        return windowToContainer(windowPoint)
    }
    
    /// 容器坐标到屏幕坐标
    private func containerToScreen(_ containerPoint: CGPoint) -> CGPoint {
        let windowPoint = containerToWindow(containerPoint)
        return windowToScreen(windowPoint)
    }
    
    /// 窗口坐标到容器坐标
    private func windowToContainer(_ windowPoint: CGPoint) -> CGPoint {
        guard let window = window, let containerView = containerView else { return windowPoint }
        
        let cacheKey = "windowToContainer_\(window.frame)_\(containerView.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return windowPoint.applying(cachedTransform)
        }
        
        // 计算容器在窗口中的位置
        let containerFrame = containerView.convert(containerView.bounds, to: nil)
        let transform = CGAffineTransform(translationX: -containerFrame.origin.x, y: -containerFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return windowPoint.applying(transform)
    }
    
    /// 容器坐标到窗口坐标
    private func containerToWindow(_ containerPoint: CGPoint) -> CGPoint {
        guard let window = window, let containerView = containerView else { return containerPoint }
        
        let cacheKey = "containerToWindow_\(window.frame)_\(containerView.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return containerPoint.applying(cachedTransform)
        }
        
        // 计算容器在窗口中的位置
        let containerFrame = containerView.convert(containerView.bounds, to: nil)
        let transform = CGAffineTransform(translationX: containerFrame.origin.x, y: containerFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return containerPoint.applying(transform)
    }
    
    /// 屏幕坐标到画布坐标
    private func screenToCanvas(_ screenPoint: CGPoint) -> CGPoint {
        let containerPoint = screenToContainer(screenPoint)
        return containerToCanvas(containerPoint)
    }
    
    /// 画布坐标到屏幕坐标
    private func canvasToScreen(_ canvasPoint: CGPoint) -> CGPoint {
        let containerPoint = canvasToContainer(canvasPoint)
        return containerToScreen(containerPoint)
    }
    
    /// 容器坐标到画布坐标
    private func containerToCanvas(_ containerPoint: CGPoint) -> CGPoint {
        guard let containerView = containerView, let canvasView = canvasView else { return containerPoint }
        
        let cacheKey = "containerToCanvas_\(containerView.frame)_\(canvasView.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return containerPoint.applying(cachedTransform)
        }
        
        // 计算画布在容器中的位置
        let canvasFrame = canvasView.convert(canvasView.bounds, to: containerView)
        let transform = CGAffineTransform(translationX: -canvasFrame.origin.x, y: -canvasFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return containerPoint.applying(transform)
    }
    
    /// 画布坐标到容器坐标
    private func canvasToContainer(_ canvasPoint: CGPoint) -> CGPoint {
        guard let containerView = containerView, let canvasView = canvasView else { return canvasPoint }
        
        let cacheKey = "canvasToContainer_\(containerView.frame)_\(canvasView.frame)"
        if let cachedTransform = getCachedTransform(key: cacheKey) {
            return canvasPoint.applying(cachedTransform)
        }
        
        // 计算画布在容器中的位置
        let canvasFrame = canvasView.convert(canvasView.bounds, to: containerView)
        let transform = CGAffineTransform(translationX: canvasFrame.origin.x, y: canvasFrame.origin.y)
        
        setCachedTransform(key: cacheKey, transform: transform)
        return canvasPoint.applying(transform)
    }
    
    // MARK: - Cache Management
    
    /// 获取缓存的变换矩阵
    private func getCachedTransform(key: String) -> CGAffineTransform? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        if let transform = transformCache[key] {
            cacheHits += 1
            return transform
        } else {
            cacheMisses += 1
            return nil
        }
    }
    
    /// 设置缓存的变换矩阵
    private func setCachedTransform(key: String, transform: CGAffineTransform) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        transformCache[key] = transform
    }
}

// MARK: - Extensions

extension CGPoint {
    /// 确保亚像素级精度
    public func withSubPixelPrecision() -> CGPoint {
        return CGPoint(x: Double(x), y: Double(y))
    }
    
    /// 像素对齐
    public func pixelAligned() -> CGPoint {
        return CGPoint(x: round(x), y: round(y))
    }
}
