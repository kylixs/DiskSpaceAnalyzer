import Foundation
import AppKit
import Common
import DataModel
import DirectoryTreeView
import TreeMapVisualization
import InteractionFeedback
import SessionManager

// MARK: - UserInterface Module
// 用户界面模块 - 提供完整的用户界面集成

/// UserInterface模块信息
public struct UserInterfaceModule {
    public static let version = "1.0.0"
    public static let description = "用户界面集成系统"
    
    public static func initialize() {
        print("🖥️ UserInterface模块初始化")
        print("📋 包含: MainWindowController、ToolbarManager、DirectoryTreePanel、TreeMapPanel、StatusBarManager")
        print("📊 版本: \(version)")
        print("✅ UserInterface模块初始化完成")
    }
}

// MARK: - 工具栏管理器

/// 工具栏管理器 - 创建和管理所有工具栏按钮和控件
public class ToolbarManager: NSObject {
    
    // 工具栏项标识符
    private enum ToolbarItemIdentifier {
        static let selectFolder = NSToolbarItem.Identifier("selectFolder")
        static let startScan = NSToolbarItem.Identifier("startScan")
        static let stopScan = NSToolbarItem.Identifier("stopScan")
        static let refresh = NSToolbarItem.Identifier("refresh")
        static let progressIndicator = NSToolbarItem.Identifier("progressIndicator")
        static let flexibleSpace = NSToolbarItem.Identifier.flexibleSpace
    }
    
    // UI组件
    private var toolbar: NSToolbar?
    private var progressIndicator: NSProgressIndicator?
    
    // 回调
    public var onSelectFolder: (() -> Void)?
    public var onStartScan: (() -> Void)?
    public var onStopScan: (() -> Void)?
    public var onRefresh: (() -> Void)?
    
    // 状态
    private var isScanning = false
    
    public override init() {
        super.init()
    }
    
    /// 创建工具栏
    public func createToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconAndLabel
        
        self.toolbar = toolbar
        return toolbar
    }
    
    /// 更新扫描状态
    public func updateScanningState(_ scanning: Bool) {
        isScanning = scanning
        
        DispatchQueue.main.async { [weak self] in
            self?.toolbar?.validateVisibleItems()
            
            if scanning {
                self?.progressIndicator?.startAnimation(nil)
            } else {
                self?.progressIndicator?.stopAnimation(nil)
            }
        }
    }
    
    /// 更新进度
    public func updateProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.progressIndicator?.doubleValue = progress * 100
        }
    }
    
    // MARK: - 私有方法
    
    private func createSelectFolderItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: ToolbarItemIdentifier.selectFolder)
        item.label = "选择文件夹"
        item.paletteLabel = "选择文件夹"
        item.toolTip = "选择要扫描的文件夹"
        
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: "选择文件夹")
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(selectFolderAction)
        
        item.view = button
        return item
    }
    
    private func createStartScanItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: ToolbarItemIdentifier.startScan)
        item.label = "开始扫描"
        item.paletteLabel = "开始扫描"
        item.toolTip = "开始扫描选定的文件夹"
        
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "开始扫描")
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(startScanAction)
        
        // 设置绿色
        if let image = button.image {
            let coloredImage = image.withSymbolConfiguration(.init(pointSize: 16, weight: .medium))
            button.image = coloredImage
        }
        
        item.view = button
        return item
    }
    
    private func createStopScanItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: ToolbarItemIdentifier.stopScan)
        item.label = "停止扫描"
        item.paletteLabel = "停止扫描"
        item.toolTip = "停止当前扫描"
        
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "stop.circle.fill", accessibilityDescription: "停止扫描")
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(stopScanAction)
        
        item.view = button
        return item
    }
    
    private func createRefreshItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: ToolbarItemIdentifier.refresh)
        item.label = "刷新"
        item.paletteLabel = "刷新"
        item.toolTip = "刷新当前视图"
        
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "刷新")
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(refreshAction)
        
        item.view = button
        return item
    }
    
    private func createProgressIndicatorItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: ToolbarItemIdentifier.progressIndicator)
        item.label = "进度"
        item.paletteLabel = "扫描进度"
        
        let progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.doubleValue = 0
        progressIndicator.frame = NSRect(x: 0, y: 0, width: 150, height: 16)
        
        self.progressIndicator = progressIndicator
        item.view = progressIndicator
        return item
    }
    
    // MARK: - 动作方法
    
    @objc private func selectFolderAction() {
        onSelectFolder?()
    }
    
    @objc private func startScanAction() {
        onStartScan?()
    }
    
    @objc private func stopScanAction() {
        onStopScan?()
    }
    
    @objc private func refreshAction() {
        onRefresh?()
    }
}

