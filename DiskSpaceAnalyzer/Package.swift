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
            name: "Core",
            targets: ["Core"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        .executableTarget(
            name: "DiskSpaceAnalyzer",
            dependencies: [],
            path: "Sources/DiskSpaceAnalyzer"
        ),
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
        .testTarget(
            name: "DataModelTests",
            dependencies: ["Core"],
            path: "Tests/DataModelTests"
        ),
        .testTarget(
            name: "CoordinateSystemTests",
            dependencies: ["Core"],
            path: "Tests/CoordinateSystemTests"
        ),
        .testTarget(
            name: "PerformanceOptimizerTests",
            dependencies: ["Core"],
            path: "Tests/PerformanceOptimizerTests"
        ),
        .testTarget(
            name: "ScanEngineTests",
            dependencies: ["Core"],
            path: "Tests/ScanEngineTests"
        ),
        .testTarget(
            name: "TreeMapVisualizationTests",
            dependencies: ["Core"],
            path: "Tests/TreeMapVisualizationTests"
        ),
        .testTarget(
            name: "InteractionFeedbackTests",
            dependencies: ["Core"],
            path: "Tests/InteractionFeedbackTests"
        ),
        .testTarget(
            name: "SessionManagerTests",
            dependencies: ["Core"],
            path: "Tests/SessionManagerTests"
        ),
        .testTarget(
            name: "UserInterfaceTests",
            dependencies: ["Core"],
            path: "Tests/UserInterfaceTests"
        )
    ]
)
