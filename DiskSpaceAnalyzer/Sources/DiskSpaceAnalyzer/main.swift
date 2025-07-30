import Foundation
import AppKit
import Core

/// DiskSpaceAnalyzer 主程序入口点
/// 
/// 磁盘空间分析器 - 使用完整的UserInterface模块

// MARK: - 应用程序委托

class DiskSpaceAnalyzerAppDelegate: NSObject, NSApplicationDelegate {
    
    /// 用户界面管理器
    private let userInterface = UserInterface.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 DiskSpaceAnalyzer 启动成功！")
        
        // 初始化用户界面
        userInterface.initialize()
        
        // 显示主窗口
        userInterface.showMainWindow()
        
        print("✅ 完整的用户界面已加载")
        print("🛠️ 工具栏包含: 选择文件夹、开始扫描、暂停、停止、刷新、设置、统计、导出")
        print("📊 界面布局: 工具栏 + 进度栏 + 分栏视图 + 状态栏")
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
    
    print("🎯 启动 DiskSpaceAnalyzer v1.0.0")
    print("📱 使用完整的UserInterface模块")
    print("🏗️ 架构: 9个核心模块，完全模块化设计")
    print("💻 平台: macOS 10.15+")
    
    // 运行应用程序
    app.run()
}

// 启动应用程序
main()
