// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InteractionFeedbackTests",
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
        
        // 复制InteractionFeedback模块源码
        .target(
            name: "InteractionFeedback",
            dependencies: ["Common"],
            path: "Sources/InteractionFeedback"
        ),
        
        // 测试目标
        .testTarget(
            name: "InteractionFeedbackTests",
            dependencies: ["InteractionFeedback", "Common"],
            path: "Tests/InteractionFeedbackTests"
        )
    ]
)
