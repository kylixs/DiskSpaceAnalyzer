// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataModelTests",
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
        
        // 测试目标
        .testTarget(
            name: "DataModelTests",
            dependencies: ["DataModel", "Common"],
            path: "Tests/DataModelTests"
        )
    ]
)
