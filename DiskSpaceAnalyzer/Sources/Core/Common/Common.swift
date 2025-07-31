import Foundation
import AppKit

// MARK: - Common Module
// 这个模块包含所有共享的枚举、结构体、常量和工具类

/// Common模块信息
public struct CommonModule {
    public static let version = "1.0.0"
    public static let description = "共享的枚举、结构体、常量和工具类"
    
    public static func initialize() {
        print("🔧 Common模块初始化")
        print("📋 包含: 枚举、结构体、常量、工具类")
        print("📊 版本: \(version)")
    }
}

// 重新导出所有公共接口，方便其他模块使用
// 这样其他模块只需要 import Common 就可以使用所有共享类型

