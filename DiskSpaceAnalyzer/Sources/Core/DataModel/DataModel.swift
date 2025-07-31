import Foundation
import Combine

// MARK: - DataModel Module
// 数据模型模块 - 提供核心数据结构和持久化功能

/// DataModel模块信息
public struct DataModelModule {
    public static let version = "1.0.0"
    public static let description = "核心数据模型和持久化功能"
    
    public static func initialize() {
        print("📊 DataModel模块初始化")
        print("📋 包含: FileNode、DirectoryTree、ScanSession、DataPersistence")
        print("📊 版本: \(version)")
        
        // 初始化数据目录
        _ = DataPersistence.dataDirectory
        _ = DataPersistence.sessionsDirectory
        _ = DataPersistence.cacheDirectory
        
        // 清理过期缓存
        DataPersistence.cleanExpiredCache()
        
        print("✅ DataModel模块初始化完成")
    }
}

// MARK: - 便利构造函数和工厂方法

extension FileNode {
    /// 创建文件节点
    /// - Parameters:
    ///   - name: 文件名
    ///   - path: 文件路径
    ///   - size: 文件大小
    ///   - modifiedAt: 修改时间
    /// - Returns: 文件节点
    public static func createFile(
        name: String,
        path: String,
        size: Int64,
        modifiedAt: Date = Date()
    ) -> FileNode {
        return FileNode(
            name: name,
            path: path,
            size: size,
            isDirectory: false,
            modifiedAt: modifiedAt
        )
    }
    
    /// 创建目录节点
    /// - Parameters:
    ///   - name: 目录名
    ///   - path: 目录路径
    ///   - modifiedAt: 修改时间
    /// - Returns: 目录节点
    public static func createDirectory(
        name: String,
        path: String,
        modifiedAt: Date = Date()
    ) -> FileNode {
        return FileNode(
            name: name,
            path: path,
            size: 0,
            isDirectory: true,
            modifiedAt: modifiedAt
        )
    }
}

extension DirectoryTree {
    /// 创建带根节点的目录树
    /// - Parameter rootPath: 根路径
    /// - Returns: 目录树实例
    public static func createWithRoot(path rootPath: String) -> DirectoryTree {
        let rootName = URL(fileURLWithPath: rootPath).lastPathComponent
        let rootNode = FileNode.createDirectory(name: rootName, path: rootPath)
        return DirectoryTree(root: rootNode)
    }
}

extension ScanSession {
    /// 创建新的扫描会话
    /// - Parameters:
    ///   - path: 扫描路径
    ///   - name: 会话名称（可选）
    /// - Returns: 扫描会话实例
    public static func create(for path: String, name: String? = nil) -> ScanSession {
        let sessionName = name ?? URL(fileURLWithPath: path).lastPathComponent
        return ScanSession(scanPath: path, name: sessionName)
    }
}

// MARK: - 数据模型协议

/// 可序列化的数据模型协议
public protocol SerializableDataModel: Codable, Identifiable {
    var id: UUID { get }
    var createdAt: Date { get }
}

/// 可观察的数据模型协议
public protocol ObservableDataModel: ObservableObject {
    associatedtype ID: Hashable
    var id: ID { get }
}

/// 可持久化的数据模型协议
public protocol PersistableDataModel: SerializableDataModel {
    func save() throws
    static func load(id: UUID) throws -> Self?
    func delete() throws
}

// MARK: - 扩展实现协议

extension FileNode: SerializableDataModel {
    // 已实现 Codable, Identifiable
    // createdAt 属性已存在
}

extension ScanSession: SerializableDataModel {
    // 已实现 Codable, Identifiable
    // createdAt 属性已存在
}

extension ScanSession: PersistableDataModel {
    /// 保存会话
    public func save() throws {
        try DataPersistence.saveSession(self)
    }
    
    /// 加载会话
    /// - Parameter id: 会话ID
    /// - Returns: 会话实例
    public static func load(id: UUID) throws -> ScanSession? {
        return try DataPersistence.loadSession(id: id)
    }
    
    /// 删除会话
    public func delete() throws {
        try DataPersistence.deleteSession(id: self.id)
    }
}

// MARK: - 数据模型管理器

