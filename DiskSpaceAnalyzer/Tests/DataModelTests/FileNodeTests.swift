import XCTest
@testable import DataModel
@testable import Common

final class FileNodeTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var tempDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileNodeTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - Creation Tests
    
    func testFileNodeCreation() throws {
        let file = FileNode(
            name: "test.txt",
            path: "/path/test.txt",
            size: 1024,
            isDirectory: false
        )
        
        XCTAssertEqual(file.name, "test.txt")
        XCTAssertEqual(file.path, "/path/test.txt")
        XCTAssertEqual(file.size, 1024)
        XCTAssertFalse(file.isDirectory)
        XCTAssertNotNil(file.id)
        XCTAssertNotNil(file.createdAt)
        XCTAssertNil(file.parent)
        XCTAssertTrue(file.children.isEmpty)
    }
    
    func testDirectoryNodeCreation() throws {
        let directory = FileNode(
            name: "testdir",
            path: "/path/testdir",
            size: 0,
            isDirectory: true
        )
        
        XCTAssertEqual(directory.name, "testdir")
        XCTAssertEqual(directory.path, "/path/testdir")
        XCTAssertEqual(directory.size, 0)
        XCTAssertTrue(directory.isDirectory)
        XCTAssertTrue(directory.children.isEmpty)
    }
    
    func testFileNodeFromURL() throws {
        // 创建测试文件
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testData = "Hello, World!".data(using: .utf8)!
        try testData.write(to: testFile)
        
        let fileNode = try FileNode(url: testFile)
        
        XCTAssertEqual(fileNode.name, "test.txt")
        XCTAssertEqual(fileNode.path, testFile.path)
        XCTAssertEqual(fileNode.size, Int64(testData.count))
        XCTAssertFalse(fileNode.isDirectory)
    }
    
    func testDirectoryNodeFromURL() throws {
        // 创建测试目录
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        let dirNode = try FileNode(url: testDir)
        
        XCTAssertEqual(dirNode.name, "testdir")
        XCTAssertEqual(dirNode.path, testDir.path)
        XCTAssertEqual(dirNode.size, 0)
        XCTAssertTrue(dirNode.isDirectory)
    }
    
    // MARK: - Property Tests
    
    func testComputedProperties() throws {
        let file = FileNode(name: "test.txt", path: "/path/test.txt", size: 1024, isDirectory: false)
        let directory = FileNode(name: "testdir", path: "/path/testdir", size: 0, isDirectory: true)
        
        // 文件节点属性
        XCTAssertTrue(file.isLeaf)
        XCTAssertTrue(file.isRoot)
        XCTAssertEqual(file.totalSize, 1024)
        XCTAssertEqual(file.fileCount, 1)
        XCTAssertEqual(file.directoryCount, 0)
        XCTAssertEqual(file.depth, 0)
        
        // 目录节点属性
        XCTAssertTrue(directory.isLeaf)
        XCTAssertTrue(directory.isRoot)
        XCTAssertEqual(directory.totalSize, 0)
        XCTAssertEqual(directory.fileCount, 0)
        XCTAssertEqual(directory.directoryCount, 1)
        XCTAssertEqual(directory.depth, 0)
    }
    
    func testFileExtensionAndType() throws {
        let txtFile = FileNode(name: "document.txt", path: "/path/document.txt", size: 100, isDirectory: false)
        let jpgFile = FileNode(name: "image.jpg", path: "/path/image.jpg", size: 200, isDirectory: false)
        let mp4File = FileNode(name: "video.mp4", path: "/path/video.mp4", size: 300, isDirectory: false)
        let noExtFile = FileNode(name: "README", path: "/path/README", size: 50, isDirectory: false)
        
        XCTAssertEqual(txtFile.fileExtension, "txt")
        XCTAssertEqual(txtFile.fileType, .document)
        XCTAssertTrue(txtFile.isTextFile)
        XCTAssertFalse(txtFile.isImageFile)
        XCTAssertFalse(txtFile.isVideoFile)
        XCTAssertFalse(txtFile.isAudioFile)
        
        XCTAssertEqual(jpgFile.fileExtension, "jpg")
        XCTAssertEqual(jpgFile.fileType, .image)
        XCTAssertFalse(jpgFile.isTextFile)
        XCTAssertTrue(jpgFile.isImageFile)
        XCTAssertFalse(jpgFile.isVideoFile)
        XCTAssertFalse(jpgFile.isAudioFile)
        
        XCTAssertEqual(mp4File.fileExtension, "mp4")
        XCTAssertEqual(mp4File.fileType, .video)
        XCTAssertFalse(mp4File.isTextFile)
        XCTAssertFalse(mp4File.isImageFile)
        XCTAssertTrue(mp4File.isVideoFile)
        XCTAssertFalse(mp4File.isAudioFile)
        
        XCTAssertEqual(noExtFile.fileExtension, "")
        XCTAssertEqual(noExtFile.fileType, .file)
    }
    
    func testPathOperations() throws {
        let file = FileNode(name: "test.txt", path: "/Users/john/Documents/test.txt", size: 100, isDirectory: false)
        
        XCTAssertEqual(file.fileName, "test.txt")
        XCTAssertEqual(file.parentPath, "/Users/john/Documents")
        XCTAssertEqual(file.relativePath(from: "/Users/john"), "Documents/test.txt")
        XCTAssertTrue(file.isDescendant(of: "/Users/john"))
        XCTAssertFalse(file.isDescendant(of: "/Users/jane"))
    }
    
    // MARK: - Parent-Child Relationship Tests
    
    func testAddChild() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1.txt", path: "/parent/child1.txt", size: 100, isDirectory: false)
        let child2 = FileNode(name: "child2.txt", path: "/parent/child2.txt", size: 200, isDirectory: false)
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        XCTAssertEqual(parent.children.count, 2)
        XCTAssertTrue(parent.children.contains(child1))
        XCTAssertTrue(parent.children.contains(child2))
        XCTAssertEqual(child1.parent?.id, parent.id)
        XCTAssertEqual(child2.parent?.id, parent.id)
        XCTAssertFalse(parent.isLeaf)
        XCTAssertFalse(child1.isRoot)
        XCTAssertFalse(child2.isRoot)
    }
    
    func testRemoveChild() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1.txt", path: "/parent/child1.txt", size: 100, isDirectory: false)
        let child2 = FileNode(name: "child2.txt", path: "/parent/child2.txt", size: 200, isDirectory: false)
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        parent.removeChild(child1)
        
        XCTAssertEqual(parent.children.count, 1)
        XCTAssertFalse(parent.children.contains(child1))
        XCTAssertTrue(parent.children.contains(child2))
        XCTAssertNil(child1.parent)
        XCTAssertEqual(child2.parent?.id, parent.id)
    }
    
    func testRemoveFromParent() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child = FileNode(name: "child.txt", path: "/parent/child.txt", size: 100, isDirectory: false)
        
        parent.addChild(child)
        XCTAssertEqual(parent.children.count, 1)
        XCTAssertEqual(child.parent?.id, parent.id)
        
        child.removeFromParent()
        
        XCTAssertEqual(parent.children.count, 0)
        XCTAssertNil(child.parent)
        XCTAssertTrue(child.isRoot)
    }
    
    func testHierarchyCalculations() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        let level1 = FileNode(name: "level1", path: "/level1", size: 0, isDirectory: true)
        let level2 = FileNode(name: "level2", path: "/level1/level2", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/level1/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/level1/level2/file2.txt", size: 200, isDirectory: false)
        
        root.addChild(level1)
        level1.addChild(level2)
        level1.addChild(file1)
        level2.addChild(file2)
        
        // 测试深度计算
        XCTAssertEqual(root.depth, 0)
        XCTAssertEqual(level1.depth, 1)
        XCTAssertEqual(level2.depth, 2)
        XCTAssertEqual(file1.depth, 2)
        XCTAssertEqual(file2.depth, 3)
        
        // 测试总大小计算
        XCTAssertEqual(root.totalSize, 300)
        XCTAssertEqual(level1.totalSize, 300)
        XCTAssertEqual(level2.totalSize, 200)
        XCTAssertEqual(file1.totalSize, 100)
        XCTAssertEqual(file2.totalSize, 200)
        
        // 测试文件和目录计数
        XCTAssertEqual(root.fileCount, 2)
        XCTAssertEqual(root.directoryCount, 3)
        XCTAssertEqual(level1.fileCount, 2)
        XCTAssertEqual(level1.directoryCount, 2)
        XCTAssertEqual(level2.fileCount, 1)
        XCTAssertEqual(level2.directoryCount, 1)
    }
    
    // MARK: - Sorting Tests
    
    func testSortedChildren() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let file1 = FileNode(name: "small.txt", path: "/parent/small.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "large.txt", path: "/parent/large.txt", size: 1000, isDirectory: false)
        let file3 = FileNode(name: "medium.txt", path: "/parent/medium.txt", size: 500, isDirectory: false)
        let dir1 = FileNode(name: "directory", path: "/parent/directory", size: 0, isDirectory: true)
        
        parent.addChild(file1)
        parent.addChild(file2)
        parent.addChild(file3)
        parent.addChild(dir1)
        
        // 按大小排序（降序）
        let sortedBySize = parent.sortedChildren(by: .size, ascending: false)
        XCTAssertEqual(sortedBySize[0].size, 1000) // large.txt
        XCTAssertEqual(sortedBySize[1].size, 500)  // medium.txt
        XCTAssertEqual(sortedBySize[2].size, 100)  // small.txt
        XCTAssertEqual(sortedBySize[3].size, 0)    // directory
        
        // 按名称排序（升序）
        let sortedByName = parent.sortedChildren(by: .name, ascending: true)
        XCTAssertEqual(sortedByName[0].name, "directory")
        XCTAssertEqual(sortedByName[1].name, "large.txt")
        XCTAssertEqual(sortedByName[2].name, "medium.txt")
        XCTAssertEqual(sortedByName[3].name, "small.txt")
        
        // 按类型排序（目录优先）
        let sortedByType = parent.sortedChildren(by: .type, ascending: true)
        XCTAssertTrue(sortedByType[0].isDirectory) // directory first
        XCTAssertFalse(sortedByType[1].isDirectory)
        XCTAssertFalse(sortedByType[2].isDirectory)
        XCTAssertFalse(sortedByType[3].isDirectory)
    }
    
    // MARK: - Search Tests
    
    func testFindChild() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1.txt", path: "/parent/child1.txt", size: 100, isDirectory: false)
        let child2 = FileNode(name: "child2.txt", path: "/parent/child2.txt", size: 200, isDirectory: false)
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        XCTAssertEqual(parent.findChild(named: "child1.txt")?.id, child1.id)
        XCTAssertEqual(parent.findChild(named: "child2.txt")?.id, child2.id)
        XCTAssertNil(parent.findChild(named: "nonexistent.txt"))
        
        XCTAssertEqual(parent.findChild(by: child1.id)?.id, child1.id)
        XCTAssertEqual(parent.findChild(by: child2.id)?.id, child2.id)
        XCTAssertNil(parent.findChild(by: UUID()))
    }
    
    func testFindDescendant() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        let level1 = FileNode(name: "level1", path: "/level1", size: 0, isDirectory: true)
        let file = FileNode(name: "file.txt", path: "/level1/file.txt", size: 100, isDirectory: false)
        
        root.addChild(level1)
        level1.addChild(file)
        
        XCTAssertEqual(root.findDescendant(at: "/level1")?.id, level1.id)
        XCTAssertEqual(root.findDescendant(at: "/level1/file.txt")?.id, file.id)
        XCTAssertNil(root.findDescendant(at: "/nonexistent"))
        
        XCTAssertEqual(root.findDescendant(by: file.id)?.id, file.id)
        XCTAssertNil(root.findDescendant(by: UUID()))
    }
    
    // MARK: - Traversal Tests
    
    func testTraverseDepthFirst() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        let dir1 = FileNode(name: "dir1", path: "/dir1", size: 0, isDirectory: true)
        let dir2 = FileNode(name: "dir2", path: "/dir2", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/dir1/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/dir2/file2.txt", size: 200, isDirectory: false)
        
        root.addChild(dir1)
        root.addChild(dir2)
        dir1.addChild(file1)
        dir2.addChild(file2)
        
        var visitedNodes: [FileNode] = []
        root.traverseDepthFirst { node in
            visitedNodes.append(node)
        }
        
        XCTAssertEqual(visitedNodes.count, 5)
        XCTAssertEqual(visitedNodes[0].id, root.id)
        // 深度优先遍历的具体顺序取决于实现
        XCTAssertTrue(visitedNodes.contains { $0.id == dir1.id })
        XCTAssertTrue(visitedNodes.contains { $0.id == dir2.id })
        XCTAssertTrue(visitedNodes.contains { $0.id == file1.id })
        XCTAssertTrue(visitedNodes.contains { $0.id == file2.id })
    }
    
    func testTraverseBreadthFirst() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        let dir1 = FileNode(name: "dir1", path: "/dir1", size: 0, isDirectory: true)
        let dir2 = FileNode(name: "dir2", path: "/dir2", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/dir1/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/dir2/file2.txt", size: 200, isDirectory: false)
        
        root.addChild(dir1)
        root.addChild(dir2)
        dir1.addChild(file1)
        dir2.addChild(file2)
        
        var visitedNodes: [FileNode] = []
        root.traverseBreadthFirst { node in
            visitedNodes.append(node)
        }
        
        XCTAssertEqual(visitedNodes.count, 5)
        XCTAssertEqual(visitedNodes[0].id, root.id)
        // 广度优先遍历：先访问同级节点
        let level1Indices = visitedNodes.enumerated().compactMap { index, node in
            (node.id == dir1.id || node.id == dir2.id) ? index : nil
        }
        let level2Indices = visitedNodes.enumerated().compactMap { index, node in
            (node.id == file1.id || node.id == file2.id) ? index : nil
        }
        
        XCTAssertTrue(level1Indices.allSatisfy { $0 < level2Indices.min()! })
    }
    
    // MARK: - Codable Tests
    
    func testFileNodeCodable() throws {
        let original = FileNode(name: "test.txt", path: "/path/test.txt", size: 1024, isDirectory: false)
        original.modifiedAt = Date(timeIntervalSince1970: 1640995200)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FileNode.self, from: data)
        
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.path, original.path)
        XCTAssertEqual(decoded.size, original.size)
        XCTAssertEqual(decoded.isDirectory, original.isDirectory)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.modifiedAt?.timeIntervalSince1970, original.modifiedAt?.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testLargeHierarchyPerformance() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        
        // 创建大型层次结构
        measure {
            for i in 0..<100 {
                let dir = FileNode(name: "dir\(i)", path: "/dir\(i)", size: 0, isDirectory: true)
                root.addChild(dir)
                
                for j in 0..<50 {
                    let file = FileNode(name: "file\(j).txt", path: "/dir\(i)/file\(j).txt", size: Int64(j * 100), isDirectory: false)
                    dir.addChild(file)
                }
            }
        }
        
        // 验证结构
        XCTAssertEqual(root.children.count, 100)
        XCTAssertEqual(root.fileCount, 5000)
        XCTAssertEqual(root.directoryCount, 101) // root + 100 dirs
    }
    
    func testTraversalPerformance() throws {
        let root = FileNode(name: "root", path: "/", size: 0, isDirectory: true)
        
        // 创建测试层次结构
        for i in 0..<50 {
            let dir = FileNode(name: "dir\(i)", path: "/dir\(i)", size: 0, isDirectory: true)
            root.addChild(dir)
            
            for j in 0..<20 {
                let file = FileNode(name: "file\(j).txt", path: "/dir\(i)/file\(j).txt", size: Int64(j * 100), isDirectory: false)
                dir.addChild(file)
            }
        }
        
        measure {
            var count = 0
            root.traverseDepthFirst { _ in
                count += 1
            }
            XCTAssertEqual(count, 1051) // 1 root + 50 dirs + 1000 files
        }
    }
}