// MARK: - NSToolbarDelegate

extension ToolbarManager: NSToolbarDelegate {
    
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case ToolbarItemIdentifier.selectFolder:
            return createSelectFolderItem()
        case ToolbarItemIdentifier.startScan:
            return createStartScanItem()
        case ToolbarItemIdentifier.stopScan:
            return createStopScanItem()
        case ToolbarItemIdentifier.refresh:
            return createRefreshItem()
        case ToolbarItemIdentifier.progressIndicator:
            return createProgressIndicatorItem()
        case .flexibleSpace:
            return NSToolbarItem(itemIdentifier: .flexibleSpace)
        default:
            return nil
        }
    }
    
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            ToolbarItemIdentifier.selectFolder,
            ToolbarItemIdentifier.startScan,
            ToolbarItemIdentifier.stopScan,
            .flexibleSpace,
            ToolbarItemIdentifier.progressIndicator,
            .flexibleSpace,
            ToolbarItemIdentifier.refresh
        ]
    }
    
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
    
    public func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case ToolbarItemIdentifier.startScan:
            return !isScanning
        case ToolbarItemIdentifier.stopScan:
            return isScanning
        default:
            return true
        }
    }
}

// MARK: - 状态栏管理器

/// 状态栏管理器 - 管理状态栏显示
public class StatusBarManager {
    
    // UI组件
    private var statusBar: NSView?
    private var statusLabel: NSTextField?
    private var statisticsLabel: NSTextField?
    
    public init() {
        _ = createStatusBar()
    }
    
    /// 创建状态栏
    public func createStatusBar() -> NSView {
        let statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 状态标签
        let statusLabel = NSTextField()
        statusLabel.isBordered = false
        statusLabel.isEditable = false
        statusLabel.backgroundColor = .clear
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.stringValue = "就绪"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 统计标签
        let statisticsLabel = NSTextField()
        statisticsLabel.isBordered = false
        statisticsLabel.isEditable = false
        statisticsLabel.backgroundColor = .clear
        statisticsLabel.font = NSFont.systemFont(ofSize: 11)
        statisticsLabel.alignment = .right
        statisticsLabel.stringValue = ""
        statisticsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusBar.addSubview(statusLabel)
        statusBar.addSubview(statisticsLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            
            statisticsLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -8),
            statisticsLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            statisticsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 20)
        ])
        
        self.statusBar = statusBar
        self.statusLabel = statusLabel
        self.statisticsLabel = statisticsLabel
        
        return statusBar
    }
    
    /// 更新状态文本
    public func updateStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel?.stringValue = status
        }
    }
    
    /// 更新统计信息
    public func updateStatistics(_ statistics: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statisticsLabel?.stringValue = statistics
        }
    }
    
    /// 获取状态栏视图
    public func getStatusBar() -> NSView? {
        return statusBar
    }
}

// MARK: - 目录树面板

/// 目录树面板 - 管理左侧目录树显示
public class DirectoryTreePanel {
    
    // UI组件
    private var containerView: NSView?
    private var scrollView: NSScrollView?
    private var outlineView: NSOutlineView?
    
