// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoordinateSystemTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CoordinateSystem",
            targets: ["CoordinateSystem"]
        )
    ],
    dependencies: [
        // 这里可以添加外部依赖
    ],
    targets: [
        // Common模块 - 基础模块
        .target(
            name: "Common",
            dependencies: [],
            path: "../../sources/Common"
        ),
        
        // CoordinateSystem模块 - 坐标系统模块
        .target(
            name: "CoordinateSystem",
            dependencies: ["Common"],
            path: "../../sources/CoordinateSystem"
        ),
        
        // CoordinateSystemTests测试目标
        .testTarget(
            name: "CoordinateSystemTests",
            dependencies: ["CoordinateSystem", "Common"],
            path: "../../tests/CoordinateSystemTests"
        )
    ]
)
