import Foundation
import Combine

/// 目录树结构管理类
/// 支持高效的增删改查操作和多种遍历方式
public class DirectoryTree: ObservableObject {
    
    // MARK: - Properties
    
    /// 根节点
    @Published public private(set) var root: FileNode?
    
    /// 路径到节点的映射索引（提供O(1)查找）
    private var pathIndex: [String: FileNode] = [:]
    
    /// ID到节点的映射索引
    private var idIndex: [UUID: FileNode] = [:]
    
    /// 总节点数
    @Published public private(set) var nodeCount: Int = 0
    
    /// 总文件数
    @Published public private(set) var fileCount: Int = 0
    
    /// 总目录数
    @Published public private(set) var directoryCount: Int = 0
    
    /// 总大小
    @Published public private(set) var totalSize: Int64 = 0
    
    /// 最大深度
    @Published public private(set) var maxDepth: Int = 0
    
    /// 线程安全访问队列
    private let accessQueue = DispatchQueue(label: "DirectoryTree.access", attributes: .concurrent)
    
    /// 更新队列（用于批量操作）
    private let updateQueue = DispatchQueue(label: "DirectoryTree.update")
    
    /// 是否正在批量更新
    private var isBatchUpdating = false
    
    /// 批量更新的变更集合
    private var batchChanges: Set<String> = []
    
    // MARK: - Initialization
    
    public init() {
        // 空初始化
    }
    
    /// 使用根节点初始化
    /// - Parameter root: 根节点
    public init(root: FileNode) {
        setRoot(root)
    }
    
    // MARK: - Root Management
    
