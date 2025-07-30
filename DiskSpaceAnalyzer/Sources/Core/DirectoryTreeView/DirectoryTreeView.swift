import Foundation
import AppKit
import Combine

/// 目录树显示模块 - 统一的目录树管理接口
public class DirectoryTreeView {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = DirectoryTreeView()
    
    /// 目录树控制器
    public let treeController: DirectoryTreeViewController
    
    /// 智能目录节点根节点
    public var rootNode: SmartDirectoryNode? {
        get { treeController.rootNode }
        set { treeController.rootNode = newValue }
    }
    
    /// 展开状态管理器
    public var expansionManager: TreeExpansionManager {
        return treeController.expansionManager
    }
    
    /// 目录合并器
    public var directoryMerger: DirectoryMerger {
        return treeController.directoryMerger
    }
    
    /// 配置
    public struct Configuration {
        public let maxDisplayDirectories: Int
        public let maxExpandedNodes: Int
        public let enableVirtualization: Bool
        public let responseTimeTarget: TimeInterval  // 目标响应时间
        
        public init(maxDisplayDirectories: Int = 10, maxExpandedNodes: Int = 100, enableVirtualization: Bool = true, responseTimeTarget: TimeInterval = 0.05) {
            self.maxDisplayDirectories = maxDisplayDirectories
            self.maxExpandedNodes = maxExpandedNodes
            self.enableVirtualization = enableVirtualization
            self.responseTimeTarget = responseTimeTarget
        }
    }
    
    /// 当前配置
    private var configuration: Configuration
    
    /// 选择变化回调
    public var selectionChangeCallback: ((SmartDirectoryNode?) -> Void)? {
        get { treeController.selectionChangeCallback }
        set { treeController.selectionChangeCallback = newValue }
    }
    
