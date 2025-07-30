import Foundation
import AppKit

/// 工具栏管理器 - 管理工具栏的创建和状态更新
public class ToolbarManager: NSObject {
    
    // MARK: - Properties
    
    /// 工具栏
    private var toolbar: NSToolbar!
    
    /// 进度指示器
    private var progressIndicator: NSProgressIndicator!
    
    /// 当前路径标签
    private var currentPathLabel: NSTextField!
    
    /// 主窗口控制器引用
    public weak var mainWindowController: MainWindowController?
    
    /// 当前扫描状态
    private var isScanning: Bool = false
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 创建工具栏
    public func createToolbar() -> NSToolbar {
        toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.displayMode = .iconAndLabel
        
        return toolbar
    }
    
    /// 更新扫描状态
    public func updateScanningState(_ scanning: Bool, progress: Double = 0.0, currentPath: String = "") {
        isScanning = scanning
        
        DispatchQueue.main.async { [weak self] in
            self?.progressIndicator.isHidden = !scanning
            if scanning {
                self?.progressIndicator.doubleValue = progress * 100
                self?.progressIndicator.startAnimation(nil)
            } else {
                self?.progressIndicator.stopAnimation(nil)
            }
            
            self?.currentPathLabel.stringValue = currentPath
            self?.toolbar.validateVisibleItems()
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建工具栏项
    private func createToolbarItem(identifier: String, label: String, image: NSImage?, action: Selector?) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(identifier))
        item.label = label
        item.toolTip = label
        
        if let image = image {
            item.image = image
        }
        
        if let action = action {
            item.target = self
            item.action = action
        }
        
        return item
    }
    
    /// 创建进度指示器项
    private func createProgressItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("Progress"))
        
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.isHidden = true
        
        NSLayoutConstraint.activate([
            progressIndicator.widthAnchor.constraint(equalToConstant: 150)
        ])
        
        item.view = progressIndicator
        item.label = "进度"
        
        return item
    }
    
    /// 创建路径显示项
    private func createPathItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("CurrentPath"))
        
        currentPathLabel = NSTextField(labelWithString: "")
        currentPathLabel.font = NSFont.systemFont(ofSize: 12)
        currentPathLabel.textColor = NSColor.secondaryLabelColor
        currentPathLabel.lineBreakMode = .byTruncatingMiddle
        
        NSLayoutConstraint.activate([
            currentPathLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        item.view = currentPathLabel
        item.label = "当前路径"
        
        return item
    }
    
    // MARK: - Actions
    
    @objc private func selectFolderAction() {
        mainWindowController?.selectFolderAction()
    }
    
    @objc private func startScanAction() {
        mainWindowController?.startScanAction()
    }
    
    @objc private func stopScanAction() {
        mainWindowController?.stopScanAction()
    }
    
    @objc private func refreshAction() {
        mainWindowController?.refreshAction()
    }
}

// MARK: - NSToolbarDelegate

extension ToolbarManager: NSToolbarDelegate {
    
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier.rawValue {
        case "SelectFolder":
            let image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
            return createToolbarItem(identifier: "SelectFolder", label: "选择文件夹", image: image, action: #selector(selectFolderAction))
            
        case "StartScan":
            let image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: nil)
            image?.isTemplate = false
            let item = createToolbarItem(identifier: "StartScan", label: "开始扫描", image: image, action: #selector(startScanAction))
            return item
            
        case "StopScan":
            let image = NSImage(systemSymbolName: "stop.circle.fill", accessibilityDescription: nil)
            image?.isTemplate = false
            let item = createToolbarItem(identifier: "StopScan", label: "停止扫描", image: image, action: #selector(stopScanAction))
            return item
            
        case "Refresh":
            let image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
            return createToolbarItem(identifier: "Refresh", label: "刷新", image: image, action: #selector(refreshAction))
            
        case "Progress":
            return createProgressItem()
            
        case "CurrentPath":
            return createPathItem()
            
        default:
            return nil
        }
    }
    
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier("SelectFolder"),
            NSToolbarItem.Identifier("StartScan"),
            NSToolbarItem.Identifier("StopScan"),
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier("Refresh"),
            NSToolbarItem.Identifier.flexibleSpace,
            NSToolbarItem.Identifier("Progress"),
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier("CurrentPath")
        ]
    }
    
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar) + [
            NSToolbarItem.Identifier.separator,
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier.flexibleSpace
        ]
    }
    
    public func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "StartScan":
            return !isScanning
        case "StopScan":
            return isScanning
        default:
            return true
        }
    }
}
