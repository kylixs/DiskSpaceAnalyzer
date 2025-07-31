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
        testSession = ScanSession.create(for: tempDirectory.path, name: "Test Session")
        
        // 创建测试目录树
        testTree = DirectoryTree.createWithRoot(path: tempDirectory.path)
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
        let file = FileNode.createFile(
            name: "test.txt",
            path: "/path/test.txt",
            size: 1024
        )
        
        XCTAssertEqual(file.name, "test.txt")
        XCTAssertEqual(file.path, "/path/test.txt")
        XCTAssertEqual(file.size, 1024)
        XCTAssertFalse(file.isDirectory)
        XCTAssertEqual(file.totalSize, 1024)
        XCTAssertTrue(file.isLeaf)
        XCTAssertTrue(file.isRoot)
        
        // 测试目录节点创建
        let directory = FileNode.createDirectory(
            name: "testdir",
            path: "/path/testdir"
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
        let parent = FileNode.createDirectory(name: "parent", path: "/parent")
        let child1 = FileNode.createFile(name: "child1.txt", path: "/parent/child1.txt", size: 100)
        let child2 = FileNode.createFile(name: "child2.txt", path: "/parent/child2.txt", size: 200)
        
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
    
    func testFileNodeTraversal() throws {
        // 创建测试树结构
        let root = FileNode.createDirectory(name: "root", path: "/root")
        let dir1 = FileNode.createDirectory(name: "dir1", path: "/root/dir1")
        let dir2 = FileNode.createDirectory(name: "dir2", path: "/root/dir2")
        let file1 = FileNode.createFile(name: "file1.txt", path: "/root/dir1/file1.txt", size: 100)
        let file2 = FileNode.createFile(name: "file2.txt", path: "/root/dir2/file2.txt", size: 200)
        
        root.addChild(dir1)
        root.addChild(dir2)
        dir1.addChild(file1)
        dir2.addChild(file2)
        
        // 测试深度优先遍历
        var dfsNodes: [FileNode] = []
        root.depthFirstTraversal { node in
            dfsNodes.append(node)
        }
        
        XCTAssertEqual(dfsNodes.count, 5)
        XCTAssertEqual(dfsNodes[0].name, "root")
        XCTAssertEqual(dfsNodes[1].name, "dir1")
        XCTAssertEqual(dfsNodes[2].name, "file1.txt")
        
        // 测试广度优先遍历
        var bfsNodes: [FileNode] = []
        root.breadthFirstTraversal { node in
            bfsNodes.append(node)
        }
        
        XCTAssertEqual(bfsNodes.count, 5)
        XCTAssertEqual(bfsNodes[0].name, "root")
        XCTAssertEqual(bfsNodes[1].name, "dir1")
        XCTAssertEqual(bfsNodes[2].name, "dir2")
        XCTAssertEqual(bfsNodes[3].name, "file1.txt")
        XCTAssertEqual(bfsNodes[4].name, "file2.txt")
    }
    
    func testFileNodeSorting() throws {
        let parent = FileNode.createDirectory(name: "parent", path: "/parent")
        let smallFile = FileNode.createFile(name: "small.txt", path: "/parent/small.txt", size: 100)
        let largeFile = FileNode.createFile(name: "large.txt", path: "/parent/large.txt", size: 1000)
        let mediumFile = FileNode.createFile(name: "medium.txt", path: "/parent/medium.txt", size: 500)
        
        parent.addChild(smallFile)
        parent.addChild(largeFile)
        parent.addChild(mediumFile)
        
        // 按大小排序（降序）
        parent.sortChildrenBySize(ascending: false)
        XCTAssertEqual(parent.children[0].name, "large.txt")
        XCTAssertEqual(parent.children[1].name, "medium.txt")
        XCTAssertEqual(parent.children[2].name, "small.txt")
        
        // 按名称排序（升序）
        parent.sortChildrenByName(ascending: true)
        XCTAssertEqual(parent.children[0].name, "large.txt")
        XCTAssertEqual(parent.children[1].name, "medium.txt")
        XCTAssertEqual(parent.children[2].name, "small.txt")
    }
    
    // MARK: - DirectoryTree Tests
    
    func testDirectoryTreeCreation() throws {
        let tree = DirectoryTree.createWithRoot(path: "/test/path")
        
        XCTAssertNotNil(tree.root)
        XCTAssertEqual(tree.root?.name, "path")
        XCTAssertEqual(tree.root?.path, "/test/path")
        XCTAssertTrue(tree.root?.isDirectory ?? false)
    }
    
    func testDirectoryTreeOperations() throws {
        let tree = DirectoryTree()
        let root = FileNode.createDirectory(name: "root", path: "/root")
        let child1 = FileNode.createDirectory(name: "child1", path: "/root/child1")
        let child2 = FileNode.createFile(name: "file.txt", path: "/root/file.txt", size: 1024)
        
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
    
    func testDirectoryTreeBatchOperations() throws {
        let tree = DirectoryTree()
        let root = FileNode.createDirectory(name: "root", path: "/root")
        tree.setRoot(root)
        
        // 准备批量添加的节点
        let nodes: [(FileNode, String?)] = [
            (FileNode.createDirectory(name: "dir1", path: "/root/dir1"), "/root"),
            (FileNode.createDirectory(name: "dir2", path: "/root/dir2"), "/root"),
            (FileNode.createFile(name: "file1.txt", path: "/root/dir1/file1.txt", size: 100), "/root/dir1"),
            (FileNode.createFile(name: "file2.txt", path: "/root/dir2/file2.txt", size: 200), "/root/dir2")
        ]
        
        // 批量添加节点
        tree.batchAddNodes(nodes)
        
        // 验证结果
        let stats = tree.getStatistics()
        XCTAssertEqual(stats.nodeCount, 5) // root + 2 dirs + 2 files
        XCTAssertEqual(stats.fileCount, 2)
        XCTAssertEqual(stats.directoryCount, 3)
        XCTAssertEqual(stats.totalSize, 300)
    }
    
    func testDirectoryTreeAnalysis() throws {
        let tree = DirectoryTree()
        let root = FileNode.createDirectory(name: "root", path: "/root")
        tree.setRoot(root)
        
        // 添加不同大小的目录
        let smallDir = FileNode.createDirectory(name: "small", path: "/root/small")
        let mediumDir = FileNode.createDirectory(name: "medium", path: "/root/medium")
        let largeDir = FileNode.createDirectory(name: "large", path: "/root/large")
        
        smallDir.addChild(FileNode.createFile(name: "small.txt", path: "/root/small/small.txt", size: 100))
        mediumDir.addChild(FileNode.createFile(name: "medium.txt", path: "/root/medium/medium.txt", size: 500))
        largeDir.addChild(FileNode.createFile(name: "large.txt", path: "/root/large/large.txt", size: 1000))
        
        tree.addNode(smallDir, to: root)
        tree.addNode(mediumDir, to: root)
        tree.addNode(largeDir, to: root)
        
        // 测试查找最大文件
        let largestFiles = tree.findLargestFiles(count: 2)
        XCTAssertEqual(largestFiles.count, 2)
        XCTAssertEqual(largestFiles[0].size, 1000)
        XCTAssertEqual(largestFiles[1].size, 500)
        
        // 测试查找最大目录
        let largestDirs = tree.findLargestDirectories(count: 2)
        XCTAssertEqual(largestDirs.count, 2)
        XCTAssertEqual(largestDirs[0].totalSize, 1000)
        XCTAssertEqual(largestDirs[1].totalSize, 500)
        
        // 测试大小分布分析
        let distribution = tree.analyzeSizeDistribution()
        XCTAssertEqual(distribution.min, 0) // root directory
        XCTAssertEqual(distribution.max, 1000)
        XCTAssertEqual(distribution.median, 100)
    }
    
    // MARK: - ScanSession Tests
    
    func testScanSessionCreation() throws {
        let session = ScanSession.create(for: "/test/path", name: "Test Session")
        
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
        
        // 测试恢复扫描
        session.start() // 从暂停状态恢复
        XCTAssertEqual(session.status, .scanning)
        XCTAssertTrue(session.isRunning)
        XCTAssertNotNil(session.resumedAt)
        
        // 测试完成扫描
        session.complete(success: true)
        XCTAssertEqual(session.status, .completed)
        XCTAssertTrue(session.isCompleted)
        XCTAssertNotNil(session.completedAt)
    }
    
    func testScanSessionProgressTracking() throws {
        let session = testSession!
        session.start()
        
        // 更新进度
        session.updateProgress(
            currentPath: "/test/current/file.txt",
            progress: 0.5,
            speed: 100.0,
            estimatedTime: 60.0
        )
        
        XCTAssertEqual(session.currentPath, "/test/current/file.txt")
        XCTAssertEqual(session.progress, 0.5)
        XCTAssertEqual(session.scanSpeed, 100.0)
        XCTAssertEqual(session.estimatedTimeRemaining, 60.0)
        
        // 测试进度边界值
        session.updateProgress(currentPath: "", progress: -0.1, speed: 0, estimatedTime: 0)
        XCTAssertEqual(session.progress, 0.0) // 应该被限制在0.0
        
        session.updateProgress(currentPath: "", progress: 1.5, speed: 0, estimatedTime: 0)
        XCTAssertEqual(session.progress, 1.0) // 应该被限制在1.0
    }
    
    func testScanSessionErrorHandling() throws {
        let session = testSession!
        
        // 添加错误
        let error1 = ScanError(
            message: "Permission denied",
            path: "/restricted/file",
            category: .permission,
            severity: .warning
        )
        
        let error2 = ScanError(
            message: "File not found",
            path: "/missing/file",
            category: .fileSystem,
            severity: .info
        )
        
        session.addError(error1)
        session.addError(error2)
        
        XCTAssertEqual(session.errors.count, 2)
        XCTAssertEqual(session.errors[0].message, "Permission denied")
        XCTAssertEqual(session.errors[1].category, .fileSystem)
    }
    
    func testScanSessionSerialization() throws {
        let session = testSession!
        session.start()
        session.updateProgress(currentPath: "/test", progress: 0.5, speed: 100, estimatedTime: 60)
        session.addTag("test")
        session.notes = "Test notes"
        session.isFavorite = true
        
        // 序列化
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        
        // 反序列化
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSession = try decoder.decode(ScanSession.self, from: data)
        
        // 验证
        XCTAssertEqual(decodedSession.id, session.id)
        XCTAssertEqual(decodedSession.name, session.name)
        XCTAssertEqual(decodedSession.scanPath, session.scanPath)
        XCTAssertEqual(decodedSession.status, session.status)
        XCTAssertEqual(decodedSession.progress, session.progress)
        XCTAssertEqual(decodedSession.tags, session.tags)
        XCTAssertEqual(decodedSession.notes, session.notes)
        XCTAssertEqual(decodedSession.isFavorite, session.isFavorite)
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
    
    func testDirectoryTreePersistence() throws {
        let tree = testTree!
        let session = testSession!
        
        // 添加一些测试数据到树中
        let root = tree.root!
        let testDir = FileNode.createDirectory(name: "testdir", path: "/testdir")
        let testFile = FileNode.createFile(name: "test.txt", path: "/testdir/test.txt", size: 1024)
        
        testDir.addChild(testFile)
        tree.addNode(testDir, to: root)
        
        // 保存目录树
        try DataPersistence.saveDirectoryTree(tree, for: session.id)
        
        // 加载目录树
        let loadedTree = try DataPersistence.loadDirectoryTree(for: session.id)
        XCTAssertNotNil(loadedTree)
        
        let stats = loadedTree!.getStatistics()
        XCTAssertEqual(stats.nodeCount, 3) // root + testdir + test.txt
        XCTAssertEqual(stats.fileCount, 1)
        XCTAssertEqual(stats.directoryCount, 2)
    }
    
    func testCachePersistence() throws {
        let testData = ["key1": "value1", "key2": "value2"]
        let cacheKey = "test_cache_key"
        
        // 保存到缓存
        try DataPersistence.saveToCache(testData, key: cacheKey, expiration: 3600)
        
        // 从缓存加载
        let loadedData = DataPersistence.loadFromCache(key: cacheKey, type: [String: String].self)
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData?["key1"], "value1")
        XCTAssertEqual(loadedData?["key2"], "value2")
        
        // 测试过期缓存
        try DataPersistence.saveToCache(testData, key: "expired_key", expiration: -1) // 已过期
        let expiredData = DataPersistence.loadFromCache(key: "expired_key", type: [String: String].self)
        XCTAssertNil(expiredData)
    }
    
    func testSessionExportImport() throws {
        let session = testSession!
        session.start()
        session.notes = "Export test"
        session.addTag("export")
        
        // 保存会话
        try DataPersistence.saveSession(session)
        
        // 导出会话
        let exportData = try DataPersistence.exportSession(id: session.id)
        XCTAssertGreaterThan(exportData.count, 0)
        
        // 删除原会话
        try DataPersistence.deleteSession(id: session.id)
        
        // 导入会话
        let importedSessionId = try DataPersistence.importSession(from: exportData)
        XCTAssertEqual(importedSessionId, session.id)
        
        // 验证导入的会话
        let importedSession = try DataPersistence.loadSession(id: importedSessionId)
        XCTAssertNotNil(importedSession)
        XCTAssertEqual(importedSession?.name, session.name)
        XCTAssertEqual(importedSession?.notes, session.notes)
        XCTAssertTrue(importedSession?.tags.contains("export") ?? false)
    }
    
    // MARK: - DataModelManager Tests
    
    func testDataModelManager() throws {
        let manager = DataModelManager.shared
        
        // 创建会话
        let session = manager.createSession(for: "/test/path", name: "Manager Test")
        XCTAssertEqual(manager.currentSession?.id, session.id)
        XCTAssertTrue(manager.sessions.contains { $0.id == session.id })
        
        // 保存会话
        manager.saveSession(session)
        
        // 刷新会话列表
        manager.refreshSessions()
        XCTAssertTrue(manager.sessions.contains { $0.id == session.id })
        
        // 获取统计信息
        let stats = manager.getDataStatistics()
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 1)
        
        // 删除会话
        manager.deleteSession(session)
        XCTAssertFalse(manager.sessions.contains { $0.id == session.id })
        XCTAssertNil(manager.currentSession)
    }
    
    // MARK: - Performance Tests
    
    func testFileNodePerformance() throws {
        measure {
            let root = FileNode.createDirectory(name: "root", path: "/root")
            
            // 创建大量子节点
            for i in 0..<1000 {
                let child = FileNode.createFile(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i * 100)
                )
                root.addChild(child)
            }
            
            // 计算总大小
            _ = root.totalSize
            
            // 排序子节点
            root.sortChildrenBySize()
        }
    }
    
    func testDirectoryTreePerformance() throws {
        measure {
            let tree = DirectoryTree()
            let root = FileNode.createDirectory(name: "root", path: "/root")
            tree.setRoot(root)
            
            // 添加大量节点
            for i in 0..<1000 {
                let node = FileNode.createFile(
                    name: "file\(i).txt",
                    path: "/root/file\(i).txt",
                    size: Int64(i * 100)
                )
                tree.addNode(node, to: root)
            }
            
            // 执行查找操作
            _ = tree.findLargestFiles(count: 10)
            _ = tree.getStatistics()
        }
    }
}

// MARK: - Test Extensions

extension ScanError {
    /// 便利构造函数用于测试
    init(message: String, path: String, category: ErrorCategory, severity: ErrorSeverity) {
        self.init()
        self.message = message
        self.path = path
        self.category = category
        self.severity = severity
        self.timestamp = Date()
    }
}
