// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PerformanceOptimizerTests",
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
        
        // 复制PerformanceOptimizer模块源码
        .target(
            name: "PerformanceOptimizer",
            dependencies: ["Common"],
            path: "Sources/PerformanceOptimizer"
        ),
        
        // 测试目标
        .testTarget(
            name: "PerformanceOptimizerTests",
            dependencies: ["PerformanceOptimizer", "Common"],
            path: "Tests/PerformanceOptimizerTests"
        )
    ]
)
