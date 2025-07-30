import Foundation
import AppKit

/// 进度对话框管理器 - 管理扫描进度对话框的显示和更新
public class ProgressDialogManager: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ProgressDialogManager()
    
    /// 当前进度窗口
    private var progressWindow: NSWindow?
    
    /// 进度指示器
    private var progressIndicator: NSProgressIndicator?
    
    /// 状态标签
    private var statusLabel: NSTextField?
    
    /// 取消按钮
    private var cancelButton: NSButton?
    
    /// 取消回调
    public var cancelCallback: (() -> Void)?
    
    /// 当前会话
    private weak var currentSession: ScanSession?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 显示进度对话框
    public func showProgressDialog(for session: ScanSession) {
        DispatchQueue.main.async { [weak self] in
            self?.currentSession = session
            self?.createProgressWindow()
            self?.updateProgress(session.progress, status: "准备扫描...")
        }
    }
    
    /// 更新进度
    public func updateProgress(_ progress: Double, status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.progressIndicator?.doubleValue = progress * 100
            self?.statusLabel?.stringValue = status
        }
    }
    
    /// 隐藏进度对话框
    public func hideProgressDialog() {
        DispatchQueue.main.async { [weak self] in
            self?.progressWindow?.close()
            self?.progressWindow = nil
            self?.currentSession = nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建进度窗口
    private func createProgressWindow() {
        guard progressWindow == nil else { return }
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "扫描进度"
        window.isReleasedWhenClosed = false
        window.center()
        
        // 创建内容视图
        let contentView = NSView()
        window.contentView = contentView
        
        // 创建进度指示器
        let indicator = NSProgressIndicator()
        indicator.style = .bar
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 100
        indicator.doubleValue = 0
        
        // 创建状态标签
        let label = NSTextField(labelWithString: "准备中...")
        label.alignment = .center
        
        // 创建取消按钮
        let button = NSButton(title: "取消", target: self, action: #selector(cancelButtonClicked))
        
        // 添加到视图
        contentView.addSubview(indicator)
        contentView.addSubview(label)
        contentView.addSubview(button)
        
        // 设置约束
        indicator.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 进度条
            indicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            indicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            indicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            indicator.heightAnchor.constraint(equalToConstant: 20),
            
            // 状态标签
            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 取消按钮
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15),
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // 保存引用
        self.progressWindow = window
        self.progressIndicator = indicator
        self.statusLabel = label
        self.cancelButton = button
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    /// 取消按钮点击
    @objc private func cancelButtonClicked() {
        cancelCallback?()
        hideProgressDialog()
    }
}

/// AppDelegate - 应用程序委托
public class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// 会话控制器
    private let sessionController = SessionController.shared
    
    /// 错误处理器
    private let errorHandler = ErrorHandler.shared
    
    /// 日志管理器
    private let logManager = LogManager.shared
    
    /// 进度对话框管理器
    private let progressDialogManager = ProgressDialogManager.shared
    
    // MARK: - NSApplicationDelegate
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        logManager.info("Application did finish launching", category: "AppDelegate")
        
        // 初始化应用程序
        initializeApplication()
        
        // 设置错误处理
        setupErrorHandling()
        
        // 设置会话管理
        setupSessionManagement()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        logManager.info("Application will terminate", category: "AppDelegate")
        
        // 清理资源
        cleanup()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    /// 初始化应用程序
    private func initializeApplication() {
        // 设置日志级别
        #if DEBUG
        logManager.logLevel = .debug
        #else
        logManager.logLevel = .info
        #endif
        
        logManager.info("Initializing DiskSpaceAnalyzer", category: "AppDelegate")
        
        // 这里可以添加其他初始化逻辑
    }
    
    /// 设置错误处理
    private func setupErrorHandling() {
        errorHandler.errorNotificationCallback = { [weak self] error in
            self?.handleApplicationError(error)
        }
        
        errorHandler.errorRecoveryCallback = { [weak self] error, strategy in
            self?.handleErrorRecovery(error, strategy: strategy)
        }
    }
    
    /// 设置会话管理
    private func setupSessionManagement() {
        sessionController.sessionCompletionCallback = { [weak self] session in
            self?.handleSessionCompletion(session)
        }
        
        sessionController.sessionFailureCallback = { [weak self] session, error in
            self?.handleSessionFailure(session, error: error)
        }
        
        sessionController.sessionProgressCallback = { [weak self] session, progress in
            self?.handleSessionProgress(session, progress: progress)
        }
        
        progressDialogManager.cancelCallback = { [weak self] in
            self?.handleProgressCancel()
        }
    }
    
    /// 处理应用程序错误
    private func handleApplicationError(_ error: AppError) {
        logManager.error("Application error: \(error.localizedDescription)", category: "AppDelegate")
        
        // 对于严重错误，显示用户通知
        if error.severity >= .error {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = error.title
                alert.informativeText = error.message
                alert.alertStyle = .warning
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
        }
    }
    
    /// 处理错误恢复
    private func handleErrorRecovery(_ error: AppError, strategy: ErrorRecoveryStrategy) {
        logManager.info("Handling error recovery: \(strategy)", category: "AppDelegate")
        
        switch strategy {
        case .userAction:
            // 显示用户操作对话框
            showUserActionDialog(for: error)
        case .restart:
            // 重启应用程序
            restartApplication()
        default:
            break
        }
    }
    
    /// 处理会话完成
    private func handleSessionCompletion(_ session: ScanSession) {
        logManager.info("Session completed: \(session.id)", category: "AppDelegate")
        progressDialogManager.hideProgressDialog()
    }
    
    /// 处理会话失败
    private func handleSessionFailure(_ session: ScanSession, error: Error) {
        logManager.error("Session failed: \(session.id) - \(error)", category: "AppDelegate")
        progressDialogManager.hideProgressDialog()
    }
    
    /// 处理会话进度
    private func handleSessionProgress(_ session: ScanSession, progress: Double) {
        let status = "正在扫描: \(session.currentPath)"
        progressDialogManager.updateProgress(progress, status: status)
    }
    
    /// 处理进度取消
    private func handleProgressCancel() {
        if let currentSession = sessionController.currentSession {
            sessionController.cancelSession(currentSession)
        }
    }
    
    /// 显示用户操作对话框
    private func showUserActionDialog(for error: AppError) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要用户操作"
            alert.informativeText = error.message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "重试")
            alert.addButton(withTitle: "忽略")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                // 重试
                break
            case .alertSecondButtonReturn:
                // 忽略
                break
            default:
                // 取消
                break
            }
        }
    }
    
    /// 重启应用程序
    private func restartApplication() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        
        NSApp.terminate(nil)
    }
    
    /// 清理资源
    private func cleanup() {
        logManager.info("Cleaning up application resources", category: "AppDelegate")
        
        // 刷新日志
        logManager.flush()
        
        // 这里可以添加其他清理逻辑
    }
}
