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
        ),
        .library(
            name: "DirectoryTreeView",
            targets: ["DirectoryTreeView"]
        ),
        .library(
            name: "TreeMapVisualization",
            targets: ["TreeMapVisualization"]
        ),
        .library(
            name: "InteractionFeedback",
            targets: ["InteractionFeedback"]
        ),
        .library(
            name: "SessionManager",
            targets: ["SessionManager"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // 可执行目标
        .executableTarget(
            name: "DiskSpaceAnalyzer",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer", "ScanEngine", "DirectoryTreeView", "TreeMapVisualization", "InteractionFeedback", "SessionManager"],
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
        
        // DirectoryTreeView模块 - 智能目录树显示
        .target(
            name: "DirectoryTreeView",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "Sources/DirectoryTreeView"
        ),
        
        // TreeMapVisualization模块 - TreeMap可视化
        .target(
            name: "TreeMapVisualization",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer"],
            path: "Sources/TreeMapVisualization"
        ),
        
        // InteractionFeedback模块 - 交互反馈系统
        .target(
            name: "InteractionFeedback",
            dependencies: ["Common", "CoordinateSystem", "DirectoryTreeView", "TreeMapVisualization", "PerformanceOptimizer"],
            path: "Sources/InteractionFeedback"
        ),
        
        // SessionManager模块 - 会话管理系统
        .target(
            name: "SessionManager",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer", "ScanEngine"],
            path: "Sources/SessionManager"
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
        ),
        
        // DirectoryTreeView模块测试
        .testTarget(
            name: "DirectoryTreeViewTests",
            dependencies: ["DirectoryTreeView", "Common", "DataModel", "PerformanceOptimizer"],
            path: "Tests/DirectoryTreeViewTests"
        ),
        
        // TreeMapVisualization模块测试
        .testTarget(
            name: "TreeMapVisualizationTests",
            dependencies: ["TreeMapVisualization", "Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer"],
            path: "Tests/TreeMapVisualizationTests"
        ),
        
        // InteractionFeedback模块测试
        .testTarget(
            name: "InteractionFeedbackTests",
            dependencies: ["InteractionFeedback", "Common", "CoordinateSystem", "DirectoryTreeView", "TreeMapVisualization", "PerformanceOptimizer"],
            path: "Tests/InteractionFeedbackTests"
        ),
        
        // SessionManager模块测试
        .testTarget(
            name: "SessionManagerTests",
            dependencies: ["SessionManager", "Common", "DataModel", "PerformanceOptimizer", "ScanEngine"],
            path: "Tests/SessionManagerTests"
        )
    ]
)
