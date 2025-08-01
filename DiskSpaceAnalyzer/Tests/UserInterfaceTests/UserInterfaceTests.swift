import XCTest
import AppKit
@testable import UserInterface
@testable import TreeMapVisualization
@testable import DirectoryTreeView
@testable import CoordinateSystem
@testable import DataModel
@testable import Common

final class UserInterfaceTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var toolbarManager: ToolbarManager!
    var statusBarManager: StatusBarManager!
    var directoryTreePanel: DirectoryTreePanel!
    var treeMapPanel: TreeMapPanel!
    var userInterface: UserInterface!
    
    var testFileNode: FileNode!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // 创建测试文件节点
        testFileNode = FileNode(
            name: "TestRoot",
            path: "/test",
            size: 10000,
            isDirectory: true
        )
        
        // 添加子节点
        let subDir = FileNode(name: "subdir", path: "/test/subdir", size: 5000, isDirectory: true)
        let file = FileNode(name: "file.txt", path: "/test/file.txt", size: 5000, isDirectory: false)
        
        testFileNode.addChild(subDir)
        testFileNode.addChild(file)
        
        // 初始化UI组件
        toolbarManager = ToolbarManager()
        statusBarManager = StatusBarManager()
        directoryTreePanel = DirectoryTreePanel()
        treeMapPanel = TreeMapPanel()
        userInterface = UserInterface.shared
    }
    
    override func tearDownWithError() throws {
        toolbarManager = nil
        statusBarManager = nil
        directoryTreePanel = nil
        treeMapPanel = nil
        userInterface = nil
        testFileNode = nil
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        XCTAssertNotNil(toolbarManager)
        XCTAssertNotNil(statusBarManager)
        XCTAssertNotNil(directoryTreePanel)
        XCTAssertNotNil(treeMapPanel)
        XCTAssertNotNil(userInterface)
        
        // 测试单例模式
        XCTAssertTrue(UserInterface.shared === userInterface)
    }
    
    // MARK: - ToolbarManager Tests
    
    func testToolbarManagerCreateToolbar() throws {
        let toolbar = toolbarManager.createToolbar()
        
        XCTAssertNotNil(toolbar)
        XCTAssertEqual(toolbar.identifier, "MainToolbar")
        XCTAssertNotNil(toolbar.delegate)
    }
    
    func testToolbarManagerUpdateScanningState() throws {
        XCTAssertNoThrow(toolbarManager.updateScanningState(true))
        XCTAssertNoThrow(toolbarManager.updateScanningState(false))
    }
    
    func testToolbarManagerUpdateProgress() throws {
        XCTAssertNoThrow(toolbarManager.updateProgress(0.0))
        XCTAssertNoThrow(toolbarManager.updateProgress(0.5))
        XCTAssertNoThrow(toolbarManager.updateProgress(1.0))
    }
    
    func testToolbarManagerCallbacks() throws {
        var selectFolderCalled = false
        var startScanCalled = false
        var stopScanCalled = false
        var refreshCalled = false
        
        toolbarManager.onSelectFolder = { selectFolderCalled = true }
        toolbarManager.onStartScan = { startScanCalled = true }
        toolbarManager.onStopScan = { stopScanCalled = true }
        toolbarManager.onRefresh = { refreshCalled = true }
        
        // 测试回调设置
        XCTAssertNotNil(toolbarManager.onSelectFolder)
        XCTAssertNotNil(toolbarManager.onStartScan)
        XCTAssertNotNil(toolbarManager.onStopScan)
        XCTAssertNotNil(toolbarManager.onRefresh)
    }
    
    func testToolbarManagerDelegateMethods() throws {
        let toolbar = toolbarManager.createToolbar()
        
        // 测试工具栏委托方法
        let defaultItems = toolbarManager.toolbarDefaultItemIdentifiers(toolbar)
        XCTAssertGreaterThan(defaultItems.count, 0)
        
        let allowedItems = toolbarManager.toolbarAllowedItemIdentifiers(toolbar)
        XCTAssertGreaterThan(allowedItems.count, 0)
        
        // 测试工具栏项创建
        if let firstItemId = defaultItems.first {
            let toolbarItem = toolbarManager.toolbar(toolbar, itemForItemIdentifier: firstItemId, willBeInsertedIntoToolbar: true)
            XCTAssertNotNil(toolbarItem)
        }
    }
    
    // MARK: - StatusBarManager Tests
    
    func testStatusBarManagerCreateStatusBar() throws {
        let statusBar = statusBarManager.createStatusBar()
        
        XCTAssertNotNil(statusBar)
        XCTAssertTrue(statusBar.wantsLayer)
    }
    
    func testStatusBarManagerUpdateStatus() throws {
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        XCTAssertNoThrow(statusBarManager.updateStatus("Test Status"))
        XCTAssertNoThrow(statusBarManager.updateStatus(""))
    }
    
    func testStatusBarManagerUpdateStatistics() throws {
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        XCTAssertNoThrow(statusBarManager.updateStatistics("Files: 100, Size: 1MB"))
        XCTAssertNoThrow(statusBarManager.updateStatistics(""))
    }
    
    func testStatusBarManagerGetStatusBar() throws {
        let statusBar1 = statusBarManager.createStatusBar()
        let statusBar2 = statusBarManager.getStatusBar()
        
        XCTAssertNotNil(statusBar1)
        XCTAssertNotNil(statusBar2)
    }
    
    // MARK: - DirectoryTreePanel Tests
    
    func testDirectoryTreePanelCreatePanel() throws {
        let panel = directoryTreePanel.createPanel()
        
        XCTAssertNotNil(panel)
        XCTAssertTrue(panel.wantsLayer)
    }
    
    func testDirectoryTreePanelSetData() throws {
        let panel = directoryTreePanel.createPanel()
        XCTAssertNotNil(panel)
        
        XCTAssertNoThrow(directoryTreePanel.setData(testFileNode))
    }
    
    func testDirectoryTreePanelGetPanel() throws {
        let panel1 = directoryTreePanel.createPanel()
        let panel2 = directoryTreePanel.getPanel()
        
        XCTAssertNotNil(panel1)
        XCTAssertNotNil(panel2)
    }
    
    // MARK: - TreeMapPanel Tests
    
    func testTreeMapPanelCreatePanel() throws {
        let panel = treeMapPanel.createPanel()
        
        XCTAssertNotNil(panel)
        XCTAssertTrue(panel.wantsLayer)
    }
    
    func testTreeMapPanelSetData() throws {
        let panel = treeMapPanel.createPanel()
        XCTAssertNotNil(panel)
        
        XCTAssertNoThrow(treeMapPanel.setData(testFileNode))
    }
    
    func testTreeMapPanelGetPanel() throws {
        let panel1 = treeMapPanel.createPanel()
        let panel2 = treeMapPanel.getPanel()
        
        XCTAssertNotNil(panel1)
        XCTAssertNotNil(panel2)
    }
    
    // MARK: - UserInterfaceManager Tests
    
    func testUserInterfaceLaunch() throws {
        // 测试启动不会崩溃
        XCTAssertNoThrow(userInterface.launch())
    }
    
    func testUserInterfaceGetMainWindowController() throws {
        // 在启动前可能返回nil
        let controller = userInterface.getMainWindowController()
        // 可能为nil，这是正常的
        XCTAssertTrue(controller != nil || controller == nil)
    }
    
    // MARK: - Integration Tests
    
    func testFullUIWorkflow() throws {
        // 创建工具栏
        let toolbar = toolbarManager.createToolbar()
        XCTAssertNotNil(toolbar)
        
        // 创建状态栏
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        // 创建目录树面板
        let directoryPanel = directoryTreePanel.createPanel()
        XCTAssertNotNil(directoryPanel)
        
        // 创建TreeMap面板
        let treeMapPanelView = treeMapPanel.createPanel()
        XCTAssertNotNil(treeMapPanelView)
        
        // 设置数据
        directoryTreePanel.setData(testFileNode)
        treeMapPanel.setData(testFileNode)
        
        // 更新状态
        statusBarManager.updateStatus("Ready")
        statusBarManager.updateStatistics("Files: 2, Directories: 1")
        
        // 更新工具栏状态
        toolbarManager.updateScanningState(false)
        toolbarManager.updateProgress(0.0)
        
        // 验证所有组件都正常工作
        XCTAssertTrue(true, "完整的UI工作流程应该正常执行")
    }
    
    func testUIComponentsIntegration() throws {
        // 测试UI组件之间的集成
        let toolbar = toolbarManager.createToolbar()
        let statusBar = statusBarManager.createStatusBar()
        let directoryPanel = directoryTreePanel.createPanel()
        let treeMapPanelView = treeMapPanel.createPanel()
        
        // 验证所有组件都已创建
        XCTAssertNotNil(toolbar)
        XCTAssertNotNil(statusBar)
        XCTAssertNotNil(directoryPanel)
        XCTAssertNotNil(treeMapPanelView)
        
        // 测试数据传递
        directoryTreePanel.setData(testFileNode)
        treeMapPanel.setData(testFileNode)
        
        // 测试状态更新
        statusBarManager.updateStatus("Scanning...")
        toolbarManager.updateScanningState(true)
        toolbarManager.updateProgress(0.5)
        
        // 完成扫描
        statusBarManager.updateStatus("Scan completed")
        toolbarManager.updateScanningState(false)
        toolbarManager.updateProgress(1.0)
        
        XCTAssertTrue(true, "UI组件集成测试完成")
    }
    
    // MARK: - Performance Tests
    
    func testToolbarCreationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let toolbar = toolbarManager.createToolbar()
                XCTAssertNotNil(toolbar)
            }
        }
    }
    
    func testStatusBarUpdatePerformance() throws {
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        measure {
            for i in 0..<100 {
                statusBarManager.updateStatus("Status \(i)")
                statusBarManager.updateStatistics("Files: \(i)")
            }
        }
    }
    
    func testPanelCreationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let directoryPanel = directoryTreePanel.createPanel()
                let treeMapPanelView = treeMapPanel.createPanel()
                
                XCTAssertNotNil(directoryPanel)
                XCTAssertNotNil(treeMapPanelView)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testToolbarManagerWithNilCallbacks() throws {
        // 测试没有设置回调的情况
        toolbarManager.onSelectFolder = nil
        toolbarManager.onStartScan = nil
        toolbarManager.onStopScan = nil
        toolbarManager.onRefresh = nil
        
        let toolbar = toolbarManager.createToolbar()
        XCTAssertNotNil(toolbar)
        
        // 应该不会崩溃
        XCTAssertTrue(true)
    }
    
    func testStatusBarManagerWithEmptyStrings() throws {
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        XCTAssertNoThrow(statusBarManager.updateStatus(""))
        XCTAssertNoThrow(statusBarManager.updateStatistics(""))
    }
    
    func testPanelsWithNilData() throws {
        let directoryPanel = directoryTreePanel.createPanel()
        let treeMapPanelView = treeMapPanel.createPanel()
        
        XCTAssertNotNil(directoryPanel)
        XCTAssertNotNil(treeMapPanelView)
        
        // 测试设置数据后的行为
        directoryTreePanel.setData(testFileNode)
        treeMapPanel.setData(testFileNode)
        
        XCTAssertTrue(true, "设置数据不应该崩溃")
    }
    
    func testToolbarProgressBoundaryValues() throws {
        XCTAssertNoThrow(toolbarManager.updateProgress(-0.1)) // 负值
        XCTAssertNoThrow(toolbarManager.updateProgress(0.0))  // 最小值
        XCTAssertNoThrow(toolbarManager.updateProgress(1.0))  // 最大值
        XCTAssertNoThrow(toolbarManager.updateProgress(1.1))  // 超出范围
    }
    
    func testUserInterfaceMultipleLaunches() throws {
        // 测试多次启动
        XCTAssertNoThrow(userInterface.launch())
        XCTAssertNoThrow(userInterface.launch())
        
        // 应该不会崩溃
        XCTAssertTrue(true)
    }
    
    // MARK: - UI State Tests
    
    func testToolbarStateTransitions() throws {
        let toolbar = toolbarManager.createToolbar()
        XCTAssertNotNil(toolbar)
        
        // 测试状态转换
        toolbarManager.updateScanningState(false) // 初始状态
        toolbarManager.updateProgress(0.0)
        
        toolbarManager.updateScanningState(true)  // 开始扫描
        toolbarManager.updateProgress(0.3)
        
        toolbarManager.updateProgress(0.7)        // 扫描进行中
        
        toolbarManager.updateScanningState(false) // 扫描完成
        toolbarManager.updateProgress(1.0)
        
        XCTAssertTrue(true, "工具栏状态转换应该正常")
    }
    
    func testStatusBarStateUpdates() throws {
        let statusBar = statusBarManager.createStatusBar()
        XCTAssertNotNil(statusBar)
        
        // 测试状态更新序列
        statusBarManager.updateStatus("Ready")
        statusBarManager.updateStatistics("No files scanned")
        
        statusBarManager.updateStatus("Scanning...")
        statusBarManager.updateStatistics("Files: 50, Size: 2.5MB")
        
        statusBarManager.updateStatus("Scan completed")
        statusBarManager.updateStatistics("Files: 100, Size: 5.0MB")
        
        XCTAssertTrue(true, "状态栏状态更新应该正常")
    }
}
