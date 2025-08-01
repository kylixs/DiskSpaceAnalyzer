// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UserInterfaceTests",
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
        
        // 复制CoordinateSystem模块源码
        .target(
            name: "CoordinateSystem",
            dependencies: ["Common"],
            path: "Sources/CoordinateSystem"
        ),
        
        // 复制PerformanceOptimizer模块源码
        .target(
            name: "PerformanceOptimizer",
            dependencies: ["Common"],
            path: "Sources/PerformanceOptimizer"
        ),
        
        // 复制TreeMapVisualization模块源码
        .target(
            name: "TreeMapVisualization",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer"],
            path: "Sources/TreeMapVisualization"
        ),
        
        // 复制DirectoryTreeView模块源码
        .target(
            name: "DirectoryTreeView",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "Sources/DirectoryTreeView"
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
            dependencies: ["Common", "DataModel", "ScanEngine", "PerformanceOptimizer"],
            path: "Sources/SessionManager"
        ),
        
        // 复制InteractionFeedback模块源码
        .target(
            name: "InteractionFeedback",
            dependencies: ["Common"],
            path: "Sources/InteractionFeedback"
        ),
        
        // 复制UserInterface模块源码
        .target(
            name: "UserInterface",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "TreeMapVisualization", "DirectoryTreeView", "PerformanceOptimizer", "InteractionFeedback", "SessionManager"],
            path: "Sources/UserInterface"
        ),
        
        // 测试目标
        .testTarget(
            name: "UserInterfaceTests",
            dependencies: ["UserInterface", "TreeMapVisualization", "DirectoryTreeView", "CoordinateSystem", "DataModel", "PerformanceOptimizer", "InteractionFeedback", "SessionManager", "ScanEngine", "Common"],
            path: "Tests/UserInterfaceTests"
        )
    ]
)