    // 管理器
    private let directoryTreeView = DirectoryTreeView.shared
    
    // 回调
    public var onSelectionChanged: ((SmartDirectoryNode?) -> Void)?
    
    public init() {
        _ = createPanel()
        setupCallbacks()
    }
    
    /// 创建面板
    public func createPanel() -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // 创建标题
        let titleLabel = NSTextField()
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.stringValue = "目录结构"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建滚动视图和大纲视图
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.indentationPerLevel = 16
        outlineView.rowSizeStyle = .default
        
        // 创建列
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DirectoryColumn"))
        column.title = "目录"
        column.width = 200
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        
        scrollView.documentView = outlineView
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        self.containerView = containerView
        self.scrollView = scrollView
        self.outlineView = outlineView
        
        // 设置DirectoryTreeView
        directoryTreeView.outlineView = outlineView
        directoryTreeView.scrollView = scrollView
        
        return containerView
    }
    
    /// 设置数据
    public func setData(_ fileNode: FileNode) {
        directoryTreeView.setDataSource(fileNode)
    }
    
    /// 获取面板视图
    public func getPanel() -> NSView? {
        return containerView
    }
    
    private func setupCallbacks() {
        directoryTreeView.onSelectionChanged = { [weak self] node in
            self?.onSelectionChanged?(node)
        }
    }
}

// MARK: - TreeMap面板

/// TreeMap面板 - 管理右侧TreeMap显示
public class TreeMapPanel {
    
    // UI组件
    private var containerView: NSView?
    private var treeMapView: TreeMapView?
    
    // 管理器
    private let treeMapVisualization = TreeMapVisualization.shared
    private let interactionFeedback = InteractionFeedback.shared
    
    // 回调
    public var onRectClicked: ((TreeMapRect) -> Void)?
    public var onRectHovered: ((TreeMapRect?) -> Void)?
    
    public init() {
        _ = createPanel()
        setupCallbacks()
    }
    
    /// 创建面板
    public func createPanel() -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // 创建标题
        let titleLabel = NSTextField()
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.stringValue = "磁盘空间分布"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建TreeMap视图
        let treeMapView = TreeMapView(frame: .zero)
        treeMapView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(treeMapView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            treeMapView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            treeMapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            treeMapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            treeMapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        self.containerView = containerView
        self.treeMapView = treeMapView
        
        // 设置TreeMapVisualization
        treeMapVisualization.setTreeMapView(treeMapView)
        interactionFeedback.setTreeMapView(treeMapView)
        
        return containerView
    }
    
    /// 设置数据
    public func setData(_ fileNode: FileNode) {
        treeMapVisualization.updateData(fileNode)
    }
    
    /// 获取面板视图
    public func getPanel() -> NSView? {
        return containerView
    }
    
    private func setupCallbacks() {
        treeMapVisualization.onRectClicked = { [weak self] rect in
            self?.onRectClicked?(rect)
        }
        
        treeMapVisualization.onRectHovered = { [weak self] rect in
            self?.onRectHovered?(rect)
        }
    }
}

// MARK: - 主窗口控制器

/// 主窗口控制器 - 管理整个应用程序的主窗口
public class MainWindowController: NSWindowController {
    
    // UI组件
    private var toolbarManager: ToolbarManager!
    private var statusBarManager: StatusBarManager!
    private var directoryTreePanel: DirectoryTreePanel!
    private var treeMapPanel: TreeMapPanel!
    private var splitView: NSSplitView!
    
    // 管理器
    private let sessionManager = SessionManager.shared
    
    // 当前会话 - 暂时简化
    private var currentRootNode: FileNode?
    
    public convenience init() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        setupWindow()
        setupUI()
        setupCallbacks()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "磁盘空间分析器"
        window.minSize = NSSize(width: 800, height: 600)
        window.center()
        
