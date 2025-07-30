import Foundation
import AppKit

/// 对话框管理器 - 统一管理各种系统对话框的创建和显示
public class DialogManager {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = DialogManager()
    
    /// 当前显示的对话框
    private var currentDialogs: Set<NSWindow> = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 显示文件选择对话框
    public func showFileSelectionDialog(completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "选择"
        openPanel.message = "选择要分析的文件夹"
        
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url?.path)
            } else {
                completion(nil)
            }
        }
    }
    
    /// 显示错误对话框
    public func showErrorDialog(title: String, message: String, error: Error? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "确定")
        
        if let error = error {
            alert.addButton(withTitle: "详细信息")
        }
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn, let error = error {
            showDetailedErrorDialog(error: error)
        }
    }
    
    /// 显示警告对话框
    public func showWarningDialog(title: String, message: String, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    /// 显示信息对话框
    public func showInfoDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        alert.runModal()
    }
    
    /// 显示确认对话框
    public func showConfirmationDialog(title: String, message: String, confirmTitle: String = "确定", cancelTitle: String = "取消", completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    // MARK: - Private Methods
    
    /// 显示详细错误对话框
    private func showDetailedErrorDialog(error: Error) {
        let alert = NSAlert()
        alert.messageText = "错误详细信息"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        // 添加详细信息
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        textView.isEditable = false
        textView.string = "\(error)"
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        
        alert.accessoryView = scrollView
        
        alert.runModal()
    }
}

/// 主题管理器 - 监听系统外观变化，自动切换深色/浅色模式
public class ThemeManager: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ThemeManager()
    
    /// 当前主题
    public private(set) var currentTheme: Theme = .system
    
    /// 主题变化回调
    public var themeChangeCallback: ((Theme) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupThemeObserver()
        updateCurrentTheme()
    }
    
    // MARK: - Public Methods
    
    /// 设置主题
    public func setTheme(_ theme: Theme) {
        currentTheme = theme
        applyTheme()
        themeChangeCallback?(theme)
    }
    
    /// 获取当前是否为深色模式
    public var isDarkMode: Bool {
        switch currentTheme {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            if #available(macOS 10.14, *) {
                return NSApp.effectiveAppearance.name == .darkAqua
            } else {
                return false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置主题观察者
    private func setupThemeObserver() {
        if #available(macOS 10.14, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(systemAppearanceChanged),
                name: NSApplication.didChangeEffectiveAppearanceNotification,
                object: nil
            )
        }
    }
    
    /// 系统外观变化
    @objc private func systemAppearanceChanged() {
        if currentTheme == .system {
            updateCurrentTheme()
            applyTheme()
            themeChangeCallback?(currentTheme)
        }
    }
    
    /// 更新当前主题
    private func updateCurrentTheme() {
        // 主题逻辑已在isDarkMode中处理
    }
    
    /// 应用主题
    private func applyTheme() {
        if #available(macOS 10.14, *) {
            let appearance: NSAppearance
            
            switch currentTheme {
            case .light:
                appearance = NSAppearance(named: .aqua)!
            case .dark:
                appearance = NSAppearance(named: .darkAqua)!
            case .system:
                appearance = NSApp.effectiveAppearance
            }
            
            NSApp.appearance = appearance
        }
    }
}
/// 系统集成器 - 集成macOS系统功能
public class SystemIntegration: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = SystemIntegration()
    
    /// 通知中心
    private let notificationCenter = NSUserNotificationCenter.default
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupNotificationCenter()
    }
    
    // MARK: - Public Methods
    
    /// 发送系统通知
    public func sendNotification(title: String, message: String, identifier: String? = nil) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        if let identifier = identifier {
            notification.identifier = identifier
        }
        
        notificationCenter.deliver(notification)
    }
    
    /// 更新Dock图标徽章
    public func updateDockBadge(_ text: String?) {
        DispatchQueue.main.async {
            NSApp.dockTile.badgeLabel = text
        }
    }
    
    /// 在Finder中显示文件
    public func showInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
    
    /// 复制到剪贴板
    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// 请求文件系统权限
    public func requestFileSystemPermission(completion: @escaping (Bool) -> Void) {
        // 在macOS 10.15+中，可能需要请求完全磁盘访问权限
        // 这里简化处理
        completion(true)
    }
    
    // MARK: - Private Methods
    
    /// 设置通知中心
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
    }
}

// MARK: - NSUserNotificationCenterDelegate

extension SystemIntegration: NSUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        // 通知已发送
    }
    
    public func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        // 用户点击了通知
        center.removeDeliveredNotification(notification)
    }
    
    public func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        // 即使应用程序在前台也显示通知
        return true
    }
}
