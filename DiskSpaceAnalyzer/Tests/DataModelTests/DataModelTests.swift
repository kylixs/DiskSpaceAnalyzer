import XCTest
@testable import Core

final class DataModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var tempDirectory: URL!
    var testSession: ScanSession!
    var testTree: DirectoryTree!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // 创建临时测试目录
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataModelTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // 创建测试会话
        testSession = ScanSession(scanPath: tempDirectory.path, name: "Test Session")
        
        // 创建测试目录树
        testTree = DirectoryTree()
    }
    
    override func tearDownWithError() throws {
        // 清理临时目录
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        
        testSession = nil
        testTree = nil
    }
    
    // MARK: - FileNode Tests
    
    func testFileNodeCreation() throws {
        // 测试文件节点创建
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
        XCTAssertEqual(file.totalSize, 1024)
        XCTAssertTrue(file.isLeaf)
        XCTAssertTrue(file.isRoot)
        
        // 测试目录节点创建
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
        XCTAssertEqual(directory.totalSize, 0)
        XCTAssertTrue(directory.isLeaf)
        XCTAssertTrue(directory.isRoot)
    }
    
    func testFileNodeParentChildRelationship() throws {
        let parent = FileNode(name: "parent", path: "/parent", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1.txt", path: "/parent/child1.txt", size: 100, isDirectory: false)
        let child2 = FileNode(name: "child2.txt", path: "/parent/child2.txt", size: 200, isDirectory: false)
        
        // 添加子节点
        parent.addChild(child1)
        parent.addChild(child2)
        
        // 验证父子关系
        XCTAssertEqual(parent.children.count, 2)
        XCTAssertEqual(child1.parent?.id, parent.id)
        XCTAssertEqual(child2.parent?.id, parent.id)
        XCTAssertFalse(parent.isLeaf)
        XCTAssertFalse(child1.isRoot)
        XCTAssertFalse(child2.isRoot)
        
        // 验证总大小计算
        XCTAssertEqual(parent.totalSize, 300)
        XCTAssertEqual(parent.fileCount, 2)
        XCTAssertEqual(parent.directoryCount, 1)
        
        // 测试移除子节点
        parent.removeChild(child1)
        XCTAssertEqual(parent.children.count, 1)
        XCTAssertNil(child1.parent)
        XCTAssertEqual(parent.totalSize, 200)
    }
    
    // MARK: - DirectoryTree Tests
    
    func testDirectoryTreeCreation() throws {
        let root = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        let tree = DirectoryTree(root: root)
        
        XCTAssertNotNil(tree.root)
        XCTAssertEqual(tree.root?.name, "root")
        XCTAssertEqual(tree.root?.path, "/root")
        XCTAssertTrue(tree.root?.isDirectory ?? false)
    }
    
    func testDirectoryTreeOperations() throws {
        let tree = DirectoryTree()
        let root = FileNode(name: "root", path: "/root", size: 0, isDirectory: true)
        let child1 = FileNode(name: "child1", path: "/root/child1", size: 0, isDirectory: true)
        let child2 = FileNode(name: "file.txt", path: "/root/file.txt", size: 1024, isDirectory: false)
        
        // 设置根节点
        tree.setRoot(root)
        XCTAssertEqual(tree.root?.id, root.id)
        
        // 添加子节点
        XCTAssertTrue(tree.addNode(child1, to: root))
        XCTAssertTrue(tree.addNode(child2, to: root))
        
        // 验证统计信息
        let stats = tree.getStatistics()
        XCTAssertEqual(stats.nodeCount, 3)
        XCTAssertEqual(stats.fileCount, 1)
        XCTAssertEqual(stats.directoryCount, 2)
        XCTAssertEqual(stats.totalSize, 1024)
        
        // 测试查找功能
        XCTAssertNotNil(tree.findNode(at: "/root/child1"))
        XCTAssertNotNil(tree.findNode(by: child2.id))
        XCTAssertEqual(tree.findNodes(named: "child1").count, 1)
        
        // 测试移除节点
        XCTAssertTrue(tree.removeNode(child1))
        XCTAssertNil(tree.findNode(at: "/root/child1"))
        
        let updatedStats = tree.getStatistics()
        XCTAssertEqual(updatedStats.nodeCount, 2)
        XCTAssertEqual(updatedStats.directoryCount, 1)
    }
    
    // MARK: - ScanSession Tests
    
    func testScanSessionCreation() throws {
        let session = ScanSession(scanPath: "/test/path", name: "Test Session")
        
        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.scanPath, "/test/path")
        XCTAssertEqual(session.status, .pending)
        XCTAssertFalse(session.isRunning)
        XCTAssertFalse(session.isCompleted)
        XCTAssertEqual(session.progress, 0.0)
    }
    
    func testScanSessionLifecycle() throws {
        let session = testSession!
        
        // 测试开始扫描
        session.start()
        XCTAssertEqual(session.status, .scanning)
        XCTAssertTrue(session.isRunning)
        XCTAssertNotNil(session.startedAt)
        
        // 测试暂停扫描
        session.pause()
        XCTAssertEqual(session.status, .paused)
        XCTAssertFalse(session.isRunning)
        XCTAssertNotNil(session.pausedAt)
        
        // 测试完成扫描
        session.start() // 从暂停状态恢复
        session.complete(success: true)
        XCTAssertEqual(session.status, .completed)
        XCTAssertTrue(session.isCompleted)
        XCTAssertNotNil(session.completedAt)
    }
    
    // MARK: - DataPersistence Tests
    
    func testDataPersistenceDirectories() throws {
        // 验证数据目录存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: DataPersistence.dataDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: DataPersistence.sessionsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: DataPersistence.cacheDirectory.path))
    }
    
    func testSessionPersistence() throws {
        let session = testSession!
        session.start()
        session.notes = "Test persistence"
        
        // 保存会话
        try DataPersistence.saveSession(session)
        
        // 加载会话
        let loadedSession = try DataPersistence.loadSession(id: session.id)
        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedSession?.id, session.id)
        XCTAssertEqual(loadedSession?.name, session.name)
        XCTAssertEqual(loadedSession?.notes, session.notes)
        
        // 验证会话在列表中
        let sessionIds = DataPersistence.getAllSessionIds()
        XCTAssertTrue(sessionIds.contains(session.id))
        
        // 删除会话
        try DataPersistence.deleteSession(id: session.id)
        let deletedSession = try DataPersistence.loadSession(id: session.id)
        XCTAssertNil(deletedSession)
    }
}
