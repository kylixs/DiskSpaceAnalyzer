import XCTest
@testable import Core

class DirectoryTreeTests: XCTestCase {
    
    var directoryTree: DirectoryTree!
    var rootNode: FileNode!
    
    override func setUp() {
        super.setUp()
        
        directoryTree = DirectoryTree()
        rootNode = FileNode(
            name: "root",
            path: "/root",
            size: 0,
            isDirectory: true
        )
    }
    
    override func tearDown() {
        directoryTree = nil
        rootNode = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNil(directoryTree.rootNode)
    }
    
    func testInitializationWithRootNode() {
        let tree = DirectoryTree(rootNode: rootNode)
        XCTAssertNotNil(tree.rootNode)
        XCTAssertEqual(tree.rootNode?.id, rootNode.id)
    }
    
    // MARK: - Root Node Tests
    
    func testSetRootNode() {
        directoryTree.setRootNode(rootNode)
        
        XCTAssertNotNil(directoryTree.rootNode)
        XCTAssertEqual(directoryTree.rootNode?.id, rootNode.id)
    }
    
    // MARK: - Node Management Tests
    
    func testAddNode() {
        directoryTree.setRootNode(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: "/root/child.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        XCTAssertEqual(rootNode.children.first?.id, childNode.id)
        XCTAssertEqual(childNode.parent?.id, rootNode.id)
    }
    
    func testRemoveNode() {
        directoryTree.setRootNode(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: "/root/child.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        directoryTree.removeNode(childNode)
        
        XCTAssertEqual(rootNode.children.count, 0)
        XCTAssertNil(childNode.parent)
    }
    
    // MARK: - Search Tests
    
    func testFindNodeByPath() {
        directoryTree.setRootNode(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: "/root/child.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        let foundNode = directoryTree.findNode(at: "/root/child.txt")
        XCTAssertNotNil(foundNode)
        XCTAssertEqual(foundNode?.id, childNode.id)
        
        let notFoundNode = directoryTree.findNode(at: "/nonexistent")
        XCTAssertNil(notFoundNode)
    }
    
    func testFindNodeById() {
        directoryTree.setRootNode(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: "/root/child.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        let foundNode = directoryTree.findNode(by: childNode.id)
        XCTAssertNotNil(foundNode)
        XCTAssertEqual(foundNode?.id, childNode.id)
        
        let notFoundNode = directoryTree.findNode(by: UUID())
        XCTAssertNil(notFoundNode)
    }
    
    // MARK: - Query Tests
    
    func testGetNodesBySize() {
        directoryTree.setRootNode(rootNode)
        
        let smallFile = FileNode(name: "small.txt", path: "/root/small.txt", size: 100, isDirectory: false)
        let largeFile = FileNode(name: "large.txt", path: "/root/large.txt", size: 1000, isDirectory: false)
        let mediumFile = FileNode(name: "medium.txt", path: "/root/medium.txt", size: 500, isDirectory: false)
        
        directoryTree.addNode(smallFile, to: rootNode)
        directoryTree.addNode(largeFile, to: rootNode)
        directoryTree.addNode(mediumFile, to: rootNode)
        
        let nodesBySize = directoryTree.getNodesBySize(limit: 3)
        
        XCTAssertEqual(nodesBySize.count, 3)
        XCTAssertEqual(nodesBySize[0].name, "large.txt")
        XCTAssertEqual(nodesBySize[1].name, "medium.txt")
        XCTAssertEqual(nodesBySize[2].name, "small.txt")
    }
    
    func testGetNodesByType() {
        directoryTree.setRootNode(rootNode)
        
        let file = FileNode(name: "file.txt", path: "/root/file.txt", size: 100, isDirectory: false)
        let directory = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        
        directoryTree.addNode(file, to: rootNode)
        directoryTree.addNode(directory, to: rootNode)
        
        let files = directoryTree.getNodes(ofType: .regularFile)
        let directories = directoryTree.getNodes(ofType: .directory)
        
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.name, "file.txt")
        
        XCTAssertEqual(directories.count, 2) // root + subdir
        XCTAssertTrue(directories.contains { $0.name == "root" })
        XCTAssertTrue(directories.contains { $0.name == "subdir" })
    }
    
    // MARK: - Traversal Tests
    
    func testDepthFirstTraversal() {
        directoryTree.setRootNode(rootNode)
        
        let subDir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/subdir/file2.txt", size: 200, isDirectory: false)
        
        directoryTree.addNode(subDir, to: rootNode)
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: subDir)
        
        var visitedNodes: [String] = []
        directoryTree.traverseDepthFirst { node in
            visitedNodes.append(node.name)
            return true
        }
        
        XCTAssertEqual(visitedNodes, ["root", "subdir", "file2.txt", "file1.txt"])
    }
    
    func testBreadthFirstTraversal() {
        directoryTree.setRootNode(rootNode)
        
        let subDir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/subdir/file2.txt", size: 200, isDirectory: false)
        
        directoryTree.addNode(subDir, to: rootNode)
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: subDir)
        
        var visitedNodes: [String] = []
        directoryTree.traverseBreadthFirst { node in
            visitedNodes.append(node.name)
            return true
        }
        
        XCTAssertEqual(visitedNodes, ["root", "subdir", "file1.txt", "file2.txt"])
    }
    
    func testTraversalEarlyTermination() {
        directoryTree.setRootNode(rootNode)
        
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/file2.txt", size: 200, isDirectory: false)
        
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: rootNode)
        
        var visitedNodes: [String] = []
        directoryTree.traverseDepthFirst { node in
            visitedNodes.append(node.name)
            return node.name != "file1.txt" // Stop after visiting file1.txt
        }
        
        XCTAssertEqual(visitedNodes, ["root", "file1.txt"])
    }
    
