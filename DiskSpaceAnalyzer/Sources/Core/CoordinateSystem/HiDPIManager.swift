import Foundation
import CoreGraphics
import AppKit

/// HiDPI显示器信息
public struct DisplayInfo {
    public let id: CGDirectDisplayID
    public let scaleFactor: CGFloat
    public let frame: CGRect
    public let isMain: Bool
    public let colorSpace: CGColorSpace?
    
    public init(id: CGDirectDisplayID, scaleFactor: CGFloat, frame: CGRect, isMain: Bool, colorSpace: CGColorSpace? = nil) {
        self.id = id
        self.scaleFactor = scaleFactor
        self.frame = frame
        self.isMain = isMain
        self.colorSpace = colorSpace
    }
}

/// HiDPI管理器 - 处理高分辨率显示器的精确适配
public class HiDPIManager {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = HiDPIManager()
    
    /// 当前显示器信息
    private var displayInfos: [CGDirectDisplayID: DisplayInfo] = [:]
    
    /// 缩放因子变化通知
    public static let scaleFactorDidChangeNotification = Notification.Name("HiDPIManager.scaleFactorDidChange")
    
    /// 观察者
    private var observers: [NSObjectProtocol] = []
    
    /// 更新锁
    private let updateLock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
        updateDisplayInfos()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Public Methods
    
    /// 获取主显示器的缩放因子
    public func getMainDisplayScaleFactor() -> CGFloat {
        return NSScreen.main?.backingScaleFactor ?? 1.0
    }
    
    /// 获取指定窗口所在显示器的缩放因子
    public func getScaleFactor(for window: NSWindow) -> CGFloat {
        guard let screen = window.screen else {
            return getMainDisplayScaleFactor()
        }
        return screen.backingScaleFactor
    }
    
    /// 获取指定点所在显示器的缩放因子
    public func getScaleFactor(for point: CGPoint) -> CGFloat {
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
        return screen?.backingScaleFactor ?? getMainDisplayScaleFactor()
    }
    
    /// 应用HiDPI缩放到坐标点
    public func applyHiDPIScaling(to point: CGPoint, scaleFactor: CGFloat? = nil) -> CGPoint {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        return CGPoint(x: point.x * scale, y: point.y * scale)
    }
    
    /// 移除HiDPI缩放从坐标点
    public func removeHiDPIScaling(from point: CGPoint, scaleFactor: CGFloat? = nil) -> CGPoint {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        guard scale > 0 else { return point }
        return CGPoint(x: point.x / scale, y: point.y / scale)
    }
    
