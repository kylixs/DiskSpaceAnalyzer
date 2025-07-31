// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScanEngineTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ScanEngine",
            targets: ["ScanEngine"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // Common模块 - 基础模块
        .target(
            name: "Common",
            dependencies: [],
            path: "Sources/Common"
        ),
        
        // DataModel模块 - 数据模型模块
        .target(
            name: "DataModel",
            dependencies: ["Common"],
            path: "Sources/DataModel"
        ),
        
        // PerformanceOptimizer模块 - 性能优化模块
        .target(
            name: "PerformanceOptimizer",
            dependencies: ["Common"],
            path: "Sources/PerformanceOptimizer"
        ),
        
        // ScanEngine模块 - 文件系统扫描引擎
        .target(
            name: "ScanEngine",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "Sources/ScanEngine"
        ),
        
        // ScanEngineTests测试目标
        .testTarget(
            name: "ScanEngineTests",
            dependencies: ["ScanEngine", "Common", "DataModel", "PerformanceOptimizer"],
            path: "Tests/ScanEngineTests"
        )
    ]
)
