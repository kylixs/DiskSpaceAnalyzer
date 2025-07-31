import XCTest
@testable import DataModel
@testable import Common

final class DirectoryTreeTests: BaseTestCase {
    
    var directoryTree: DirectoryTree!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        directoryTree = DirectoryTree()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DirectoryTreeTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        directoryTree = nil
        tempDirectory = nil
    }
    
    // MARK: - Basic Tests
    
    func testDirectoryTreeInitialization() throws {
        XCTAssertNotNil(directoryTree)
        XCTAssertNil(directoryTree.root)
        XCTAssertEqual(directoryTree.nodeCount, 0)
        XCTAssertEqual(directoryTree.fileCount, 0)
        XCTAssertEqual(directoryTree.directoryCount, 0)
        XCTAssertEqual(directoryTree.totalSize, 0)
    }
    
    func testSetRoot() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        
        directoryTree.setRoot(rootNode)
        
        // 等待异步操作完成
        let expectation = XCTestExpectation(description: "Root set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(directoryTree.root)
        XCTAssertEqual(directoryTree.root?.name, "root")
        XCTAssertEqual(directoryTree.root?.path, tempDirectory.path)
    }
    
    func testAddNode() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        directoryTree.setRoot(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: tempDirectory.appendingPathComponent("child.txt").path,
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        XCTAssertEqual(rootNode.children.first?.name, "child.txt")
        XCTAssertEqual(childNode.parent?.id, rootNode.id)
    }
    
    func testFindNode() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        directoryTree.setRoot(rootNode)
        
        let childPath = tempDirectory.appendingPathComponent("child.txt").path
        let childNode = FileNode(
            name: "child.txt",
            path: childPath,
            size: 100,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        let foundNode = directoryTree.findNode(at: childPath)
        XCTAssertNotNil(foundNode)
        XCTAssertEqual(foundNode?.path, childPath)
        XCTAssertEqual(foundNode?.name, "child.txt")
        
        let notFoundNode = directoryTree.findNode(at: "/nonexistent/path")
        XCTAssertNil(notFoundNode)
    }
    
    func testRemoveNode() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        directoryTree.setRoot(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: tempDirectory.appendingPathComponent("child.txt").path,
            size: 100,
            isDirectory: false
        )
        directoryTree.addNode(childNode, to: rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        
        directoryTree.removeNode(childNode)
        
        XCTAssertEqual(rootNode.children.count, 0)
        XCTAssertNil(childNode.parent)
    }
    
    func testStatisticsUpdate() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        directoryTree.setRoot(rootNode)
        
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/file2.txt", size: 200, isDirectory: false)
        let subDir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: rootNode)
        directoryTree.addNode(subDir, to: rootNode)
        
        // 等待统计信息更新
        let expectation = XCTestExpectation(description: "Statistics updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(directoryTree.nodeCount, 4) // root + file1 + file2 + subdir
        XCTAssertEqual(directoryTree.fileCount, 2) // file1 + file2
        XCTAssertEqual(directoryTree.directoryCount, 2) // root + subdir
        XCTAssertEqual(directoryTree.totalSize, 300) // 100 + 200
    }
    
    // MARK: - Performance Tests
    
    func testLargeTreePerformance() throws {
        let rootNode = FileNode(
            name: "root",
            path: tempDirectory.path,
            size: 0,
            isDirectory: true
        )
        directoryTree.setRoot(rootNode)
        
        measure {
            // 添加大量节点
            for i in 0..<1000 {
                let node = FileNode(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i * 100),
                    isDirectory: false
                )
                directoryTree.addNode(node, to: rootNode)
            }
        }
        
        XCTAssertEqual(rootNode.children.count, 10000)
    }
}
