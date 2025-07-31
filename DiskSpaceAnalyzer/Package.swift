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
        ),
        .library(
            name: "UserInterface",
            targets: ["UserInterface"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // 可执行目标
        .executableTarget(
            name: "DiskSpaceAnalyzer",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer", "ScanEngine", "DirectoryTreeView", "TreeMapVisualization", "InteractionFeedback", "SessionManager", "UserInterface"],
            path: "sources/App"
        ),
        
        // 基础模块 - 无依赖
        .target(
            name: "Common",
            dependencies: [],
            path: "sources/Common"
        ),
        
        // 数据模型模块 - 依赖Common
        .target(
            name: "DataModel",
            dependencies: ["Common"],
            path: "sources/DataModel"
        ),
        
        // 坐标系统模块 - 依赖Common
        .target(
            name: "CoordinateSystem",
            dependencies: ["Common"],
            path: "sources/CoordinateSystem"
        ),
        
        // 性能优化模块 - 依赖Common
        .target(
            name: "PerformanceOptimizer",
            dependencies: ["Common"],
            path: "sources/PerformanceOptimizer"
        ),
        
        // ScanEngine模块 - 文件系统扫描引擎
        .target(
            name: "ScanEngine",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "sources/ScanEngine"
        ),
        
        // DirectoryTreeView模块 - 智能目录树显示
        .target(
            name: "DirectoryTreeView",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer"],
            path: "sources/DirectoryTreeView"
        ),
        
        // TreeMapVisualization模块 - TreeMap可视化
        .target(
            name: "TreeMapVisualization",
            dependencies: ["Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer"],
            path: "sources/TreeMapVisualization"
        ),
        
        // InteractionFeedback模块 - 交互反馈系统
        .target(
            name: "InteractionFeedback",
            dependencies: ["Common", "CoordinateSystem", "DirectoryTreeView", "TreeMapVisualization", "PerformanceOptimizer"],
            path: "sources/InteractionFeedback"
        ),
        
        // SessionManager模块 - 会话管理系统
        .target(
            name: "SessionManager",
            dependencies: ["Common", "DataModel", "PerformanceOptimizer", "ScanEngine"],
            path: "sources/SessionManager"
        ),
        
        // UserInterface模块 - 用户界面集成
        .target(
            name: "UserInterface",
            dependencies: ["Common", "DataModel", "DirectoryTreeView", "TreeMapVisualization", "InteractionFeedback", "SessionManager"],
            path: "sources/UserInterface"
        ),
        
        // 测试目标
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            path: "tests/CommonTests"
        ),
        .testTarget(
            name: "DataModelTests",
            dependencies: ["DataModel", "Common"],
            path: "tests/DataModelTests"
        ),
        .testTarget(
            name: "CoordinateSystemTests",
            dependencies: ["CoordinateSystem", "Common"],
            path: "tests/CoordinateSystemTests"
        ),
        .testTarget(
            name: "PerformanceOptimizerTests",
            dependencies: ["PerformanceOptimizer", "Common"],
            path: "tests/PerformanceOptimizerTests"
        ),
        
        // ScanEngine模块测试
        .testTarget(
            name: "ScanEngineTests",
            dependencies: ["ScanEngine", "Common", "DataModel", "PerformanceOptimizer"],
            path: "tests/ScanEngineTests"
        ),
        
        // DirectoryTreeView模块测试
        .testTarget(
            name: "DirectoryTreeViewTests",
            dependencies: ["DirectoryTreeView", "Common", "DataModel", "PerformanceOptimizer"],
            path: "tests/DirectoryTreeViewTests"
        ),
        
        // TreeMapVisualization模块测试
        .testTarget(
            name: "TreeMapVisualizationTests",
            dependencies: ["TreeMapVisualization", "Common", "DataModel", "CoordinateSystem", "PerformanceOptimizer"],
            path: "tests/TreeMapVisualizationTests"
        ),
        
        // InteractionFeedback模块测试
        .testTarget(
            name: "InteractionFeedbackTests",
            dependencies: ["InteractionFeedback", "Common", "CoordinateSystem", "DirectoryTreeView", "TreeMapVisualization", "PerformanceOptimizer"],
            path: "tests/InteractionFeedbackTests"
        ),
        
        // SessionManager模块测试
        .testTarget(
            name: "SessionManagerTests",
            dependencies: ["SessionManager", "Common", "DataModel", "PerformanceOptimizer", "ScanEngine"],
            path: "tests/SessionManagerTests"
        ),
        
        // UserInterface模块测试
        .testTarget(
            name: "UserInterfaceTests",
            dependencies: ["UserInterface", "Common", "DataModel", "DirectoryTreeView", "TreeMapVisualization", "InteractionFeedback", "SessionManager"],
            path: "tests/UserInterfaceTests"
        )
    ]
)
