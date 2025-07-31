import Foundation
import AppKit
import Common
import DataModel
import PerformanceOptimizer

// MARK: - DirectoryTreeView Module
// 目录树显示模块 - 提供智能目录树显示功能

/// DirectoryTreeView模块信息
public struct DirectoryTreeViewModule {
    public static let version = "1.0.0"
    public static let description = "智能目录树显示组件"
    
    public static func initialize() {
        print("🌳 DirectoryTreeView模块初始化")
        print("📋 包含: DirectoryTreeViewController、SmartDirectoryNode、DirectoryMerger、TreeExpansionManager")
        print("📊 版本: \(version)")
        print("✅ DirectoryTreeView模块初始化完成")
    }
}

// MARK: - 智能目录节点

/// 智能目录节点 - 支持懒加载和缓存
public class SmartDirectoryNode: NSObject {
    public let fileNode: FileNode
    public private(set) var children: [SmartDirectoryNode] = []
    public var isExpanded = false
    public private(set) var isLoaded = false
    
    // 显示属性
    public var displayName: String {
        return fileNode.name
    }
    
    public var formattedSize: String {
        return SharedUtilities.formatFileSize(fileNode.size)
    }
    
    public var itemCount: Int {
        return fileNode.children.count
    }
    
    public var sizePercentage: Double {
        guard let parent = parent, parent.fileNode.size > 0 else { return 0 }
        return Double(fileNode.size) / Double(parent.fileNode.size) * 100
    }
    
    // 层级关系
    public weak var parent: SmartDirectoryNode?
    public var level: Int {
        return (parent?.level ?? -1) + 1
    }
    
    // 缓存
    private var cachedDisplayInfo: DisplayInfo?
    private var lastUpdateTime: Date?
    
    public init(fileNode: FileNode, parent: SmartDirectoryNode? = nil) {
        self.fileNode = fileNode
        self.parent = parent
        super.init()
    }
    
    /// 懒加载子节点
    public func loadChildren() {
        guard !isLoaded && fileNode.isDirectory else { return }
        
        // 只显示目录，不显示文件
        let directoryChildren = fileNode.children.filter { $0.isDirectory }
        
        // 按大小排序，只取前10个
        let sortedChildren = directoryChildren.sorted { $0.size > $1.size }
        let topChildren = Array(sortedChildren.prefix(10))
        
        // 创建智能节点
        children = topChildren.map { SmartDirectoryNode(fileNode: $0, parent: self) }
        
        // 如果有更多子目录，创建"其他"节点
        if sortedChildren.count > 10 {
            let remainingChildren = Array(sortedChildren.dropFirst(10))
            let totalSize = remainingChildren.reduce(0) { $0 + $1.size }
            let otherNode = FileNode(
                name: "其他 (\(remainingChildren.count)个目录)",
                path: fileNode.path + "/其他",
                size: totalSize,
                isDirectory: true
            )
            children.append(SmartDirectoryNode(fileNode: otherNode, parent: self))
        }
        
        isLoaded = true
        lastUpdateTime = Date()
    }
    
    /// 展开节点
    public func expand() {
        guard fileNode.isDirectory else { return }
        
        if !isLoaded {
            loadChildren()
        }
        isExpanded = true
    }
    
    /// 折叠节点
    public func collapse() {
        isExpanded = false
        // 递归折叠所有子节点
        children.forEach { $0.collapse() }
    }
    
    /// 获取显示信息（带缓存）
    public func getDisplayInfo() -> DisplayInfo {
        let now = Date()
        
        // 检查缓存是否有效（1秒内）
        if let cached = cachedDisplayInfo,
           let lastUpdate = lastUpdateTime,
           now.timeIntervalSince(lastUpdate) < 1.0 {
            return cached
        }
        
        // 重新计算显示信息
        let info = DisplayInfo(
            name: displayName,
            size: formattedSize,
            itemCount: itemCount,
            percentage: String(format: "%.1f%%", sizePercentage),
            icon: fileNode.isDirectory ? "folder" : "doc",
            level: level
        )
        
        cachedDisplayInfo = info
        lastUpdateTime = now
        
        return info
    }
    
