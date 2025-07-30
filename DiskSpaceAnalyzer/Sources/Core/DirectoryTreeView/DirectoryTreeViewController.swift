import Foundation
import AppKit
import Combine

/// 目录树控制器 - 管理目录树的显示和交互
public class DirectoryTreeViewController: NSViewController {
    
    // MARK: - Properties
    
    /// 目录树视图
    @IBOutlet public weak var outlineView: NSOutlineView!
    
    /// 滚动视图
    @IBOutlet public weak var scrollView: NSScrollView!
    
    /// 根目录节点
    public var rootNode: SmartDirectoryNode? {
        didSet {
            updateTreeData()
        }
    }
    
    /// 展开状态管理器
    public let expansionManager = TreeExpansionManager()
    
    /// 目录合并器
    public let directoryMerger = DirectoryMerger()
    
    /// 数据源
    private var treeDataSource: [SmartDirectoryNode] = []
    
    /// 选择变化回调
    public var selectionChangeCallback: ((SmartDirectoryNode?) -> Void)?
    
    /// 双击回调
    public var doubleClickCallback: ((SmartDirectoryNode) -> Void)?
    
    /// Combine订阅
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupOutlineView()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 更新树数据
    public func updateTreeData() {
        guard let rootNode = rootNode else {
            treeDataSource = []
            reloadData()
            return
        }
        
        // 应用目录合并
        treeDataSource = directoryMerger.processDirectories([rootNode])
        reloadData()
    }
    
    /// 展开节点
    public func expandNode(_ node: SmartDirectoryNode) {
        guard let item = findOutlineItem(for: node) else { return }
        
        outlineView.expandItem(item)
        expansionManager.setExpanded(node.id, expanded: true)
    }
    
    /// 折叠节点
    public func collapseNode(_ node: SmartDirectoryNode) {
        guard let item = findOutlineItem(for: node) else { return }
        
        outlineView.collapseItem(item)
        expansionManager.setExpanded(node.id, expanded: false)
    }
    
    /// 选择节点
    public func selectNode(_ node: SmartDirectoryNode) {
        guard let item = findOutlineItem(for: node) else { return }
        
        let row = outlineView.row(forItem: item)
        if row >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }
    
    /// 获取选中的节点
    public func getSelectedNode() -> SmartDirectoryNode? {
        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0 else { return nil }
        
        return outlineView.item(atRow: selectedRow) as? SmartDirectoryNode
    }
    
    /// 重新加载数据
    public func reloadData() {
        DispatchQueue.main.async { [weak self] in
            self?.outlineView.reloadData()
            self?.restoreExpansionState()
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置大纲视图
    private func setupOutlineView() {
        outlineView.dataSource = self
        outlineView.delegate = self
        
        // 设置列
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "名称"
        nameColumn.width = 200
        outlineView.addTableColumn(nameColumn)
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeColumn.title = "大小"
        sizeColumn.width = 100
        outlineView.addTableColumn(sizeColumn)
        
        let percentColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("percent"))
        percentColumn.title = "百分比"
        percentColumn.width = 80
        outlineView.addTableColumn(percentColumn)
        
        // 设置样式
        outlineView.headerView = NSTableHeaderView()
        outlineView.intercellSpacing = NSSize(width: 3, height: 2)
        outlineView.rowSizeStyle = .default
        
        // 设置双击动作
        outlineView.doubleAction = #selector(handleDoubleClick)
        outlineView.target = self
    }
    
    /// 设置绑定
    private func setupBindings() {
        // 监听选择变化
        NotificationCenter.default.publisher(for: NSOutlineView.selectionDidChangeNotification, object: outlineView)
            .sink { [weak self] _ in
                self?.handleSelectionChange()
            }
            .store(in: &cancellables)
    }
    
    /// 处理选择变化
    private func handleSelectionChange() {
        let selectedNode = getSelectedNode()
        selectionChangeCallback?(selectedNode)
    }
    
    /// 处理双击
    @objc private func handleDoubleClick() {
        guard let selectedNode = getSelectedNode() else { return }
        doubleClickCallback?(selectedNode)
    }
    
    /// 查找大纲视图项目
    private func findOutlineItem(for node: SmartDirectoryNode) -> Any? {
        // 简化实现：在数据源中查找
        return findNodeInDataSource(node, in: treeDataSource)
    }
    
    /// 在数据源中查找节点
    private func findNodeInDataSource(_ targetNode: SmartDirectoryNode, in nodes: [SmartDirectoryNode]) -> SmartDirectoryNode? {
        for node in nodes {
            if node.id == targetNode.id {
                return node
            }
            
            if let found = findNodeInDataSource(targetNode, in: node.children) {
                return found
            }
        }
        return nil
    }
    
    /// 恢复展开状态
    private func restoreExpansionState() {
        restoreExpansionForNodes(treeDataSource)
    }
    
    /// 为节点恢复展开状态
    private func restoreExpansionForNodes(_ nodes: [SmartDirectoryNode]) {
        for node in nodes {
            if expansionManager.isExpanded(node.id) {
                outlineView.expandItem(node)
            }
            restoreExpansionForNodes(node.children)
        }
    }
}

// MARK: - NSOutlineViewDataSource

extension DirectoryTreeViewController: NSOutlineViewDataSource {
    
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? SmartDirectoryNode {
            return node.children.count
        } else {
            return treeDataSource.count
        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? SmartDirectoryNode {
            return node.children[index]
        } else {
            return treeDataSource[index]
        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? SmartDirectoryNode else { return false }
        return !node.children.isEmpty
    }
}

// MARK: - NSOutlineViewDelegate

extension DirectoryTreeViewController: NSOutlineViewDelegate {
    
    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SmartDirectoryNode,
              let identifier = tableColumn?.identifier else { return nil }
        
        let cellView = NSTableCellView()
        let textField = NSTextField()
        textField.isBordered = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        
        switch identifier.rawValue {
        case "name":
            textField.stringValue = node.displayName
            if node.isDirectory {
                textField.textColor = .controlAccentColor
            }
        case "size":
            textField.stringValue = node.formattedSize
            textField.alignment = .right
        case "percent":
            textField.stringValue = node.formattedPercentage
            textField.alignment = .right
        default:
            break
        }
        
        cellView.addSubview(textField)
        cellView.textField = textField
        
        // 设置约束
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])
        
        return cellView
    }
    
    public func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        guard let node = item as? SmartDirectoryNode else { return false }
        expansionManager.setExpanded(node.id, expanded: true)
        return true
    }
    
    public func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        guard let node = item as? SmartDirectoryNode else { return false }
        expansionManager.setExpanded(node.id, expanded: false)
        return true
    }
    
    public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 20.0
    }
}
