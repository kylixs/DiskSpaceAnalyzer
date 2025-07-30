import Foundation
import AppKit

// MARK: - Core Module Main Export
// 这个文件是Core模块的主入口，导入所有子模块

// 由于Swift Package Manager的限制，我们不能使用@_exported import
// 所以这里只是作为一个标识文件

/// Core模块信息
public struct CoreModule {
    public static let version = "1.0.0"
    public static let modules = [
        "DataModel", "CoordinateSystem", "PerformanceOptimizer", 
        "ScanEngine", "DirectoryTreeView", "TreeMapVisualization",
        "InteractionFeedback", "SessionManager", "UserInterface"
    ]
    
    public static func initialize() {
        print("🏗️ Core模块初始化")
        print("📦 包含模块: \(modules.joined(separator: ", "))")
        print("📊 版本: \(version)")
    }
}

// 注意: 实际的类和结构体导入需要在使用的地方直接import
// 例如: import Core 会自动包含所有子模块的公共接口
