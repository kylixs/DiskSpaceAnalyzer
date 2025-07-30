import Foundation

/// 数据模型协议
public protocol DataModelProtocol {
    // MARK: - Node Management
    func createFileNode(path: String, size: Int64, isDirectory: Bool) -> FileNode
    func getNode(by id: UUID) -> FileNode?
    func getChildren(of node: FileNode) -> [FileNode]
    func updateNode(_ node: FileNode)
    func deleteNode(_ node: FileNode)
    
    // MARK: - Tree Operations
    func getRootNode() -> FileNode?
    func findNode(at path: String) -> FileNode?
    func getNodesBySize(limit: Int) -> [FileNode]
    func getNodesByType(_ type: FileType) -> [FileNode]
    
    // MARK: - Session Management
    func createSession(scanPath: String) -> ScanSession
    func saveSession(_ session: ScanSession)
    func loadSession(_ sessionId: UUID) -> ScanSession?
    func getAllSessions() -> [ScanSession]
    func deleteSession(_ sessionId: UUID)
    
    // MARK: - Data Persistence
    func saveData() async throws
    func loadData() async throws
    func exportData(format: ExportFormat) -> Data
    func importData(_ data: Data) throws
}

/// 数据模型主类
/// 统一管理文件节点、目录树和会话数据
public class DataModel: ObservableObject {
    
    // MARK: - Properties
    
    /// 目录树
    @Published public private(set) var directoryTree: DirectoryTree
    
    /// 数据持久化管理器
    private let persistence: DataPersistence
    
    /// 当前活动会话
    @Published public private(set) var currentSession: ScanSession?
    
    /// 所有会话列表
    @Published public private(set) var allSessions: [ScanSession] = []
    
    // MARK: - Initialization
    
    public init() throws {
        self.directoryTree = DirectoryTree()
        self.persistence = try DataPersistence()
        
        // 加载所有会话
        loadAllSessions()
    }
    
    // MARK: - Node Management
    
