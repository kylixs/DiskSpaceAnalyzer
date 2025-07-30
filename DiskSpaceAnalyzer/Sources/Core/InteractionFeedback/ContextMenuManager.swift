import Foundation
import AppKit

/// 上下文菜单项配置
public struct ContextMenuItem {
    public let title: String
    public let action: Selector?
    public let target: AnyObject?
    public let keyEquivalent: String
    public let isEnabled: Bool
    public let isSeparator: Bool
    
    public init(title: String, action: Selector? = nil, target: AnyObject? = nil, keyEquivalent: String = "", isEnabled: Bool = true, isSeparator: Bool = false) {
        self.title = title
        self.action = action
        self.target = target
        self.keyEquivalent = keyEquivalent
        self.isEnabled = isEnabled
        self.isSeparator = isSeparator
    }
    
    /// 创建分隔符
    public static var separator: ContextMenuItem {
        return ContextMenuItem(title: "", isSeparator: true)
    }
}

/// 右键菜单管理器 - 管理右键上下文菜单的创建和显示
public class ContextMenuManager: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = ContextMenuManager()
    
    /// 当前显示的菜单
    private var currentMenu: NSMenu?
    
    /// 当前目标矩形
    private var currentRect: TreeMapRect?
    
    /// 工作区
    private let workspace = NSWorkspace.shared
    
    /// 剪贴板
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 显示上下文菜单
    public func showContextMenu(for rect: TreeMapRect, at point: CGPoint, in view: NSView) {
        currentRect = rect
        
        let menu = createContextMenu(for: rect)
        currentMenu = menu
        
        // 显示菜单
        menu.popUp(positioning: nil, at: point, in: view)
    }
    
    /// 隐藏当前菜单
    public func hideCurrentMenu() {
        currentMenu?.cancelTracking()
        currentMenu = nil
        currentRect = nil
    }
    
    // MARK: - Private Methods
    
    /// 创建上下文菜单
    private func createContextMenu(for rect: TreeMapRect) -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        
        let node = rect.node
        
        // 基本信息项
        let infoItem = createMenuItem(
            title: node.name,
            action: nil,
            isEnabled: false
        )
        infoItem.attributedTitle = createInfoAttributedString(for: node)
        menu.addItem(infoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 在Finder中显示
        menu.addItem(createMenuItem(
            title: "在Finder中显示",
            action: #selector(showInFinder),
            keyEquivalent: "r"
        ))
        
        // 复制路径
        menu.addItem(createMenuItem(
            title: "复制路径",
            action: #selector(copyPath),
            keyEquivalent: "c"
        ))
        
        // 复制名称
        menu.addItem(createMenuItem(
            title: "复制名称",
            action: #selector(copyName)
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // 目录特有选项
        if node.isDirectory {
            menu.addItem(createMenuItem(
                title: "在终端中打开",
                action: #selector(openInTerminal),
                keyEquivalent: "t"
            ))
            
            menu.addItem(createMenuItem(
                title: "计算大小",
                action: #selector(calculateSize)
            ))
        } else {
            // 文件特有选项
            menu.addItem(createMenuItem(
                title: "打开",
                action: #selector(openFile),
                keyEquivalent: "o"
            ))
            
            menu.addItem(createMenuItem(
                title: "用其他应用打开",
                action: #selector(openWith)
            ))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 获取信息
        menu.addItem(createMenuItem(
            title: "获取信息",
            action: #selector(getInfo),
            keyEquivalent: "i"
        ))
        
        return menu
    }
    
    /// 创建菜单项
    private func createMenuItem(title: String, action: Selector?, keyEquivalent: String = "", isEnabled: Bool = true) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.isEnabled = isEnabled
        return item
    }
    
    /// 创建信息属性字符串
    private func createInfoAttributedString(for node: FileNode) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // 文件名
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.controlTextColor
        ]
        attributedString.append(NSAttributedString(string: node.name, attributes: nameAttributes))
        
        // 大小信息
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        byteFormatter.countStyle = .file
        
        let sizeString = byteFormatter.string(fromByteCount: node.size)
        let typeString = node.isDirectory ? "目录" : "文件"
        
        let detailString = "\n\(sizeString) • \(typeString)"
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        attributedString.append(NSAttributedString(string: detailString, attributes: detailAttributes))
        
        return attributedString
    }
    
    // MARK: - Menu Actions
    
    /// 在Finder中显示
    @objc private func showInFinder() {
        guard let rect = currentRect else { return }
        
        workspace.selectFile(rect.node.path, inFileViewerRootedAtPath: "")
    }
    
    /// 复制路径
    @objc private func copyPath() {
        guard let rect = currentRect else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(rect.node.path, forType: .string)
    }
    
    /// 复制名称
    @objc private func copyName() {
        guard let rect = currentRect else { return }
        
        pasteboard.clearContents()
        pasteboard.setString(rect.node.name, forType: .string)
    }
    
    /// 在终端中打开
    @objc private func openInTerminal() {
        guard let rect = currentRect, rect.node.isDirectory else { return }
        
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(rect.node.path)'"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    /// 计算大小
    @objc private func calculateSize() {
        guard let rect = currentRect, rect.node.isDirectory else { return }
        
        // 这里可以触发重新扫描该目录
        NotificationCenter.default.post(
            name: NSNotification.Name("CalculateDirectorySize"),
            object: rect.node
        )
    }
    
    /// 打开文件
    @objc private func openFile() {
        guard let rect = currentRect, !rect.node.isDirectory else { return }
        
        workspace.openFile(rect.node.path)
    }
    
    /// 用其他应用打开
    @objc private func openWith() {
        guard let rect = currentRect, !rect.node.isDirectory else { return }
        
        workspace.openFile(rect.node.path, withApplication: nil, andDeactivate: false)
    }
    
    /// 获取信息
    @objc private func getInfo() {
        guard let rect = currentRect else { return }
        
        // 显示文件信息对话框
        showInfoDialog(for: rect.node)
    }
    
    /// 显示信息对话框
    private func showInfoDialog(for node: FileNode) {
        let alert = NSAlert()
        alert.messageText = "文件信息"
        alert.informativeText = createInfoText(for: node)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        alert.runModal()
    }
    
    /// 创建信息文本
    private func createInfoText(for node: FileNode) -> String {
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        byteFormatter.countStyle = .file
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var info = "名称: \(node.name)\n"
        info += "路径: \(node.path)\n"
        info += "类型: \(node.isDirectory ? "目录" : "文件")\n"
        info += "大小: \(byteFormatter.string(fromByteCount: node.size))\n"
        
        if node.isDirectory && node.totalSize != node.size {
            info += "总大小: \(byteFormatter.string(fromByteCount: node.totalSize))\n"
            info += "子项数量: \(node.children.count)\n"
        }
        
        info += "创建时间: \(dateFormatter.string(from: node.createdDate))\n"
        info += "修改时间: \(dateFormatter.string(from: node.modifiedDate))\n"
        
        let permissions = node.permissions
        info += "权限: \(permissions.owner.description)\(permissions.group.description)\(permissions.others.description)"
        
        return info
    }
}

