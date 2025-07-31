// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CommonTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // Common模块 - 基础模块，无依赖
        .target(
            name: "Common",
            dependencies: [],
            path: "Sources/Common"
        ),
        
        // CommonTests测试目标
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"],
            path: "Tests/CommonTests"
        )
    ]
)
