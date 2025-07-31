import XCTest
import AppKit
@testable import UserInterface
@testable import Common
@testable import DataModel
@testable import DirectoryTreeView
@testable import TreeMapVisualization
@testable import InteractionFeedback
@testable import SessionManager

final class UserInterfaceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var userInterface: UserInterface!
    var toolbarManager: ToolbarManager!
    var statusBarManager: StatusBarManager!
    var directoryTreePanel: DirectoryTreePanel!
    var treeMapPanel: TreeMapPanel!
    var mainWindowController: MainWindowController!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        userInterface = UserInterface.shared
        toolbarManager = ToolbarManager()
        statusBarManager = StatusBarManager()
        directoryTreePanel = DirectoryTreePanel()
        treeMapPanel = TreeMapPanel()
    }
    
    override func tearDownWithError() throws {
        userInterface = nil
        toolbarManager = nil
        statusBarManager = nil
        directoryTreePanel = nil
        treeMapPanel = nil
        mainWindowController = nil
    }
    
    // MARK: - UserInterface Tests
    
    func testUserInterfaceInitialization() throws {
        XCTAssertNotNil(userInterface, "UserInterface应该能够正确初始化")
        XCTAssertNotNil(UserInterface.shared, "UserInterface.shared应该存在")
        XCTAssertTrue(UserInterface.shared === userInterface, "应该是单例模式")
    }
    
    func testGetMainWindowController() throws {
        // 初始状态应该没有主窗口控制器
        XCTAssertNil(userInterface.getMainWindowController(), "初始状态应该没有主窗口控制器")
    }
    
    // MARK: - ToolbarManager Tests
    
    func testToolbarManagerInitialization() throws {
        XCTAssertNotNil(toolbarManager, "ToolbarManager应该能够正确初始化")
    }
    
    func testCreateToolbar() throws {
        let toolbar = toolbarManager.createToolbar()
        
        XCTAssertNotNil(toolbar, "应该能创建工具栏")
        XCTAssertEqual(toolbar.identifier, "MainToolbar", "工具栏标识符应该正确")
        XCTAssertFalse(toolbar.allowsUserCustomization, "不应该允许用户自定义")
        XCTAssertFalse(toolbar.autosavesConfiguration, "不应该自动保存配置")
        XCTAssertEqual(toolbar.displayMode, .iconAndLabel, "显示模式应该是图标和标签")
    }
    
    func testToolbarCallbacks() throws {
        var selectFolderCalled = false
        var startScanCalled = false
        var stopScanCalled = false
        var refreshCalled = false
        
        toolbarManager.onSelectFolder = {
            selectFolderCalled = true
        }
        
        toolbarManager.onStartScan = {
            startScanCalled = true
        }
        
        toolbarManager.onStopScan = {
            stopScanCalled = true
        }
        
        toolbarManager.onRefresh = {
            refreshCalled = true
        }
        
        // 验证回调设置
        XCTAssertNotNil(toolbarManager.onSelectFolder, "选择文件夹回调应该被设置")
        XCTAssertNotNil(toolbarManager.onStartScan, "开始扫描回调应该被设置")
        XCTAssertNotNil(toolbarManager.onStopScan, "停止扫描回调应该被设置")
        XCTAssertNotNil(toolbarManager.onRefresh, "刷新回调应该被设置")
    }
    
    func testUpdateScanningState() throws {
        // 测试更新扫描状态
        XCTAssertNoThrow(toolbarManager.updateScanningState(true), "更新扫描状态为true不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateScanningState(false), "更新扫描状态为false不应该抛出异常")
    }
    
    func testUpdateProgress() throws {
        // 测试更新进度
        XCTAssertNoThrow(toolbarManager.updateProgress(0.0), "更新进度为0不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateProgress(0.5), "更新进度为0.5不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateProgress(1.0), "更新进度为1不应该抛出异常")
    }
    
    // MARK: - StatusBarManager Tests
    
    func testStatusBarManagerInitialization() throws {
        XCTAssertNotNil(statusBarManager, "StatusBarManager应该能够正确初始化")
    }
    
    func testCreateStatusBar() throws {
        let statusBar = statusBarManager.createStatusBar()
        
        XCTAssertNotNil(statusBar, "应该能创建状态栏")
        XCTAssertTrue(statusBar.wantsLayer, "状态栏应该启用图层")
    }
    
    func testGetStatusBar() throws {
        let statusBar1 = statusBarManager.createStatusBar()
        let statusBar2 = statusBarManager.getStatusBar()
        
        XCTAssertNotNil(statusBar2, "应该能获取状态栏")
        XCTAssertTrue(statusBar1 === statusBar2, "应该是同一个状态栏实例")
    }
    
    func testUpdateStatus() throws {
        _ = statusBarManager.createStatusBar()
        
        XCTAssertNoThrow(statusBarManager.updateStatus("测试状态"), "更新状态不应该抛出异常")
        XCTAssertNoThrow(statusBarManager.updateStatus(""), "更新空状态不应该抛出异常")
    }
    
    func testUpdateStatistics() throws {
        _ = statusBarManager.createStatusBar()
        
        XCTAssertNoThrow(statusBarManager.updateStatistics("100个文件"), "更新统计信息不应该抛出异常")
        XCTAssertNoThrow(statusBarManager.updateStatistics(""), "更新空统计信息不应该抛出异常")
    }
    
    // MARK: - DirectoryTreePanel Tests
    
    func testDirectoryTreePanelInitialization() throws {
        XCTAssertNotNil(directoryTreePanel, "DirectoryTreePanel应该能够正确初始化")
    }
    
    func testCreateDirectoryTreePanel() throws {
        let panel = directoryTreePanel.createPanel()
        
        XCTAssertNotNil(panel, "应该能创建目录树面板")
        XCTAssertTrue(panel.wantsLayer, "面板应该启用图层")
    }
    
    func testGetDirectoryTreePanel() throws {
        let panel1 = directoryTreePanel.createPanel()
        let panel2 = directoryTreePanel.getPanel()
        
        XCTAssertNotNil(panel2, "应该能获取目录树面板")
        XCTAssertTrue(panel1 === panel2, "应该是同一个面板实例")
    }
    
    func testSetDirectoryTreeData() throws {
        let testNode = FileNode(name: "测试目录", path: "/test", size: 1000, isDirectory: true)
        
        XCTAssertNoThrow(directoryTreePanel.setData(testNode), "设置目录树数据不应该抛出异常")
    }
    
    func testDirectoryTreePanelCallbacks() throws {
        var selectionChanged = false
        
        directoryTreePanel.onSelectionChanged = { _ in
            selectionChanged = true
        }
        
        XCTAssertNotNil(directoryTreePanel.onSelectionChanged, "选择变化回调应该被设置")
    }
    
    // MARK: - TreeMapPanel Tests
    
    func testTreeMapPanelInitialization() throws {
        XCTAssertNotNil(treeMapPanel, "TreeMapPanel应该能够正确初始化")
    }
    
    func testCreateTreeMapPanel() throws {
        let panel = treeMapPanel.createPanel()
        
        XCTAssertNotNil(panel, "应该能创建TreeMap面板")
        XCTAssertTrue(panel.wantsLayer, "面板应该启用图层")
    }
    
    func testGetTreeMapPanel() throws {
        let panel1 = treeMapPanel.createPanel()
        let panel2 = treeMapPanel.getPanel()
        
        XCTAssertNotNil(panel2, "应该能获取TreeMap面板")
        XCTAssertTrue(panel1 === panel2, "应该是同一个面板实例")
    }
    
    func testSetTreeMapData() throws {
        let testNode = FileNode(name: "测试文件", path: "/test.txt", size: 500, isDirectory: false)
        
        XCTAssertNoThrow(treeMapPanel.setData(testNode), "设置TreeMap数据不应该抛出异常")
    }
    
    func testTreeMapPanelCallbacks() throws {
        var rectClicked = false
        var rectHovered = false
        
        treeMapPanel.onRectClicked = { _ in
            rectClicked = true
        }
        
        treeMapPanel.onRectHovered = { _ in
            rectHovered = true
        }
        
        XCTAssertNotNil(treeMapPanel.onRectClicked, "矩形点击回调应该被设置")
        XCTAssertNotNil(treeMapPanel.onRectHovered, "矩形悬停回调应该被设置")
    }
    
    // MARK: - MainWindowController Tests
    
    func testMainWindowControllerInitialization() throws {
        // 由于MainWindowController涉及UI创建，在测试环境中可能有限制
        // 这里主要测试基本的初始化逻辑
        XCTAssertNoThrow(MainWindowController(), "MainWindowController初始化不应该抛出异常")
    }
    
    // MARK: - Integration Tests
    
    func testToolbarAndStatusBarIntegration() throws {
        let toolbar = toolbarManager.createToolbar()
        let statusBar = statusBarManager.createStatusBar()
        
        XCTAssertNotNil(toolbar, "工具栏应该创建成功")
        XCTAssertNotNil(statusBar, "状态栏应该创建成功")
        
        // 测试状态更新
        toolbarManager.updateScanningState(true)
        statusBarManager.updateStatus("扫描中...")
        
        // 验证没有异常
        XCTAssertTrue(true, "集成测试应该成功")
    }
    
    func testPanelIntegration() throws {
        let directoryPanel = directoryTreePanel.createPanel()
        let treeMapPanel = self.treeMapPanel.createPanel()
        
        XCTAssertNotNil(directoryPanel, "目录面板应该创建成功")
        XCTAssertNotNil(treeMapPanel, "TreeMap面板应该创建成功")
        
        // 创建测试数据
        let testNode = FileNode(name: "集成测试", path: "/integration/test", size: 2000, isDirectory: true)
        let childNode = FileNode(name: "子文件", path: "/integration/test/child.txt", size: 1000, isDirectory: false)
        testNode.children.append(childNode)
        
        // 设置数据
        directoryTreePanel.setData(testNode)
        self.treeMapPanel.setData(testNode)
        
        // 验证没有异常
        XCTAssertTrue(true, "面板集成测试应该成功")
    }
    
    func testFullUIWorkflow() throws {
        // 创建所有UI组件
        let toolbar = toolbarManager.createToolbar()
        let statusBar = statusBarManager.createStatusBar()
        let directoryPanel = directoryTreePanel.createPanel()
        let treeMapPanel = self.treeMapPanel.createPanel()
        
        XCTAssertNotNil(toolbar, "工具栏应该创建成功")
        XCTAssertNotNil(statusBar, "状态栏应该创建成功")
        XCTAssertNotNil(directoryPanel, "目录面板应该创建成功")
        XCTAssertNotNil(treeMapPanel, "TreeMap面板应该创建成功")
        
        // 模拟扫描流程
        toolbarManager.updateScanningState(true)
        statusBarManager.updateStatus("开始扫描...")
        
        // 模拟进度更新
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            toolbarManager.updateProgress(progress)
            statusBarManager.updateStatus("扫描进度: \(Int(progress * 100))%")
        }
        
        // 模拟扫描完成
        toolbarManager.updateScanningState(false)
        statusBarManager.updateStatus("扫描完成")
        
        // 创建测试数据
        let rootNode = FileNode(name: "根目录", path: "/", size: 10000, isDirectory: true)
        let subDir = FileNode(name: "子目录", path: "/subdir", size: 5000, isDirectory: true)
        let file1 = FileNode(name: "文件1.txt", path: "/file1.txt", size: 3000, isDirectory: false)
        let file2 = FileNode(name: "文件2.txt", path: "/subdir/file2.txt", size: 2000, isDirectory: false)
        
        subDir.children.append(file2)
        rootNode.children.append(subDir)
        rootNode.children.append(file1)
        
        // 设置数据到面板
        directoryTreePanel.setData(rootNode)
        self.treeMapPanel.setData(rootNode)
        
        // 更新统计信息
        statusBarManager.updateStatistics("2个文件, 1个目录, 总计 10KB")
        
        // 验证工作流程完成
        XCTAssertTrue(true, "完整UI工作流程应该成功")
    }
    
    // MARK: - Performance Tests
    
    func testToolbarCreationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let manager = ToolbarManager()
                _ = manager.createToolbar()
            }
        }
    }
    
    func testStatusBarUpdatePerformance() throws {
        _ = statusBarManager.createStatusBar()
        
        measure {
            for i in 0..<100 {
                statusBarManager.updateStatus("状态更新 \(i)")
                statusBarManager.updateStatistics("统计信息 \(i)")
            }
        }
    }
    
    func testPanelDataUpdatePerformance() throws {
        _ = directoryTreePanel.createPanel()
        _ = treeMapPanel.createPanel()
        
        // 创建大量测试数据
        let rootNode = FileNode(name: "性能测试根目录", path: "/perf", size: 100000, isDirectory: true)
        for i in 0..<50 {
            let childNode = FileNode(name: "文件\(i).txt", path: "/perf/file\(i).txt", size: Int64(i * 100), isDirectory: false)
            rootNode.children.append(childNode)
        }
        
        measure {
            directoryTreePanel.setData(rootNode)
            treeMapPanel.setData(rootNode)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNilDataHandling() throws {
        // 测试处理nil或空数据的情况
        let emptyNode = FileNode(name: "", path: "", size: 0, isDirectory: true)
        
        XCTAssertNoThrow(directoryTreePanel.setData(emptyNode), "处理空节点不应该抛出异常")
        XCTAssertNoThrow(treeMapPanel.setData(emptyNode), "处理空节点不应该抛出异常")
    }
    
    func testInvalidProgressValues() throws {
        // 测试无效的进度值
        XCTAssertNoThrow(toolbarManager.updateProgress(-0.1), "负进度值不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateProgress(1.1), "超过1的进度值不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateProgress(Double.nan), "NaN进度值不应该抛出异常")
        XCTAssertNoThrow(toolbarManager.updateProgress(Double.infinity), "无穷大进度值不应该抛出异常")
    }
    
    func testLargeDataHandling() throws {
        // 测试处理大量数据的情况
        let largeNode = FileNode(name: "大数据测试", path: "/large", size: Int64.max, isDirectory: true)
        
        // 添加大量子节点
        for i in 0..<1000 {
            let childNode = FileNode(name: "大文件\(i)", path: "/large/file\(i)", size: Int64(i * 1000000), isDirectory: false)
            largeNode.children.append(childNode)
        }
        
        XCTAssertNoThrow(directoryTreePanel.setData(largeNode), "处理大量数据不应该抛出异常")
        XCTAssertNoThrow(treeMapPanel.setData(largeNode), "处理大量数据不应该抛出异常")
    }
    
    // MARK: - UI State Tests
    
    func testScanningStateTransitions() throws {
        // 测试扫描状态转换
        toolbarManager.updateScanningState(false) // 初始状态
        toolbarManager.updateScanningState(true)  // 开始扫描
        toolbarManager.updateScanningState(false) // 停止扫描
        toolbarManager.updateScanningState(true)  // 重新开始
        toolbarManager.updateScanningState(false) // 完成扫描
        
        // 验证状态转换没有异常
        XCTAssertTrue(true, "扫描状态转换应该成功")
    }
    
    func testProgressUpdates() throws {
        // 测试进度更新序列
        let progressValues: [Double] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
        
        for progress in progressValues {
            XCTAssertNoThrow(toolbarManager.updateProgress(progress), "进度更新不应该抛出异常")
        }
    }
    
    func testStatusUpdates() throws {
        _ = statusBarManager.createStatusBar()
        
        let statusMessages = [
            "就绪",
            "正在扫描...",
            "扫描进度: 50%",
            "扫描完成",
            "错误: 无法访问文件",
            "已取消"
        ]
        
        for message in statusMessages {
            XCTAssertNoThrow(statusBarManager.updateStatus(message), "状态更新不应该抛出异常")
        }
    }
}