    // MARK: - Statistics Tests
    
    func testGetStatistics() {
        directoryTree.setRootNode(rootNode)
        
        let subDir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/subdir/file2.txt", size: 200, isDirectory: false)
        
        directoryTree.addNode(subDir, to: rootNode)
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: subDir)
        
        let statistics = directoryTree.getStatistics()
        
        XCTAssertEqual(statistics.totalFiles, 2)
        XCTAssertEqual(statistics.totalDirectories, 2) // root + subdir
        XCTAssertEqual(statistics.totalSize, 300) // 100 + 200
        XCTAssertEqual(statistics.maxDepth, 2) // file2.txt is at depth 2
    }
    
    // MARK: - Clear Tests
    
    func testClear() {
        directoryTree.setRootNode(rootNode)
        
        let childNode = FileNode(
            name: "child.txt",
            path: "/root/child.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryTree.addNode(childNode, to: rootNode)
        
        XCTAssertNotNil(directoryTree.rootNode)
        XCTAssertNotNil(directoryTree.findNode(at: "/root/child.txt"))
        
        directoryTree.clear()
        
        XCTAssertNil(directoryTree.rootNode)
        XCTAssertNil(directoryTree.findNode(at: "/root/child.txt"))
    }
    
    // MARK: - Batch Operations Tests
    
    func testPerformBatchOperations() {
        directoryTree.setRootNode(rootNode)
        
        let expectation = XCTestExpectation(description: "Batch operations completed")
        
        directoryTree.performBatchOperations {
            for i in 0..<100 {
                let file = FileNode(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i * 100),
                    isDirectory: false
                )
                self.directoryTree.addNode(file, to: self.rootNode)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(rootNode.children.count, 100)
    }
    
    // MARK: - Search Tests
    
    func testSearchNodes() {
        directoryTree.setRootNode(rootNode)
        
        let txtFile = FileNode(name: "document.txt", path: "/root/document.txt", size: 100, isDirectory: false)
        let pdfFile = FileNode(name: "document.pdf", path: "/root/document.pdf", size: 200, isDirectory: false)
        let jpgFile = FileNode(name: "image.jpg", path: "/root/image.jpg", size: 300, isDirectory: false)
        
        directoryTree.addNode(txtFile, to: rootNode)
        directoryTree.addNode(pdfFile, to: rootNode)
        directoryTree.addNode(jpgFile, to: rootNode)
        
        let txtFiles = directoryTree.searchNodes { $0.name.hasSuffix(".txt") }
        let documentFiles = directoryTree.searchNodes { $0.name.hasPrefix("document") }
        
        XCTAssertEqual(txtFiles.count, 1)
        XCTAssertEqual(txtFiles.first?.name, "document.txt")
        
        XCTAssertEqual(documentFiles.count, 2)
        XCTAssertTrue(documentFiles.contains { $0.name == "document.txt" })
        XCTAssertTrue(documentFiles.contains { $0.name == "document.pdf" })
    }
    
    func testGetChildren() {
        directoryTree.setRootNode(rootNode)
        
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/file2.txt", size: 200, isDirectory: false)
        
        directoryTree.addNode(file1, to: rootNode)
        directoryTree.addNode(file2, to: rootNode)
        
        let children = directoryTree.getChildren(at: "/root")
        
        XCTAssertEqual(children.count, 2)
        XCTAssertTrue(children.contains { $0.name == "file1.txt" })
        XCTAssertTrue(children.contains { $0.name == "file2.txt" })
        
        let nonExistentChildren = directoryTree.getChildren(at: "/nonexistent")
        XCTAssertEqual(nonExistentChildren.count, 0)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        directoryTree.setRootNode(rootNode)
        
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 10
        
        // 并发添加节点
        for i in 0..<10 {
            DispatchQueue.global().async {
                let file = FileNode(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i * 100),
                    isDirectory: false
                )
                self.directoryTree.addNode(file, to: self.rootNode)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // 验证所有节点都被添加
        XCTAssertEqual(rootNode.children.count, 10)
        
        // 验证可以找到所有节点
        for i in 0..<10 {
            let foundNode = directoryTree.findNode(at: "/root/file\(i).txt")
            XCTAssertNotNil(foundNode)
        }
    }
    
    // MARK: - Performance Tests
    
    func testLargeTreePerformance() {
        directoryTree.setRootNode(rootNode)
        
        measure {
            for i in 0..<1000 {
                let file = FileNode(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i),
                    isDirectory: false
                )
                directoryTree.addNode(file, to: rootNode)
            }
        }
    }
    
    func testSearchPerformance() {
        directoryTree.setRootNode(rootNode)
        
        // 创建大量节点
        for i in 0..<1000 {
            let file = FileNode(
                name: "file\(i).txt",
                path: "/root/file\(i).txt",
                size: Int64(i),
                isDirectory: false
            )
            directoryTree.addNode(file, to: rootNode)
        }
        
        measure {
            _ = directoryTree.findNode(at: "/root/file500.txt")
        }
    }
}
