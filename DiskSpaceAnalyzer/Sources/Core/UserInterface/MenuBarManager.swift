import Foundation
import AppKit

/// 菜单栏管理器 - 创建和管理符合macOS规范的应用程序菜单
public class MenuBarManager: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = MenuBarManager()
    
    /// 主菜单
    private var mainMenu: NSMenu!
    
    /// 最近使用的路径
    private var recentPaths: [String] = []
    
    /// 最大最近路径数量
    private let maxRecentPaths = 10
    
    /// 主窗口控制器
    public weak var mainWindowController: MainWindowController?
    
    /// 会话管理器
    private let sessionManager = SessionManager.shared
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        loadRecentPaths()
    }
    
    // MARK: - Public Methods
    
    /// 设置应用程序菜单
    public func setupApplicationMenu() {
        mainMenu = NSMenu()
        
        // 创建各个菜单
        createApplicationMenu()
        createFileMenu()
        createEditMenu()
        createViewMenu()
        createWindowMenu()
        createHelpMenu()
        
        // 设置为应用程序主菜单
        NSApp.mainMenu = mainMenu
    }
    
    /// 添加最近使用的路径
    public func addRecentPath(_ path: String) {
        // 移除已存在的路径
        recentPaths.removeAll { $0 == path }
        
        // 添加到开头
        recentPaths.insert(path, at: 0)
        
        // 限制数量
        if recentPaths.count > maxRecentPaths {
            recentPaths = Array(recentPaths.prefix(maxRecentPaths))
        }
        
        // 保存并更新菜单
        saveRecentPaths()
        updateRecentPathsMenu()
    }
    
    /// 清除最近使用的路径
    public func clearRecentPaths() {
        recentPaths.removeAll()
        saveRecentPaths()
        updateRecentPathsMenu()
    }
    
    // MARK: - Private Methods
    
    /// 创建应用程序菜单
    private func createApplicationMenu() {
        let appMenu = NSMenu()
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "磁盘空间分析器"
        
        // 关于
        let aboutItem = NSMenuItem(title: "关于 \(appName)", action: #selector(aboutAction), keyEquivalent: "")
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 偏好设置
        let preferencesItem = NSMenuItem(title: "偏好设置...", action: #selector(preferencesAction), keyEquivalent: ",")
        preferencesItem.target = self
        appMenu.addItem(preferencesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 服务菜单
        let servicesItem = NSMenuItem(title: "服务", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 隐藏应用程序
        let hideItem = NSMenuItem(title: "隐藏 \(appName)", action: #selector(NSApp.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideItem)
        
        // 隐藏其他应用程序
        let hideOthersItem = NSMenuItem(title: "隐藏其他", action: #selector(NSApp.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        // 显示全部
        let showAllItem = NSMenuItem(title: "显示全部", action: #selector(NSApp.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: "退出 \(appName)", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        
        // 添加到主菜单
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
    }
    
    /// 创建文件菜单
    private func createFileMenu() {
        let fileMenu = NSMenu(title: "文件")
        
        // 选择文件夹
        let selectFolderItem = NSMenuItem(title: "选择文件夹...", action: #selector(selectFolderAction), keyEquivalent: "o")
        selectFolderItem.target = self
        fileMenu.addItem(selectFolderItem)
        
        fileMenu.addItem(NSMenuItem.separator())
        
        // 最近使用
        let recentItem = NSMenuItem(title: "最近使用", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu(title: "最近使用")
        recentItem.submenu = recentMenu
        fileMenu.addItem(recentItem)
        
        // 更新最近使用菜单
        updateRecentPathsMenu()
        
        fileMenu.addItem(NSMenuItem.separator())
        
        // 导出报告
        let exportItem = NSMenuItem(title: "导出报告...", action: #selector(exportReportAction), keyEquivalent: "e")
        exportItem.target = self
        fileMenu.addItem(exportItem)
        
        fileMenu.addItem(NSMenuItem.separator())
        
        // 关闭窗口
        let closeItem = NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(closeItem)
        
        // 添加到主菜单
        let fileMenuItem = NSMenuItem(title: "文件", action: nil, keyEquivalent: "")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
    }
    
    /// 创建编辑菜单
    private func createEditMenu() {
        let editMenu = NSMenu(title: "编辑")
        
        // 撤销
        let undoItem = NSMenuItem(title: "撤销", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(undoItem)
        
        // 重做
        let redoItem = NSMenuItem(title: "重做", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(redoItem)
        
        editMenu.addItem(NSMenuItem.separator())
        
        // 剪切
        let cutItem = NSMenuItem(title: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(cutItem)
        
        // 复制
        let copyItem = NSMenuItem(title: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(copyItem)
        
        // 粘贴
        let pasteItem = NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(pasteItem)
        
        // 全选
        let selectAllItem = NSMenuItem(title: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(selectAllItem)
        
        // 添加到主菜单
        let editMenuItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
    }
    
    /// 创建视图菜单
    private func createViewMenu() {
        let viewMenu = NSMenu(title: "视图")
        
        // 刷新
        let refreshItem = NSMenuItem(title: "刷新", action: #selector(refreshAction), keyEquivalent: "r")
        refreshItem.target = self
        viewMenu.addItem(refreshItem)
        
        viewMenu.addItem(NSMenuItem.separator())
        
        // 显示/隐藏工具栏
        let toolbarItem = NSMenuItem(title: "显示工具栏", action: #selector(NSWindow.toggleToolbarShown(_:)), keyEquivalent: "t")
        toolbarItem.keyEquivalentModifierMask = [.command, .option]
        viewMenu.addItem(toolbarItem)
        
        // 自定义工具栏
        let customizeToolbarItem = NSMenuItem(title: "自定义工具栏...", action: #selector(NSWindow.runToolbarCustomizationPalette(_:)), keyEquivalent: "")
        viewMenu.addItem(customizeToolbarItem)
        
        viewMenu.addItem(NSMenuItem.separator())
        
        // 进入全屏
        let fullScreenItem = NSMenuItem(title: "进入全屏", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(fullScreenItem)
        
        // 添加到主菜单
        let viewMenuItem = NSMenuItem(title: "视图", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
    }
    
    /// 创建窗口菜单
    private func createWindowMenu() {
        let windowMenu = NSMenu(title: "窗口")
        
        // 最小化
        let minimizeItem = NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(minimizeItem)
        
        // 缩放
        let zoomItem = NSMenuItem(title: "缩放", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(zoomItem)
        
        windowMenu.addItem(NSMenuItem.separator())
        
        // 前置全部窗口
        let bringAllToFrontItem = NSMenuItem(title: "前置全部窗口", action: #selector(NSApp.arrangeInFront(_:)), keyEquivalent: "")
        windowMenu.addItem(bringAllToFrontItem)
        
        // 设置为窗口菜单
        NSApp.windowsMenu = windowMenu
        
        // 添加到主菜单
        let windowMenuItem = NSMenuItem(title: "窗口", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
    }
    
    /// 创建帮助菜单
    private func createHelpMenu() {
        let helpMenu = NSMenu(title: "帮助")
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "磁盘空间分析器"
        
        // 帮助
        let helpItem = NSMenuItem(title: "\(appName) 帮助", action: #selector(helpAction), keyEquivalent: "?")
        helpItem.target = self
        helpMenu.addItem(helpItem)
        
        // 添加到主菜单
        let helpMenuItem = NSMenuItem(title: "帮助", action: nil, keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
    }
    
    /// 更新最近使用路径菜单
    private func updateRecentPathsMenu() {
        guard let fileMenu = mainMenu.item(withTitle: "文件")?.submenu,
              let recentItem = fileMenu.item(withTitle: "最近使用"),
              let recentMenu = recentItem.submenu else { return }
        
        // 清除现有项目
        recentMenu.removeAllItems()
        
        if recentPaths.isEmpty {
            let emptyItem = NSMenuItem(title: "无最近使用项目", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            recentMenu.addItem(emptyItem)
        } else {
            // 添加最近路径
            for (index, path) in recentPaths.enumerated() {
                let pathItem = NSMenuItem(title: (path as NSString).lastPathComponent, action: #selector(openRecentPathAction(_:)), keyEquivalent: "")
                pathItem.target = self
                pathItem.representedObject = path
                pathItem.toolTip = path
                
                // 添加快捷键（前9个）
                if index < 9 {
                    pathItem.keyEquivalent = "\(index + 1)"
                }
                
                recentMenu.addItem(pathItem)
            }
            
            recentMenu.addItem(NSMenuItem.separator())
            
            // 清除最近使用
            let clearItem = NSMenuItem(title: "清除最近使用", action: #selector(clearRecentPathsAction), keyEquivalent: "")
            clearItem.target = self
            recentMenu.addItem(clearItem)
        }
    }
    
    /// 保存最近使用路径
    private func saveRecentPaths() {
        UserDefaults.standard.set(recentPaths, forKey: "RecentPaths")
    }
    
    /// 加载最近使用路径
    private func loadRecentPaths() {
        recentPaths = UserDefaults.standard.stringArray(forKey: "RecentPaths") ?? []
    }
    
    // MARK: - Menu Actions
    
    @objc private func aboutAction() {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "磁盘空间分析器"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        let alert = NSAlert()
        alert.messageText = appName
        alert.informativeText = "版本 \(version) (构建 \(build))\n\n一个用于分析磁盘空间使用情况的macOS应用程序。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        alert.runModal()
    }
    
    @objc private func preferencesAction() {
        // 显示偏好设置窗口
        // 这里可以实现偏好设置界面
        let alert = NSAlert()
        alert.messageText = "偏好设置"
        alert.informativeText = "偏好设置功能正在开发中。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func selectFolderAction() {
        mainWindowController?.selectFolderAction()
    }
    
    @objc private func exportReportAction() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["txt"]
        savePanel.nameFieldStringValue = "DiskSpaceAnalyzer-Report-\(Date().timeIntervalSince1970).txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let report = self.sessionManager.exportFullReport()
                try? report.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    @objc private func refreshAction() {
        // 刷新当前视图
        if let session = sessionManager.currentSession {
            mainWindowController?.updateUI(for: session)
        }
    }
    
    @objc private func helpAction() {
        // 打开帮助文档
        if let url = URL(string: "https://github.com/your-repo/disk-space-analyzer/wiki") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func openRecentPathAction(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        
        // 检查路径是否仍然存在
        if FileManager.default.fileExists(atPath: path) {
            mainWindowController?.startScan(at: path)
        } else {
            // 路径不存在，从最近使用中移除
            recentPaths.removeAll { $0 == path }
            saveRecentPaths()
            updateRecentPathsMenu()
            
            let alert = NSAlert()
            alert.messageText = "路径不存在"
            alert.informativeText = "路径 \(path) 不存在，已从最近使用中移除。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    @objc private func clearRecentPathsAction() {
        clearRecentPaths()
    }
}

// MARK: - NSMenuItemValidation

extension MenuBarManager: NSMenuItemValidation {
    
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return true }
        
        switch action {
        case #selector(exportReportAction):
            // 只有在有会话数据时才能导出报告
            return sessionManager.currentSession != nil || !sessionManager.sessionHistory.isEmpty
            
        case #selector(refreshAction):
            // 只有在有当前会话时才能刷新
            return sessionManager.currentSession != nil
            
        case #selector(selectFolderAction):
            // 只有在没有正在进行的扫描时才能选择新文件夹
            if let session = sessionManager.currentSession {
                return session.state != .scanning
            }
            return true
            
        default:
            return true
        }
    }
}