    /// 双击回调
    public var doubleClickCallback: ((SmartDirectoryNode) -> Void)? {
        get { treeController.doubleClickCallback }
        set { treeController.doubleClickCallback = newValue }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = Configuration()
        self.treeController = DirectoryTreeViewController()
        
        setupConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// 配置目录树
    public func configure(with config: Configuration) {
        self.configuration = config
        setupConfiguration()
    }
    
    /// 从FileNode创建并设置根节点
    public func setRootNode(from fileNode: FileNode) {
        guard fileNode.isDirectory else {
            print("Warning: Root node must be a directory")
            return
        }
        
        let smartNode = SmartDirectoryNode.createTree(from: fileNode)
        rootNode = smartNode
        
        // 应用目录合并
        if let root = smartNode {
            directoryMerger.processDirectoryTree(root)
        }
        
        // 刷新显示
        treeController.updateTreeData()
    }
    
    /// 更新节点数据
    public func updateNode(_ node: SmartDirectoryNode) {
        node.invalidateCache()
        treeController.reloadData()
    }
    
    /// 展开节点
    public func expandNode(_ node: SmartDirectoryNode) {
        treeController.expandNode(node)
    }
    
    /// 折叠节点
    public func collapseNode(_ node: SmartDirectoryNode) {
        treeController.collapseNode(node)
    }
    
    /// 选择节点
    public func selectNode(_ node: SmartDirectoryNode) {
        treeController.selectNode(node)
    }
    
    /// 获取选中的节点
    public func getSelectedNode() -> SmartDirectoryNode? {
        return treeController.getSelectedNode()
    }
    
    /// 展开所有节点
    public func expandAll() {
        guard let root = rootNode else { return }
        expansionManager.expandAll([root])
        treeController.reloadData()
    }
    
    /// 折叠所有节点
    public func collapseAll() {
        expansionManager.collapseAll()
        treeController.reloadData()
    }
    
    /// 查找节点
    public func findNode(withId id: UUID) -> SmartDirectoryNode? {
        return rootNode?.findDescendant(withId: id)
    }
    
    /// 查找节点（按路径）
    public func findNode(withPath path: String) -> SmartDirectoryNode? {
        return findNodeByPath(path, in: rootNode)
    }
    
    /// 获取节点统计信息
    public func getNodeStatistics(_ node: SmartDirectoryNode) -> [String: Any] {
        return [
            "name": node.displayName,
            "path": node.path,
            "totalSize": node.totalSize,
            "formattedSize": node.formattedSize,
            "fileCount": node.fileCount,
            "directoryCount": node.directoryCount,
            "depth": node.depth,
            "isLeaf": node.isLeaf,
            "percentageOfParent": node.percentageOfParent,
            "childrenCount": node.children.count
        ]
    }
    
    /// 获取树统计信息
    public func getTreeStatistics() -> [String: Any] {
        guard let root = rootNode else {
            return ["hasRoot": false]
        }
        
        let allNodes = collectAllNodes([root])
        let expandedCount = expansionManager.getExpandedNodeIds().count
        
        return [
            "hasRoot": true,
            "rootName": root.displayName,
            "totalNodes": allNodes.count,
            "expandedNodes": expandedCount,
            "maxDisplayDirectories": configuration.maxDisplayDirectories,
            "maxExpandedNodes": configuration.maxExpandedNodes,
            "totalSize": root.totalSize,
            "formattedTotalSize": root.formattedSize
        ]
    }
    
    /// 导出树结构报告
    public func exportTreeReport() -> String {
        var report = "=== Directory Tree Report ===\n\n"
        
        let stats = getTreeStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Configuration:\n"
        report += "  Max Display Directories: \(configuration.maxDisplayDirectories)\n"
        report += "  Max Expanded Nodes: \(configuration.maxExpandedNodes)\n"
        report += "  Virtualization Enabled: \(configuration.enableVirtualization)\n"
        report += "  Response Time Target: \(String(format: "%.0fms", configuration.responseTimeTarget * 1000))\n\n"
        
        if let hasRoot = stats["hasRoot"] as? Bool, hasRoot {
            report += "=== Tree Statistics ===\n"
            report += "Root: \(stats["rootName"] ?? "Unknown")\n"
            report += "Total Nodes: \(stats["totalNodes"] ?? 0)\n"
            report += "Expanded Nodes: \(stats["expandedNodes"] ?? 0)\n"
            report += "Total Size: \(stats["formattedTotalSize"] ?? "Unknown")\n\n"
            
            // 展开状态详情
            let expandedIds = expansionManager.getExpandedNodeIds()
            report += "=== Expanded Nodes ===\n"
            for nodeId in expandedIds {
                if let node = findNode(withId: nodeId) {
                    report += "\(node.displayName) (\(node.formattedSize))\n"
                }
            }
        } else {
            report += "No root node set.\n"
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置配置
    private func setupConfiguration() {
        directoryMerger.maxDisplayDirectories = configuration.maxDisplayDirectories
        expansionManager.maxExpandedNodes = configuration.maxExpandedNodes
    }
    
    /// 按路径查找节点
    private func findNodeByPath(_ path: String, in node: SmartDirectoryNode?) -> SmartDirectoryNode? {
        guard let node = node else { return nil }
        
        if node.path == path {
            return node
        }
        
        for child in node.children {
            if let found = findNodeByPath(path, in: child) {
                return found
            }
        }
        
        return nil
    }
    
    /// 收集所有节点
    private func collectAllNodes(_ nodes: [SmartDirectoryNode]) -> [SmartDirectoryNode] {
        var allNodes: [SmartDirectoryNode] = []
        
        for node in nodes {
            allNodes.append(node)
            allNodes.append(contentsOf: collectAllNodes(node.children))
        }
        
        return allNodes
    }
}

// MARK: - Global Convenience Functions

/// 全局目录树访问函数
public func getDirectoryTree() -> DirectoryTreeView {
    return DirectoryTreeView.shared
}

/// 设置目录树根节点
public func setDirectoryTreeRoot(_ fileNode: FileNode) {
    DirectoryTreeView.shared.setRootNode(from: fileNode)
}

/// 获取目录树统计信息
public func getDirectoryTreeStats() -> [String: Any] {
    return DirectoryTreeView.shared.getTreeStatistics()
}
