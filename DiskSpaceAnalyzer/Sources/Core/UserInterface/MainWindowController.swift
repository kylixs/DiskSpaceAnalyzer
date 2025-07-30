import Foundation
import AppKit
import Combine

/// 主窗口控制器 - 管理主窗口的创建、布局和生命周期
public class MainWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// 分栏视图控制器
    private var splitViewController: NSSplitViewController!
    
    /// 左侧目录树视图控制器
    private var directoryTreeViewController: NSViewController!
    
    /// 右侧TreeMap视图控制器
    private var treeMapViewController: NSViewController!
    
    /// 工具栏
    private var toolbar: NSToolbar!
    
    /// 状态栏
    private var statusBar: NSView!
    
    /// 会话管理器
    private let sessionManager = SessionManager.shared
    
    /// 目录树视图
    private let directoryTreeView = DirectoryTreeView.shared
    
    /// TreeMap可视化
    private let treeMapVisualization = TreeMapVisualization.shared
    
    /// 交互反馈
    private let interactionFeedback = InteractionFeedback.shared
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /// 当前扫描会话
    private var currentSession: ScanSession?
    
    // MARK: - Initialization
    
    public init() {
        // 创建主窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupSplitView()
        setupToolbar()
        setupStatusBar()
        setupBindings()
        setupIntegration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Window Lifecycle
    
    public override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.title = "磁盘空间分析器"
        window?.setFrameAutosaveName("MainWindow")
        window?.center()
        
        // 设置最小窗口大小
        window?.minSize = NSSize(width: 800, height: 600)
        
        // 设置窗口委托
        window?.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 显示窗口
    public func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 开始扫描
    public func startScan(at path: String) {
        currentSession = sessionManager.startScanSession(rootPath: path)
        updateUI(for: currentSession)
    }
    
    /// 更新UI状态
    public func updateUI(for session: ScanSession?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateToolbarState(session)
            self?.updateStatusBar(session)
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置窗口
    private func setupWindow() {
        guard let window = window else { return }
        
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        
        // 设置窗口外观
        if #available(macOS 10.14, *) {
            window.appearance = NSApp.effectiveAppearance
        }
    }
    
    /// 设置分栏视图
    private func setupSplitView() {
        splitViewController = NSSplitViewController()
        splitViewController.splitView.isVertical = true
        splitViewController.splitView.dividerStyle = .thin
        
        // 创建左侧视图控制器（目录树）
        directoryTreeViewController = createDirectoryTreeViewController()
        let leftItem = NSSplitViewItem(viewController: directoryTreeViewController)
        leftItem.minimumThickness = 250
        leftItem.maximumThickness = 400
        leftItem.holdingPriority = NSLayoutConstraint.Priority(251)
        
        // 创建右侧视图控制器（TreeMap）
        treeMapViewController = createTreeMapViewController()
        let rightItem = NSSplitViewItem(viewController: treeMapViewController)
        rightItem.minimumThickness = 400
        
        // 添加到分栏视图
        splitViewController.addSplitViewItem(leftItem)
        splitViewController.addSplitViewItem(rightItem)
        
        // 设置为窗口内容
        window?.contentViewController = splitViewController
    }
    
    /// 创建目录树视图控制器
    private func createDirectoryTreeViewController() -> NSViewController {
        let viewController = NSViewController()
        let scrollView = NSScrollView()
        
        // 创建目录树视图
        let treeView = NSOutlineView()
        treeView.headerView = nil
        treeView.usesAlternatingRowBackgroundColors = true
        treeView.allowsMultipleSelection = false
        treeView.allowsEmptySelection = true
        
        // 添加列
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DirectoryColumn"))
        column.title = "目录"
        column.isEditable = false
        treeView.addTableColumn(column)
        treeView.outlineTableColumn = column
        
        // 设置数据源和委托
        treeView.dataSource = directoryTreeView
        treeView.delegate = directoryTreeView
        
        // 配置滚动视图
        scrollView.documentView = treeView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        
        viewController.view = scrollView
        return viewController
    }
    
    /// 创建TreeMap视图控制器
    private func createTreeMapViewController() -> NSViewController {
        let viewController = NSViewController()
        let containerView = NSView()
        
        // 创建TreeMap视图
        let treeMapView = NSView()
        treeMapView.wantsLayer = true
        treeMapView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置交互反馈
        interactionFeedback.targetView = treeMapView
        
        containerView.addSubview(treeMapView)
        
        // 设置约束
        treeMapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            treeMapView.topAnchor.constraint(equalTo: containerView.topAnchor),
            treeMapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            treeMapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            treeMapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        viewController.view = containerView
        return viewController
    }
    
    /// 设置工具栏
    private func setupToolbar() {
        toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.displayMode = .iconAndLabel
        
        window?.toolbar = toolbar
    }
    
    /// 设置状态栏
    private func setupStatusBar() {
        statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建状态标签
        let statusLabel = NSTextField(labelWithString: "就绪")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        
        statusBar.addSubview(statusLabel)
        
        // 设置约束
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 添加到窗口
        if let contentView = window?.contentView {
            contentView.addSubview(statusBar)
            
            statusBar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                statusBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                statusBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                statusBar.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            // 调整分栏视图约束
            if let splitView = splitViewController.view {
                splitView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    splitView.bottomAnchor.constraint(equalTo: statusBar.topAnchor)
                ])
            }
        }
    }
    
    /// 设置数据绑定
    private func setupBindings() {
        // 监听会话状态变化
        sessionManager.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.currentSession = session
                self?.updateUI(for: session)
            }
            .store(in: &cancellables)
        
        // 监听系统状态变化
        sessionManager.$systemStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateSystemStatus(status)
            }
            .store(in: &cancellables)
    }
    
    /// 设置模块集成
    private func setupIntegration() {
        // 设置目录树选择回调
        directoryTreeView.selectionChangeCallback = { [weak self] node in
            self?.handleDirectorySelection(node)
        }
        
        // 设置TreeMap交互回调
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TreeMapRectSelected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let rect = notification.object as? TreeMapRect {
                self?.handleTreeMapSelection(rect)
            }
        }
    }
    
    /// 更新工具栏状态
    private func updateToolbarState(_ session: ScanSession?) {
        // 这里可以根据会话状态更新工具栏按钮的启用状态
        toolbar.validateVisibleItems()
    }
    
    /// 更新状态栏
    private func updateStatusBar(_ session: ScanSession?) {
        guard let statusLabel = statusBar.subviews.first as? NSTextField else { return }
        
        if let session = session {
            switch session.state {
            case .scanning:
                statusLabel.stringValue = "正在扫描: \(session.currentPath)"
            case .processing:
                statusLabel.stringValue = "正在处理数据..."
            case .completed:
                statusLabel.stringValue = "扫描完成"
            case .failed:
                statusLabel.stringValue = "扫描失败"
            default:
                statusLabel.stringValue = "准备中..."
            }
        } else {
            statusLabel.stringValue = "就绪"
        }
    }
    
    /// 更新系统状态
    private func updateSystemStatus(_ status: SystemStatus) {
        // 根据系统状态更新UI
        switch status {
        case .idle:
            window?.title = "磁盘空间分析器"
        case .scanning:
            window?.title = "磁盘空间分析器 - 扫描中"
        case .processing:
            window?.title = "磁盘空间分析器 - 处理中"
        case .error:
            window?.title = "磁盘空间分析器 - 错误"
        default:
            break
        }
    }
    
    /// 处理目录选择
    private func handleDirectorySelection(_ node: FileNode?) {
        guard let node = node else { return }
        
        // 更新TreeMap显示
        updateTreeMapDisplay(for: node)
    }
    
    /// 处理TreeMap选择
    private func handleTreeMapSelection(_ rect: TreeMapRect) {
        // 在目录树中选中对应节点
        directoryTreeView.selectNode(rect.node)
    }
    
    /// 更新TreeMap显示
    private func updateTreeMapDisplay(for node: FileNode) {
        guard let treeMapView = treeMapViewController.view.subviews.first else { return }
        
        treeMapVisualization.displayTreeMap(for: node, in: treeMapView.bounds) { [weak self] result in
            DispatchQueue.main.async {
                self?.renderTreeMap(result, in: treeMapView)
            }
        }
    }
    
    /// 渲染TreeMap
    private func renderTreeMap(_ result: TreeMapLayoutResult, in view: NSView) {
        // 清除现有内容
        view.layer?.sublayers?.removeAll()
        
        // 渲染新的矩形
        for rect in result.rects {
            let layer = CALayer()
            layer.frame = rect.rect
            layer.backgroundColor = rect.color
            layer.cornerRadius = 2
            
            view.layer?.addSublayer(layer)
        }
        
        // 设置交互反馈
        interactionFeedback.updateTreeMapData(result.rects)
    }
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 检查是否有正在进行的扫描
        if let session = currentSession, session.state == .scanning {
            let alert = NSAlert()
            alert.messageText = "正在扫描"
            alert.informativeText = "当前正在进行扫描，确定要关闭窗口吗？"
            alert.addButton(withTitle: "取消扫描并关闭")
            alert.addButton(withTitle: "继续扫描")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                sessionManager.sessionController.cancelSession(session)
                return true
            } else {
                return false
            }
        }
        
        return true
    }
    
    public func windowWillClose(_ notification: Notification) {
        // 清理资源
        cancellables.removeAll()
    }
}

