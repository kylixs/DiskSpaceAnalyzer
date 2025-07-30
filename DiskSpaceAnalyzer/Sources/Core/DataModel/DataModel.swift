import Foundation
import AppKit

/// 数据模型模块 - 统一的数据模型管理接口
public class DataModel {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = DataModel()
    
    /// 文件节点管理器
    public let fileNodeManager: FileNodeManager
    
    /// 目录树管理器
    public let directoryTreeManager: DirectoryTreeManager
    
    /// 扫描会话管理器
    public let scanSessionManager: ScanSessionManager
    
    /// 数据持久化管理器
    public let dataPersistenceManager: DataPersistenceManager
    
    /// 数据模型是否已初始化
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init() {
        self.fileNodeManager = FileNodeManager()
        self.directoryTreeManager = DirectoryTreeManager()
        self.scanSessionManager = ScanSessionManager()
        self.dataPersistenceManager = DataPersistenceManager()
        
        setupIntegration()
    }
    
    // MARK: - Public Methods
    
    /// 初始化数据模型
    public func initialize() {
        guard !isInitialized else { return }
        
        // 初始化各个管理器
        fileNodeManager.initialize()
        directoryTreeManager.initialize()
        scanSessionManager.initialize()
        dataPersistenceManager.initialize()
        
        isInitialized = true
        
        print("📊 DataModel模块初始化完成")
    }
    
    /// 创建文件节点
    public func createFileNode(path: String, isDirectory: Bool, size: Int64 = 0) -> FileNode {
        return fileNodeManager.createNode(path: path, isDirectory: isDirectory, size: size)
    }
    
    /// 创建目录树
    public func createDirectoryTree(rootPath: String) -> DirectoryTree {
        return directoryTreeManager.createTree(rootPath: rootPath)
    }
    
    /// 创建扫描会话
    public func createScanSession(rootPath: String, configuration: AppScanConfiguration = .default) -> ScanSession {
        return scanSessionManager.createSession(rootPath: rootPath, configuration: configuration)
    }
    
    /// 保存数据
    public func saveData<T: Codable>(_ data: T, to path: String) throws {
        try dataPersistenceManager.save(data, to: path)
    }
    
    /// 加载数据
    public func loadData<T: Codable>(_ type: T.Type, from path: String) throws -> T {
        return try dataPersistenceManager.load(type, from: path)
    }
    
    /// 获取数据模型状态
    public func getDataModelState() -> [String: Any] {
        return [
            "isInitialized": isInitialized,
            "fileNodeCount": fileNodeManager.getNodeCount(),
            "directoryTreeCount": directoryTreeManager.getTreeCount(),
            "activeSessions": scanSessionManager.getActiveSessionCount(),
            "persistedDataSize": dataPersistenceManager.getTotalDataSize()
        ]
    }
    
    /// 导出数据模型报告
    public func exportDataModelReport() -> String {
        var report = "=== Data Model Report ===\n\n"
        
        let state = getDataModelState()
        
        report += "Generated: \(Date())\n"
        report += "Initialized: \(state["isInitialized"] ?? false)\n"
        report += "File Node Count: \(state["fileNodeCount"] ?? 0)\n"
        report += "Directory Tree Count: \(state["directoryTreeCount"] ?? 0)\n"
        report += "Active Sessions: \(state["activeSessions"] ?? 0)\n"
        report += "Persisted Data Size: \(AppByteFormatter.shared.string(fromByteCount: state["persistedDataSize"] as? Int64 ?? 0))\n\n"
        
        report += "=== Components Status ===\n"
        report += "✅ FileNodeManager - 文件节点管理\n"
        report += "✅ DirectoryTreeManager - 目录树管理\n"
        report += "✅ ScanSessionManager - 扫描会话管理\n"
        report += "✅ DataPersistenceManager - 数据持久化管理\n"
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置模块集成
    private func setupIntegration() {
        // 设置各管理器之间的协作关系
        scanSessionManager.fileNodeManager = fileNodeManager
        scanSessionManager.directoryTreeManager = directoryTreeManager
        
        directoryTreeManager.fileNodeManager = fileNodeManager
        
        dataPersistenceManager.onDataSaved = { [weak self] path in
            print("📁 数据已保存到: \(path)")
        }
        
        dataPersistenceManager.onDataLoaded = { [weak self] path in
            print("📂 数据已从以下位置加载: \(path)")
        }
    }
}

// MARK: - 管理器类定义

/// 文件节点管理器
public class FileNodeManager {
    private var nodeCache: [String: FileNode] = [:]
    private let queue = DispatchQueue(label: "FileNodeManager", attributes: .concurrent)
    
    func initialize() {
        print("📄 FileNodeManager初始化")
    }
    
    func createNode(path: String, isDirectory: Bool, size: Int64) -> FileNode {
        return queue.sync(flags: .barrier) {
            if let existingNode = nodeCache[path] {
                return existingNode
            }
            
            let node = FileNode(path: path, isDirectory: isDirectory, size: size)
            nodeCache[path] = node
            return node
        }
    }
    
    func getNodeCount() -> Int {
        return queue.sync { nodeCache.count }
    }
}

/// 目录树管理器
public class DirectoryTreeManager {
    weak var fileNodeManager: FileNodeManager?
    private var treeCache: [String: DirectoryTree] = [:]
    private let queue = DispatchQueue(label: "DirectoryTreeManager", attributes: .concurrent)
    
    func initialize() {
        print("🌳 DirectoryTreeManager初始化")
    }
    
    func createTree(rootPath: String) -> DirectoryTree {
        return queue.sync(flags: .barrier) {
            if let existingTree = treeCache[rootPath] {
                return existingTree
            }
            
            let tree = DirectoryTree(rootPath: rootPath)
            treeCache[rootPath] = tree
            return tree
        }
    }
    
    func getTreeCount() -> Int {
        return queue.sync { treeCache.count }
    }
}

/// 扫描会话管理器
public class ScanSessionManager {
    weak var fileNodeManager: FileNodeManager?
    weak var directoryTreeManager: DirectoryTreeManager?
    private var activeSessions: [String: ScanSession] = [:]
    private let queue = DispatchQueue(label: "ScanSessionManager", attributes: .concurrent)
    
    func initialize() {
        print("🔍 ScanSessionManager初始化")
    }
    
    func createSession(rootPath: String, configuration: AppScanConfiguration) -> ScanSession {
        return queue.sync(flags: .barrier) {
            let sessionId = UUID().uuidString
            let session = ScanSession(
                id: sessionId,
                rootPath: rootPath,
                configuration: configuration
            )
            activeSessions[sessionId] = session
            return session
        }
    }
    
    func getActiveSessionCount() -> Int {
        return queue.sync { activeSessions.count }
    }
}

/// 数据持久化管理器
public class DataPersistenceManager {
    var onDataSaved: ((String) -> Void)?
    var onDataLoaded: ((String) -> Void)?
    
    func initialize() {
        print("💾 DataPersistenceManager初始化")
    }
    
    func save<T: Codable>(_ data: T, to path: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: URL(fileURLWithPath: path))
        
        onDataSaved?(path)
    }
    
    func load<T: Codable>(_ type: T.Type, from path: String) throws -> T {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let data = try decoder.decode(type, from: jsonData)
        onDataLoaded?(path)
        
        return data
    }
    
    func getTotalDataSize() -> Int64 {
        // 这里可以实现计算持久化数据总大小的逻辑
        return 0
    }
}