    /// 清除缓存
    public func clearCache() {
        cachedDisplayInfo = nil
        lastUpdateTime = nil
        children.forEach { $0.clearCache() }
    }
    
    /// 内部方法：设置子节点（用于合并节点）
    internal func setChildren(_ newChildren: [SmartDirectoryNode]) {
        children = newChildren
    }
    
    /// 显示信息结构
    public struct DisplayInfo {
        public let name: String
        public let size: String
        public let itemCount: Int
        public let percentage: String
        public let icon: String
        public let level: Int
    }
}

// MARK: - 目录合并器

/// 目录合并器 - 处理小目录合并显示
public class DirectoryMerger {
    public static let shared = DirectoryMerger()
    
    private let mergeThreshold = 10 // 最多显示10个目录
    private let sizeThreshold: Double = 0.01 // 小于1%的目录合并
    
    private init() {}
    
    /// 合并小目录
    public func mergeSmallDirectories(_ nodes: [SmartDirectoryNode]) -> [SmartDirectoryNode] {
        guard nodes.count > mergeThreshold else { return nodes }
        
        // 按大小排序
        let sortedNodes = nodes.sorted { $0.fileNode.size > $1.fileNode.size }
        
        // 计算总大小
        let totalSize = sortedNodes.reduce(0) { $0 + $1.fileNode.size }
        
        // 找出需要合并的小目录
        var keepNodes: [SmartDirectoryNode] = []
        var mergeNodes: [SmartDirectoryNode] = []
        
        for node in sortedNodes {
            let percentage = Double(node.fileNode.size) / Double(totalSize)
            
            if keepNodes.count < mergeThreshold - 1 && percentage >= sizeThreshold {
                keepNodes.append(node)
            } else {
                mergeNodes.append(node)
            }
        }
        
        // 如果有需要合并的节点，创建"其他"节点
        if !mergeNodes.isEmpty {
            let mergedSize = mergeNodes.reduce(0) { $0 + $1.fileNode.size }
            let mergedNode = createMergedNode(mergeNodes, totalSize: mergedSize)
            keepNodes.append(mergedNode)
        }
        
        return keepNodes
    }
    
    private func createMergedNode(_ nodes: [SmartDirectoryNode], totalSize: Int64) -> SmartDirectoryNode {
        let mergedFileNode = FileNode(
            name: "其他 (\(nodes.count)个目录)",
            path: "merged://other",
            size: totalSize,
            isDirectory: true
        )
        
        let mergedNode = SmartDirectoryNode(fileNode: mergedFileNode)
        
        // 手动设置子节点
        for node in nodes {
            node.parent = mergedNode
        }
        // 使用反射或者添加内部方法来设置children
        mergedNode.setChildren(nodes)
        
        return mergedNode
    }
}

// MARK: - 树展开管理器

/// 树展开管理器 - 管理节点展开状态
public class TreeExpansionManager {
    public static let shared = TreeExpansionManager()
    
    private var expansionStates: [String: Bool] = [:]
    private var expansionHistory: [String] = []
    private let maxHistoryCount = 100
    
    private init() {}
    
    /// 设置节点展开状态
    public func setExpanded(_ path: String, expanded: Bool) {
        expansionStates[path] = expanded
        
        if expanded {
            // 记录展开历史
            expansionHistory.append(path)
            if expansionHistory.count > maxHistoryCount {
                expansionHistory.removeFirst()
            }
        }
    }
    
    /// 获取节点展开状态
    public func isExpanded(_ path: String) -> Bool {
        return expansionStates[path] ?? false
    }
    