    /// 创建文件节点
    /// - Parameters:
    ///   - path: 文件路径
    ///   - size: 文件大小
    ///   - isDirectory: 是否为目录
    /// - Returns: 创建的文件节点
    public func createFileNode(path: String, size: Int64, isDirectory: Bool) -> FileNode {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        
        // 获取文件属性
        var createdDate = Date()
        var modifiedDate = Date()
        var permissions = FilePermissions()
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            createdDate = attributes[.creationDate] as? Date ?? Date()
            modifiedDate = attributes[.modificationDate] as? Date ?? Date()
            
            // 解析权限
            if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
                permissions = parsePermissions(posixPermissions.uint16Value)
            }
        } catch {
            print("Failed to get attributes for \(path): \(error)")
        }
        
        return FileNode(
            name: name,
            path: path,
            size: size,
            isDirectory: isDirectory,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            permissions: permissions
        )
    }
    
    /// 获取节点
    /// - Parameter id: 节点ID
    /// - Returns: 找到的节点或nil
    public func getNode(by id: UUID) -> FileNode? {
        return directoryTree.findNode(by: id)
    }
    
    /// 获取子节点
    /// - Parameter node: 父节点
    /// - Returns: 子节点数组
    public func getChildren(of node: FileNode) -> [FileNode] {
        return node.children
    }
    
    /// 更新节点
    /// - Parameter node: 要更新的节点
    public func updateNode(_ node: FileNode) {
        // 触发UI更新
        objectWillChange.send()
    }
    
    /// 删除节点
    /// - Parameter node: 要删除的节点
    public func deleteNode(_ node: FileNode) {
        directoryTree.removeNode(node)
    }
    
    // MARK: - Tree Operations
    
    /// 获取根节点
    /// - Returns: 根节点或nil
    public func getRootNode() -> FileNode? {
        return directoryTree.rootNode
    }
    
    /// 设置根节点
    /// - Parameter node: 根节点
    public func setRootNode(_ node: FileNode) {
        directoryTree.setRootNode(node)
    }
    
    /// 查找节点
    /// - Parameter path: 文件路径
    /// - Returns: 找到的节点或nil
    public func findNode(at path: String) -> FileNode? {
        return directoryTree.findNode(at: path)
    }
    
    /// 按大小获取节点
    /// - Parameter limit: 限制数量
    /// - Returns: 按大小排序的节点数组
    public func getNodesBySize(limit: Int) -> [FileNode] {
        return directoryTree.getNodesBySize(limit: limit)
    }
    
    /// 按类型获取节点
    /// - Parameter type: 文件类型
    /// - Returns: 符合条件的节点数组
    public func getNodesByType(_ type: FileType) -> [FileNode] {
        return directoryTree.getNodes(ofType: type)
    }
    
    // MARK: - Session Management
    
    /// 创建会话
    /// - Parameter scanPath: 扫描路径
    /// - Returns: 创建的会话
    public func createSession(scanPath: String) -> ScanSession {
        let session = ScanSession(scanPath: scanPath)
        currentSession = session
        return session
    }
    
    /// 保存会话
    /// - Parameter session: 要保存的会话
    public func saveSession(_ session: ScanSession) {
        do {
            try persistence.saveSession(session)
            loadAllSessions() // 重新加载会话列表
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    /// 加载会话
    /// - Parameter sessionId: 会话ID
    /// - Returns: 加载的会话或nil
    public func loadSession(_ sessionId: UUID) -> ScanSession? {
        do {
            let session = try persistence.loadSession(sessionId)
            if let session = session {
                currentSession = session
                if let rootNode = session.rootNode {
                    setRootNode(rootNode)
                }
            }
            return session
        } catch {
            print("Failed to load session: \(error)")
            return nil
        }
    }
    
    /// 获取所有会话
    /// - Returns: 所有会话数组
    public func getAllSessions() -> [ScanSession] {
        return allSessions
    }
    
    /// 删除会话
    /// - Parameter sessionId: 会话ID
    public func deleteSession(_ sessionId: UUID) {
        do {
            try persistence.deleteSession(sessionId)
            loadAllSessions() // 重新加载会话列表
            
            // 如果删除的是当前会话，清除当前会话
            if currentSession?.id == sessionId {
                currentSession = nil
                directoryTree.clear()
            }
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    // MARK: - Data Persistence
    
    /// 保存数据
    public func saveData() async throws {
        if let session = currentSession {
            try persistence.saveSession(session)
        }
    }
    
    /// 加载数据
    public func loadData() async throws {
        loadAllSessions()
    }
    
    /// 导出数据
    /// - Parameter format: 导出格式
    /// - Returns: 导出的数据
    public func exportData(format: ExportFormat) -> Data {
        guard let session = currentSession else {
            return Data()
        }
        
        do {
            return try persistence.exportSession(session, format: format)
        } catch {
            print("Failed to export data: \(error)")
            return Data()
        }
    }
    
    /// 导入数据
    /// - Parameter data: 要导入的数据
    public func importData(_ data: Data) throws {
        let session = try persistence.importSession(from: data)
        currentSession = session
        
        if let rootNode = session.rootNode {
            setRootNode(rootNode)
        }
        
        saveSession(session)
    }
    
    // MARK: - Utility Methods
    
    /// 获取树统计信息
    /// - Returns: 树统计信息
    public func getTreeStatistics() -> TreeStatistics {
        return directoryTree.getStatistics()
    }
    
    /// 清空数据
    public func clear() {
        directoryTree.clear()
        currentSession = nil
    }
    
    /// 获取存储统计信息
    /// - Returns: 存储统计信息
    public func getStorageStatistics() -> StorageStatistics? {
        do {
            return try persistence.getStorageStatistics()
        } catch {
            print("Failed to get storage statistics: \(error)")
            return nil
        }
    }
    
    /// 清理旧会话
    /// - Parameter days: 清理多少天前的会话
    public func cleanupOldSessions(olderThan days: Int) {
        do {
            try persistence.cleanupOldSessions(olderThan: days)
            loadAllSessions()
        } catch {
            print("Failed to cleanup old sessions: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载所有会话
    private func loadAllSessions() {
        do {
            allSessions = try persistence.getAllSessions()
        } catch {
            print("Failed to load sessions: \(error)")
            allSessions = []
        }
    }
    
    /// 解析POSIX权限
    /// - Parameter permissions: POSIX权限值
    /// - Returns: 文件权限结构
    private func parsePermissions(_ permissions: UInt16) -> FilePermissions {
        let owner = PermissionSet(
            read: (permissions & 0o400) != 0,
            write: (permissions & 0o200) != 0,
            execute: (permissions & 0o100) != 0
        )
        
        let group = PermissionSet(
            read: (permissions & 0o040) != 0,
            write: (permissions & 0o020) != 0,
            execute: (permissions & 0o010) != 0
        )
        
        let others = PermissionSet(
            read: (permissions & 0o004) != 0,
            write: (permissions & 0o002) != 0,
            execute: (permissions & 0o001) != 0
        )
        
        return FilePermissions(owner: owner, group: group, others: others)
    }
}

// MARK: - DataModelProtocol Implementation

extension DataModel: DataModelProtocol {
    // 所有协议方法已在上面实现
}
