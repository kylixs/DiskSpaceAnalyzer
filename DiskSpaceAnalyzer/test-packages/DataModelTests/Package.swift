// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataModelTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DataModelTests",
            targets: ["DataModelTests"]
        )
    ],
    dependencies: [
        .package(path: "../../sources")
    ],
    targets: [
        .testTarget(
            name: "DataModelTests",
            dependencies: [
                .product(name: "DataModel", package: "sources"),
                .product(name: "Common", package: "sources")
            ],
            path: "Tests/DataModelTests"
        )
    ]
)