    /// 展开路径上的所有父节点
    public func expandPath(_ path: String) {
        let components = path.components(separatedBy: "/")
        var currentPath = ""
        
        for component in components {
            if !component.isEmpty {
                currentPath += "/" + component
                setExpanded(currentPath, expanded: true)
            }
        }
    }
    
    /// 折叠所有节点
    public func collapseAll() {
        expansionStates.removeAll()
        expansionHistory.removeAll()
    }
    
    /// 获取展开历史
    public func getExpansionHistory() -> [String] {
        return expansionHistory
    }
    
    /// 恢复展开状态
    public func restoreExpansionState(_ states: [String: Bool]) {
        expansionStates = states
    }
    
    /// 获取当前展开状态
    public func getCurrentExpansionState() -> [String: Bool] {
        return expansionStates
    }
}

// MARK: - 目录树控制器

/// 目录树控制器 - 协调数据渲染和用户交互
public class DirectoryTreeViewController: NSObject {
    
    // UI组件
    public weak var outlineView: NSOutlineView?
    public weak var scrollView: NSScrollView?
    
    // 数据源
    private var rootNode: SmartDirectoryNode?
    private var flattenedNodes: [SmartDirectoryNode] = []
    
    // 管理器
    private let expansionManager = TreeExpansionManager.shared
    private let directoryMerger = DirectoryMerger.shared
    private let throttleManager = ThrottleManager.shared
    
    // 性能优化
    private var visibleRange: NSRange = NSRange(location: 0, length: 0)
    private var lastUpdateTime: Date = Date()
    private let updateThreshold: TimeInterval = 0.05 // 50ms
    
    // 回调
    public var onSelectionChanged: ((SmartDirectoryNode?) -> Void)?
    public var onNodeExpanded: ((SmartDirectoryNode) -> Void)?
    public var onNodeCollapsed: ((SmartDirectoryNode) -> Void)?
    
    public override init() {
        super.init()
    }
    
    /// 设置根节点
    public func setRootNode(_ fileNode: FileNode) {
        rootNode = SmartDirectoryNode(fileNode: fileNode)
        rootNode?.loadChildren()
        updateFlattenedNodes()
        reloadData()
    }
    
    /// 更新数据
    public func updateData() {
        guard Date().timeIntervalSince(lastUpdateTime) >= updateThreshold else { return }
        
        throttleManager.throttle(key: "tree_update", interval: updateThreshold) { [weak self] in
            self?.performUpdate()
        }
    }
    
    private func performUpdate() {
        updateFlattenedNodes()
        reloadVisibleRows()
        lastUpdateTime = Date()
    }
    
    /// 展开节点
    public func expandNode(_ node: SmartDirectoryNode) {
        guard !node.isExpanded else { return }
        
        node.expand()
        expansionManager.setExpanded(node.fileNode.path, expanded: true)
        updateFlattenedNodes()
        
        // 增量更新
        if let outlineView = outlineView {
            if flattenedNodes.contains(node) {
                outlineView.expandItem(node, expandChildren: false)
            }
        }
        
        onNodeExpanded?(node)
    }
    
    /// 折叠节点
    public func collapseNode(_ node: SmartDirectoryNode) {
        guard node.isExpanded else { return }
        
        node.collapse()
        expansionManager.setExpanded(node.fileNode.path, expanded: false)
        updateFlattenedNodes()
        
        // 增量更新
        if let outlineView = outlineView {
            outlineView.collapseItem(node)
        }
        
        onNodeCollapsed?(node)
    }
    
