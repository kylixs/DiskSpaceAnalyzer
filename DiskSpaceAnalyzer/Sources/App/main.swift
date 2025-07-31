import Foundation
import AppKit
import Common
import DataModel
import CoordinateSystem
import PerformanceOptimizer

/// DiskSpaceAnalyzer 主程序入口点
/// 
/// 磁盘空间分析器 - 模块化架构演示

// MARK: - 应用程序委托

class DiskSpaceAnalyzerAppDelegate: NSObject, NSApplicationDelegate {
    
    /// 主窗口
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 DiskSpaceAnalyzer 启动成功！")
        print("📦 已加载模块: Common, DataModel, CoordinateSystem, PerformanceOptimizer")
        
        // 创建主窗口
        createMainWindow()
        
        print("✅ 模块化架构演示程序已启动")
        print("🛠️ 当前版本: \(AppConstants.appVersion)")
        print("📊 应用名称: \(AppConstants.appDisplayName)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 DiskSpaceAnalyzer 即将退出")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - 私有方法
    
    private func createMainWindow() {
        // 创建窗口
        let windowRect = NSRect(
            x: 0, 
            y: 0, 
            width: AppConstants.defaultWindowWidth, 
            height: AppConstants.defaultWindowHeight
        )
        
        mainWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        mainWindow?.title = AppConstants.appName
        mainWindow?.center()
        mainWindow?.makeKeyAndOrderFront(nil)
        
        // 创建简单的内容视图
        let contentView = NSView(frame: windowRect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 添加标签显示模块信息
        let label = NSTextField(labelWithString: """
        DiskSpaceAnalyzer 模块化架构演示
        
        已加载的模块:
        • Common - 共享工具和常量
        • DataModel - 数据模型和持久化
        • CoordinateSystem - 坐标系统和变换
        • PerformanceOptimizer - 性能优化
        
        应用信息:
        • 版本: \(AppConstants.appVersion)
        • 最小窗口尺寸: \(Int(AppConstants.minWindowWidth)) x \(Int(AppConstants.minWindowHeight))
        • 最大缓存大小: \(AppConstants.maxCacheSize) 项
        
        运行 'swift test' 来执行单元测试
        """)
        
        label.frame = NSRect(x: 50, y: 50, width: windowRect.width - 100, height: windowRect.height - 100)
        label.alignment = NSTextAlignment.left
        label.font = NSFont.systemFont(ofSize: 14)
        
        contentView.addSubview(label)
        mainWindow?.contentView = contentView
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
    
    print("🎯 启动 DiskSpaceAnalyzer \(AppConstants.appVersion)")
    print("🏗️ 架构: 模块化设计")
    print("💻 平台: macOS 13.0+")
    
    // 运行应用程序
    app.run()
}

// 启动应用程序
main()
