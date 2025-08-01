// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SessionManagerTests",
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
        
        // 复制ScanEngine模块源码
        .target(
            name: "ScanEngine",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "Sources/ScanEngine"
        ),
        
        // 复制SessionManager模块源码
        .target(
            name: "SessionManager",
            dependencies: ["Common", "DataModel", "ScanEngine"],
            path: "Sources/SessionManager"
        ),
        
        // 测试目标
        .testTarget(
            name: "SessionManagerTests",
            dependencies: ["SessionManager", "ScanEngine", "DataModel", "PerformanceOptimizer", "Common"],
            path: "Tests/SessionManagerTests"
        )
    ]
)