    /// 选择节点
    public func selectNode(_ node: SmartDirectoryNode) {
        guard let outlineView = outlineView else { return }
        
        let row = outlineView.row(forItem: node)
        if row >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        }
    }
    
    /// 获取选中节点
    public func getSelectedNode() -> SmartDirectoryNode? {
        guard let outlineView = outlineView else { return nil }
        
        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0 else { return nil }
        
        return outlineView.item(atRow: selectedRow) as? SmartDirectoryNode
    }
    
    /// 刷新数据
    private func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.outlineView?.reloadData()
        }
    }
    
    /// 刷新可见行
    private func reloadVisibleRows() {
        guard let outlineView = outlineView else { return }
        
        DispatchQueue.main.async {
            let visibleRect = outlineView.visibleRect
            let visibleRange = outlineView.rows(in: visibleRect)
            
            if visibleRange.length > 0 {
                let indexSet = IndexSet(integersIn: visibleRange.location..<(visibleRange.location + visibleRange.length))
                let columnSet = IndexSet(integersIn: 0..<outlineView.numberOfColumns)
                outlineView.reloadData(forRowIndexes: indexSet, columnIndexes: columnSet)
            }
        }
    }
    
    /// 更新扁平化节点列表
    private func updateFlattenedNodes() {
        flattenedNodes.removeAll()
        
        guard let root = rootNode else { return }
        
        flattenNodes(root, into: &flattenedNodes)
    }
    
    private func flattenNodes(_ node: SmartDirectoryNode, into nodes: inout [SmartDirectoryNode]) {
        nodes.append(node)
        
        if node.isExpanded {
            for child in node.children {
                flattenNodes(child, into: &nodes)
            }
        }
    }
    
    /// 获取节点在指定行的项目
    public func item(atRow row: Int) -> SmartDirectoryNode? {
        guard row >= 0 && row < flattenedNodes.count else { return nil }
        return flattenedNodes[row]
    }
    
    /// 获取节点的行号
    public func row(forItem item: SmartDirectoryNode) -> Int {
        return flattenedNodes.firstIndex(of: item) ?? -1
    }
    
    /// 获取子节点数量
    public func numberOfChildren(ofItem item: SmartDirectoryNode?) -> Int {
        if let item = item {
            return item.isExpanded ? item.children.count : 0
        } else {
            return rootNode != nil ? 1 : 0
        }
    }
    
    /// 获取指定索引的子节点
    public func child(_ index: Int, ofItem item: SmartDirectoryNode?) -> SmartDirectoryNode? {
        if let item = item {
            guard index >= 0 && index < item.children.count else { return nil }
            return item.children[index]
        } else {
            return index == 0 ? rootNode : nil
        }
    }
    
    /// 检查节点是否可展开
    public func isItemExpandable(_ item: SmartDirectoryNode) -> Bool {
        return item.fileNode.isDirectory && !item.children.isEmpty
    }
}

// MARK: - NSOutlineViewDataSource

extension DirectoryTreeViewController: NSOutlineViewDataSource {
    
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return numberOfChildren(ofItem: item as? SmartDirectoryNode)
    }
    
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return child(index, ofItem: item as? SmartDirectoryNode) as Any
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? SmartDirectoryNode else { return false }
        return isItemExpandable(node)
    }
}

// MARK: - NSOutlineViewDelegate

extension DirectoryTreeViewController: NSOutlineViewDelegate {
    
    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SmartDirectoryNode else { return nil }
        
        let identifier = NSUserInterfaceItemIdentifier("DirectoryCell")
        
