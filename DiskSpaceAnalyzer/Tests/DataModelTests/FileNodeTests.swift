import XCTest
@testable import DataModel
@testable import Common

final class FileNodeTests: BaseTestCase {
    
    var tempDirectory: URL!
    
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
        tempDirectory = nil
    }
    
    // MARK: - Basic Tests
    
    func testFileNodeInitialization() throws {
        let fileNode = FileNode(
            name: "test.txt",
            path: "/path/to/test.txt",
            size: 1024,
            isDirectory: false
        )
        
        XCTAssertEqual(fileNode.name, "test.txt")
        XCTAssertEqual(fileNode.path, "/path/to/test.txt")
        XCTAssertEqual(fileNode.size, 1024)
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertNotNil(fileNode.id)
        XCTAssertNotNil(fileNode.createdAt)
        XCTAssertNotNil(fileNode.modifiedAt)
    }
    
    func testDirectoryNodeInitialization() throws {
        let dirNode = FileNode(
            name: "testdir",
            path: "/path/to/testdir",
            size: 0,
            isDirectory: true
        )
        
        XCTAssertEqual(dirNode.name, "testdir")
        XCTAssertEqual(dirNode.path, "/path/to/testdir")
        XCTAssertEqual(dirNode.size, 0)
        XCTAssertTrue(dirNode.isDirectory)
        XCTAssertEqual(dirNode.children.count, 0)
    }
    
    // MARK: - Parent-Child Relationship Tests
    
    func testAddChild() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child = FileNode(name: "child.txt", path: "/parent/child.txt", size: 100, isDirectory: false)
        
        parent.addChild(child)
        
        XCTAssertEqual(parent.children.count, 1)
        XCTAssertEqual(parent.children.first?.id, child.id)
        XCTAssertEqual(child.parent?.id, parent.id)
    }
    
    func testRemoveChild() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child = FileNode(name: "child.txt", path: "/parent/child.txt", size: 100, isDirectory: false)
        
        parent.addChild(child)
        XCTAssertEqual(parent.children.count, 1)
        
        parent.removeChild(child)
        XCTAssertEqual(parent.children.count, 0)
        XCTAssertNil(child.parent)
    }
    
    func testFindChildByName() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1.txt", path: "/parent/child1.txt", size: 100, isDirectory: false)
        let child2 = FileNode(name: "child2.txt", path: "/parent/child2.txt", size: 200, isDirectory: false)
        
        parent.addChild(child1)
        parent.addChild(child2)
        
        XCTAssertEqual(parent.findChild(named: "child1.txt")?.id, child1.id)
        XCTAssertEqual(parent.findChild(named: "child2.txt")?.id, child2.id)
        XCTAssertNil(parent.findChild(named: "nonexistent.txt"))
    }
    
    func testFindChildByPath() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child = FileNode(name: "child.txt", path: "/parent/child.txt", size: 100, isDirectory: false)
        
        parent.addChild(child)
        
        XCTAssertEqual(parent.findChild(at: "/parent/child.txt")?.id, child.id)
        XCTAssertNil(parent.findChild(at: "/nonexistent/path"))
    }
    
    // MARK: - Size Calculation Tests
    
    func testTotalSizeCalculation() throws {
        let root = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/file2.txt", size: 200, isDirectory: false)
        let subdir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        let file3 = FileNode(name: "file3.txt", path: "/root/subdir/file3.txt", size: 300, isDirectory: false)
        
        root.addChild(file1)
        root.addChild(file2)
        root.addChild(subdir)
        subdir.addChild(file3)
        
        XCTAssertEqual(root.totalSize, 600) // 100 + 200 + 300
        XCTAssertEqual(subdir.totalSize, 300)
        XCTAssertEqual(file1.totalSize, 100)
    }
    
    func testFileAndDirectoryCount() throws {
        let root = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        let file1 = FileNode(name: "file1.txt", path: "/root/file1.txt", size: 100, isDirectory: false)
        let file2 = FileNode(name: "file2.txt", path: "/root/file2.txt", size: 200, isDirectory: false)
        let subdir = FileNode(name: "subdir", path: "/root/subdir", size: 0, isDirectory: true)
        let file3 = FileNode(name: "file3.txt", path: "/root/subdir/file3.txt", size: 300, isDirectory: false)
        
        root.addChild(file1)
        root.addChild(file2)
        root.addChild(subdir)
        subdir.addChild(file3)
        
        XCTAssertEqual(root.fileCount, 3) // file1, file2, file3
        XCTAssertEqual(root.directoryCount, 2) // root, subdir
        XCTAssertEqual(subdir.fileCount, 1) // file3
        XCTAssertEqual(subdir.directoryCount, 1) // subdir itself
    }
    
    // MARK: - Serialization Tests
    
    func testSerialization() throws {
        let original = FileNode(
            name: "test.txt",
            path: "/path/test.txt",
            size: 1024,
            isDirectory: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FileNode.self, from: data)
        
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.path, original.path)
        XCTAssertEqual(decoded.size, original.size)
        XCTAssertEqual(decoded.isDirectory, original.isDirectory)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.modifiedAt.timeIntervalSince1970, original.modifiedAt.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testLargeTreePerformance() throws {
        let root = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        
        // 创建大量子节点
        for i in 0..<1000 {
            let child = FileNode(
                name: "file\(i).txt",
                path: "/root/file\(i).txt",
                size: Int64(i * 100),
                isDirectory: false
            )
            root.addChild(child)
        }
        
        measure {
            _ = root.totalSize
        }
        
        XCTAssertEqual(root.children.count, 1000)
        XCTAssertEqual(root.fileCount, 1000)
    }
}