        // 恢复窗口状态
        if let savedFrame = sessionManager.getPreferences().windowFrame {
            window.setFrame(savedFrame, display: false)
        }
    }
    
    private func setupUI() {
        guard let window = window else { return }
        
        // 创建工具栏
        toolbarManager = ToolbarManager()
        window.toolbar = toolbarManager.createToolbar()
        
        // 创建状态栏
        statusBarManager = StatusBarManager()
        
        // 创建面板
        directoryTreePanel = DirectoryTreePanel()
        treeMapPanel = TreeMapPanel()
        
        // 创建分割视图
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加面板到分割视图
        if let leftPanel = directoryTreePanel.getPanel(),
           let rightPanel = treeMapPanel.getPanel() {
            splitView.addArrangedSubview(leftPanel)
            splitView.addArrangedSubview(rightPanel)
        }
        
        // 创建主容器
        let contentView = NSView()
        let statusBar = statusBarManager.createStatusBar()
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(splitView)
        contentView.addSubview(statusBar)
        
        // 设置约束
        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
            
            statusBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        window.contentView = contentView
        
        // 设置分割视图比例
        DispatchQueue.main.async { [weak self] in
            self?.setSplitViewPosition()
        }
    }
    
    private func setSplitViewPosition() {
        guard let window = window else { return }
        
        let windowWidth = window.frame.width
        let leftWidth = windowWidth * 0.3 // 30%给左侧
        
        splitView.setPosition(leftWidth, ofDividerAt: 0)
        
        // 恢复分割器位置
        if let savedPosition = sessionManager.getPreferences().windowSplitterPosition {
            splitView.setPosition(windowWidth * savedPosition, ofDividerAt: 0)
        }
    }
    
    private func setupCallbacks() {
        // 工具栏回调
        toolbarManager.onSelectFolder = { [weak self] in
            self?.selectFolder()
        }
        
        toolbarManager.onStartScan = { [weak self] in
            self?.startScan()
        }
        
        toolbarManager.onStopScan = { [weak self] in
            self?.stopScan()
        }
        
        toolbarManager.onRefresh = { [weak self] in
            self?.refresh()
        }
        
        // 面板回调
        directoryTreePanel.onSelectionChanged = { [weak self] node in
            self?.handleDirectorySelection(node)
        }
        
        treeMapPanel.onRectClicked = { [weak self] rect in
            self?.handleTreeMapClick(rect)
        }
        
        treeMapPanel.onRectHovered = { [weak self] rect in
            self?.handleTreeMapHover(rect)
        }
    }
    
    // MARK: - 工具栏动作
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "选择要扫描的文件夹"
        
        openPanel.begin { [weak self] response in
            if response == .OK, let url = openPanel.url {
                self?.scanPath(url.path)
            }
        }
    }
    
    private func startScan() {
        // 如果没有选择路径，先选择文件夹
        guard let rootNode = currentRootNode else {
            selectFolder()
            return
        }
        
        // 开始新的扫描
        scanPath(rootNode.path)
    }
    
    private func stopScan() {
        toolbarManager.updateScanningState(false)
        statusBarManager.updateStatus("扫描已停止")
    }
    
    private func refresh() {
        guard let rootNode = currentRootNode else { return }
        
        // 刷新当前数据
        directoryTreePanel.setData(rootNode)
        treeMapPanel.setData(rootNode)
        
        updateStatistics()
    }
    
    private func scanPath(_ path: String) {
        // 更新UI状态
        toolbarManager.updateScanningState(true)
        statusBarManager.updateStatus("正在扫描: \(path)")
        
        // 简化版本：直接创建测试数据
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // 模拟扫描完成
            let testNode = FileNode(name: "测试根目录", path: path, size: 1000000, isDirectory: true)
            
            DispatchQueue.main.async {
                self?.handleScanCompleted(testNode)
            }
        }
    }
    
    // MARK: - 扫描回调处理
    
    private func handleScanProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.toolbarManager.updateProgress(progress)
            self?.statusBarManager.updateStatus("扫描进度: \(Int(progress * 100))%")
        }
    }
    
    private func handleScanCompleted(_ rootNode: FileNode) {
        toolbarManager.updateScanningState(false)
        statusBarManager.updateStatus("扫描完成")
        
        currentRootNode = rootNode
        directoryTreePanel.setData(rootNode)
        treeMapPanel.setData(rootNode)
        updateStatistics()
    }
    
    private func handleScanError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.toolbarManager.updateScanningState(false)
            self?.statusBarManager.updateStatus("扫描出错")
            
            // 显示错误对话框
            self?.sessionManager.showError(error, in: self?.window)
        }
    }
    
    // MARK: - 面板交互处理
    
    private func handleDirectorySelection(_ node: SmartDirectoryNode?) {
        guard let node = node else { return }
        
        // 更新TreeMap显示选中的目录
        treeMapPanel.setData(node.fileNode)
        
        // 更新状态栏
        let info = node.getDisplayInfo()
        statusBarManager.updateStatus("已选择: \(info.name)")
    }
    
    private func handleTreeMapClick(_ rect: TreeMapRect) {
        // 如果点击的是目录，导航到该目录
        if rect.node.isDirectory {
            treeMapPanel.setData(rect.node)
            statusBarManager.updateStatus("已导航到: \(rect.node.name)")
        }
    }
    
    private func handleTreeMapHover(_ rect: TreeMapRect?) {
        if let rect = rect {
            let size = SharedUtilities.formatFileSize(rect.node.size)
            statusBarManager.updateStatus("悬停: \(rect.node.name) (\(size))")
        } else {
            statusBarManager.updateStatus("就绪")
        }
    }
    
    // MARK: - 统计信息更新
    
    private func updateStatistics() {
        guard let rootNode = currentRootNode else {
            statusBarManager.updateStatistics("")
            return
        }
        
        var fileCount = 0
        var dirCount = 0
        var totalSize: Int64 = 0
        
        func traverse(_ node: FileNode) {
            if node.isDirectory {
                dirCount += 1
                for child in node.children {
                    traverse(child)
                }
            } else {
                fileCount += 1
                totalSize += node.size
            }
        }
        
        traverse(rootNode)
        
        let sizeText = SharedUtilities.formatFileSize(totalSize)
        let statistics = "\(fileCount) 个文件, \(dirCount) 个目录, 总计 \(sizeText)"
        statusBarManager.updateStatistics(statistics)
    }
    
    // MARK: - 窗口生命周期
    
    public override func windowDidLoad() {
        super.windowDidLoad()
        
        // 初始化状态
        statusBarManager.updateStatus("就绪")
        updateStatistics()
    }
    
    deinit {
        // 保存窗口状态
        if let window = window {
            sessionManager.getPreferences().windowFrame = window.frame
            
            // 保存分割器位置
            let leftWidth = splitView.subviews.first?.frame.width ?? 0
            let totalWidth = splitView.frame.width
            if totalWidth > 0 {
                let ratio = leftWidth / totalWidth
                sessionManager.getPreferences().windowSplitterPosition = ratio
            }
        }
    }
}

// MARK: - 用户界面管理器

/// 用户界面管理器 - 统一管理所有用户界面功能
public class UserInterface {
    public static let shared = UserInterface()
    
    private var mainWindowController: MainWindowController?
    
    private init() {}
    
    /// 启动用户界面
    public func launch() {
        DispatchQueue.main.async { [weak self] in
            self?.createMainWindow()
        }
    }
    
    /// 创建主窗口
    private func createMainWindow() {
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)
        
        // 设置为主窗口
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    /// 获取主窗口控制器
    public func getMainWindowController() -> MainWindowController? {
        return mainWindowController
    }
    
    /// 关闭应用程序
    public func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
