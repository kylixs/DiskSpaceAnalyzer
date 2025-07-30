import Foundation
import Combine

/// 智能目录节点 - 封装目录的显示逻辑和统计计算
public class SmartDirectoryNode: ObservableObject, Identifiable {
    
    // MARK: - Properties
    
    /// 节点ID
    public let id: UUID
    
    /// 对应的文件节点
    public let fileNode: FileNode
    
    /// 父节点
    public weak var parent: SmartDirectoryNode?
    
    /// 子节点（懒加载）
    @Published public private(set) var children: [SmartDirectoryNode] = []
    
    /// 是否已加载子节点
    private var childrenLoaded = false
    
    /// 缓存的总大小
    private var cachedTotalSize: Int64?
    
    /// 缓存的百分比
    private var cachedPercentage: Double?
    
    /// 格式化器
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter
    }()
    
    // MARK: - Computed Properties
    
    /// 显示名称
    public var displayName: String {
        return fileNode.name
    }
    
    /// 是否为目录
    public var isDirectory: Bool {
        return fileNode.isDirectory
    }
    
    /// 路径
    public var path: String {
        return fileNode.path
    }
    
    /// 总大小（包括子目录）
    public var totalSize: Int64 {
        if let cached = cachedTotalSize {
            return cached
        }
        
        let size = calculateTotalSize()
        cachedTotalSize = size
        return size
    }
    
    /// 格式化的大小
    public var formattedSize: String {
        return Self.byteFormatter.string(fromByteCount: totalSize)
    }
    
    /// 相对于父节点的百分比
    public var percentageOfParent: Double {
        if let cached = cachedPercentage {
            return cached
        }
        
        let percentage = calculatePercentageOfParent()
        cachedPercentage = percentage
        return percentage
    }
    
    /// 格式化的百分比
    public var formattedPercentage: String {
        let percentage = percentageOfParent
        if percentage < 0.01 {
            return "<0.01%"
        } else {
            return String(format: "%.1f%%", percentage * 100)
        }
    }
    
    /// 文件数量
    public var fileCount: Int {
        return calculateFileCount()
    }
    
    /// 目录数量
    public var directoryCount: Int {
        return calculateDirectoryCount()
    }
    
    // MARK: - Initialization
    
    public init(fileNode: FileNode, parent: SmartDirectoryNode? = nil) {
        self.id = fileNode.id
        self.fileNode = fileNode
        self.parent = parent
    }
    
    // MARK: - Public Methods
    
    /// 加载子节点
    public func loadChildren() {
        guard !childrenLoaded && isDirectory else { return }
        
        let childNodes = fileNode.children.compactMap { childFileNode -> SmartDirectoryNode? in
            // 只显示目录，不显示文件
            guard childFileNode.isDirectory else { return nil }
            return SmartDirectoryNode(fileNode: childFileNode, parent: self)
        }
        
        // 按大小排序
        children = childNodes.sorted { $0.totalSize > $1.totalSize }
        childrenLoaded = true
        
        // 清除缓存，因为子节点可能影响计算
        invalidateCache()
    }
    
    /// 添加子节点
    public func addChild(_ child: SmartDirectoryNode) {
        child.parent = self
        children.append(child)
        
        // 重新排序
        children.sort { $0.totalSize > $1.totalSize }
        
        // 清除缓存
        invalidateCache()
    }
    
    /// 移除子节点
    public func removeChild(_ child: SmartDirectoryNode) {
        children.removeAll { $0.id == child.id }
        child.parent = nil
        
        // 清除缓存
        invalidateCache()
    }
    
    /// 查找子节点
    public func findChild(withId id: UUID) -> SmartDirectoryNode? {
        return children.first { $0.id == id }
    }
    
    /// 查找子节点（递归）
    public func findDescendant(withId id: UUID) -> SmartDirectoryNode? {
        if self.id == id {
            return self
        }
        
        for child in children {
            if let found = child.findDescendant(withId: id) {
                return found
            }
        }
        
        return nil
    }
    
    /// 获取路径到根节点
    public func getPathToRoot() -> [SmartDirectoryNode] {
        var path: [SmartDirectoryNode] = [self]
        var current = parent
        
        while let node = current {
            path.insert(node, at: 0)
            current = node.parent
        }
        
        return path
    }
    
    /// 获取深度
    public var depth: Int {
        var depth = 0
        var current = parent
        
        while current != nil {
            depth += 1
            current = current?.parent
        }
        
        return depth
    }
    
    /// 是否为叶子节点
    public var isLeaf: Bool {
        return children.isEmpty
    }
    
    /// 清除缓存
    public func invalidateCache() {
        cachedTotalSize = nil
        cachedPercentage = nil
        
        // 递归清除父节点缓存
        parent?.invalidateCache()
    }
    
    // MARK: - Private Methods
    
    /// 计算总大小
    private func calculateTotalSize() -> Int64 {
        var total = fileNode.size
        
        // 加载子节点（如果还没加载）
        if !childrenLoaded {
            loadChildren()
        }
        
        // 递归计算子节点大小
        for child in children {
            total += child.totalSize
        }
        
        return total
    }
    
    /// 计算相对于父节点的百分比
    private func calculatePercentageOfParent() -> Double {
        guard let parent = parent else { return 1.0 }
        
        let parentSize = parent.totalSize
        guard parentSize > 0 else { return 0.0 }
        
        return Double(totalSize) / Double(parentSize)
    }
    
    /// 计算文件数量
    private func calculateFileCount() -> Int {
        var count = 0
        
        // 计算当前节点的文件数
        for child in fileNode.children {
            if !child.isDirectory {
                count += 1
            }
        }
        
        // 递归计算子目录的文件数
        for child in children {
            count += child.fileCount
        }
        
        return count
    }
    
    /// 计算目录数量
    private func calculateDirectoryCount() -> Int {
        var count = children.count
        
        // 递归计算子目录数量
        for child in children {
            count += child.directoryCount
        }
        
        return count
    }
}

// MARK: - Equatable

extension SmartDirectoryNode: Equatable {
    public static func == (lhs: SmartDirectoryNode, rhs: SmartDirectoryNode) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension SmartDirectoryNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CustomStringConvertible

extension SmartDirectoryNode: CustomStringConvertible {
    public var description: String {
        return "\(displayName) (\(formattedSize), \(formattedPercentage))"
    }
}

// MARK: - Factory Methods

extension SmartDirectoryNode {
    
    /// 从FileNode创建SmartDirectoryNode树
    public static func createTree(from fileNode: FileNode) -> SmartDirectoryNode? {
        guard fileNode.isDirectory else { return nil }
        
        let smartNode = SmartDirectoryNode(fileNode: fileNode)
        smartNode.loadChildren()
        
        return smartNode
    }
    
    /// 批量创建节点
    public static func createNodes(from fileNodes: [FileNode], parent: SmartDirectoryNode? = nil) -> [SmartDirectoryNode] {
        return fileNodes.compactMap { fileNode in
            guard fileNode.isDirectory else { return nil }
            return SmartDirectoryNode(fileNode: fileNode, parent: parent)
        }
    }
}
