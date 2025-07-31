import XCTest
import AppKit
@testable import DirectoryTreeView
@testable import Common
@testable import DataModel
@testable import PerformanceOptimizer

final class DirectoryTreeViewTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var directoryTreeView: DirectoryTreeView!
    var controller: DirectoryTreeViewController!
    var expansionManager: TreeExpansionManager!
    var directoryMerger: DirectoryMerger!
    
    var testRootNode: FileNode!
    var outlineView: NSOutlineView!
    var scrollView: NSScrollView!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        directoryTreeView = DirectoryTreeView.shared
        controller = DirectoryTreeViewController()
        expansionManager = TreeExpansionManager.shared
        directoryMerger = DirectoryMerger.shared
        
        // 创建测试数据
        createTestData()
        
        // 创建UI组件
        outlineView = NSOutlineView()
        scrollView = NSScrollView()
        
        // 设置UI组件
        directoryTreeView.outlineView = outlineView
        directoryTreeView.scrollView = scrollView
    }
    
    override func tearDownWithError() throws {
        expansionManager.collapseAll()
        
        directoryTreeView = nil
        controller = nil
        expansionManager = nil
        directoryMerger = nil
        testRootNode = nil
        outlineView = nil
        scrollView = nil
    }
    
    private func createTestData() {
        // 创建根节点
        testRootNode = FileNode(name: "TestRoot", path: "/test", size: 0, isDirectory: true)
        
        // 创建子目录
        let dir1 = FileNode(name: "Directory1", path: "/test/dir1", size: 1000000, isDirectory: true)
        let dir2 = FileNode(name: "Directory2", path: "/test/dir2", size: 500000, isDirectory: true)
        let dir3 = FileNode(name: "Directory3", path: "/test/dir3", size: 200000, isDirectory: true)
        
        testRootNode.addChild(dir1)
        testRootNode.addChild(dir2)
        testRootNode.addChild(dir3)
        
        // 为dir1添加子目录
        let subdir1 = FileNode(name: "SubDir1", path: "/test/dir1/sub1", size: 600000, isDirectory: true)
        let subdir2 = FileNode(name: "SubDir2", path: "/test/dir1/sub2", size: 400000, isDirectory: true)
        dir1.addChild(subdir1)
        dir1.addChild(subdir2)
        
        // 添加一些文件（应该被过滤掉）
        let file1 = FileNode(name: "file1.txt", path: "/test/file1.txt", size: 1000, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/test/dir1/file2.txt", size: 2000, isDirectory: false)
        testRootNode.addChild(file1)
        dir1.addChild(file2)
    }
    
    // MARK: - DirectoryTreeView Tests
    
    func testDirectoryTreeViewInitialization() throws {
        XCTAssertNotNil(directoryTreeView, "DirectoryTreeView应该能够正确初始化")
        XCTAssertNotNil(DirectoryTreeView.shared, "DirectoryTreeView.shared应该存在")
        XCTAssertTrue(DirectoryTreeView.shared === directoryTreeView, "应该是单例模式")
    }
    
    func testSetDataSource() throws {
        directoryTreeView.setDataSource(testRootNode)
        
        XCTAssertNotNil(outlineView.dataSource, "OutlineView应该有数据源")
        XCTAssertNotNil(outlineView.delegate, "OutlineView应该有代理")
    }
    
    func testUpdateData() throws {
        directoryTreeView.setDataSource(testRootNode)
        
        XCTAssertNoThrow(directoryTreeView.updateData(), "更新数据不应该抛出异常")
    }
    
    // MARK: - SmartDirectoryNode Tests
    
    func testSmartDirectoryNodeInitialization() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        
        XCTAssertEqual(smartNode.fileNode.name, "TestRoot")
        XCTAssertEqual(smartNode.displayName, "TestRoot")
        XCTAssertFalse(smartNode.isExpanded)
        XCTAssertFalse(smartNode.isLoaded)
        XCTAssertEqual(smartNode.level, 0)
        XCTAssertNil(smartNode.parent)
    }
    
    func testSmartDirectoryNodeHierarchy() throws {
        let parentNode = SmartDirectoryNode(fileNode: testRootNode)
        let childNode = SmartDirectoryNode(fileNode: testRootNode.children.first!, parent: parentNode)
        
        XCTAssertEqual(childNode.level, 1)
        XCTAssertTrue(childNode.parent === parentNode)
    }
    
    func testSmartDirectoryNodeLazyLoading() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        
        XCTAssertFalse(smartNode.isLoaded)
        XCTAssertEqual(smartNode.children.count, 0)
        
        smartNode.loadChildren()
        
        XCTAssertTrue(smartNode.isLoaded)
        XCTAssertGreaterThan(smartNode.children.count, 0)
        
        // 应该只加载目录，不加载文件
        let hasFiles = smartNode.children.contains { !$0.fileNode.isDirectory }
        XCTAssertFalse(hasFiles, "不应该加载文件节点")
    }
    
    func testSmartDirectoryNodeExpansion() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        
        XCTAssertFalse(smartNode.isExpanded)
        
        smartNode.expand()
        
        XCTAssertTrue(smartNode.isExpanded)
        XCTAssertTrue(smartNode.isLoaded)
        XCTAssertGreaterThan(smartNode.children.count, 0)
    }
    
    func testSmartDirectoryNodeCollapse() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        smartNode.expand()
        
        // 展开子节点
        if let firstChild = smartNode.children.first {
            firstChild.expand()
            XCTAssertTrue(firstChild.isExpanded)
        }
        
        smartNode.collapse()
        
        XCTAssertFalse(smartNode.isExpanded)
        
        // 检查子节点也被折叠
        if let firstChild = smartNode.children.first {
            XCTAssertFalse(firstChild.isExpanded)
        }
    }
    
    func testSmartDirectoryNodeDisplayInfo() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        let displayInfo = smartNode.getDisplayInfo()
        
        XCTAssertEqual(displayInfo.name, "TestRoot")
        XCTAssertNotNil(displayInfo.size)
        XCTAssertEqual(displayInfo.level, 0)
        XCTAssertEqual(displayInfo.icon, "folder")
    }
    
    func testSmartDirectoryNodeCaching() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        
        // 第一次获取显示信息
        let info1 = smartNode.getDisplayInfo()
        
        // 第二次获取应该使用缓存
        let info2 = smartNode.getDisplayInfo()
        
        XCTAssertEqual(info1.name, info2.name)
        XCTAssertEqual(info1.size, info2.size)
        
        // 清除缓存
        smartNode.clearCache()
        
        // 再次获取应该重新计算
        let info3 = smartNode.getDisplayInfo()
        XCTAssertEqual(info1.name, info3.name)
    }
    
    // MARK: - DirectoryMerger Tests
    
    func testDirectoryMergerInitialization() throws {
        XCTAssertNotNil(directoryMerger, "DirectoryMerger应该能够正确初始化")
        XCTAssertNotNil(DirectoryMerger.shared, "DirectoryMerger.shared应该存在")
        XCTAssertTrue(DirectoryMerger.shared === directoryMerger, "应该是单例模式")
    }
    
    func testDirectoryMergerSmallDirectories() throws {
        // 创建多个小目录节点
        var nodes: [SmartDirectoryNode] = []
        
        for i in 0..<15 {
            let fileNode = FileNode(name: "Dir\(i)", path: "/test/dir\(i)", size: Int64(1000 - i * 50), isDirectory: true)
            let smartNode = SmartDirectoryNode(fileNode: fileNode)
            nodes.append(smartNode)
        }
        
        let mergedNodes = directoryMerger.mergeSmallDirectories(nodes)
        
        // 应该合并小目录
        XCTAssertLessThanOrEqual(mergedNodes.count, 10, "应该将小目录合并")
        
        // 检查是否有"其他"节点
        let hasOtherNode = mergedNodes.contains { $0.fileNode.name.contains("其他") }
        XCTAssertTrue(hasOtherNode, "应该有合并的'其他'节点")
    }
    
    func testDirectoryMergerNoMergeNeeded() throws {
        // 创建少量目录节点
        var nodes: [SmartDirectoryNode] = []
        
        for i in 0..<5 {
            let fileNode = FileNode(name: "Dir\(i)", path: "/test/dir\(i)", size: Int64(1000 + i * 100), isDirectory: true)
            let smartNode = SmartDirectoryNode(fileNode: fileNode)
            nodes.append(smartNode)
        }
        
        let mergedNodes = directoryMerger.mergeSmallDirectories(nodes)
        
        // 不需要合并
        XCTAssertEqual(mergedNodes.count, nodes.count, "少量目录不需要合并")
    }
    
    // MARK: - TreeExpansionManager Tests
    
    func testTreeExpansionManagerInitialization() throws {
        XCTAssertNotNil(expansionManager, "TreeExpansionManager应该能够正确初始化")
        XCTAssertNotNil(TreeExpansionManager.shared, "TreeExpansionManager.shared应该存在")
        XCTAssertTrue(TreeExpansionManager.shared === expansionManager, "应该是单例模式")
    }
    
    func testTreeExpansionManagerSetExpanded() throws {
        let path = "/test/dir1"
        
        XCTAssertFalse(expansionManager.isExpanded(path))
        
        expansionManager.setExpanded(path, expanded: true)
        
        XCTAssertTrue(expansionManager.isExpanded(path))
        
        expansionManager.setExpanded(path, expanded: false)
        
        XCTAssertFalse(expansionManager.isExpanded(path))
    }
    
    func testTreeExpansionManagerExpandPath() throws {
        let path = "/test/dir1/subdir1"
        
        expansionManager.expandPath(path)
        
        XCTAssertTrue(expansionManager.isExpanded("/test"))
        XCTAssertTrue(expansionManager.isExpanded("/test/dir1"))
        XCTAssertTrue(expansionManager.isExpanded("/test/dir1/subdir1"))
    }
    
    func testTreeExpansionManagerCollapseAll() throws {
        expansionManager.setExpanded("/test", expanded: true)
        expansionManager.setExpanded("/test/dir1", expanded: true)
        
        XCTAssertTrue(expansionManager.isExpanded("/test"))
        XCTAssertTrue(expansionManager.isExpanded("/test/dir1"))
        
        expansionManager.collapseAll()
        
        XCTAssertFalse(expansionManager.isExpanded("/test"))
        XCTAssertFalse(expansionManager.isExpanded("/test/dir1"))
    }
    
    func testTreeExpansionManagerHistory() throws {
        expansionManager.setExpanded("/test", expanded: true)
        expansionManager.setExpanded("/test/dir1", expanded: true)
        expansionManager.setExpanded("/test/dir2", expanded: true)
        
        let history = expansionManager.getExpansionHistory()
        
        XCTAssertEqual(history.count, 3)
        XCTAssertTrue(history.contains("/test"))
        XCTAssertTrue(history.contains("/test/dir1"))
        XCTAssertTrue(history.contains("/test/dir2"))
    }
    
    func testTreeExpansionManagerStateRestore() throws {
        let originalState = [
            "/test": true,
            "/test/dir1": true,
            "/test/dir2": false
        ]
        
        expansionManager.restoreExpansionState(originalState)
        
        XCTAssertTrue(expansionManager.isExpanded("/test"))
        XCTAssertTrue(expansionManager.isExpanded("/test/dir1"))
        XCTAssertFalse(expansionManager.isExpanded("/test/dir2"))
        
        let currentState = expansionManager.getCurrentExpansionState()
        XCTAssertEqual(currentState["/test"], true)
        XCTAssertEqual(currentState["/test/dir1"], true)
        XCTAssertEqual(currentState["/test/dir2"], false)
    }
    
    // MARK: - DirectoryTreeViewController Tests
    
    func testDirectoryTreeControllerInitialization() throws {
        XCTAssertNotNil(controller, "DirectoryTreeViewController应该能够正确初始化")
    }
    
    func testDirectoryTreeControllerSetRootNode() throws {
        controller.setRootNode(testRootNode)
        
        // 验证数据源方法
        let childrenCount = controller.numberOfChildren(ofItem: nil)
        XCTAssertEqual(childrenCount, 1, "根节点应该有一个子项")
        
        let rootItem = controller.child(0, ofItem: nil)
        XCTAssertNotNil(rootItem, "应该能获取根项")
        
        if let smartNode = rootItem {
            XCTAssertEqual(smartNode.fileNode.name, "TestRoot")
        }
    }
    
    func testDirectoryTreeControllerDataSource() throws {
        controller.setRootNode(testRootNode)
        
        // 测试根节点
        let rootItem = controller.child(0, ofItem: nil) as? SmartDirectoryNode
        XCTAssertNotNil(rootItem)
        
        // 测试子节点
        if let root = rootItem {
            root.loadChildren()
            let childrenCount = controller.numberOfChildren(ofItem: root)
            XCTAssertGreaterThan(childrenCount, 0, "根节点应该有子节点")
            
            let firstChild = controller.child(0, ofItem: root)
            XCTAssertNotNil(firstChild, "应该能获取第一个子节点")
        }
    }
    
    func testDirectoryTreeControllerExpandable() throws {
        controller.setRootNode(testRootNode)
        
        let rootItem = controller.child(0, ofItem: nil) as? SmartDirectoryNode
        XCTAssertNotNil(rootItem)
        
        if let root = rootItem {
            root.loadChildren()
            let isExpandable = controller.isItemExpandable(root)
            XCTAssertTrue(isExpandable, "有子节点的目录应该可展开")
        }
    }
    
    func testDirectoryTreeControllerNodeOperations() throws {
        controller.setRootNode(testRootNode)
        
        let rootItem = controller.child(0, ofItem: nil) as? SmartDirectoryNode
        XCTAssertNotNil(rootItem)
        
        if let root = rootItem {
            // 测试展开
            XCTAssertFalse(root.isExpanded)
            controller.expandNode(root)
            XCTAssertTrue(root.isExpanded)
            
            // 测试折叠
            controller.collapseNode(root)
            XCTAssertFalse(root.isExpanded)
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() throws {
        // 设置数据源
        directoryTreeView.setDataSource(testRootNode)
        
        // 获取根节点
        let selectedNode = directoryTreeView.getSelectedNode()
        // 初始状态可能没有选中节点
        
        // 展开路径
        directoryTreeView.expandPath("/test/Directory1")
        
        // 验证展开状态
        XCTAssertTrue(expansionManager.isExpanded("/test"))
        XCTAssertTrue(expansionManager.isExpanded("/test/Directory1"))
        
        // 折叠所有
        directoryTreeView.collapseAll()
        
        XCTAssertFalse(expansionManager.isExpanded("/test"))
        XCTAssertFalse(expansionManager.isExpanded("/test/Directory1"))
    }
    
    func testCallbacks() throws {
        var selectionChangedCalled = false
        var nodeExpandedCalled = false
        var nodeCollapsedCalled = false
        
        directoryTreeView.onSelectionChanged = { _ in
            selectionChangedCalled = true
        }
        
        directoryTreeView.onNodeExpanded = { _ in
            nodeExpandedCalled = true
        }
        
        directoryTreeView.onNodeCollapsed = { _ in
            nodeCollapsedCalled = true
        }
        
        directoryTreeView.setDataSource(testRootNode)
        
        // 模拟节点操作
        let rootItem = controller.child(0, ofItem: nil) as? SmartDirectoryNode
        if let root = rootItem {
            directoryTreeView.expandNode(root)
            XCTAssertTrue(nodeExpandedCalled, "应该调用节点展开回调")
            
            directoryTreeView.collapseNode(root)
            XCTAssertTrue(nodeCollapsedCalled, "应该调用节点折叠回调")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataSetPerformance() throws {
        // 创建大量测试数据
        let largeRootNode = FileNode(name: "LargeRoot", path: "/large", size: 0, isDirectory: true)
        
        for i in 0..<100 {
            let dir = FileNode(name: "Dir\(i)", path: "/large/dir\(i)", size: Int64(i * 1000), isDirectory: true)
            largeRootNode.addChild(dir)
            
            // 为每个目录添加子目录
            for j in 0..<10 {
                let subdir = FileNode(name: "SubDir\(j)", path: "/large/dir\(i)/sub\(j)", size: Int64(j * 100), isDirectory: true)
                dir.addChild(subdir)
            }
        }
        
        measure {
            directoryTreeView.setDataSource(largeRootNode)
            directoryTreeView.updateData()
        }
    }
    
    func testNodeExpansionPerformance() throws {
        directoryTreeView.setDataSource(testRootNode)
        
        let rootItem = controller.child(0, ofItem: nil) as? SmartDirectoryNode
        XCTAssertNotNil(rootItem)
        
        if let root = rootItem {
            measure {
                for _ in 0..<100 {
                    directoryTreeView.expandNode(root)
                    directoryTreeView.collapseNode(root)
                }
            }
        }
    }
    
    func testCachePerformance() throws {
        let smartNode = SmartDirectoryNode(fileNode: testRootNode)
        smartNode.loadChildren()
        
        measure {
            for _ in 0..<1000 {
                _ = smartNode.getDisplayInfo()
            }
        }
    }
}
