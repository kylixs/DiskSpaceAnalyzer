// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DirectoryTreeViewTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [],
    dependencies: [],
    targets: [
        // 复制Common模块源码
        .target(
            name: "Common",
            dependencies: [],
            path: "Sources/Common"
        ),
        
        // 复制DataModel模块源码
        .target(
            name: "DataModel",
            dependencies: ["Common"],
            path: "Sources/DataModel"
        ),
        
        // 复制PerformanceOptimizer模块源码
        .target(
            name: "PerformanceOptimizer",
            dependencies: ["Common"],
            path: "Sources/PerformanceOptimizer"
        ),
        
        // 复制DirectoryTreeView模块源码
        .target(
            name: "DirectoryTreeView",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "Sources/DirectoryTreeView"
        ),
        
        // 测试目标
        .testTarget(
            name: "DirectoryTreeViewTests",
            dependencies: ["DirectoryTreeView", "DataModel", "PerformanceOptimizer", "Common"],
            path: "Tests/DirectoryTreeViewTests"
        )
    ]
)
