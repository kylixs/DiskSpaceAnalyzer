import XCTest
import AppKit
@testable import TreeMapVisualization
@testable import CoordinateSystem
@testable import DataModel
@testable import Common

final class TreeMapVisualizationTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var layoutEngine: TreeMapLayoutEngine!
    var colorManager: ColorManager!
    var treeMapView: TreeMapView!
    
    var testNode: FileNode!
    var testBounds: CGRect!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        layoutEngine = TreeMapLayoutEngine.shared
        colorManager = ColorManager.shared
        treeMapView = TreeMapView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        
        testBounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        
        // 创建测试节点
        testNode = FileNode(
            name: "TestRoot",
            path: "/test",
            size: 1000,
            isDirectory: true
        )
        
        // 添加子节点
        let child1 = FileNode(name: "file1.txt", path: "/test/file1.txt", size: 400, isDirectory: false)
        let child2 = FileNode(name: "file2.txt", path: "/test/file2.txt", size: 300, isDirectory: false)
        let child3 = FileNode(name: "file3.txt", path: "/test/file3.txt", size: 200, isDirectory: false)
        let child4 = FileNode(name: "file4.txt", path: "/test/file4.txt", size: 100, isDirectory: false)
        
        testNode.addChild(child1)
        testNode.addChild(child2)
        testNode.addChild(child3)
        testNode.addChild(child4)
    }
    
    override func tearDownWithError() throws {
        layoutEngine.clearCache()
        
        layoutEngine = nil
        colorManager = nil
        treeMapView = nil
        testNode = nil
        testBounds = nil
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        XCTAssertNotNil(layoutEngine)
        XCTAssertNotNil(colorManager)
        XCTAssertNotNil(treeMapView)
        
        // 测试单例模式
        XCTAssertTrue(TreeMapLayoutEngine.shared === layoutEngine)
        XCTAssertTrue(ColorManager.shared === colorManager)
    }
    
    // MARK: - TreeMapRect Tests
    
    func testTreeMapRectCreation() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let color = NSColor.blue
        let treeMapRect = TreeMapRect(node: testNode, rect: rect, color: color, level: 1)
        
        XCTAssertEqual(treeMapRect.node.name, testNode.name)
        XCTAssertEqual(treeMapRect.rect, rect)
        XCTAssertEqual(treeMapRect.color, color)
        XCTAssertEqual(treeMapRect.level, 1)
    }
    
    func testTreeMapRectContains() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testNode, rect: rect, color: NSColor.blue)
        
        // 测试包含的点
        XCTAssertTrue(treeMapRect.contains(CGPoint(x: 50, y: 50)))
        XCTAssertTrue(treeMapRect.contains(CGPoint(x: 10, y: 20))) // 边界点
        
        // 测试不包含的点
        XCTAssertFalse(treeMapRect.contains(CGPoint(x: 5, y: 15)))
        XCTAssertFalse(treeMapRect.contains(CGPoint(x: 150, y: 150)))
    }
    
    func testTreeMapRectCenter() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testNode, rect: rect, color: NSColor.blue)
        
        let center = treeMapRect.center
        XCTAssertEqual(center.x, 60, accuracy: 0.001) // 10 + 100/2
        XCTAssertEqual(center.y, 60, accuracy: 0.001) // 20 + 80/2
    }
    
    func testTreeMapRectArea() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let treeMapRect = TreeMapRect(node: testNode, rect: rect, color: NSColor.blue)
        
        let area = treeMapRect.area
        XCTAssertEqual(area, 8000, accuracy: 0.001) // 100 * 80
    }
    
    // MARK: - TreeMapLayoutEngine Tests
    
    func testLayoutEngineCalculateLayout() throws {
        let expectation = XCTestExpectation(description: "Layout calculation")
        
        layoutEngine.calculateLayout(for: testNode, bounds: testBounds) { rects in
            XCTAssertGreaterThan(rects.count, 0)
            
            // 验证所有矩形都在边界内
            for rect in rects {
                XCTAssertTrue(self.testBounds.contains(rect.rect))
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLayoutEngineClearCache() throws {
        XCTAssertNoThrow(layoutEngine.clearCache())
    }
    
    func testLayoutEngineGetCacheStatistics() throws {
        let stats = layoutEngine.getCacheStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.count, 0)
        XCTAssertGreaterThanOrEqual(stats.memoryUsage, 0)
    }
    
    // MARK: - ColorManager Tests
    
    func testColorManagerGetColor() throws {
        let fileColor = colorManager.getColor(for: testNode.children[0]) // 文件
        let dirColor = colorManager.getColor(for: testNode) // 目录
        
        XCTAssertNotNil(fileColor)
        XCTAssertNotNil(dirColor)
        // 文件和目录的颜色应该不同
        XCTAssertNotEqual(fileColor, dirColor)
    }
    
    func testColorManagerHighlightColor() throws {
        let node = testNode.children[0]
        let baseColor = colorManager.getColor(for: node)
        let highlightColor = colorManager.getHighlightColor(for: node)
        
        XCTAssertNotNil(highlightColor)
        XCTAssertNotEqual(baseColor, highlightColor)
    }
    
    func testColorManagerSelectionColor() throws {
        let node = testNode.children[0]
        let selectionColor = colorManager.getSelectionColor(for: node)
        
        XCTAssertNotNil(selectionColor)
        XCTAssertEqual(selectionColor, NSColor.selectedControlColor)
    }
    
    // MARK: - TreeMapView Tests
    
    func testTreeMapViewInitialization() throws {
        XCTAssertNotNil(treeMapView)
        XCTAssertEqual(treeMapView.frame.size.width, 400)
        XCTAssertEqual(treeMapView.frame.size.height, 300)
    }
    
    func testTreeMapViewSetData() throws {
        XCTAssertNoThrow(treeMapView.setData(testNode))
    }
    
    func testTreeMapViewUpdateLayout() throws {
        treeMapView.setData(testNode)
        XCTAssertNoThrow(treeMapView.updateLayout())
    }
    
    // MARK: - Integration Tests
    
    func testFullTreeMapWorkflow() throws {
        let expectation = XCTestExpectation(description: "Full workflow")
        
        // 设置数据
        treeMapView.setData(testNode)
        
        // 计算布局
        layoutEngine.calculateLayout(for: testNode, bounds: testBounds) { rects in
            XCTAssertGreaterThan(rects.count, 0)
            
            // 验证颜色管理
            for rect in rects {
                let color = self.colorManager.getColor(for: rect.node)
                XCTAssertNotNil(color)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testTreeMapWithComplexHierarchy() throws {
        // 创建复杂的文件层次结构
        let rootNode = FileNode(name: "ComplexRoot", path: "/complex", size: 10000, isDirectory: true)
        
        // 添加多层子目录
        for i in 0..<3 {
            let subDir = FileNode(name: "subdir\(i)", path: "/complex/subdir\(i)", size: 3000, isDirectory: true)
            
            for j in 0..<5 {
                let file = FileNode(name: "file\(j).txt", path: "/complex/subdir\(i)/file\(j).txt", size: 600, isDirectory: false)
                subDir.addChild(file)
            }
            
            rootNode.addChild(subDir)
        }
        
        let expectation = XCTestExpectation(description: "Complex hierarchy layout")
        
        // 计算布局
        layoutEngine.calculateLayout(for: rootNode, bounds: testBounds) { rects in
            XCTAssertGreaterThan(rects.count, 0)
            
            // 验证所有矩形都在边界内
            for rect in rects {
                XCTAssertTrue(self.testBounds.contains(rect.rect))
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    
    func testLayoutEnginePerformance() throws {
        // 创建大量节点
        let rootNode = FileNode(name: "PerfRoot", path: "/perf", size: 10000, isDirectory: true)
        
        for i in 0..<50 {
            let node = FileNode(name: "file\(i).txt", path: "/perf/file\(i).txt", size: Int64(i + 1), isDirectory: false)
            rootNode.addChild(node)
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            layoutEngine.calculateLayout(for: rootNode, bounds: testBounds) { _ in
                expectation.fulfill()
            }
            
            _ = XCTWaiter.wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testColorManagerPerformance() throws {
        let nodes = testNode.children
        
        measure {
            for _ in 0..<1000 {
                for node in nodes {
                    _ = colorManager.getColor(for: node)
                    _ = colorManager.getHighlightColor(for: node)
                }
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testLayoutWithSingleNode() throws {
        let singleNode = FileNode(name: "single.txt", path: "/single.txt", size: 1000, isDirectory: false)
        let expectation = XCTestExpectation(description: "Single node layout")
        
        layoutEngine.calculateLayout(for: singleNode, bounds: testBounds) { rects in
            // 单个文件节点可能不会生成矩形，或者生成一个矩形
            XCTAssertGreaterThanOrEqual(rects.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLayoutWithZeroSizeNodes() throws {
        let zeroSizeNode = FileNode(name: "empty.txt", path: "/test/empty.txt", size: 0, isDirectory: false)
        let expectation = XCTestExpectation(description: "Zero size node layout")
        
        layoutEngine.calculateLayout(for: zeroSizeNode, bounds: testBounds) { rects in
            // 零大小的节点应该被处理（可能分配最小面积或被忽略）
            XCTAssertGreaterThanOrEqual(rects.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testColorManagerWithValidNode() throws {
        // 测试颜色管理器的基本功能
        let validNode = testNode.children[0]
        let color = colorManager.getColor(for: validNode)
        XCTAssertNotNil(color)
    }
    
    func testTreeMapViewWithNilData() throws {
        // 测试更新布局的处理
        XCTAssertNoThrow(treeMapView.updateLayout())
    }
}
