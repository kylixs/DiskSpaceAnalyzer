import Foundation

/// 文件/目录节点数据结构
/// 支持UUID标识、父子关系管理和属性计算
public class FileNode: ObservableObject, Identifiable, Codable {
    
    // MARK: - Properties
    
    /// 唯一标识符
    public let id: UUID
    
    /// 文件/目录名称
    @Published public var name: String
    
    /// 完整路径
    @Published public var path: String
    
    /// 文件大小（字节）
    @Published public var size: Int64
    
    /// 是否为目录
    @Published public var isDirectory: Bool
    
    /// 创建时间
    public let createdAt: Date
    
    /// 修改时间
    @Published public var modifiedAt: Date
    
    /// 访问时间
    @Published public var accessedAt: Date
    
    /// 文件权限
    @Published public var permissions: String
    
    /// 父节点（弱引用避免循环依赖）
    public weak var parent: FileNode?
    
    /// 子节点列表
    @Published public var children: [FileNode] = []
    
    /// 是否已展开（用于UI状态）
    @Published public var isExpanded: Bool = false
    
    /// 是否被选中（用于UI状态）
    @Published public var isSelected: Bool = false
    
    /// 扫描状态
    public var scanStatus: ScanStatus = .pending
    
    /// 错误信息（如果扫描失败）
    public var error: ScanError?
    
    // MARK: - Computed Properties
    
    /// 总大小（包含所有子节点）
    /// 使用缓存避免重复计算
    private var _totalSizeCache: Int64?
    private var _totalSizeCacheTime: Date?
    private let cacheValidityDuration: TimeInterval = 1.0 // 1秒缓存有效期
    
    public var totalSize: Int64 {
        // 检查缓存是否有效
        if let cachedSize = _totalSizeCache,
           let cacheTime = _totalSizeCacheTime,
           Date().timeIntervalSince(cacheTime) < cacheValidityDuration {
            return cachedSize
        }
        
        // 重新计算总大小
        let calculatedSize = calculateTotalSize()
        _totalSizeCache = calculatedSize
        _totalSizeCacheTime = Date()
        return calculatedSize
    }
    
    /// 子节点数量
    public var childCount: Int {
        return children.count
    }
    
    /// 文件数量（递归）
    public var fileCount: Int {
        var count = isDirectory ? 0 : 1
        for child in children {
            count += child.fileCount
        }
        return count
    }
    
    /// 目录数量（递归）
    public var directoryCount: Int {
        var count = isDirectory ? 1 : 0
        for child in children {
            count += child.directoryCount
        }
        return count
    }
    
    /// 深度（从根节点开始）
    public var depth: Int {
        var depth = 0
        var current = parent
        while current != nil {
            depth += 1
            current = current?.parent
        }
        return depth
    }
    
    /// 是否为根节点
    public var isRoot: Bool {
        return parent == nil
    }
    
    /// 是否为叶子节点
    public var isLeaf: Bool {
        return children.isEmpty
    }
    
    // MARK: - Initialization
    
    /// 初始化文件节点
    /// - Parameters:
    ///   - name: 文件/目录名称
    ///   - path: 完整路径
    ///   - size: 文件大小
    ///   - isDirectory: 是否为目录
    ///   - modifiedAt: 修改时间
    ///   - accessedAt: 访问时间
    ///   - permissions: 文件权限
    public init(
        name: String,
        path: String,
        size: Int64 = 0,
        isDirectory: Bool = false,
        modifiedAt: Date = Date(),
        accessedAt: Date = Date(),
        permissions: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.createdAt = Date()
        self.modifiedAt = modifiedAt
        self.accessedAt = accessedAt
        self.permissions = permissions
    }
    
    // MARK: - Parent-Child Relationship Management
    
    /// 添加子节点
    /// - Parameter child: 要添加的子节点
    public func addChild(_ child: FileNode) {
        // 避免重复添加
        guard !children.contains(where: { $0.id == child.id }) else {
            return
        }
        
        // 设置父子关系
        child.parent = self
        children.append(child)
        
        // 清除缓存
        invalidateCache()
        
        // 通知父节点更新
        notifyParentOfChange()
    }
    
    /// 移除子节点
    /// - Parameter child: 要移除的子节点
    public func removeChild(_ child: FileNode) {
        children.removeAll { $0.id == child.id }
        child.parent = nil
        
        // 清除缓存
        invalidateCache()
        
        // 通知父节点更新
        notifyParentOfChange()
    }
    
    /// 移除所有子节点
    public func removeAllChildren() {
        for child in children {
            child.parent = nil
        }
        children.removeAll()
        
        // 清除缓存
        invalidateCache()
        
        // 通知父节点更新
        notifyParentOfChange()
    }
    
    /// 查找子节点
    /// - Parameter name: 子节点名称
    /// - Returns: 找到的子节点，如果不存在返回nil
    public func findChild(named name: String) -> FileNode? {
        return children.first { $0.name == name }
    }
    
    /// 查找子节点（通过路径）
    /// - Parameter path: 子节点路径
    /// - Returns: 找到的子节点，如果不存在返回nil
    public func findChild(at path: String) -> FileNode? {
        return children.first { $0.path == path }
    }
    
    // MARK: - Path Operations
    
    /// 构建完整路径
    /// - Returns: 从根节点到当前节点的完整路径
    public func buildFullPath() -> String {
        var pathComponents: [String] = []
        var current: FileNode? = self
        
        while let node = current {
            pathComponents.insert(node.name, at: 0)
            current = node.parent
        }
        
        return pathComponents.joined(separator: "/")
    }
    