// MARK: - NSToolbarDelegate

extension MainWindowController: NSToolbarDelegate {
    
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier.rawValue {
        case "SelectFolder":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "选择文件夹"
            item.toolTip = "选择要分析的文件夹"
            item.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(selectFolderAction)
            return item
            
        case "StartScan":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "开始扫描"
            item.toolTip = "开始扫描选定的文件夹"
            item.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(startScanAction)
            return item
            
        case "StopScan":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "停止扫描"
            item.toolTip = "停止当前的扫描"
            item.image = NSImage(systemSymbolName: "stop.circle", accessibilityDescription: nil)
            item.target = self
            item.action = #selector(stopScanAction)
            return item
            
        default:
            return nil
        }
    }
    
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier("SelectFolder"),
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier("StartScan"),
            NSToolbarItem.Identifier("StopScan"),
            NSToolbarItem.Identifier.flexibleSpace
        ]
    }
    
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar) + [
            NSToolbarItem.Identifier.separator,
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier.flexibleSpace
        ]
    }
    
    // MARK: - Toolbar Actions
    
    @objc private func selectFolderAction() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "选择"
        
        openPanel.begin { [weak self] response in
            if response == .OK, let url = openPanel.url {
                self?.startScan(at: url.path)
            }
        }
    }
    
    @objc private func startScanAction() {
        // 如果没有选择路径，先选择文件夹
        selectFolderAction()
    }
    
    @objc private func stopScanAction() {
        if let session = currentSession {
            sessionManager.sessionController.cancelSession(session)
        }
    }
}