/// 数据模型管理器 - 统一管理所有数据操作
public class DataModelManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = DataModelManager()
    
    private init() {
        loadAllSessions()
    }
    
    // MARK: - Properties
    
    /// 所有会话
    @Published public private(set) var sessions: [ScanSession] = []
    
    /// 当前活动会话
    @Published public var currentSession: ScanSession?
    
    /// 收藏的会话
    public var favoriteSessions: [ScanSession] {
        return sessions.filter { $0.isFavorite }
    }
    
    /// 最近的会话
    public var recentSessions: [ScanSession] {
        return sessions.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
    }
    
    // MARK: - Session Management
    
    /// 创建新会话
    /// - Parameters:
    ///   - path: 扫描路径
    ///   - name: 会话名称
    /// - Returns: 新创建的会话
    public func createSession(for path: String, name: String? = nil) -> ScanSession {
        let session = ScanSession.create(for: path, name: name)
        sessions.append(session)
        currentSession = session
        return session
    }
    
    /// 保存会话
    /// - Parameter session: 要保存的会话
    public func saveSession(_ session: ScanSession) {
        do {
            try session.save()
            
            // 保存目录树（如果存在）
            if let tree = session.directoryTree {
                try DataPersistence.saveDirectoryTree(tree, for: session.id)
            }
            
            print("✅ 会话保存成功: \(session.name)")
        } catch {
            print("❌ 会话保存失败: \(error)")
        }
    }
    
    /// 删除会话
    /// - Parameter session: 要删除的会话
    public func deleteSession(_ session: ScanSession) {
        do {
            try session.delete()
            sessions.removeAll { $0.id == session.id }
            
            if currentSession?.id == session.id {
                currentSession = nil
            }
            
            print("✅ 会话删除成功: \(session.name)")
        } catch {
            print("❌ 会话删除失败: \(error)")
        }
    }
    
    /// 加载所有会话
    private func loadAllSessions() {
        let sessionIds = DataPersistence.getAllSessionIds()
        
        sessions = sessionIds.compactMap { id in
            do {
                return try ScanSession.load(id: id)
            } catch {
                print("❌ 加载会话失败 (\(id)): \(error)")
                return nil
            }
        }
        
        print("📊 加载了 \(sessions.count) 个会话")
    }
    
    /// 刷新会话列表
    public func refreshSessions() {
        loadAllSessions()
    }
    
    // MARK: - Data Statistics
    
    /// 获取数据统计信息
    /// - Returns: 数据统计信息
    public func getDataStatistics() -> DataStatistics {
        let totalSessions = sessions.count
        let completedSessions = sessions.filter { $0.status == .completed }.count
        let totalScannedBytes = sessions.reduce(0) { $0 + $1.statistics.totalBytesScanned }
        let dataDirectorySize = DataPersistence.getDataDirectorySize()
        
        return DataStatistics(
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            totalScannedBytes: totalScannedBytes,
            dataDirectorySize: dataDirectorySize
        )
    }
    
    /// 清理数据
    /// - Parameter keepSessions: 是否保留会话数据
    public func cleanData(keepSessions: Bool = true) {
        DataPersistence.cleanAllData(keepSessions: keepSessions)
        
        if !keepSessions {
            sessions.removeAll()
            currentSession = nil
        }
    }
}

// MARK: - 数据统计信息

/// 数据统计信息
public struct DataStatistics {
    public let totalSessions: Int
    public let completedSessions: Int
    public let totalScannedBytes: Int64
    public let dataDirectorySize: Int64
    
    /// 完成率
    public var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    /// 格式化的总扫描大小
    public var formattedTotalScannedBytes: String {
        return ByteFormatter.shared.string(fromByteCount: totalScannedBytes)
    }
    
    /// 格式化的数据目录大小
    public var formattedDataDirectorySize: String {
        return ByteFormatter.shared.string(fromByteCount: dataDirectorySize)
    }
}

// MARK: - 模块导出总结

/*
 DataModel模块导出的公共接口：
 
 === 核心类型 ===
 - FileNode: 文件/目录节点
 - DirectoryTree: 目录树结构
 - ScanSession: 扫描会话
 - DataPersistence: 数据持久化
 
 === 支持类型 ===
 - TreeStatistics: 目录树统计
 - SizeDistribution: 大小分布
 - PausePoint: 暂停点信息
 - SessionSummary: 会话摘要
 - PersistenceError: 持久化错误
 
 === 管理类型 ===
 - DataModelManager: 数据模型管理器
 - DataStatistics: 数据统计信息
 
 === 协议 ===
 - SerializableDataModel: 可序列化数据模型
 - ObservableDataModel: 可观察数据模型
 - PersistableDataModel: 可持久化数据模型
 
 === 便利方法 ===
 - FileNode.createFile(): 创建文件节点
 - FileNode.createDirectory(): 创建目录节点
 - DirectoryTree.createWithRoot(): 创建带根节点的目录树
 - ScanSession.create(): 创建扫描会话
 
 使用方式：
 import Core
 
 // 创建文件节点
 let file = FileNode.createFile(name: "test.txt", path: "/path/test.txt", size: 1024)
 
 // 创建目录树
 let tree = DirectoryTree.createWithRoot(path: "/Users/username")
 
 // 创建扫描会话
 let session = ScanSession.create(for: "/Users/username", name: "Home Directory")
 
 // 使用数据管理器
 let manager = DataModelManager.shared
 let newSession = manager.createSession(for: "/path", name: "My Scan")
 manager.saveSession(newSession)
 */