    /// 获取相对路径
    /// - Parameter ancestor: 祖先节点
    /// - Returns: 相对于祖先节点的路径
    public func relativePath(from ancestor: FileNode) -> String? {
        var pathComponents: [String] = []
        var current: FileNode? = self
        
        while let node = current {
            if node.id == ancestor.id {
                return pathComponents.reversed().joined(separator: "/")
            }
            pathComponents.append(node.name)
            current = node.parent
        }
        
        return nil // ancestor不是当前节点的祖先
    }
    
    // MARK: - Size Calculation
    
    /// 递归计算总大小
    /// - Returns: 包含所有子节点的总大小
    private func calculateTotalSize() -> Int64 {
        var total = size
        for child in children {
            total += child.totalSize
        }
        return total
    }
    
    /// 清除大小缓存
    public func invalidateCache() {
        _totalSizeCache = nil
        _totalSizeCacheTime = nil
        
        // 递归清除父节点缓存
        parent?.invalidateCache()
    }
    
    /// 通知父节点发生变化
    private func notifyParentOfChange() {
        parent?.invalidateCache()
    }
    
    // MARK: - Tree Traversal
    
    /// 深度优先遍历
    /// - Parameter visitor: 访问者函数
    public func depthFirstTraversal(_ visitor: (FileNode) -> Void) {
        visitor(self)
        for child in children {
            child.depthFirstTraversal(visitor)
        }
    }
    
    /// 广度优先遍历
    /// - Parameter visitor: 访问者函数
    public func breadthFirstTraversal(_ visitor: (FileNode) -> Void) {
        var queue: [FileNode] = [self]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            visitor(current)
            queue.append(contentsOf: current.children)
        }
    }
    
    /// 查找节点
    /// - Parameter predicate: 查找条件
    /// - Returns: 第一个满足条件的节点
    public func findNode(where predicate: (FileNode) -> Bool) -> FileNode? {
        if predicate(self) {
            return self
        }
        
        for child in children {
            if let found = child.findNode(where: predicate) {
                return found
            }
        }
        
        return nil
    }
    
    /// 收集所有满足条件的节点
    /// - Parameter predicate: 查找条件
    /// - Returns: 所有满足条件的节点数组
    public func collectNodes(where predicate: (FileNode) -> Bool) -> [FileNode] {
        var result: [FileNode] = []
        
        if predicate(self) {
            result.append(self)
        }
        
        for child in children {
            result.append(contentsOf: child.collectNodes(where: predicate))
        }
        
        return result
    }
    
    // MARK: - Sorting
    
    /// 按名称排序子节点
    /// - Parameter ascending: 是否升序
    public func sortChildrenByName(ascending: Bool = true) {
        children.sort { ascending ? $0.name < $1.name : $0.name > $1.name }
    }
    
    /// 按大小排序子节点
    /// - Parameter ascending: 是否升序
    public func sortChildrenBySize(ascending: Bool = false) {
        children.sort { ascending ? $0.totalSize < $1.totalSize : $0.totalSize > $1.totalSize }
    }
    
    /// 按修改时间排序子节点
    /// - Parameter ascending: 是否升序
    public func sortChildrenByModifiedDate(ascending: Bool = false) {
        children.sort { ascending ? $0.modifiedAt < $1.modifiedAt : $0.modifiedAt > $1.modifiedAt }
    }
    
    // MARK: - Codable Support
    
    private enum CodingKeys: String, CodingKey {
        case id, name, path, size, isDirectory, createdAt, modifiedAt, accessedAt, permissions
        case children, isExpanded, isSelected, scanStatus, error
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int64.self, forKey: .size)
        isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        accessedAt = try container.decode(Date.self, forKey: .accessedAt)
        permissions = try container.decode(String.self, forKey: .permissions)
        
        children = try container.decode([FileNode].self, forKey: .children)
        isExpanded = try container.decode(Bool.self, forKey: .isExpanded)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        scanStatus = try container.decode(ScanStatus.self, forKey: .scanStatus)
        error = try container.decodeIfPresent(ScanError.self, forKey: .error)
        
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
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(accessedAt, forKey: .accessedAt)
        try container.encode(permissions, forKey: .permissions)
        
        try container.encode(children, forKey: .children)
        try container.encode(isExpanded, forKey: .isExpanded)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(scanStatus, forKey: .scanStatus)
        try container.encodeIfPresent(error, forKey: .error)
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

// MARK: - CustomStringConvertible

extension FileNode: CustomStringConvertible {
    public var description: String {
        let sizeStr = ByteFormatter.shared.string(fromByteCount: totalSize)
        let typeStr = isDirectory ? "📁" : "📄"
        return "\(typeStr) \(name) (\(sizeStr))"
    }
}

// MARK: - Thread Safety Extensions

extension FileNode {
    /// 线程安全地读取属性
    /// - Parameter block: 读取操作
    /// - Returns: 读取结果
    public func safeRead<T>(_ block: (FileNode) -> T) -> T {
        let queue = DispatchQueue(label: "FileNode.access", attributes: .concurrent)
        return queue.sync {
            return block(self)
        }
    }
    
    /// 线程安全地写入属性
    /// - Parameter block: 写入操作
    public func safeWrite(_ block: @escaping (FileNode) -> Void) {
        let queue = DispatchQueue(label: "FileNode.access", attributes: .concurrent)
        queue.async(flags: .barrier) {
            block(self)
        }
    }
}