    /// 设置根节点
    /// - Parameter node: 新的根节点
    public func setRoot(_ node: FileNode) {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.root = node
            self?.rebuildIndex()
            self?.updateStatistics()
        }
    }
    
    /// 清除所有数据
    public func clear() {
        accessQueue.async(flags: .barrier) { [weak self] in
            self?.root = nil
            self?.pathIndex.removeAll()
            self?.idIndex.removeAll()
            self?.nodeCount = 0
            self?.fileCount = 0
            self?.directoryCount = 0
            self?.totalSize = 0
            self?.maxDepth = 0
        }
    }
    
    // MARK: - Node Operations
    
    /// 添加节点
    /// - Parameters:
    ///   - node: 要添加的节点
    ///   - parent: 父节点，如果为nil则作为根节点
    /// - Returns: 是否添加成功
    @discardableResult
    public func addNode(_ node: FileNode, to parent: FileNode? = nil) -> Bool {
        return accessQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return false }
            
            // 如果没有指定父节点且没有根节点，则设为根节点
            if parent == nil && self.root == nil {
                self.root = node
                self.addToIndex(node)
                self.updateStatisticsAfterAdd(node)
                return true
            }
            
            // 如果指定了父节点，添加为子节点
            if let parentNode = parent {
                parentNode.addChild(node)
                self.addToIndex(node)
                self.updateStatisticsAfterAdd(node)
                return true
            }
            
            return false
        }
    }
    
    /// 移除节点
    /// - Parameter node: 要移除的节点
    /// - Returns: 是否移除成功
    @discardableResult
    public func removeNode(_ node: FileNode) -> Bool {
        return accessQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return false }
            
            // 如果是根节点
            if node.id == self.root?.id {
                self.root = nil
                self.removeFromIndex(node)
                self.updateStatisticsAfterRemove(node)
                return true
            }
            
            // 如果有父节点，从父节点移除
            if let parent = node.parent {
                parent.removeChild(node)
                self.removeFromIndex(node)
                self.updateStatisticsAfterRemove(node)
                return true
            }
            
            return false
        }
    }
    
    /// 移动节点
    /// - Parameters:
    ///   - node: 要移动的节点
    ///   - newParent: 新的父节点
    /// - Returns: 是否移动成功
    @discardableResult
    public func moveNode(_ node: FileNode, to newParent: FileNode) -> Bool {
        return accessQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return false }
            
            // 检查是否会形成循环
            if self.wouldCreateCycle(moving: node, to: newParent) {
                return false
            }
            
            // 从原父节点移除
            node.parent?.removeChild(node)
            
            // 添加到新父节点
            newParent.addChild(node)
            
            // 更新索引
            self.updatePathIndex(for: node)
            
            return true
        }
    }
    
    // MARK: - Search Operations
    
    /// 根据路径查找节点
    /// - Parameter path: 节点路径
    /// - Returns: 找到的节点，如果不存在返回nil
    public func findNode(at path: String) -> FileNode? {
        return accessQueue.sync {
            return pathIndex[path]
        }
    }
    
    /// 根据ID查找节点
    /// - Parameter id: 节点ID
    /// - Returns: 找到的节点，如果不存在返回nil
    public func findNode(by id: UUID) -> FileNode? {
        return accessQueue.sync {
            return idIndex[id]
        }
    }
    
    /// 根据名称查找节点
    /// - Parameter name: 节点名称
    /// - Returns: 所有匹配的节点
    public func findNodes(named name: String) -> [FileNode] {
        return accessQueue.sync {
            return pathIndex.values.filter { $0.name == name }
        }
    }
    
    /// 根据条件查找节点
    /// - Parameter predicate: 查找条件
    /// - Returns: 所有满足条件的节点
    public func findNodes(where predicate: (FileNode) -> Bool) -> [FileNode] {
        return accessQueue.sync {
            return pathIndex.values.filter(predicate)
        }
    }
    
    /// 查找最大的文件
    /// - Parameter count: 返回的文件数量
    /// - Returns: 按大小排序的文件列表
    public func findLargestFiles(count: Int = 10) -> [FileNode] {
        return accessQueue.sync {
            return pathIndex.values
                .filter { !$0.isDirectory }
                .sorted { $0.size > $1.size }
                .prefix(count)
                .map { $0 }
        }
    }
    
    /// 查找最大的目录
    /// - Parameter count: 返回的目录数量
    /// - Returns: 按总大小排序的目录列表
    public func findLargestDirectories(count: Int = 10) -> [FileNode] {
        return accessQueue.sync {
            return pathIndex.values
                .filter { $0.isDirectory }
                .sorted { $0.totalSize > $1.totalSize }
                .prefix(count)
                .map { $0 }
        }
    }
    
    // MARK: - Traversal Operations
    
    /// 深度优先遍历
    /// - Parameter visitor: 访问者函数
    public func depthFirstTraversal(_ visitor: (FileNode) -> Void) {
        accessQueue.sync {
            root?.depthFirstTraversal(visitor)
        }
    }
    
    /// 广度优先遍历
    /// - Parameter visitor: 访问者函数
    public func breadthFirstTraversal(_ visitor: (FileNode) -> Void) {
        accessQueue.sync {
            root?.breadthFirstTraversal(visitor)
        }
    }
    
    /// 按层级遍历
    /// - Parameter visitor: 访问者函数，参数为(节点, 层级)
    public func levelOrderTraversal(_ visitor: (FileNode, Int) -> Void) {
        accessQueue.sync {
            guard let root = self.root else { return }
            
            var queue: [(FileNode, Int)] = [(root, 0)]
            
            while !queue.isEmpty {
                let (current, level) = queue.removeFirst()
                visitor(current, level)
                
                for child in current.children {
                    queue.append((child, level + 1))
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// 开始批量更新
    public func beginBatchUpdate() {
        updateQueue.sync {
            isBatchUpdating = true
            batchChanges.removeAll()
        }
    }
    
    /// 结束批量更新
    public func endBatchUpdate() {
        updateQueue.sync {
            isBatchUpdating = false
            
            // 处理批量变更
            if !batchChanges.isEmpty {
                accessQueue.async(flags: .barrier) { [weak self] in
                    self?.processBatchChanges()
                }
            }
            
            batchChanges.removeAll()
        }
    }
    
    /// 批量添加节点
    /// - Parameter nodes: 要添加的节点数组，格式为[(节点, 父节点路径)]
    public func batchAddNodes(_ nodes: [(FileNode, String?)]) {
        beginBatchUpdate()
        
        for (node, parentPath) in nodes {
            let parent = parentPath != nil ? findNode(at: parentPath!) : nil
            addNode(node, to: parent)
        }
        
        endBatchUpdate()
    }
    
    /// 批量移除节点
    /// - Parameter nodes: 要移除的节点数组
    public func batchRemoveNodes(_ nodes: [FileNode]) {
        beginBatchUpdate()
        
        for node in nodes {
            removeNode(node)
        }
        
        endBatchUpdate()
    }
    
    // MARK: - Statistics and Analysis
    
    /// 获取目录树统计信息
    /// - Returns: 统计信息结构
    public func getStatistics() -> TreeStatistics {
        return accessQueue.sync {
            return TreeStatistics(
                nodeCount: nodeCount,
                fileCount: fileCount,
                directoryCount: directoryCount,
                totalSize: totalSize,
                maxDepth: maxDepth,
                averageChildrenPerDirectory: directoryCount > 0 ? Double(nodeCount - directoryCount) / Double(directoryCount) : 0
            )
        }
    }
    
    /// 分析目录大小分布
    /// - Returns: 大小分布信息
    public func analyzeSizeDistribution() -> SizeDistribution {
        return accessQueue.sync {
            let directories = pathIndex.values.filter { $0.isDirectory }
            let sizes = directories.map { $0.totalSize }
            
            guard !sizes.isEmpty else {
                return SizeDistribution(min: 0, max: 0, average: 0, median: 0, standardDeviation: 0)
            }
            
            let sortedSizes = sizes.sorted()
            let min = sortedSizes.first!
            let max = sortedSizes.last!
            let average = sizes.reduce(0, +) / Int64(sizes.count)
            let median = sortedSizes[sortedSizes.count / 2]
            
            // 计算标准差
            let variance = sizes.map { pow(Double($0 - average), 2) }.reduce(0, +) / Double(sizes.count)
            let standardDeviation = sqrt(variance)
            
            return SizeDistribution(
                min: min,
                max: max,
                average: average,
                median: median,
                standardDeviation: standardDeviation
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// 重建索引
    private func rebuildIndex() {
        pathIndex.removeAll()
        idIndex.removeAll()
        
        guard let root = self.root else { return }
        
        root.depthFirstTraversal { [weak self] node in
            self?.addToIndex(node)
        }
    }
    
    /// 添加节点到索引
    /// - Parameter node: 要添加的节点
    private func addToIndex(_ node: FileNode) {
        pathIndex[node.path] = node
        idIndex[node.id] = node
        
        // 递归添加子节点
        for child in node.children {
            addToIndex(child)
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
    
    /// 更新路径索引
    /// - Parameter node: 要更新的节点
    private func updatePathIndex(for node: FileNode) {
        // 移除旧路径
        let oldPaths = pathIndex.compactMap { (path, indexedNode) in
            indexedNode.id == node.id ? path : nil
        }
        
        for oldPath in oldPaths {
            pathIndex.removeValue(forKey: oldPath)
        }
        
        // 添加新路径
        node.depthFirstTraversal { [weak self] node in
            self?.pathIndex[node.path] = node
        }
    }
    
    /// 检查移动操作是否会创建循环
    /// - Parameters:
    ///   - node: 要移动的节点
    ///   - newParent: 新的父节点
    /// - Returns: 是否会创建循环
    private func wouldCreateCycle(moving node: FileNode, to newParent: FileNode) -> Bool {
        var current: FileNode? = newParent
        
        while current != nil {
            if current?.id == node.id {
                return true
            }
            current = current?.parent
        }
        
        return false
    }
    
    /// 更新统计信息
    private func updateStatistics() {
        guard let root = self.root else {
            nodeCount = 0
            fileCount = 0
            directoryCount = 0
            totalSize = 0
            maxDepth = 0
            return
        }
        
        var tempNodeCount = 0
        var tempFileCount = 0
        var tempDirectoryCount = 0
        var tempTotalSize: Int64 = 0
        var tempMaxDepth = 0
        
        root.depthFirstTraversal { node in
            tempNodeCount += 1
            
            if node.isDirectory {
                tempDirectoryCount += 1
            } else {
                tempFileCount += 1
                tempTotalSize += node.size
            }
            
            tempMaxDepth = max(tempMaxDepth, node.depth)
        }
        
        nodeCount = tempNodeCount
        fileCount = tempFileCount
        directoryCount = tempDirectoryCount
        totalSize = tempTotalSize
        maxDepth = tempMaxDepth
    }
    
    /// 添加节点后更新统计信息
    /// - Parameter node: 添加的节点
    private func updateStatisticsAfterAdd(_ node: FileNode) {
        var addedNodes = 0
        var addedFiles = 0
        var addedDirectories = 0
        var addedSize: Int64 = 0
        
        node.depthFirstTraversal { node in
            addedNodes += 1
            
            if node.isDirectory {
                addedDirectories += 1
            } else {
                addedFiles += 1
                addedSize += node.size
            }
            
            maxDepth = max(maxDepth, node.depth)
        }
        
        nodeCount += addedNodes
        fileCount += addedFiles
        directoryCount += addedDirectories
        totalSize += addedSize
    }
    
    /// 移除节点后更新统计信息
    /// - Parameter node: 移除的节点
    private func updateStatisticsAfterRemove(_ node: FileNode) {
        var removedNodes = 0
        var removedFiles = 0
        var removedDirectories = 0
        var removedSize: Int64 = 0
        
        node.depthFirstTraversal { node in
            removedNodes += 1
            
            if node.isDirectory {
                removedDirectories += 1
            } else {
                removedFiles += 1
                removedSize += node.size
            }
        }
        
        nodeCount -= removedNodes
        fileCount -= removedFiles
        directoryCount -= removedDirectories
        totalSize -= removedSize
        
        // 重新计算最大深度
        if nodeCount > 0 {
            updateStatistics()
        } else {
            maxDepth = 0
        }
    }
    
    /// 处理批量变更
    private func processBatchChanges() {
        // 重建索引和统计信息
        rebuildIndex()
        updateStatistics()
    }
}

// MARK: - Supporting Types

/// 目录树统计信息
public struct TreeStatistics {
    public let nodeCount: Int
    public let fileCount: Int
    public let directoryCount: Int
    public let totalSize: Int64
    public let maxDepth: Int
    public let averageChildrenPerDirectory: Double
    
    public init(nodeCount: Int, fileCount: Int, directoryCount: Int, totalSize: Int64, maxDepth: Int, averageChildrenPerDirectory: Double) {
        self.nodeCount = nodeCount
        self.fileCount = fileCount
        self.directoryCount = directoryCount
        self.totalSize = totalSize
        self.maxDepth = maxDepth
        self.averageChildrenPerDirectory = averageChildrenPerDirectory
    }
}

/// 大小分布信息
public struct SizeDistribution {
    public let min: Int64
    public let max: Int64
    public let average: Int64
    public let median: Int64
    public let standardDeviation: Double
    
    public init(min: Int64, max: Int64, average: Int64, median: Int64, standardDeviation: Double) {
        self.min = min
        self.max = max
        self.average = average
        self.median = median
        self.standardDeviation = standardDeviation
    }
}

// MARK: - Thread Safety Extensions

extension DirectoryTree {
    /// 线程安全地读取数据
    /// - Parameter block: 读取操作
    /// - Returns: 读取结果
    public func safeRead<T>(_ block: (DirectoryTree) -> T) -> T {
        return accessQueue.sync {
            return block(self)
        }
    }
    
    /// 线程安全地写入数据
    /// - Parameter block: 写入操作
    public func safeWrite(_ block: (DirectoryTree) -> Void) {
        accessQueue.async(flags: .barrier) {
            block(self)
        }
    }
}