    /// 应用HiDPI缩放到尺寸
    public func applyHiDPIScaling(to size: CGSize, scaleFactor: CGFloat? = nil) -> CGSize {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
    
    /// 移除HiDPI缩放从尺寸
    public func removeHiDPIScaling(from size: CGSize, scaleFactor: CGFloat? = nil) -> CGSize {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        guard scale > 0 else { return size }
        return CGSize(width: size.width / scale, height: size.height / scale)
    }
    
    /// 应用HiDPI缩放到矩形
    public func applyHiDPIScaling(to rect: CGRect, scaleFactor: CGFloat? = nil) -> CGRect {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        return CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
    }
    
    /// 移除HiDPI缩放从矩形
    public func removeHiDPIScaling(from rect: CGRect, scaleFactor: CGFloat? = nil) -> CGRect {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        guard scale > 0 else { return rect }
        return CGRect(
            x: rect.origin.x / scale,
            y: rect.origin.y / scale,
            width: rect.size.width / scale,
            height: rect.size.height / scale
        )
    }
    
    /// 像素完美对齐
    public func pixelAlign(_ point: CGPoint, scaleFactor: CGFloat? = nil) -> CGPoint {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        return CGPoint(
            x: round(point.x * scale) / scale,
            y: round(point.y * scale) / scale
        )
    }
    
    /// 像素完美对齐矩形
    public func pixelAlign(_ rect: CGRect, scaleFactor: CGFloat? = nil) -> CGRect {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        let alignedOrigin = CGPoint(
            x: floor(rect.origin.x * scale) / scale,
            y: floor(rect.origin.y * scale) / scale
        )
        let alignedSize = CGSize(
            width: ceil(rect.size.width * scale) / scale,
            height: ceil(rect.size.height * scale) / scale
        )
        return CGRect(origin: alignedOrigin, size: alignedSize)
    }
    
    /// 获取所有显示器信息
    public func getAllDisplayInfos() -> [DisplayInfo] {
        updateLock.lock()
        defer { updateLock.unlock() }
        return Array(displayInfos.values)
    }
    
    /// 获取指定显示器信息
    public func getDisplayInfo(for displayID: CGDirectDisplayID) -> DisplayInfo? {
        updateLock.lock()
        defer { updateLock.unlock() }
        return displayInfos[displayID]
    }
    
    /// 检查是否支持非整数缩放
    public func supportsNonIntegerScaling() -> Bool {
        let scaleFactor = getMainDisplayScaleFactor()
        return scaleFactor != floor(scaleFactor)
    }
    
    /// 获取推荐的线条宽度（考虑HiDPI）
    public func getRecommendedLineWidth(scaleFactor: CGFloat? = nil) -> CGFloat {
        let scale = scaleFactor ?? getMainDisplayScaleFactor()
        return 1.0 / scale
    }
    
    // MARK: - Private Methods
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        let observer1 = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChange()
        }
        
        observers.append(observer1)
    }
    
    /// 处理屏幕参数变化
    private func handleScreenParametersChange() {
        updateDisplayInfos()
        
        // 发送缩放因子变化通知
        NotificationCenter.default.post(
            name: Self.scaleFactorDidChangeNotification,
            object: self,
            userInfo: ["displayInfos": getAllDisplayInfos()]
        )
    }
    
    /// 更新显示器信息
    private func updateDisplayInfos() {
        updateLock.lock()
        defer { updateLock.unlock() }
        
        displayInfos.removeAll()
        
        for screen in NSScreen.screens {
            guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }
            
            let displayInfo = DisplayInfo(
                id: displayID,
                scaleFactor: screen.backingScaleFactor,
                frame: screen.frame,
                isMain: screen == NSScreen.main,
                colorSpace: screen.colorSpace?.cgColorSpace
            )
            
            displayInfos[displayID] = displayInfo
        }
    }
}

// MARK: - Extensions

extension CGPoint {
    /// 应用HiDPI缩放
    public func scaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGPoint {
        return HiDPIManager.shared.applyHiDPIScaling(to: self, scaleFactor: factor)
    }
    
    /// 移除HiDPI缩放
    public func unscaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGPoint {
        return HiDPIManager.shared.removeHiDPIScaling(from: self, scaleFactor: factor)
    }
    
    /// 像素对齐
    public func pixelAligned(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGPoint {
        return HiDPIManager.shared.pixelAlign(self, scaleFactor: factor)
    }
}

extension CGSize {
    /// 应用HiDPI缩放
    public func scaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGSize {
        return HiDPIManager.shared.applyHiDPIScaling(to: self, scaleFactor: factor)
    }
    
    /// 移除HiDPI缩放
    public func unscaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGSize {
        return HiDPIManager.shared.removeHiDPIScaling(from: self, scaleFactor: factor)
    }
}

extension CGRect {
    /// 应用HiDPI缩放
    public func scaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGRect {
        return HiDPIManager.shared.applyHiDPIScaling(to: self, scaleFactor: factor)
    }
    
    /// 移除HiDPI缩放
    public func unscaledForHiDPI(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGRect {
        return HiDPIManager.shared.removeHiDPIScaling(from: self, scaleFactor: factor)
    }
    
    /// 像素对齐
    public func pixelAligned(factor: CGFloat = HiDPIManager.shared.getMainDisplayScaleFactor()) -> CGRect {
        return HiDPIManager.shared.pixelAlign(self, scaleFactor: factor)
    }
}
