// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiskSpaceAnalyzer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DiskSpaceAnalyzer",
            targets: ["DiskSpaceAnalyzer"]
        ),
        .library(
            name: "Common",
            targets: ["Common"]
        ),
        .library(
            name: "DataModel",
            targets: ["DataModel"]
        ),
        .library(
            name: "CoordinateSystem",
            targets: ["CoordinateSystem"]
        ),
        .library(
            name: "PerformanceOptimizer",
            targets: ["PerformanceOptimizer"]
        ),
        .library(
            name: "ScanEngine",
            targets: ["ScanEngine"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // 可执行目标
        .executableTarget(
            name: "DiskSpaceAnalyzer",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer", "ScanEngine"],
            path: "Sources/App"
        ),
        
        // 基础模块 - 无依赖
        .target(
            name: "Common",
            dependencies: [],
            path: "Sources/Common"
        ),
        
        // 数据模型模块 - 依赖Common
        .target(
            name: "DataModel",
            dependencies: ["Common"],
            path: "Sources/DataModel"
        ),
        
        // 坐标系统模块 - 依赖Common
        .target(
            name: "CoordinateSystem",
            dependencies: ["Common"],
            path: "Sources/CoordinateSystem"
        ),
        
        // 性能优化模块 - 依赖Common
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
        
        // 测试目标
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            path: "Tests/CommonTests"
        ),
        .testTarget(
            name: "DataModelTests",
            dependencies: ["DataModel", "Common"],
            path: "Tests/DataModelTests"
        ),
        .testTarget(
            name: "CoordinateSystemTests",
            dependencies: ["CoordinateSystem", "Common"],
            path: "Tests/CoordinateSystemTests"
        ),
        .testTarget(
            name: "PerformanceOptimizerTests",
            dependencies: ["PerformanceOptimizer", "Common"],
            path: "Tests/PerformanceOptimizerTests"
        ),
        
        // ScanEngine模块测试
        .testTarget(
            name: "ScanEngineTests",
            dependencies: ["ScanEngine", "Common", "DataModel", "PerformanceOptimizer"],
            path: "Tests/ScanEngineTests"
        )
    ]
)
