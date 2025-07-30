import XCTest
@testable import DiskSpaceAnalyzerCore

class FileNodeTests: XCTestCase {
    
    var fileNode: FileNode!
    var directoryNode: FileNode!
    
    override func setUp() {
        super.setUp()
        
        fileNode = FileNode(
            name: "test.txt",
            path: "/Users/test/test.txt",
            size: 1024,
            isDirectory: false
        )
        
        directoryNode = FileNode(
            name: "Documents",
            path: "/Users/test/Documents",
            size: 0,
            isDirectory: true
        )
    }
    
    override func tearDown() {
        fileNode = nil
        directoryNode = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testFileNodeInitialization() {
        XCTAssertEqual(fileNode.name, "test.txt")
        XCTAssertEqual(fileNode.path, "/Users/test/test.txt")
        XCTAssertEqual(fileNode.size, 1024)
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertNotNil(fileNode.id)
    }
    
    func testDirectoryNodeInitialization() {
        XCTAssertEqual(directoryNode.name, "Documents")
        XCTAssertEqual(directoryNode.path, "/Users/test/Documents")
        XCTAssertEqual(directoryNode.size, 0)
        XCTAssertTrue(directoryNode.isDirectory)
        XCTAssertNotNil(directoryNode.id)
    }
    
    // MARK: - Parent-Child Relationship Tests
    
    func testAddChild() {
        directoryNode.addChild(fileNode)
        
        XCTAssertEqual(directoryNode.children.count, 1)
        XCTAssertEqual(directoryNode.children.first?.id, fileNode.id)
        XCTAssertEqual(fileNode.parent?.id, directoryNode.id)
    }
    
    func testRemoveChild() {
        directoryNode.addChild(fileNode)
        directoryNode.removeChild(fileNode)
        
        XCTAssertEqual(directoryNode.children.count, 0)
        XCTAssertNil(fileNode.parent)
    }
    
    func testFindChild() {
        directoryNode.addChild(fileNode)
        
        let foundChild = directoryNode.findChild(named: "test.txt")
        XCTAssertNotNil(foundChild)
        XCTAssertEqual(foundChild?.id, fileNode.id)
        
        let notFoundChild = directoryNode.findChild(named: "nonexistent.txt")
        XCTAssertNil(notFoundChild)
    }
    
    // MARK: - Computed Properties Tests
    
    func testTotalSizeForFile() {
        XCTAssertEqual(fileNode.totalSize, 1024)
    }
    
    func testTotalSizeForDirectory() {
        let file1 = FileNode(name: "file1.txt", path: "/test/file1.txt", size: 500, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/test/file2.txt", size: 300, isDirectory: false)
        
        directoryNode.addChild(file1)
        directoryNode.addChild(file2)
        
        XCTAssertEqual(directoryNode.totalSize, 800) // 0 + 500 + 300
    }
    
    func testDepth() {
        XCTAssertEqual(directoryNode.depth, 0) // Root level
        
        directoryNode.addChild(fileNode)
        XCTAssertEqual(fileNode.depth, 1)
        
        let subDirectory = FileNode(name: "SubDir", path: "/test/SubDir", size: 0, isDirectory: true)
        fileNode.addChild(subDirectory)
        XCTAssertEqual(subDirectory.depth, 2)
    }
    
    func testChildCount() {
        XCTAssertEqual(directoryNode.childCount, 0)
        
        directoryNode.addChild(fileNode)
        XCTAssertEqual(directoryNode.childCount, 1)
    }
    
    func testFileCount() {
        XCTAssertEqual(fileNode.fileCount, 1)
        XCTAssertEqual(directoryNode.fileCount, 0)
        
        directoryNode.addChild(fileNode)
        XCTAssertEqual(directoryNode.fileCount, 1)
    }
    
    func testDirectoryCount() {
        XCTAssertEqual(fileNode.directoryCount, 0)
        XCTAssertEqual(directoryNode.directoryCount, 1)
        
        let subDirectory = FileNode(name: "SubDir", path: "/test/SubDir", size: 0, isDirectory: true)
        directoryNode.addChild(subDirectory)
        XCTAssertEqual(directoryNode.directoryCount, 2)
    }
    
    // MARK: - Path Tests
    
    func testGetFullPath() {
        let rootDir = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        let subDir = FileNode(name: "sub", path: "/root/sub", size: 0, isDirectory: true)
        let file = FileNode(name: "file.txt", path: "/root/sub/file.txt", size: 100, isDirectory: false)
        
        rootDir.addChild(subDir)
        subDir.addChild(file)
        
        XCTAssertEqual(file.getFullPath(), "/root/sub/file.txt")
    }
    
    // MARK: - Sorting Tests
    
    func testSortChildrenBySize() {
        let file1 = FileNode(name: "small.txt", path: "/test/small.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "large.txt", path: "/test/large.txt", size: 1000, isDirectory: false)
        let file3 = FileNode(name: "medium.txt", path: "/test/medium.txt", size: 500, isDirectory: false)
        
        directoryNode.addChild(file1)
        directoryNode.addChild(file2)
        directoryNode.addChild(file3)
        
        directoryNode.sortChildrenBySize(ascending: false)
        
        XCTAssertEqual(directoryNode.children[0].name, "large.txt")
        XCTAssertEqual(directoryNode.children[1].name, "medium.txt")
        XCTAssertEqual(directoryNode.children[2].name, "small.txt")
    }
    
    func testSortChildrenByName() {
        let fileC = FileNode(name: "c.txt", path: "/test/c.txt", size: 100, isDirectory: false)
        let fileA = FileNode(name: "a.txt", path: "/test/a.txt", size: 100, isDirectory: false)
        let fileB = FileNode(name: "b.txt", path: "/test/b.txt", size: 100, isDirectory: false)
        
        directoryNode.addChild(fileC)
        directoryNode.addChild(fileA)
        directoryNode.addChild(fileB)
        
        directoryNode.sortChildrenByName(ascending: true)
        
        XCTAssertEqual(directoryNode.children[0].name, "a.txt")
        XCTAssertEqual(directoryNode.children[1].name, "b.txt")
        XCTAssertEqual(directoryNode.children[2].name, "c.txt")
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        // 创建一个包含子节点的目录
        let subFile = FileNode(name: "sub.txt", path: "/test/sub.txt", size: 200, isDirectory: false)
        directoryNode.addChild(subFile)
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(directoryNode)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedNode = try decoder.decode(FileNode.self, from: data)
        
        // 验证
        XCTAssertEqual(decodedNode.name, directoryNode.name)
        XCTAssertEqual(decodedNode.path, directoryNode.path)
        XCTAssertEqual(decodedNode.size, directoryNode.size)
        XCTAssertEqual(decodedNode.isDirectory, directoryNode.isDirectory)
        XCTAssertEqual(decodedNode.children.count, 1)
        XCTAssertEqual(decodedNode.children.first?.name, "sub.txt")
        
        // 验证父子关系重建
        XCTAssertNotNil(decodedNode.children.first?.parent)
        XCTAssertEqual(decodedNode.children.first?.parent?.id, decodedNode.id)
    }
    
    // MARK: - Equality Tests
    
    func testEquality() {
        let anotherFileNode = FileNode(
            name: "another.txt",
            path: "/test/another.txt",
            size: 2048,
            isDirectory: false
        )
        
        XCTAssertNotEqual(fileNode, anotherFileNode)
        XCTAssertEqual(fileNode, fileNode)
    }
    
    // MARK: - Performance Tests
    
    func testTotalSizePerformance() {
        // 创建一个深层目录结构
        var currentDir = directoryNode
        
        for i in 0..<100 {
            let subDir = FileNode(name: "dir\(i)", path: "/test/dir\(i)", size: 0, isDirectory: true)
            let file = FileNode(name: "file\(i).txt", path: "/test/file\(i).txt", size: Int64(i * 100), isDirectory: false)
            
            currentDir!.addChild(subDir)
            currentDir!.addChild(file)
            currentDir = subDir
        }
        
        measure {
            _ = directoryNode.totalSize
        }
    }
    
    func testCacheInvalidation() {
        let file1 = FileNode(name: "file1.txt", path: "/test/file1.txt", size: 500, isDirectory: false)
        directoryNode.addChild(file1)
        
        let initialSize = directoryNode.totalSize
        XCTAssertEqual(initialSize, 500)
        
        // 添加另一个文件，缓存应该失效
        let file2 = FileNode(name: "file2.txt", path: "/test/file2.txt", size: 300, isDirectory: false)
        directoryNode.addChild(file2)
        
        let newSize = directoryNode.totalSize
        XCTAssertEqual(newSize, 800)
    }
}
