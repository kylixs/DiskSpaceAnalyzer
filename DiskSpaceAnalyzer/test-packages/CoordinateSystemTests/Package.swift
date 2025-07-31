// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoordinateSystemTests",
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
        
        // 复制CoordinateSystem模块源码
        .target(
            name: "CoordinateSystem",
            dependencies: ["Common"],
            path: "Sources/CoordinateSystem"
        ),
        
        // 测试目标
        .testTarget(
            name: "CoordinateSystemTests",
            dependencies: ["CoordinateSystem", "Common"],
            path: "Tests/CoordinateSystemTests"
        )
    ]
)
