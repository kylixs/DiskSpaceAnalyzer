import Foundation
import AppKit
import Common

/// HiDPI管理器 - 检测和适配HiDPI显示器
public class HiDPIManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = HiDPIManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 当前主显示器缩放因子
    @Published public private(set) var mainDisplayScaleFactor: CGFloat = 1.0
    
    /// 是否为HiDPI显示器
    @Published public private(set) var isHiDPI: Bool = false
    
    /// 所有显示器的缩放因子
    @Published public private(set) var displayScaleFactors: [String: CGFloat] = [:]
    
    /// 是否已初始化
    private var isInitialized = false
    
    // MARK: - Initialization
    
    /// 初始化HiDPI管理器
    public func initialize() {
        guard !isInitialized else { return }
        
        updateDisplayInfo()
        setupNotifications()
        
        isInitialized = true
        print("📐 HiDPI管理器初始化完成")
    }
    
    // MARK: - Public Methods
    
    /// 获取指定显示器的缩放因子
    /// - Parameter screen: 显示器
    /// - Returns: 缩放因子
    public func getScaleFactor(for screen: NSScreen?) -> CGFloat {
        guard let screen = screen else {
            return mainDisplayScaleFactor
        }
        
        return screen.backingScaleFactor
    }
    
    /// 获取主显示器的缩放因子
    /// - Returns: 主显示器缩放因子
    public func getMainDisplayScaleFactor() -> CGFloat {
        return NSScreen.main?.backingScaleFactor ?? 1.0
    }
    
    /// 检查是否为HiDPI显示器
    /// - Parameter screen: 显示器
    /// - Returns: 是否为HiDPI
    public func isHiDPIDisplay(_ screen: NSScreen?) -> Bool {
        return getScaleFactor(for: screen) > 1.0
    }
    
    /// 将点坐标转换为像素坐标
    /// - Parameters:
    ///   - point: 点坐标
    ///   - screen: 显示器
    /// - Returns: 像素坐标
    public func pointToPixel(_ point: CGPoint, on screen: NSScreen?) -> CGPoint {
        let scaleFactor = getScaleFactor(for: screen)
        return CGPoint(
            x: point.x * scaleFactor,
            y: point.y * scaleFactor
        )
    }
    
    /// 将像素坐标转换为点坐标
    /// - Parameters:
    ///   - pixel: 像素坐标
    ///   - screen: 显示器
    /// - Returns: 点坐标
    public func pixelToPoint(_ pixel: CGPoint, on screen: NSScreen?) -> CGPoint {
        let scaleFactor = getScaleFactor(for: screen)
        guard scaleFactor > 0 else { return pixel }
        
        return CGPoint(
            x: pixel.x / scaleFactor,
            y: pixel.y / scaleFactor
        )
    }
    
    /// 像素对齐坐标
    /// - Parameters:
    ///   - point: 原始坐标
    ///   - screen: 显示器
    /// - Returns: 像素对齐后的坐标
    public func pixelAlign(_ point: CGPoint, on screen: NSScreen?) -> CGPoint {
        let scaleFactor = getScaleFactor(for: screen)
        return CGPoint(
            x: round(point.x * scaleFactor) / scaleFactor,
            y: round(point.y * scaleFactor) / scaleFactor
        )
    }
    
    /// 获取像素完美的矩形
    /// - Parameters:
    ///   - rect: 原始矩形
    ///   - screen: 显示器
    /// - Returns: 像素完美的矩形
    public func pixelPerfectRect(_ rect: CGRect, on screen: NSScreen?) -> CGRect {
        let scaleFactor = getScaleFactor(for: screen)
        
        let alignedOrigin = CGPoint(
            x: floor(rect.origin.x * scaleFactor) / scaleFactor,
            y: floor(rect.origin.y * scaleFactor) / scaleFactor
        )
        
        let alignedSize = CGSize(
            width: ceil(rect.size.width * scaleFactor) / scaleFactor,
            height: ceil(rect.size.height * scaleFactor) / scaleFactor
        )
        
        return CGRect(origin: alignedOrigin, size: alignedSize)
    }
    
    /// 获取显示器信息摘要
    /// - Returns: 显示器信息字典
    public func getDisplayInfoSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        summary["mainDisplayScaleFactor"] = mainDisplayScaleFactor
        summary["isHiDPI"] = isHiDPI
        summary["displayCount"] = NSScreen.screens.count
        summary["displayScaleFactors"] = displayScaleFactors
        
        return summary
    }
    
    // MARK: - Private Methods
    
    /// 更新显示器信息
    private func updateDisplayInfo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新主显示器信息
            self.mainDisplayScaleFactor = self.getMainDisplayScaleFactor()
            self.isHiDPI = self.mainDisplayScaleFactor > 1.0
            
            // 更新所有显示器的缩放因子
            var scaleFactors: [String: CGFloat] = [:]
            for (index, screen) in NSScreen.screens.enumerated() {
                let identifier = self.getScreenIdentifier(screen, index: index)
                scaleFactors[identifier] = screen.backingScaleFactor
            }
            self.displayScaleFactors = scaleFactors
            
            print("📐 显示器信息更新: 主显示器缩放=\(self.mainDisplayScaleFactor), HiDPI=\(self.isHiDPI)")
        }
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    /// 显示器参数变化处理
    @objc private func screenParametersChanged() {
        print("📐 检测到显示器参数变化，更新HiDPI信息")
        updateDisplayInfo()
    }
    
    /// 获取显示器标识符
    /// - Parameters:
    ///   - screen: 显示器
    ///   - index: 索引
    /// - Returns: 显示器标识符
    private func getScreenIdentifier(_ screen: NSScreen, index: Int) -> String {
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "screen_\(screenNumber.intValue)"
        }
        return "screen_\(index)"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Extensions

extension NSScreen {
    /// 是否为HiDPI显示器
    public var isHiDPI: Bool {
        return backingScaleFactor > 1.0
    }
    
    /// 显示器标识符
    public var identifier: String {
        if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "screen_\(screenNumber.intValue)"
        }
        return "screen_unknown"
    }
    
    /// 显示器信息摘要
    public var infoSummary: [String: Any] {
        return [
            "identifier": identifier,
            "scaleFactor": backingScaleFactor,
            "isHiDPI": isHiDPI,
            "frame": NSStringFromRect(frame),
            "visibleFrame": NSStringFromRect(visibleFrame)
        ]
    }
}
