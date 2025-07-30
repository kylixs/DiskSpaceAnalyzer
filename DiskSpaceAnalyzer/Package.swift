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
            name: "DiskSpaceAnalyzerCore",
            targets: ["DiskSpaceAnalyzerCore"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        .executableTarget(
            name: "DiskSpaceAnalyzer",
            dependencies: ["DiskSpaceAnalyzerCore"],
            path: "Sources/App"
        ),
        .target(
            name: "DiskSpaceAnalyzerCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .testTarget(
            name: "DiskSpaceAnalyzerCoreTests",
            dependencies: ["DiskSpaceAnalyzerCore"],
            path: "Tests/DataModelTests"
        )
    ]
)
