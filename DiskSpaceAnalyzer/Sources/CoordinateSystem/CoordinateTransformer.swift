import Foundation
import AppKit
import Common

/// 坐标变换器 - 实现多层坐标系统的精确变换
public class CoordinateTransformer {
    
    // MARK: - Singleton
    
    public static let shared = CoordinateTransformer()
    
    private init() {
        setupTransformCache()
    }
    
    // MARK: - Properties
    
    /// 变换缓存
    private var transformCache: [String: CGAffineTransform] = [:]
    
    /// 缓存访问队列
    private let cacheQueue = DispatchQueue(label: "CoordinateTransformer.cache", attributes: .concurrent)
    
    // MARK: - Public Methods
    
    /// 屏幕坐标转窗口坐标
    /// - Parameters:
    ///   - screenPoint: 屏幕坐标点
    ///   - window: 目标窗口
    /// - Returns: 窗口坐标点
    public func screenToWindow(_ screenPoint: CGPoint, in window: NSWindow) -> CGPoint {
        let windowFrame = window.frame
        return CGPoint(
            x: screenPoint.x - windowFrame.origin.x,
            y: screenPoint.y - windowFrame.origin.y
        )
    }
    
    /// 窗口坐标转屏幕坐标
    /// - Parameters:
    ///   - windowPoint: 窗口坐标点
    ///   - window: 源窗口
    /// - Returns: 屏幕坐标点
    public func windowToScreen(_ windowPoint: CGPoint, from window: NSWindow) -> CGPoint {
        let windowFrame = window.frame
        return CGPoint(
            x: windowPoint.x + windowFrame.origin.x,
            y: windowPoint.y + windowFrame.origin.y
        )
    }
    
    /// 窗口坐标转容器坐标
    /// - Parameters:
    ///   - windowPoint: 窗口坐标点
    ///   - containerFrame: 容器框架
    /// - Returns: 容器坐标点
    public func windowToContainer(_ windowPoint: CGPoint, containerFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: windowPoint.x - containerFrame.origin.x,
            y: windowPoint.y - containerFrame.origin.y
        )
    }
    
    /// 容器坐标转窗口坐标
    /// - Parameters:
    ///   - containerPoint: 容器坐标点
    ///   - containerFrame: 容器框架
    /// - Returns: 窗口坐标点
    public func containerToWindow(_ containerPoint: CGPoint, containerFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: containerPoint.x + containerFrame.origin.x,
            y: containerPoint.y + containerFrame.origin.y
        )
    }
    
    /// 容器坐标转画布坐标
    /// - Parameters:
    ///   - containerPoint: 容器坐标点
    ///   - canvasTransform: 画布变换
    /// - Returns: 画布坐标点
    public func containerToCanvas(_ containerPoint: CGPoint, canvasTransform: CGAffineTransform) -> CGPoint {
        return containerPoint.applying(canvasTransform.inverted())
    }
    
    /// 画布坐标转容器坐标
    /// - Parameters:
    ///   - canvasPoint: 画布坐标点
    ///   - canvasTransform: 画布变换
    /// - Returns: 容器坐标点
    public func canvasToContainer(_ canvasPoint: CGPoint, canvasTransform: CGAffineTransform) -> CGPoint {
        return canvasPoint.applying(canvasTransform)
    }
    
    /// 通用坐标变换
    /// - Parameters:
    ///   - point: 源坐标点
    ///   - transform: 变换矩阵
    /// - Returns: 变换后的坐标点
    public func transform(_ point: CGPoint, using transform: CGAffineTransform) -> CGPoint {
        return point.applying(transform)
    }
    
    /// 创建复合变换
    /// - Parameter transforms: 变换数组
    /// - Returns: 复合变换矩阵
    public func createCompositeTransform(_ transforms: [CGAffineTransform]) -> CGAffineTransform {
        return transforms.reduce(.identity) { result, transform in
            result.concatenating(transform)
        }
    }
    
    /// 获取缓存的变换
    /// - Parameter key: 缓存键
    /// - Returns: 变换矩阵，如果不存在返回nil
    public func getCachedTransform(for key: String) -> CGAffineTransform? {
        return cacheQueue.sync {
            return transformCache[key]
        }
    }
    
    /// 缓存变换
    /// - Parameters:
    ///   - transform: 变换矩阵
    ///   - key: 缓存键
    public func cacheTransform(_ transform: CGAffineTransform, for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.transformCache[key] = transform
        }
    }
    
    /// 清除变换缓存
    public func clearTransformCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.transformCache.removeAll()
        }
    }
    
    // MARK: - HiDPI Support
    
    /// 应用HiDPI缩放
    /// - Parameters:
    ///   - point: 原始坐标点
    ///   - scaleFactor: 缩放因子
    /// - Returns: 缩放后的坐标点
    public func applyHiDPIScaling(_ point: CGPoint, scaleFactor: CGFloat) -> CGPoint {
        return CGPoint(
            x: point.x * scaleFactor,
            y: point.y * scaleFactor
        )
    }
    
    /// 移除HiDPI缩放
    /// - Parameters:
    ///   - point: 缩放后的坐标点
    ///   - scaleFactor: 缩放因子
    /// - Returns: 原始坐标点
    public func removeHiDPIScaling(_ point: CGPoint, scaleFactor: CGFloat) -> CGPoint {
        guard scaleFactor > 0 else { return point }
        return CGPoint(
            x: point.x / scaleFactor,
            y: point.y / scaleFactor
        )
    }
    
    /// 像素对齐
    /// - Parameters:
    ///   - point: 原始坐标点
    ///   - scaleFactor: 缩放因子
    /// - Returns: 像素对齐后的坐标点
    public func pixelAlign(_ point: CGPoint, scaleFactor: CGFloat = 1.0) -> CGPoint {
        let scale = scaleFactor > 0 ? scaleFactor : 1.0
        return CGPoint(
            x: floor(point.x * scale) / scale,
            y: floor(point.y * scale) / scale
        )
    }
    
    // MARK: - Private Methods
    
    /// 设置变换缓存
    private func setupTransformCache() {
        // 预设常用变换
        transformCache["identity"] = .identity
        transformCache["flipY"] = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    /// 生成缓存键
    /// - Parameters:
    ///   - sourceType: 源坐标系统类型
    ///   - targetType: 目标坐标系统类型
    ///   - additionalInfo: 附加信息
    /// - Returns: 缓存键
    private func generateCacheKey(from sourceType: CoordinateSystemType, to targetType: CoordinateSystemType, additionalInfo: String = "") -> String {
        return "\(sourceType.rawValue)_to_\(targetType.rawValue)\(additionalInfo.isEmpty ? "" : "_\(additionalInfo)")"
    }
}

// MARK: - Extensions

extension CGAffineTransform {
    /// 是否为单位矩阵
    public var isIdentity: Bool {
        return self == .identity
    }
    
    /// 获取缩放因子
    public var scaleX: CGFloat {
        return sqrt(a * a + c * c)
    }
    
    public var scaleY: CGFloat {
        return sqrt(b * b + d * d)
    }
    
    /// 获取旋转角度（弧度）
    public var rotation: CGFloat {
        return atan2(b, a)
    }
    
    /// 获取平移量
    public var translation: CGPoint {
        return CGPoint(x: tx, y: ty)
    }
}
