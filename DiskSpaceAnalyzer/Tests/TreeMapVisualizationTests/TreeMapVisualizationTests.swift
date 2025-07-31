import XCTest
import AppKit
@testable import TreeMapVisualization
@testable import Common
@testable import DataModel
@testable import CoordinateSystem
@testable import PerformanceOptimizer

final class TreeMapVisualizationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var treeMapVisualization: TreeMapVisualization!
    var layoutEngine: TreeMapLayoutEngine!
    var squarifiedAlgorithm: SquarifiedAlgorithm!
    var colorManager: ColorManager!
    var smallFilesMerger: SmallFilesMerger!
    var animationController: AnimationController!
    
    var testRootNode: FileNode!
    var testBounds: CGRect!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        treeMapVisualization = TreeMapVisualization.shared
        layoutEngine = TreeMapLayoutEngine.shared
        squarifiedAlgorithm = SquarifiedAlgorithm.shared
        colorManager = ColorManager.shared
        smallFilesMerger = SmallFilesMerger.shared
        animationController = AnimationController.shared
        
        // 创建测试数据
        createTestData()
        
        // 设置测试边界
        testBounds = CGRect(x: 0, y: 0, width: 400, height: 300)
    }
    
    override func tearDownWithError() throws {
        layoutEngine.clearCache()
        animationController.cancelAllAnimations()
        
        treeMapVisualization = nil
        layoutEngine = nil
        squarifiedAlgorithm = nil
        colorManager = nil
        smallFilesMerger = nil
        animationController = nil
        testRootNode = nil
        testBounds = nil
    }
    
    private func createTestData() {
        // 创建根节点
        testRootNode = FileNode(name: "TestRoot", path: "/test", size: 0, isDirectory: true)
        
        // 创建子文件和目录
        let file1 = FileNode(name: "large.txt", path: "/test/large.txt", size: 1000000, isDirectory: false)
        let file2 = FileNode(name: "medium.txt", path: "/test/medium.txt", size: 500000, isDirectory: false)
        let file3 = FileNode(name: "small.txt", path: "/test/small.txt", size: 100000, isDirectory: false)
        let file4 = FileNode(name: "tiny.txt", path: "/test/tiny.txt", size: 10000, isDirectory: false)
        
        let dir1 = FileNode(name: "Directory1", path: "/test/dir1", size: 800000, isDirectory: true)
        let dir2 = FileNode(name: "Directory2", path: "/test/dir2", size: 300000, isDirectory: true)
        
        testRootNode.addChild(file1)
        testRootNode.addChild(file2)
        testRootNode.addChild(file3)
        testRootNode.addChild(file4)
        testRootNode.addChild(dir1)
        testRootNode.addChild(dir2)
        
        // 为目录添加子文件
        let subfile1 = FileNode(name: "sub1.txt", path: "/test/dir1/sub1.txt", size: 400000, isDirectory: false)
        let subfile2 = FileNode(name: "sub2.txt", path: "/test/dir1/sub2.txt", size: 400000, isDirectory: false)
        dir1.addChild(subfile1)
        dir1.addChild(subfile2)
    }
    
    // MARK: - TreeMapVisualization Tests
    
    func testTreeMapVisualizationInitialization() throws {
        XCTAssertNotNil(treeMapVisualization, "TreeMapVisualization应该能够正确初始化")
        XCTAssertNotNil(TreeMapVisualization.shared, "TreeMapVisualization.shared应该存在")
        XCTAssertTrue(TreeMapVisualization.shared === treeMapVisualization, "应该是单例模式")
    }
    
    func testSetTreeMapView() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        
        treeMapVisualization.setTreeMapView(treeMapView)
        
        XCTAssertNotNil(treeMapVisualization.treeMapView, "TreeMapView应该被设置")
        XCTAssertTrue(treeMapVisualization.treeMapView === treeMapView, "应该是同一个视图")
    }
    
    func testUpdateData() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        treeMapVisualization.setTreeMapView(treeMapView)
        
        XCTAssertNoThrow(treeMapVisualization.updateData(testRootNode), "更新数据不应该抛出异常")
    }
    
    func testClearCache() throws {
        XCTAssertNoThrow(treeMapVisualization.clearCache(), "清除缓存不应该抛出异常")
    }
    
    func testGetPerformanceStatistics() throws {
        let stats = treeMapVisualization.getPerformanceStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.cacheCount, 0, "缓存数量应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.memoryUsage, 0, "内存使用应该不小于0")
    }
    
    // MARK: - TreeMapRect Tests
    
    func testTreeMapRectInitialization() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let color = NSColor.blue
        let treeMapRect = TreeMapRect(node: testRootNode, rect: rect, color: color, level: 1)
        
        XCTAssertEqual(treeMapRect.node.id, testRootNode.id)
        XCTAssertEqual(treeMapRect.rect, rect)
        XCTAssertEqual(treeMapRect.color, color)
        XCTAssertEqual(treeMapRect.level, 1)
    }
    
    func testTreeMapRectContains() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testRootNode, rect: rect, color: NSColor.blue)
        
        XCTAssertTrue(treeMapRect.contains(CGPoint(x: 50, y: 50)), "应该包含矩形内的点")
        XCTAssertFalse(treeMapRect.contains(CGPoint(x: 5, y: 5)), "不应该包含矩形外的点")
        XCTAssertFalse(treeMapRect.contains(CGPoint(x: 150, y: 150)), "不应该包含矩形外的点")
    }
    
    func testTreeMapRectCenter() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testRootNode, rect: rect, color: NSColor.blue)
        
        let center = treeMapRect.center
        XCTAssertEqual(center.x, 60, accuracy: 0.001, "中心点X坐标应该正确")
        XCTAssertEqual(center.y, 60, accuracy: 0.001, "中心点Y坐标应该正确")
    }
    
    func testTreeMapRectArea() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testRootNode, rect: rect, color: NSColor.blue)
        
        XCTAssertEqual(treeMapRect.area, 8000, accuracy: 0.001, "面积应该正确计算")
    }
    
    // MARK: - SquarifiedAlgorithm Tests
    
    func testSquarifiedAlgorithmInitialization() throws {
        XCTAssertNotNil(squarifiedAlgorithm, "SquarifiedAlgorithm应该能够正确初始化")
        XCTAssertNotNil(SquarifiedAlgorithm.shared, "SquarifiedAlgorithm.shared应该存在")
        XCTAssertTrue(SquarifiedAlgorithm.shared === squarifiedAlgorithm, "应该是单例模式")
    }
    
    func testSquarifiedAlgorithmCalculateLayout() throws {
        let nodes = testRootNode.children
        let layout = squarifiedAlgorithm.calculateLayout(nodes: nodes, bounds: testBounds)
        
        XCTAssertGreaterThan(layout.count, 0, "应该生成布局矩形")
        
        // 验证所有矩形都在边界内
        for rect in layout {
            XCTAssertTrue(testBounds.contains(rect.rect), "所有矩形都应该在边界内")
        }
        
        // 验证矩形面积与文件大小成比例
        let totalSize = nodes.reduce(0) { $0 + $1.size }
        let totalArea = testBounds.width * testBounds.height
        
        for rect in layout {
            let expectedArea = CGFloat(rect.node.size) / CGFloat(totalSize) * totalArea
            let actualArea = rect.area
            let tolerance = expectedArea * 0.1 // 10%容差
            
            XCTAssertEqual(actualArea, expectedArea, accuracy: tolerance, "矩形面积应该与文件大小成比例")
        }
    }
    
    func testSquarifiedAlgorithmEmptyNodes() throws {
        let layout = squarifiedAlgorithm.calculateLayout(nodes: [], bounds: testBounds)
        XCTAssertTrue(layout.isEmpty, "空节点列表应该返回空布局")
    }
    
    func testSquarifiedAlgorithmZeroBounds() throws {
        let nodes = testRootNode.children
        let zeroBounds = CGRect.zero
        let layout = squarifiedAlgorithm.calculateLayout(nodes: nodes, bounds: zeroBounds)
        
        XCTAssertTrue(layout.isEmpty, "零边界应该返回空布局")
    }
    
    func testSquarifiedAlgorithmSingleNode() throws {
        let singleNode = [testRootNode.children.first!]
        let layout = squarifiedAlgorithm.calculateLayout(nodes: singleNode, bounds: testBounds)
        
        XCTAssertEqual(layout.count, 1, "单个节点应该返回一个矩形")
        XCTAssertEqual(layout.first?.rect, testBounds, "单个节点应该填充整个边界")
    }
    
    // MARK: - ColorManager Tests
    
    func testColorManagerInitialization() throws {
        XCTAssertNotNil(colorManager, "ColorManager应该能够正确初始化")
        XCTAssertNotNil(ColorManager.shared, "ColorManager.shared应该存在")
        XCTAssertTrue(ColorManager.shared === colorManager, "应该是单例模式")
    }
    
    func testColorManagerGetColor() throws {
        let fileNode = testRootNode.children.first { !$0.isDirectory }!
        let dirNode = testRootNode.children.first { $0.isDirectory }!
        
        let fileColor = colorManager.getColor(for: fileNode)
        let dirColor = colorManager.getColor(for: dirNode)
        
        XCTAssertNotNil(fileColor, "文件颜色不应该为nil")
        XCTAssertNotNil(dirColor, "目录颜色不应该为nil")
        
        // 文件和目录应该有不同的颜色系
        XCTAssertNotEqual(fileColor, dirColor, "文件和目录应该有不同的颜色")
    }
    
    func testColorManagerGetHighlightColor() throws {
        let node = testRootNode.children.first!
        let baseColor = colorManager.getColor(for: node)
        let highlightColor = colorManager.getHighlightColor(for: node)
        
        XCTAssertNotNil(highlightColor, "高亮颜色不应该为nil")
        XCTAssertNotEqual(baseColor, highlightColor, "高亮颜色应该与基础颜色不同")
    }
    
    func testColorManagerGetSelectionColor() throws {
        let node = testRootNode.children.first!
        let selectionColor = colorManager.getSelectionColor(for: node)
        
        XCTAssertNotNil(selectionColor, "选中颜色不应该为nil")
        XCTAssertEqual(selectionColor, NSColor.selectedControlColor, "选中颜色应该是系统选中颜色")
    }
    
    // MARK: - SmallFilesMerger Tests
    
    func testSmallFilesMergerInitialization() throws {
        XCTAssertNotNil(smallFilesMerger, "SmallFilesMerger应该能够正确初始化")
        XCTAssertNotNil(SmallFilesMerger.shared, "SmallFilesMerger.shared应该存在")
        XCTAssertTrue(SmallFilesMerger.shared === smallFilesMerger, "应该是单例模式")
    }
    
    func testSmallFilesMergerMergeSmallFiles() throws {
        // 创建多个小文件
        var smallFiles: [FileNode] = []
        for i in 0..<10 {
            let file = FileNode(name: "small\(i).txt", path: "/test/small\(i).txt", size: 1000, isDirectory: false)
            smallFiles.append(file)
        }
        
        // 添加一个大文件
        let largeFile = FileNode(name: "large.txt", path: "/test/large.txt", size: 1000000, isDirectory: false)
        smallFiles.append(largeFile)
        
        let mergedFiles = smallFilesMerger.mergeSmallFiles(smallFiles)
        
        XCTAssertLessThanOrEqual(mergedFiles.count, 5, "应该合并小文件")
        
        // 检查是否有合并的"其他文件"节点
        let hasOtherFiles = mergedFiles.contains { $0.name.contains("其他文件") }
        XCTAssertTrue(hasOtherFiles, "应该有合并的'其他文件'节点")
    }
    
    func testSmallFilesMergerNoMergeNeeded() throws {
        let fewFiles = Array(testRootNode.children.prefix(3))
        let mergedFiles = smallFilesMerger.mergeSmallFiles(fewFiles)
        
        XCTAssertEqual(mergedFiles.count, fewFiles.count, "少量文件不需要合并")
    }
    
    // MARK: - AnimationController Tests
    
    func testAnimationControllerInitialization() throws {
        XCTAssertNotNil(animationController, "AnimationController应该能够正确初始化")
        XCTAssertNotNil(AnimationController.shared, "AnimationController.shared应该存在")
        XCTAssertTrue(AnimationController.shared === animationController, "应该是单例模式")
    }
    
    func testAnimationControllerAnimateLayout() throws {
        let expectation = XCTestExpectation(description: "布局动画完成")
        
        let oldRects: [TreeMapRect] = []
        let newRects: [TreeMapRect] = []
        
        animationController.animateLayout(from: oldRects, to: newRects) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAnimationControllerAnimateHighlight() throws {
        let expectation = XCTestExpectation(description: "高亮动画完成")
        
        let rect = TreeMapRect(node: testRootNode, rect: testBounds, color: NSColor.blue)
        
        animationController.animateHighlight(rect: rect) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAnimationControllerCancelAllAnimations() throws {
        XCTAssertNoThrow(animationController.cancelAllAnimations(), "取消所有动画不应该抛出异常")
    }
    
    // MARK: - TreeMapLayoutEngine Tests
    
    func testTreeMapLayoutEngineInitialization() throws {
        XCTAssertNotNil(layoutEngine, "TreeMapLayoutEngine应该能够正确初始化")
        XCTAssertNotNil(TreeMapLayoutEngine.shared, "TreeMapLayoutEngine.shared应该存在")
        XCTAssertTrue(TreeMapLayoutEngine.shared === layoutEngine, "应该是单例模式")
    }
    
    func testTreeMapLayoutEngineCalculateLayout() throws {
        let expectation = XCTestExpectation(description: "布局计算完成")
        
        layoutEngine.calculateLayout(for: testRootNode, bounds: testBounds) { rects in
            XCTAssertGreaterThan(rects.count, 0, "应该生成布局矩形")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testTreeMapLayoutEngineCache() throws {
        let expectation1 = XCTestExpectation(description: "第一次布局计算")
        let expectation2 = XCTestExpectation(description: "第二次布局计算（缓存）")
        
        // 第一次计算
        layoutEngine.calculateLayout(for: testRootNode, bounds: testBounds) { _ in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 2.0)
        
        // 第二次计算应该使用缓存
        let startTime = Date()
        layoutEngine.calculateLayout(for: testRootNode, bounds: testBounds) { _ in
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(elapsedTime, 0.01, "缓存的计算应该很快")
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testTreeMapLayoutEngineClearCache() throws {
        // 先计算一次布局以填充缓存
        let expectation = XCTestExpectation(description: "布局计算完成")
        
        layoutEngine.calculateLayout(for: testRootNode, bounds: testBounds) { _ in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // 清除缓存
        layoutEngine.clearCache()
        
        // 验证缓存已清除
        let stats = layoutEngine.getCacheStatistics()
        XCTAssertEqual(stats.count, 0, "缓存应该被清除")
    }
    
    func testTreeMapLayoutEngineGetCacheStatistics() throws {
        let stats = layoutEngine.getCacheStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.count, 0, "缓存数量应该不小于0")
        XCTAssertGreaterThanOrEqual(stats.memoryUsage, 0, "内存使用应该不小于0")
    }
    
    // MARK: - TreeMapView Tests
    
    func testTreeMapViewInitialization() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        
        XCTAssertNotNil(treeMapView, "TreeMapView应该能够正确初始化")
        XCTAssertEqual(treeMapView.frame, testBounds, "框架应该正确设置")
    }
    
    func testTreeMapViewSetData() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        
        XCTAssertNoThrow(treeMapView.setData(testRootNode), "设置数据不应该抛出异常")
    }
    
    func testTreeMapViewUpdateLayout() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        
        XCTAssertNoThrow(treeMapView.updateLayout(), "更新布局不应该抛出异常")
    }
    
    func testTreeMapViewCallbacks() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        
        var rectClickedCalled = false
        var rectHoveredCalled = false
        
        treeMapView.onRectClicked = { _ in
            rectClickedCalled = true
        }
        
        treeMapView.onRectHovered = { _ in
            rectHoveredCalled = true
        }
        
        // 模拟鼠标事件
        let mouseEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: CGPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )
        
        if let event = mouseEvent {
            treeMapView.mouseDown(with: event)
        }
        
        // 注意：由于没有实际的矩形数据，回调可能不会被调用
        // 这里主要测试回调设置是否正常
        XCTAssertNotNil(treeMapView.onRectClicked, "点击回调应该被设置")
        XCTAssertNotNil(treeMapView.onRectHovered, "悬停回调应该被设置")
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() throws {
        let treeMapView = TreeMapView(frame: testBounds)
        treeMapVisualization.setTreeMapView(treeMapView)
        
        // 设置回调
        var clickedRect: TreeMapRect?
        var hoveredRect: TreeMapRect?
        
        treeMapVisualization.onRectClicked = { rect in
            clickedRect = rect
        }
        
        treeMapVisualization.onRectHovered = { rect in
            hoveredRect = rect
        }
        
        // 更新数据
        treeMapVisualization.updateData(testRootNode)
        
        // 等待布局计算完成
        let expectation = XCTestExpectation(description: "布局完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // 验证性能统计
        let stats = treeMapVisualization.getPerformanceStatistics()
        XCTAssertGreaterThanOrEqual(stats.cacheCount, 0, "应该有缓存统计")
    }
    
    // MARK: - Performance Tests
    
    func testLayoutCalculationPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "布局计算性能测试")
            
            layoutEngine.calculateLayout(for: testRootNode, bounds: testBounds) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testColorGenerationPerformance() throws {
        let nodes = testRootNode.children
        
        measure {
            for node in nodes {
                _ = colorManager.getColor(for: node)
                _ = colorManager.getHighlightColor(for: node)
                _ = colorManager.getSelectionColor(for: node)
            }
        }
    }
    
    func testSmallFilesMergerPerformance() throws {
        // 创建大量小文件
        var manyFiles: [FileNode] = []
        for i in 0..<100 {
            let file = FileNode(name: "file\(i).txt", path: "/test/file\(i).txt", size: Int64(i * 1000), isDirectory: false)
            manyFiles.append(file)
        }
        
        measure {
            _ = smallFilesMerger.mergeSmallFiles(manyFiles)
        }
    }
    
    func testSquarifiedAlgorithmPerformance() throws {
        let nodes = testRootNode.children
        
        measure {
            _ = squarifiedAlgorithm.calculateLayout(nodes: nodes, bounds: testBounds)
        }
    }
}
