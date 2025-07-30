import Foundation
import AppKit

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 检查是否有正在进行的扫描
        if let session = currentSession, session.state == .scanning {
            let alert = NSAlert()
            alert.messageText = "正在扫描"
            alert.informativeText = "当前正在进行扫描，确定要关闭窗口吗？"
            alert.addButton(withTitle: "取消扫描并关闭")
            alert.addButton(withTitle: "继续扫描")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                sessionManager.sessionController.cancelSession(session)
                return true
            } else {
                return false
            }
        }
        
        return true
    }
    
    public func windowWillClose(_ notification: Notification) {
        // 清理资源
        cancellables.removeAll()
    }
}

// MARK: - NSOutlineViewDataSource

extension MainWindowController: NSOutlineViewDataSource {
    
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? FileNode {
            return node.children.count
        } else {
            // 根级别
            return currentSession?.rootNode != nil ? 1 : 0
        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? FileNode {
            return Array(node.children)[index]
        } else {
            // 根级别
            return currentSession?.rootNode as Any
        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? FileNode {
            return node.isDirectory && !node.children.isEmpty
        }
        return false
    }
}

// MARK: - NSOutlineViewDelegate

extension MainWindowController: NSOutlineViewDelegate {
    
    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FileNode,
              let identifier = tableColumn?.identifier else { return nil }
        
        let cellView = NSTableCellView()
        let textField = NSTextField()
        textField.isBordered = false
        textField.isEditable = false
        textField.backgroundColor = NSColor.clear
        
        cellView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -2),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])
        
        cellView.textField = textField
        
        switch identifier.rawValue {
        case "NameColumn":
            // 添加图标
            let imageView = NSImageView()
            let icon = node.isDirectory ? 
                NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil) :
                NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)
            imageView.image = icon
            imageView.imageScaling = .scaleProportionallyUpOrDown
            
            cellView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4)
            ])
            
            cellView.imageView = imageView
            textField.stringValue = node.name
            
        case "SizeColumn":
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
            formatter.countStyle = .file
            textField.stringValue = formatter.string(fromByteCount: node.size)
            textField.alignment = .right
            
        case "CountColumn":
            if node.isDirectory {
                textField.stringValue = "\(node.children.count)"
            } else {
                textField.stringValue = ""
            }
            textField.alignment = .right
            
        default:
            break
        }
        
        return cellView
    }
    
    public func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = directoryTreeView.selectedRow
        if selectedRow >= 0 {
            let selectedItem = directoryTreeView.item(atRow: selectedRow)
            if let node = selectedItem as? FileNode {
                handleDirectoryTreeSelection(node)
            }
        }
    }
}