        if let cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            updateCellView(cellView, with: node)
            return cellView
        } else {
            let cellView = createCellView(identifier: identifier)
            updateCellView(cellView, with: node)
            return cellView
        }
    }
    
    private func createCellView(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cellView = NSTableCellView()
        cellView.identifier = identifier
        
        // 创建图标
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cellView.addSubview(imageView)
        cellView.imageView = imageView
        
        // 创建文本标签
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isBordered = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        cellView.addSubview(textField)
        cellView.textField = textField
        
        // 设置约束
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
            imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16),
            
            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])
        
        return cellView
    }
    
    private func updateCellView(_ cellView: NSTableCellView, with node: SmartDirectoryNode) {
        let displayInfo = node.getDisplayInfo()
        
        // 更新图标
        if let imageView = cellView.imageView {
            imageView.image = NSImage(systemSymbolName: displayInfo.icon, accessibilityDescription: nil)
        }
        
        // 更新文本
        if let textField = cellView.textField {
            let attributedString = NSMutableAttributedString()
            
            // 节点名称
            attributedString.append(NSAttributedString(
                string: displayInfo.name,
                attributes: [.font: NSFont.systemFont(ofSize: 13)]
            ))
            
            // 大小信息
            attributedString.append(NSAttributedString(
                string: " (\(displayInfo.size))",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            ))
            
            textField.attributedStringValue = attributedString
        }
    }
    
    public func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedNode = getSelectedNode()
        onSelectionChanged?(selectedNode)
    }
    
    public func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        guard let node = item as? SmartDirectoryNode else { return false }
        
        // 懒加载子节点
        if !node.isLoaded {
            node.loadChildren()
        }
        
        return true
    }
    
    public func outlineViewItemDidExpand(_ notification: Notification) {
        guard let node = notification.userInfo?["NSObject"] as? SmartDirectoryNode else { return }
        
        node.isExpanded = true
        expansionManager.setExpanded(node.fileNode.path, expanded: true)
        onNodeExpanded?(node)
    }
    
    public func outlineViewItemDidCollapse(_ notification: Notification) {
        guard let node = notification.userInfo?["NSObject"] as? SmartDirectoryNode else { return }
        
        node.isExpanded = false
        expansionManager.setExpanded(node.fileNode.path, expanded: false)
        onNodeCollapsed?(node)
    }
}

// MARK: - 目录树视图管理器

/// 目录树视图管理器 - 统一管理目录树显示功能
public class DirectoryTreeView {
    public static let shared = DirectoryTreeView()
    
    private let controller = DirectoryTreeViewController()
    private let expansionManager = TreeExpansionManager.shared
    private let directoryMerger = DirectoryMerger.shared
    
    public var outlineView: NSOutlineView? {
        get { return controller.outlineView }
        set { controller.outlineView = newValue }
    }
    
    public var scrollView: NSScrollView? {
        get { return controller.scrollView }
        set { controller.scrollView = newValue }
    }
    
    // 回调
    public var onSelectionChanged: ((SmartDirectoryNode?) -> Void)? {
        get { return controller.onSelectionChanged }
        set { controller.onSelectionChanged = newValue }
    }
    
    public var onNodeExpanded: ((SmartDirectoryNode) -> Void)? {
        get { return controller.onNodeExpanded }
        set { controller.onNodeExpanded = newValue }
    }
    
    public var onNodeCollapsed: ((SmartDirectoryNode) -> Void)? {
        get { return controller.onNodeCollapsed }
        set { controller.onNodeCollapsed = newValue }
    }
    
    private init() {}
    
    /// 设置数据源
    public func setDataSource(_ fileNode: FileNode) {
        controller.setRootNode(fileNode)
        
        // 设置outline view的数据源和代理
        outlineView?.dataSource = controller
        outlineView?.delegate = controller
    }
    
    /// 更新数据
    public func updateData() {
        controller.updateData()
    }
    
    /// 展开节点
    public func expandNode(_ node: SmartDirectoryNode) {
        controller.expandNode(node)
    }
    
    /// 折叠节点
    public func collapseNode(_ node: SmartDirectoryNode) {
        controller.collapseNode(node)
    }
    
    /// 选择节点
    public func selectNode(_ node: SmartDirectoryNode) {
        controller.selectNode(node)
    }
    
    /// 获取选中节点
    public func getSelectedNode() -> SmartDirectoryNode? {
        return controller.getSelectedNode()
    }
    
    /// 展开路径
    public func expandPath(_ path: String) {
        expansionManager.expandPath(path)
        controller.updateData()
    }
    
    /// 折叠所有节点
    public func collapseAll() {
        expansionManager.collapseAll()
        controller.updateData()
    }
}
