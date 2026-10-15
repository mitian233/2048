// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Classic2048",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Classic2048", targets: ["Classic2048"])],
    targets: [
        .target(name: "GameCore"),
        .executableTarget(name: "Classic2048", dependencies: ["GameCore"]),
        .testTarget(name: "GameCoreTests", dependencies: ["GameCore"])
    ]
)
