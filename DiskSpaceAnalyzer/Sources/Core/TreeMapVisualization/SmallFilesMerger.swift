import Foundation

/// 小文件合并结果
public struct SmallFilesMergeResult {
    public let nodes: [FileNode]
    public let mergedCount: Int
    public let mergedSize: Int64
    
    public init(nodes: [FileNode], mergedCount: Int, mergedSize: Int64) {
        self.nodes = nodes
        self.mergedCount = mergedCount
        self.mergedSize = mergedSize
    }
}

/// 小文件合并器 - 识别并合并小文件
public class SmallFilesMerger {
    
    // MARK: - Properties
    
    /// 小文件阈值（百分比）
    public var threshold: Double = 0.01  // 1%
    
    /// 最大显示小文件数
    public var maxSmallFilesToShow: Int = 4
    
    /// 合并节点名称模板
    public var mergedNodeNameTemplate: String = "其他文件(%d个)"
    
    // MARK: - Public Methods
    
    /// 合并小文件
    public func mergeSmallFiles(_ nodes: [FileNode], totalSize: Int64) -> SmallFilesMergeResult {
        guard !nodes.isEmpty && totalSize > 0 else {
            return SmallFilesMergeResult(nodes: nodes, mergedCount: 0, mergedSize: 0)
        }
        
        // 计算阈值大小
        let thresholdSize = Int64(Double(totalSize) * threshold)
        
        // 分离大文件和小文件
        let (largeFiles, smallFiles) = separateFiles(nodes, thresholdSize: thresholdSize)
        
        // 如果小文件数量不多，不需要合并
        if smallFiles.count <= maxSmallFilesToShow {
            return SmallFilesMergeResult(nodes: nodes, mergedCount: 0, mergedSize: 0)
        }
        
        // 保留最大的几个小文件
        let sortedSmallFiles = smallFiles.sorted { $0.size > $1.size }
        let keptSmallFiles = Array(sortedSmallFiles.prefix(maxSmallFilesToShow))
        let filesToMerge = Array(sortedSmallFiles.dropFirst(maxSmallFilesToShow))
        
        // 创建合并节点
        let mergedNode = createMergedNode(from: filesToMerge)
        
        // 组合结果
        var resultNodes = largeFiles + keptSmallFiles
        if let merged = mergedNode {
            resultNodes.append(merged)
        }
        
        return SmallFilesMergeResult(
            nodes: resultNodes,
            mergedCount: filesToMerge.count,
            mergedSize: filesToMerge.reduce(0) { $0 + $1.size }
        )
    }
    
    // MARK: - Private Methods
    
    /// 分离大文件和小文件
    private func separateFiles(_ nodes: [FileNode], thresholdSize: Int64) -> ([FileNode], [FileNode]) {
        var largeFiles: [FileNode] = []
        var smallFiles: [FileNode] = []
        
        for node in nodes {
            if node.size >= thresholdSize {
                largeFiles.append(node)
            } else {
                smallFiles.append(node)
            }
        }
        
        return (largeFiles, smallFiles)
    }
    
    /// 创建合并节点
    private func createMergedNode(from files: [FileNode]) -> FileNode? {
        guard !files.isEmpty else { return nil }
        
        let totalSize = files.reduce(0) { $0 + $1.size }
        let mergedName = String(format: mergedNodeNameTemplate, files.count)
        
        let mergedNode = FileNode(
            name: mergedName,
            path: "merged://small_files_\(UUID().uuidString)",
            size: totalSize,
            isDirectory: false,
            createdDate: Date(),
            modifiedDate: Date(),
            permissions: FilePermissions()
        )
        
        return mergedNode
    }
}
