import XCTest
@testable import Core

class TreeMapVisualizationTests: XCTestCase {
    
    func testSquarifiedAlgorithm() {
        let algorithm = SquarifiedAlgorithm()
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // 创建测试节点
        let node1 = FileNode(name: "file1", path: "/file1", size: 100, isDirectory: false, createdDate: Date(), modifiedDate: Date(), permissions: FilePermissions())
        let node2 = FileNode(name: "file2", path: "/file2", size: 200, isDirectory: false, createdDate: Date(), modifiedDate: Date(), permissions: FilePermissions())
        
        let nodes = [node1, node2]
        let rects = algorithm.calculateLayout(nodes: nodes, bounds: bounds)
        
        XCTAssertEqual(rects.count, 2)
        XCTAssertTrue(rects.allSatisfy { bounds.contains($0) })
    }
    
    func testColorManager() {
        let colorManager = ColorManager()
        let fileNode = FileNode(name: "test", path: "/test", size: 100, isDirectory: false, createdDate: Date(), modifiedDate: Date(), permissions: FilePermissions())
        
        let color = colorManager.getColor(for: fileNode)
        XCTAssertNotNil(color)
    }
}
