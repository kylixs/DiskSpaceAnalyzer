import Foundation

/// 目录合并器 - 实现Top10算法和目录合并
public class DirectoryMerger {
    
    // MARK: - Properties
    
    /// 最大显示目录数
    public var maxDisplayDirectories: Int = 10
    
    /// 合并节点的名称模板
    public var mergedNodeNameTemplate: String = "其他(%d个目录)"
    
    // MARK: - Public Methods
    
    /// 处理目录列表，应用Top10算法
    public func processDirectories(_ directories: [SmartDirectoryNode]) -> [SmartDirectoryNode] {
        guard directories.count > maxDisplayDirectories else {
            return directories
        }
        
        // 按大小排序
        let sortedDirectories = directories.sorted { $0.totalSize > $1.totalSize }
        
        // 取前N个目录
        let topDirectories = Array(sortedDirectories.prefix(maxDisplayDirectories))
        
        // 剩余目录
        let remainingDirectories = Array(sortedDirectories.dropFirst(maxDisplayDirectories))
        
        // 如果有剩余目录，创建合并节点
        if !remainingDirectories.isEmpty {
            let mergedNode = createMergedNode(from: remainingDirectories)
            return topDirectories + [mergedNode]
        }
        
        return topDirectories
    }
    
    /// 递归处理目录树
    public func processDirectoryTree(_ node: SmartDirectoryNode) {
        // 处理当前节点的子节点
        let processedChildren = processDirectories(node.children)
        
        // 更新子节点
        node.children = processedChildren
        
        // 递归处理子节点
        for child in node.children {
            if !child.isMergedNode {
                processDirectoryTree(child)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建合并节点
    private func createMergedNode(from directories: [SmartDirectoryNode]) -> SmartDirectoryNode {
        // 创建虚拟的FileNode
        let totalSize = directories.reduce(0) { $0 + $1.totalSize }
        let mergedName = String(format: mergedNodeNameTemplate, directories.count)
        
        let mergedFileNode = FileNode(
            name: mergedName,
            path: "merged://\(UUID().uuidString)",
            size: totalSize,
            isDirectory: true,
            createdDate: Date(),
            modifiedDate: Date(),
            permissions: FilePermissions()
        )
        
        let mergedNode = SmartDirectoryNode(fileNode: mergedFileNode)
        
        // 标记为合并节点
        mergedNode.isMergedNode = true
        mergedNode.mergedDirectories = directories
        
        // 设置子节点
        for directory in directories {
            mergedNode.addChild(directory)
        }
        
        return mergedNode
    }
}

/// TreeExpansionManager - 展开状态管理器
public class TreeExpansionManager {
    
    // MARK: - Properties
    
    /// 展开状态存储
    private var expandedNodes: Set<UUID> = []
    
    /// 展开历史
    private var expansionHistory: [UUID] = []
    
    /// 最大展开数限制
    public var maxExpandedNodes: Int = 100
    
    /// 持久化键
    private let persistenceKey = "DirectoryTreeExpansionState"
    
    // MARK: - Initialization
    
    public init() {
        loadState()
    }
    
    // MARK: - Public Methods
    
    /// 设置节点展开状态
    public func setExpanded(_ nodeId: UUID, expanded: Bool) {
        if expanded {
            expandNode(nodeId)
        } else {
            collapseNode(nodeId)
        }
        
        saveState()
    }
    
    /// 检查节点是否展开
    public func isExpanded(_ nodeId: UUID) -> Bool {
        return expandedNodes.contains(nodeId)
    }
    
    /// 展开节点
    public func expandNode(_ nodeId: UUID) {
        // 如果已经展开，更新历史顺序
        if expandedNodes.contains(nodeId) {
            expansionHistory.removeAll { $0 == nodeId }
            expansionHistory.append(nodeId)
            return
        }
        
        // 检查是否超过最大展开数
        if expandedNodes.count >= maxExpandedNodes {
            // 移除最旧的展开节点
            if let oldestNode = expansionHistory.first {
                expandedNodes.remove(oldestNode)
                expansionHistory.removeFirst()
            }
        }
        
        // 添加新的展开节点
        expandedNodes.insert(nodeId)
        expansionHistory.append(nodeId)
    }
    
    /// 折叠节点
    public func collapseNode(_ nodeId: UUID) {
        expandedNodes.remove(nodeId)
        expansionHistory.removeAll { $0 == nodeId }
    }
    
    /// 批量展开节点
    public func expandNodes(_ nodeIds: [UUID]) {
        for nodeId in nodeIds {
            expandNode(nodeId)
        }
        saveState()
    }
    
    /// 批量折叠节点
    public func collapseNodes(_ nodeIds: [UUID]) {
        for nodeId in nodeIds {
            collapseNode(nodeId)
        }
        saveState()
    }
    
    /// 展开所有节点
    public func expandAll(_ nodes: [SmartDirectoryNode]) {
        let allNodeIds = collectAllNodeIds(nodes)
        expandNodes(allNodeIds)
    }
    
    /// 折叠所有节点
    public func collapseAll() {
        expandedNodes.removeAll()
        expansionHistory.removeAll()
        saveState()
    }
    
    /// 获取展开的节点ID列表
    public func getExpandedNodeIds() -> Set<UUID> {
        return expandedNodes
    }
    
    /// 获取展开历史
    public func getExpansionHistory() -> [UUID] {
        return expansionHistory
    }
    
    /// 清除状态
    public func clearState() {
        expandedNodes.removeAll()
        expansionHistory.removeAll()
        saveState()
    }
    
    // MARK: - Private Methods
    
    /// 收集所有节点ID
    private func collectAllNodeIds(_ nodes: [SmartDirectoryNode]) -> [UUID] {
        var nodeIds: [UUID] = []
        
        for node in nodes {
            nodeIds.append(node.id)
            nodeIds.append(contentsOf: collectAllNodeIds(node.children))
        }
        
        return nodeIds
    }
    
    /// 保存状态
    private func saveState() {
        let data = [
            "expandedNodes": Array(expandedNodes).map { $0.uuidString },
            "expansionHistory": expansionHistory.map { $0.uuidString }
        ]
        
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }
    
    /// 加载状态
    private func loadState() {
        guard let data = UserDefaults.standard.dictionary(forKey: persistenceKey) else { return }
        
        if let expandedNodeStrings = data["expandedNodes"] as? [String] {
            expandedNodes = Set(expandedNodeStrings.compactMap { UUID(uuidString: $0) })
        }
        
        if let historyStrings = data["expansionHistory"] as? [String] {
            expansionHistory = historyStrings.compactMap { UUID(uuidString: $0) }
        }
    }
}

// MARK: - SmartDirectoryNode Extensions

extension SmartDirectoryNode {
    
    /// 是否为合并节点
    public var isMergedNode: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isMergedNode) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isMergedNode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 合并的目录列表
    public var mergedDirectories: [SmartDirectoryNode]? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.mergedDirectories) as? [SmartDirectoryNode]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.mergedDirectories, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    static var isMergedNode = "isMergedNode"
    static var mergedDirectories = "mergedDirectories"
}
