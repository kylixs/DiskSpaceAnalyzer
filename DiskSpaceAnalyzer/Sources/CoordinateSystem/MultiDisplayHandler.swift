import Foundation
import AppKit
import Common

/// 多显示器处理器 - 管理多显示器环境下的坐标转换
public class MultiDisplayHandler: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = MultiDisplayHandler()
    
    private init() {}
    
    // MARK: - Properties
    
    /// 所有显示器信息
    @Published public private(set) var displays: [DisplayInfo] = []
    
    /// 主显示器信息
    @Published public private(set) var mainDisplay: DisplayInfo?
    
    /// 显示器配置映射
    private var displayMapping: [String: DisplayInfo] = [:]
    
    /// 是否已初始化
    private var isInitialized = false
    
    // MARK: - Initialization
    
    /// 初始化多显示器处理器
    public func initialize() {
        guard !isInitialized else { return }
        
        updateDisplayConfiguration()
        setupNotifications()
        
        isInitialized = true
        print("📐 多显示器处理器初始化完成")
    }
    
    // MARK: - Public Methods
    
    /// 获取指定显示器信息
    /// - Parameter identifier: 显示器标识符
    /// - Returns: 显示器信息
    public func getDisplay(by identifier: String) -> DisplayInfo? {
        return displayMapping[identifier]
    }
    
    /// 获取包含指定点的显示器
    /// - Parameter point: 屏幕坐标点
    /// - Returns: 显示器信息
    public func getDisplay(containing point: CGPoint) -> DisplayInfo? {
        for display in displays {
            if display.frame.contains(point) {
                return display
            }
        }
        return mainDisplay
    }
    
    /// 跨显示器坐标转换
    /// - Parameters:
    ///   - point: 源坐标点
    ///   - sourceDisplay: 源显示器
    ///   - targetDisplay: 目标显示器
    /// - Returns: 转换后的坐标点
    public func convertPoint(_ point: CGPoint, from sourceDisplay: DisplayInfo, to targetDisplay: DisplayInfo) -> CGPoint {
        // 转换为全局屏幕坐标
        let globalPoint = CGPoint(
            x: point.x + sourceDisplay.frame.origin.x,
            y: point.y + sourceDisplay.frame.origin.y
        )
        
        // 转换为目标显示器坐标
        return CGPoint(
            x: globalPoint.x - targetDisplay.frame.origin.x,
            y: globalPoint.y - targetDisplay.frame.origin.y
        )
    }
    
    /// 获取显示器间的偏移量
    /// - Parameters:
    ///   - sourceDisplay: 源显示器
    ///   - targetDisplay: 目标显示器
    /// - Returns: 偏移量
    public func getOffset(from sourceDisplay: DisplayInfo, to targetDisplay: DisplayInfo) -> CGPoint {
        return CGPoint(
            x: targetDisplay.frame.origin.x - sourceDisplay.frame.origin.x,
            y: targetDisplay.frame.origin.y - sourceDisplay.frame.origin.y
        )
    }
    
    /// 获取显示器配置摘要
    /// - Returns: 配置摘要
    public func getConfigurationSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        
        summary["displayCount"] = displays.count
        summary["mainDisplayId"] = mainDisplay?.identifier ?? "unknown"
        
        var displayInfos: [[String: Any]] = []
        for display in displays {
            displayInfos.append([
                "identifier": display.identifier,
                "scaleFactor": display.scaleFactor,
                "frame": NSStringFromRect(display.frame),
                "visibleFrame": NSStringFromRect(display.visibleFrame)
            ])
        }
        summary["displays"] = displayInfos
        
        return summary
    }
    
    // MARK: - Private Methods
    
    /// 更新显示器配置
    private func updateDisplayConfiguration() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let screens = NSScreen.screens
            var newDisplays: [DisplayInfo] = []
            var newMapping: [String: DisplayInfo] = [:]
            
            for screen in screens {
                let displayInfo = DisplayInfo(screen: screen)
                newDisplays.append(displayInfo)
                newMapping[displayInfo.identifier] = displayInfo
            }
            
            self.displays = newDisplays
            self.displayMapping = newMapping
            
            // 更新主显示器信息
            if let mainScreen = NSScreen.main {
                self.mainDisplay = DisplayInfo(screen: mainScreen)
            }
            
            print("📐 显示器配置更新: \(newDisplays.count)个显示器")
        }
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    /// 显示器配置变化处理
    @objc private func screenConfigurationChanged() {
        print("📐 检测到显示器配置变化，更新多显示器信息")
        updateDisplayConfiguration()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Extensions

extension DisplayInfo {
    /// 是否为主显示器
    public var isMain: Bool {
        return screen == NSScreen.main
    }
    
    /// 显示器名称
    public var name: String {
        return screen.localizedName
    }
    
    /// 显示器分辨率
    public var resolution: CGSize {
        return frame.size
    }
    
    /// 有效分辨率（考虑缩放）
    public var effectiveResolution: CGSize {
        return CGSize(
            width: frame.width * scaleFactor,
            height: frame.height * scaleFactor
        )
    }
}
