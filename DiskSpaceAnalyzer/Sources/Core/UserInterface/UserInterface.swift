import Foundation
import AppKit

/// 用户界面模块 - 统一的用户界面管理接口
public class UserInterface {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = UserInterface()
    
    /// 主窗口控制器
    public let mainWindowController: MainWindowController
    
    /// 菜单栏管理器
    public let menuBarManager: MenuBarManager
    
    /// 对话框管理器
    public let dialogManager: DialogManager
    
    /// 主题管理器
    public let themeManager: ThemeManager
    
    /// 系统集成器
    public let systemIntegration: SystemIntegration
    
    /// 应用程序是否已初始化
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init() {
        self.mainWindowController = MainWindowController()
        self.menuBarManager = MenuBarManager.shared
        self.dialogManager = DialogManager.shared
        self.themeManager = ThemeManager.shared
        self.systemIntegration = SystemIntegration.shared
        
        setupIntegration()
    }
    
    // MARK: - Public Methods
    
    /// 初始化用户界面
    public func initialize() {
        guard !isInitialized else { return }
        
        // 设置应用程序菜单
        menuBarManager.setupApplicationMenu()
        
        // 设置主窗口控制器引用
        menuBarManager.mainWindowController = mainWindowController
        
        // 设置主题
        setupTheme()
        
        // 设置系统集成
        setupSystemIntegration()
        
        isInitialized = true
        
        LogManager.shared.info("User interface initialized", category: "UserInterface")
    }
    
    /// 显示主窗口
    public func showMainWindow() {
        mainWindowController.showWindow()
    }
    
    /// 开始扫描
    public func startScan(at path: String) {
        mainWindowController.startScan(at: path)
        menuBarManager.addRecentPath(path)
    }
    
    /// 显示关于对话框
    public func showAboutDialog() {
        menuBarManager.aboutAction()
    }
    
    /// 显示偏好设置
    public func showPreferences() {
        menuBarManager.preferencesAction()
    }
    
    /// 导出报告
    public func exportReport() {
        menuBarManager.exportReportAction()
    }
    
    /// 获取用户界面状态
    public func getUIState() -> [String: Any] {
        return [
            "isInitialized": isInitialized,
            "mainWindowVisible": mainWindowController.window?.isVisible ?? false,
            "currentTheme": themeManager.currentTheme.rawValue,
            "isDarkMode": themeManager.isDarkMode,
            "recentPathsCount": menuBarManager.recentPaths.count
        ]
    }
    
    /// 导出用户界面报告
    public func exportUIReport() -> String {
        var report = "=== User Interface Report ===\n\n"
        
        let state = getUIState()
        
        report += "Generated: \(Date())\n"
        report += "Initialized: \(state["isInitialized"] ?? false)\n"
        report += "Main Window Visible: \(state["mainWindowVisible"] ?? false)\n"
        report += "Current Theme: \(state["currentTheme"] ?? "unknown")\n"
        report += "Dark Mode: \(state["isDarkMode"] ?? false)\n"
        report += "Recent Paths Count: \(state["recentPathsCount"] ?? 0)\n\n"
        
        // 窗口信息
        if let window = mainWindowController.window {
            report += "=== Window Information ===\n"
            report += "Frame: \(window.frame)\n"
            report += "Title: \(window.title)\n"
            report += "Level: \(window.level.rawValue)\n"
            report += "Is Key: \(window.isKeyWindow)\n"
            report += "Is Main: \(window.isMainWindow)\n\n"
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置模块集成
    private func setupIntegration() {
        // 设置主题变化回调
        themeManager.themeChangeCallback = { [weak self] theme in
            self?.handleThemeChange(theme)
        }
    }
    
    /// 设置主题
    private func setupTheme() {
        // 从用户偏好加载主题设置
        let savedTheme = UserDefaults.standard.string(forKey: "AppTheme") ?? Theme.system.rawValue
        if let theme = Theme(rawValue: savedTheme) {
            themeManager.setTheme(theme)
        }
    }
    
    /// 设置系统集成
    private func setupSystemIntegration() {
        // 请求必要的系统权限
        systemIntegration.requestFileSystemPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.dialogManager.showWarningDialog(
                        title: "权限不足",
                        message: "应用程序需要文件系统访问权限才能正常工作。请在系统偏好设置中授予权限。"
                    ) { _ in }
                }
            }
        }
    }
    
    /// 处理主题变化
    private func handleThemeChange(_ theme: Theme) {
        // 保存主题设置
        UserDefaults.standard.set(theme.rawValue, forKey: "AppTheme")
        
        // 通知主题变化
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeDidChange"),
            object: theme
        )
        
        LogManager.shared.info("Theme changed to: \(theme.displayName)", category: "UserInterface")
    }
}

// MARK: - Global Convenience Functions

/// 全局用户界面访问函数
public func getUserInterface() -> UserInterface {
    return UserInterface.shared
}

/// 初始化用户界面
public func initializeUI() {
    UserInterface.shared.initialize()
}

/// 显示主窗口
public func showMainWindow() {
    UserInterface.shared.showMainWindow()
}

/// 开始扫描
public func startUIScan(at path: String) {
    UserInterface.shared.startScan(at: path)
}

/// 显示错误对话框
public func showError(title: String, message: String, error: Error? = nil) {
    DialogManager.shared.showErrorDialog(title: title, message: message, error: error)
}

/// 显示信息对话框
public func showInfo(title: String, message: String) {
    DialogManager.shared.showInfoDialog(title: title, message: message)
}

/// 发送系统通知
public func sendNotification(title: String, message: String) {
    SystemIntegration.shared.sendNotification(title: title, message: message)
}

// MARK: - Application Integration

/// 应用程序主入口点
@main
public struct DiskSpaceAnalyzerApp {
    public static func main() {
        // 创建应用程序
        let app = NSApplication.shared
        
        // 设置应用程序委托
        let appDelegate = SessionManager.shared.appDelegate
        app.delegate = appDelegate
        
        // 初始化用户界面
        initializeUI()
        
        // 显示主窗口
        showMainWindow()
        
        // 运行应用程序
        app.run()
    }
}
