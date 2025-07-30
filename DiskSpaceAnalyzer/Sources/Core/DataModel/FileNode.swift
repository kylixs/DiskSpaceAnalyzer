import Foundation

/// 文件/目录节点数据结构
/// 支持UUID标识、父子关系管理和属性计算
public class FileNode: ObservableObject, Identifiable, Codable {
    
    // MARK: - Properties
    
    /// 节点唯一标识符
    public let id: UUID
    
    /// 文件/目录名称
    public let name: String
    
    /// 完整路径
    public let path: String
    
    /// 文件大小（字节）
    public let size: Int64
    
    /// 是否为目录
    public let isDirectory: Bool
    
    /// 创建时间
    public let createdDate: Date
    
    /// 修改时间
    public let modifiedDate: Date
    
    /// 文件权限
    public let permissions: FilePermissions
    
    /// 子节点列表（仅目录有效）
    @Published public var children: [FileNode] = []
    
    /// 父节点弱引用（避免循环依赖）
    public weak var parent: FileNode?
    
    // MARK: - Cached Properties
    
    /// 缓存的总大小（包含子节点）
    private var _cachedTotalSize: Int64?
    private var _totalSizeLastCalculated: Date?
    
    /// 缓存的深度
    private var _cachedDepth: Int?
    
    // MARK: - Computed Properties
    
    /// 递归计算总大小（包含所有子节点）
    public var totalSize: Int64 {
        // 检查缓存是否有效
        if let cached = _cachedTotalSize,
           let lastCalculated = _totalSizeLastCalculated,
           Date().timeIntervalSince(lastCalculated) < 1.0 { // 1秒缓存
            return cached
        }
        
        let total = calculateTotalSize()
        _cachedTotalSize = total
        _totalSizeLastCalculated = Date()
        return total
    }
    
    /// 节点在树中的深度
    public var depth: Int {
        if let cached = _cachedDepth {
            return cached
        }
        
        let calculatedDepth = calculateDepth()
        _cachedDepth = calculatedDepth
        return calculatedDepth
    }
    
    /// 子节点数量
    public var childCount: Int {
        return children.count
    }
    
    /// 文件数量（递归统计）
    public var fileCount: Int {
        if !isDirectory {
            return 1
        }
        return children.reduce(0) { $0 + $1.fileCount }
    }
    
    /// 目录数量（递归统计）
    public var directoryCount: Int {
        if !isDirectory {
            return 0
        }
        return 1 + children.reduce(0) { $0 + $1.directoryCount }
    }
    
    // MARK: - Initialization
    
    /// 初始化文件节点
    /// - Parameters:
    ///   - name: 文件/目录名称
    ///   - path: 完整路径
    ///   - size: 文件大小
    ///   - isDirectory: 是否为目录
    ///   - createdDate: 创建时间
    ///   - modifiedDate: 修改时间
    ///   - permissions: 文件权限
    public init(
        name: String,
        path: String,
        size: Int64,
        isDirectory: Bool,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        permissions: FilePermissions = FilePermissions()
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.permissions = permissions
    }
    
    // MARK: - Public Methods
    
    /// 添加子节点
    /// - Parameter child: 要添加的子节点
    public func addChild(_ child: FileNode) {
        guard isDirectory else { return }
        
        // 设置父子关系
        child.parent = self
        children.append(child)
        
        // 清除缓存
        invalidateCache()
    }
    
    /// 移除子节点
    /// - Parameter child: 要移除的子节点
    public func removeChild(_ child: FileNode) {
        guard isDirectory else { return }
        
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index].parent = nil
            children.remove(at: index)
            
            // 清除缓存
            invalidateCache()
        }
    }
    
    /// 查找子节点
    /// - Parameter name: 节点名称
    /// - Returns: 找到的节点或nil
    public func findChild(named name: String) -> FileNode? {
        return children.first { $0.name == name }
    }
    
    /// 获取完整路径（通过向上遍历构建）
    /// - Returns: 完整路径字符串
    public func getFullPath() -> String {
        var pathComponents: [String] = []
        var currentNode: FileNode? = self
        
        while let node = currentNode {
            pathComponents.insert(node.name, at: 0)
            currentNode = node.parent
        }
        
        return "/" + pathComponents.joined(separator: "/")
    }
    
    /// 按大小排序子节点
    /// - Parameter ascending: 是否升序排列
    public func sortChildrenBySize(ascending: Bool = false) {
        children.sort { ascending ? $0.totalSize < $1.totalSize : $0.totalSize > $1.totalSize }
    }
    
    /// 按名称排序子节点
    /// - Parameter ascending: 是否升序排列
    public func sortChildrenByName(ascending: Bool = true) {
        children.sort { ascending ? $0.name < $1.name : $0.name > $1.name }
    }
    
    // MARK: - Private Methods
    
    /// 递归计算总大小
    private func calculateTotalSize() -> Int64 {
        if !isDirectory {
            return size
        }
        
        return size + children.reduce(0) { $0 + $1.totalSize }
    }
    
    /// 计算节点深度
    private func calculateDepth() -> Int {
        var depth = 0
        var currentNode = parent
        
        while currentNode != nil {
            depth += 1
            currentNode = currentNode?.parent
        }
        
        return depth
    }
    
    /// 清除缓存
    private func invalidateCache() {
        _cachedTotalSize = nil
        _totalSizeLastCalculated = nil
        _cachedDepth = nil
        
        // 向上传播缓存失效
        parent?.invalidateCache()
    }
    
    // MARK: - Codable Support
    
    private enum CodingKeys: String, CodingKey {
        case id, name, path, size, isDirectory
        case createdDate, modifiedDate, permissions
        case children
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int64.self, forKey: .size)
        isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        modifiedDate = try container.decode(Date.self, forKey: .modifiedDate)
        permissions = try container.decode(FilePermissions.self, forKey: .permissions)
        children = try container.decode([FileNode].self, forKey: .children)
        
        // 重建父子关系
        for child in children {
            child.parent = self
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(isDirectory, forKey: .isDirectory)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(modifiedDate, forKey: .modifiedDate)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(children, forKey: .children)
    }
}

// MARK: - Equatable & Hashable

extension FileNode: Equatable {
    public static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        return lhs.id == rhs.id
    }
}

extension FileNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

/// 文件权限结构
public struct FilePermissions: Codable {
    public let owner: PermissionSet
    public let group: PermissionSet
    public let others: PermissionSet
    
    public init(
        owner: PermissionSet = PermissionSet(),
        group: PermissionSet = PermissionSet(),
        others: PermissionSet = PermissionSet()
    ) {
        self.owner = owner
        self.group = group
        self.others = others
    }
}

/// 权限集合
public struct PermissionSet: Codable {
    public let read: Bool
    public let write: Bool
    public let execute: Bool
    
    public init(read: Bool = false, write: Bool = false, execute: Bool = false) {
        self.read = read
        self.write = write
        self.execute = execute
    }
}
