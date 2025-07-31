import Foundation
import AppKit
import Common
import DataModel
import CoordinateSystem
import PerformanceOptimizer
import ScanEngine
import DirectoryTreeView
import TreeMapVisualization
import InteractionFeedback
import SessionManager
import UserInterface

/// DiskSpaceAnalyzer 主程序入口点
/// 
/// 磁盘空间分析器 - 完整功能的macOS应用程序

// MARK: - 应用程序委托

class DiskSpaceAnalyzerAppDelegate: NSObject, NSApplicationDelegate {
    
    /// 用户界面管理器
    private let userInterface = UserInterface.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 DiskSpaceAnalyzer 启动成功！")
        print("📦 已加载所有模块:")
        print("   • Common - 共享工具和常量")
        print("   • DataModel - 数据模型和持久化")
        print("   • CoordinateSystem - 坐标系统和变换")
        print("   • PerformanceOptimizer - 性能优化")
        print("   • ScanEngine - 文件系统扫描引擎")
        print("   • DirectoryTreeView - 目录树显示")
        print("   • TreeMapVisualization - TreeMap可视化")
        print("   • InteractionFeedback - 交互反馈系统")
        print("   • SessionManager - 会话管理")
        print("   • UserInterface - 用户界面集成")
        
        // 初始化所有模块
        initializeModules()
        
        // 启动用户界面
        userInterface.launch()
        
        print("✅ 磁盘空间分析器已启动")
        print("🛠️ 当前版本: \(AppConstants.appVersion)")
        print("📊 应用名称: \(AppConstants.appDisplayName)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 DiskSpaceAnalyzer 即将退出")
        
        // 清理资源
        // PerformanceOptimizer模块会自动清理
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - 私有方法
    
    private func initializeModules() {
        // 按依赖顺序初始化模块
        CommonModule.initialize()
        DataModelModule.initialize()
        CoordinateSystemModule.initialize()
        PerformanceOptimizerModule.initialize()
        ScanEngineModule.initialize()
        DirectoryTreeViewModule.initialize()
        TreeMapVisualizationModule.initialize()
        InteractionFeedbackModule.initialize()
        SessionManagerModule.initialize()
        UserInterfaceModule.initialize()
        
        print("🎯 所有模块初始化完成")
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
    print("🏗️ 架构: 10个模块化组件")
    print("💻 平台: macOS 13.0+")
    print("⚡ 技术栈: Swift 5.9+ | AppKit | Swift Concurrency")
    
    // 运行应用程序
    app.run()
}

// 启动应用程序
main()
