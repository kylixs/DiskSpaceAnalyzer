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
    
    /// 工具栏管理器
    private var toolbarManager: ToolbarManager!
    
    /// 状态栏管理器
    private var statusBarManager: StatusBarManager!
    
    /// 目录树视图 (NSOutlineView)
    private var directoryTreeView: NSOutlineView!
    
    /// TreeMap容器视图
    private var treeMapContainerView: NSView!
    
    /// 会话管理器
    private let sessionManager = SessionManager.shared
    
    /// 目录树数据管理器
    private let directoryTreeDataManager = DirectoryTreeView.shared
    
    /// TreeMap可视化管理器
    private let treeMapVisualization = TreeMapVisualization.shared
    
    /// 交互反馈管理器
    private let interactionFeedback = InteractionFeedback.shared
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /// 当前扫描会话
    private var currentSession: ScanSession?
    
    /// 当前选择的路径
    private var selectedPath: String?
    
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
        setupToolbar()
        setupSplitView()
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
        
        // 初始化状态
        statusBarManager.reset()
    }
    
    // MARK: - Public Methods
    
    /// 显示窗口
    public func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 开始扫描
    public func startScan(at path: String) {
        selectedPath = path
        currentSession = sessionManager.startScanSession(rootPath: path)
        updateUIForScanStart()
    }
    
    // MARK: - Toolbar Actions
    
    @objc public func selectFolderAction() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "选择"
        openPanel.message = "选择要分析的文件夹"
        
        openPanel.begin { [weak self] response in
            if response == .OK, let url = openPanel.url {
                self?.selectedPath = url.path
                self?.toolbarManager.updateScanningState(false, currentPath: url.path)
            }
        }
    }
    
    @objc public func startScanAction() {
        guard let path = selectedPath else {
            selectFolderAction()
            return
        }
        
        startScan(at: path)
    }
    
    @objc public func stopScanAction() {
        if let session = currentSession {
            sessionManager.sessionController.cancelSession(session)
        }
    }
    
    @objc public func refreshAction() {
        if let path = selectedPath {
            startScan(at: path)
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
    
    /// 设置工具栏
    private func setupToolbar() {
        toolbarManager = ToolbarManager()
        toolbarManager.mainWindowController = self
        
        let toolbar = toolbarManager.createToolbar()
        window?.toolbar = toolbar
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
        directoryTreeView = NSOutlineView()
        directoryTreeView.headerView = nil
        directoryTreeView.usesAlternatingRowBackgroundColors = true
        directoryTreeView.allowsMultipleSelection = false
        directoryTreeView.allowsEmptySelection = true
        directoryTreeView.indentationPerLevel = 16
        
        // 添加列
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "名称"
        nameColumn.isEditable = false
        nameColumn.width = 200
        directoryTreeView.addTableColumn(nameColumn)
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SizeColumn"))
        sizeColumn.title = "大小"
        sizeColumn.isEditable = false
        sizeColumn.width = 80
        directoryTreeView.addTableColumn(sizeColumn)
        
        let countColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CountColumn"))
        countColumn.title = "项目"
        countColumn.isEditable = false
        countColumn.width = 60
        directoryTreeView.addTableColumn(countColumn)
        
        directoryTreeView.outlineTableColumn = nameColumn
        
        // 设置数据源和委托
        directoryTreeView.dataSource = self
        directoryTreeView.delegate = self
        
        // 配置滚动视图
        scrollView.documentView = directoryTreeView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        
        viewController.view = scrollView
        return viewController
    }
    
    /// 创建TreeMap视图控制器
    private func createTreeMapViewController() -> NSViewController {
        let viewController = NSViewController()
        
        // 创建TreeMap容器视图
        treeMapContainerView = NSView()
        treeMapContainerView.wantsLayer = true
        treeMapContainerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 设置交互反馈
        interactionFeedback.targetView = treeMapContainerView
        
        viewController.view = treeMapContainerView
        return viewController
    }
    
    /// 设置状态栏
    private func setupStatusBar() {
        statusBarManager = StatusBarManager()
        
        guard let contentView = window?.contentView else { return }
        let statusBar = statusBarManager.getStatusBar()
        
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
    
    /// 设置数据绑定
    private func setupBindings() {
        // 监听会话状态变化
        sessionManager.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.currentSession = session
                self?.updateUIForSession(session)
            }
            .store(in: &cancellables)
        
        // 监听系统状态变化
        sessionManager.$systemStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateUIForSystemStatus(status)
            }
            .store(in: &cancellables)
    }
    
    /// 设置模块集成
    private func setupIntegration() {
        // 设置目录树选择回调
        // 这里将在NSOutlineViewDelegate中处理
        
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
    
    /// 更新UI以开始扫描
    private func updateUIForScanStart() {
        toolbarManager.updateScanningState(true, currentPath: selectedPath ?? "")
        statusBarManager.updateStatus("扫描中...")
        statusBarManager.updateProgress(0.0)
    }
    
    /// 更新UI（公共接口）
    public func updateUI(for session: ScanSession?) {
        updateUIForSession(session)
    }
    
    /// 更新UI以反映会话状态
    private func updateUIForSession(_ session: ScanSession?) {
        guard let session = session else {
            toolbarManager.updateScanningState(false)
            statusBarManager.reset()
            return
        }
        
        let isScanning = session.state == .scanning
        toolbarManager.updateScanningState(isScanning, progress: session.progress, currentPath: session.currentPath)
        
        // 更新状态栏
        switch session.state {
        case .scanning:
            statusBarManager.updateStatus("扫描中...")
            statusBarManager.updateProgress(session.progress)
        case .processing:
            statusBarManager.updateStatus("处理中...")
        case .completed:
            statusBarManager.updateStatus("已完成")
            statusBarManager.updateProgress(1.0)
        case .failed:
            statusBarManager.updateStatus("扫描失败")
        case .cancelled:
            statusBarManager.updateStatus("已取消")
        default:
            statusBarManager.updateStatus("准备中...")
        }
        
        // 更新统计信息
        if let stats = session.statistics {
            statusBarManager.updateStatistics(fileCount: stats.totalFiles, totalSize: stats.totalSize)
        }
    }
    
    /// 更新UI以反映系统状态
    private func updateUIForSystemStatus(_ status: SystemStatus) {
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
    
    /// 处理TreeMap选择
    private func handleTreeMapSelection(_ rect: TreeMapRect) {
        // 在目录树中选中对应节点
        // 这里需要实现节点查找和选择逻辑
    }
    
    /// 处理目录树选择
    private func handleDirectoryTreeSelection(_ node: FileNode?) {
        guard let node = node else { return }
        
        // 更新TreeMap显示
        updateTreeMapDisplay(for: node)
    }
    
    /// 更新TreeMap显示
    private func updateTreeMapDisplay(for node: FileNode) {
        treeMapVisualization.displayTreeMap(for: node, in: treeMapContainerView.bounds) { [weak self] result in
            DispatchQueue.main.async {
                self?.renderTreeMap(result, in: self?.treeMapContainerView)
            }
        }
    }
    
    /// 渲染TreeMap
    private func renderTreeMap(_ result: TreeMapLayoutResult, in view: NSView?) {
        guard let view = view else { return }
        
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