// MARK: - NSMenuDelegate

extension ContextMenuManager: NSMenuDelegate {
    
    public func menuDidClose(_ menu: NSMenu) {
        currentMenu = nil
        currentRect = nil
    }
    
    public func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        // 可以在这里添加菜单项高亮逻辑
    }
}

// MARK: - Extensions

extension ContextMenuManager {
    
    /// 获取菜单统计信息
    public func getMenuStatistics() -> [String: Any] {
        return [
            "hasCurrentMenu": currentMenu != nil,
            "hasCurrentRect": currentRect != nil,
            "menuItemCount": currentMenu?.items.count ?? 0
        ]
    }
    
    /// 导出菜单报告
    public func exportMenuReport() -> String {
        var report = "=== Context Menu Manager Report ===\n\n"
        
        let stats = getMenuStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Has Current Menu: \(stats["hasCurrentMenu"] ?? false)\n"
        report += "Has Current Rect: \(stats["hasCurrentRect"] ?? false)\n"
        report += "Menu Item Count: \(stats["menuItemCount"] ?? 0)\n\n"
        
        if let rect = currentRect {
            report += "=== Current Target ===\n"
            report += "Name: \(rect.node.name)\n"
            report += "Path: \(rect.node.path)\n"
            report += "Type: \(rect.node.isDirectory ? "Directory" : "File")\n"
            report += "Size: \(rect.node.size) bytes\n\n"
        }
        
        return report
    }
}
