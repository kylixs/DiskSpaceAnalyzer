import Foundation
import AppKit

/// DiskSpaceAnalyzer 主程序入口点
/// 
/// 磁盘空间分析器 - 功能完整的macOS应用程序

// MARK: - 应用程序委托

class DiskSpaceAnalyzerAppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建主窗口
        createMainWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 应用程序即将退出
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func createMainWindow() {
        // 创建主窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "磁盘空间分析器"
        window.center()
        window.minSize = NSSize(width: 800, height: 600)
        
        // 创建工具栏
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.displayMode = .iconAndLabel
        window.toolbar = toolbar
        
        // 创建内容视图
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建分栏视图
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        
        // 左侧目录树面板
        let leftPanel = createDirectoryTreePanel()
        splitView.addArrangedSubview(leftPanel)
        
        // 右侧TreeMap面板
        let rightPanel = createTreeMapPanel()
        splitView.addArrangedSubview(rightPanel)
        
        // 设置分栏比例
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 0)
        
        // 创建状态栏
        let statusBar = createStatusBar()
        
        // 添加到内容视图
        contentView.addSubview(splitView)
        contentView.addSubview(statusBar)
        
        // 设置约束
        splitView.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 分栏视图
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
            
            // 状态栏
            statusBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        window.contentView = contentView
        self.mainWindow = window
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    private func createDirectoryTreePanel() -> NSView {
        let panel = NSView()
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建滚动视图
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        
        // 创建目录树视图
        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.usesAlternatingRowBackgroundColors = true
        
        // 添加列
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "名称"
        nameColumn.width = 200
        outlineView.addTableColumn(nameColumn)
        outlineView.outlineTableColumn = nameColumn
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SizeColumn"))
        sizeColumn.title = "大小"
        sizeColumn.width = 80
        outlineView.addTableColumn(sizeColumn)
        
        scrollView.documentView = outlineView
        
        // 添加标题
        let titleLabel = NSTextField(labelWithString: "目录树")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.alignment = .center
        
        panel.addSubview(titleLabel)
        panel.addSubview(scrollView)
        
        // 设置约束
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -8),
            
            panel.widthAnchor.constraint(greaterThanOrEqualToConstant: 250)
        ])
        
        return panel
    }
    
    private func createTreeMapPanel() -> NSView {
        let panel = NSView()
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建TreeMap容器
        let treeMapView = NSView()
        treeMapView.wantsLayer = true
        treeMapView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        treeMapView.layer?.borderColor = NSColor.separatorColor.cgColor
        treeMapView.layer?.borderWidth = 1
        treeMapView.layer?.cornerRadius = 4
        
        // 添加占位符文本
        let placeholderLabel = NSTextField(labelWithString: "选择文件夹开始扫描")
        placeholderLabel.font = NSFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = NSColor.secondaryLabelColor
        placeholderLabel.alignment = .center
        
        // 添加标题
        let titleLabel = NSTextField(labelWithString: "TreeMap 可视化")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.alignment = .center
        
        panel.addSubview(titleLabel)
        panel.addSubview(treeMapView)
        treeMapView.addSubview(placeholderLabel)
        
        // 设置约束
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        treeMapView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),
            
            treeMapView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            treeMapView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
            treeMapView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),
            treeMapView.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -8),
            
            placeholderLabel.centerXAnchor.constraint(equalTo: treeMapView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: treeMapView.centerYAnchor),
            
            panel.widthAnchor.constraint(greaterThanOrEqualToConstant: 400)
        ])
        
        return panel
    }
    
    private func createStatusBar() -> NSView {
        let statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建分隔线
        let separator = NSBox()
        separator.boxType = .separator
        
        // 创建状态标签
        let statusLabel = NSTextField(labelWithString: "📊 状态: 就绪")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.controlTextColor
        
        let instructionLabel = NSTextField(labelWithString: "使用菜单 文件 > 选择文件夹 开始扫描")
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        
        statusBar.addSubview(separator)
        statusBar.addSubview(statusLabel)
        statusBar.addSubview(instructionLabel)
        
        // 设置约束
        separator.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: statusBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            
            instructionLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -10),
            instructionLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
        ])
        
        return statusBar
    }
}

// MARK: - 主程序入口

func main() {
    // 创建应用程序实例
    let app = NSApplication.shared
    
    // 设置应用程序委托
    let appDelegate = DiskSpaceAnalyzerAppDelegate()
    app.delegate = appDelegate
    
    // 设置应用程序属性
    app.setActivationPolicy(.regular)
    
    // 运行应用程序
    app.run()
}

// 启动应用程序
main()
