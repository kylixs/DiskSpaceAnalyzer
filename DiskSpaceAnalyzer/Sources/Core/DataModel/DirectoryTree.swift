import Foundation

/// 文件类型枚举
public enum FileType {
    case directory
    case regularFile
    case symbolicLink
    case other
}

/// 目录树结构管理类
/// 支持高效的增删改查操作和多种遍历方式
public class DirectoryTree: ObservableObject {
    
    // MARK: - Properties
    
    /// 根节点
    @Published public private(set) var rootNode: FileNode?
    
    /// 路径到节点的映射索引（O(1)查找）
    private var pathIndex: [String: FileNode] = [:]
    
    /// ID到节点的映射索引
    private var idIndex: [UUID: FileNode] = [:]
    
    /// 读写锁（保证线程安全）
    private let accessQueue = DispatchQueue(label: "DirectoryTree.access", attributes: .concurrent)
    
    // MARK: - Initialization
    
    public init() {}
    
    public init(rootNode: FileNode) {
        setRootNode(rootNode)
    }
    
    // MARK: - Public Methods
    
    /// 设置根节点
    /// - Parameter node: 根节点
    public func setRootNode(_ node: FileNode) {
        accessQueue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.rootNode = node
                self.rebuildIndex()
            }
        }
    }
    
    /// 添加节点到指定父节点
    /// - Parameters:
    ///   - node: 要添加的节点
    ///   - parent: 父节点
    public func addNode(_ node: FileNode, to parent: FileNode) {
        accessQueue.async(flags: .barrier) {
            parent.addChild(node)
            self.updateIndex(for: node)
        }
    }
    
    /// 移除节点
    /// - Parameter node: 要移除的节点
    public func removeNode(_ node: FileNode) {
        accessQueue.async(flags: .barrier) {
            if let parent = node.parent {
                parent.removeChild(node)
            }
            self.removeFromIndex(node)
        }
    }
    
    /// 根据路径查找节点
    /// - Parameter path: 文件路径
    /// - Returns: 找到的节点或nil
    public func findNode(at path: String) -> FileNode? {
        return accessQueue.sync {
            return pathIndex[path]
        }
    }
    
    /// 根据ID查找节点
    /// - Parameter id: 节点ID
    /// - Returns: 找到的节点或nil
    public func findNode(by id: UUID) -> FileNode? {
        return accessQueue.sync {
            return idIndex[id]
        }
    }
    
    /// 获取所有节点（按大小排序）
    /// - Parameter limit: 限制数量
    /// - Returns: 排序后的节点数组
    public func getNodesBySize(limit: Int = Int.max) -> [FileNode] {
        return accessQueue.sync {
            let allNodes = getAllNodes()
            let sortedNodes = allNodes.sorted { $0.totalSize > $1.totalSize }
            return Array(sortedNodes.prefix(limit))
        }
    }
    
    /// 获取指定类型的节点
    /// - Parameter type: 文件类型
    /// - Returns: 符合条件的节点数组
    public func getNodes(ofType type: FileType) -> [FileNode] {
        return accessQueue.sync {
            let allNodes = getAllNodes()
            return allNodes.filter { node in
                switch type {
                case .directory:
                    return node.isDirectory
                case .regularFile:
                    return !node.isDirectory
                case .symbolicLink:
                    // 这里可以根据需要扩展符号链接检测
                    return false
                case .other:
                    return false
                }
            }
        }
    }
    
    /// 深度优先遍历
    /// - Parameter visitor: 访问者函数
    public func traverseDepthFirst(_ visitor: (FileNode) -> Bool) {
        guard let root = rootNode else { return }
        traverseDepthFirstRecursive(root, visitor: visitor)
    }
    
    /// 广度优先遍历
    /// - Parameter visitor: 访问者函数
    public func traverseBreadthFirst(_ visitor: (FileNode) -> Bool) {
        guard let root = rootNode else { return }
        
        var queue: [FileNode] = [root]
        
        while !queue.isEmpty {
            let node = queue.removeFirst()
            
            if !visitor(node) {
                break
            }
            
            queue.append(contentsOf: node.children)
        }
    }
    
    /// 获取树的统计信息
    /// - Returns: 树统计信息
    public func getStatistics() -> TreeStatistics {
        guard let root = rootNode else {
            return TreeStatistics()
        }
        
        return accessQueue.sync {
            var totalFiles = 0
            var totalDirectories = 0
            var totalSize: Int64 = 0
            var maxDepth = 0
            
            traverseDepthFirstRecursive(root) { node in
                if node.isDirectory {
                    totalDirectories += 1
                } else {
                    totalFiles += 1
                }
                totalSize += node.size
                maxDepth = max(maxDepth, node.depth)
                return true
            }
            
            return TreeStatistics(
                totalFiles: totalFiles,
                totalDirectories: totalDirectories,
                totalSize: totalSize,
                maxDepth: maxDepth
            )
        }
    }
    
    /// 清空树
    public func clear() {
        accessQueue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.rootNode = nil
                self.pathIndex.removeAll()
                self.idIndex.removeAll()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 重建索引
    private func rebuildIndex() {
        pathIndex.removeAll()
        idIndex.removeAll()
        
        guard let root = rootNode else { return }
        
        traverseDepthFirstRecursive(root) { node in
            pathIndex[node.path] = node
            idIndex[node.id] = node
            return true
        }
    }
    
    /// 更新索引
    /// - Parameter node: 要更新的节点
    private func updateIndex(for node: FileNode) {
        pathIndex[node.path] = node
        idIndex[node.id] = node
        
        // 递归更新子节点
        for child in node.children {
            updateIndex(for: child)
        }
    }
    
    /// 从索引中移除节点
    /// - Parameter node: 要移除的节点
    private func removeFromIndex(_ node: FileNode) {
        pathIndex.removeValue(forKey: node.path)
        idIndex.removeValue(forKey: node.id)
        
        // 递归移除子节点
        for child in node.children {
            removeFromIndex(child)
        }
    }
    
    /// 深度优先遍历（递归实现）
    /// - Parameters:
    ///   - node: 当前节点
    ///   - visitor: 访问者函数
    private func traverseDepthFirstRecursive(_ node: FileNode, visitor: (FileNode) -> Bool) {
        if !visitor(node) {
            return
        }
        
        for child in node.children {
            traverseDepthFirstRecursive(child, visitor: visitor)
        }
    }
    
    /// 获取所有节点
    /// - Returns: 所有节点数组
    private func getAllNodes() -> [FileNode] {
        guard let root = rootNode else { return [] }
        
        var nodes: [FileNode] = []
        traverseDepthFirstRecursive(root) { node in
            nodes.append(node)
            return true
        }
        return nodes
    }
}

