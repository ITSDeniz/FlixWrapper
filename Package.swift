// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlixWrapper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "FlixWrapper",
            targets: ["FlixWrapper"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FlixWrapper",
            dependencies: [],
            path: "Sources/FlixWrapper"
        )
    ]
)