// MARK: - Supporting Types

/// 树统计信息
public struct TreeStatistics {
    public let totalFiles: Int
    public let totalDirectories: Int
    public let totalSize: Int64
    public let maxDepth: Int
    
    public init(
        totalFiles: Int = 0,
        totalDirectories: Int = 0,
        totalSize: Int64 = 0,
        maxDepth: Int = 0
    ) {
        self.totalFiles = totalFiles
        self.totalDirectories = totalDirectories
        self.totalSize = totalSize
        self.maxDepth = maxDepth
    }
    
    /// 格式化的总大小
    public var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Extensions

extension DirectoryTree {
    
    /// 批量操作
    /// - Parameter operations: 操作闭包
    public func performBatchOperations(_ operations: @escaping () -> Void) {
        accessQueue.async(flags: .barrier) {
            operations()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// 搜索节点
    /// - Parameters:
    ///   - predicate: 搜索条件
    ///   - limit: 结果限制
    /// - Returns: 搜索结果
    public func searchNodes(where predicate: (FileNode) -> Bool, limit: Int = Int.max) -> [FileNode] {
        return accessQueue.sync {
            let allNodes = getAllNodes()
            let matchingNodes = allNodes.filter(predicate)
            return Array(matchingNodes.prefix(limit))
        }
    }
    
    /// 获取路径下的直接子节点
    /// - Parameter path: 父路径
    /// - Returns: 子节点数组
    public func getChildren(at path: String) -> [FileNode] {
        guard let parentNode = findNode(at: path) else { return [] }
        return parentNode.children
    }
}
