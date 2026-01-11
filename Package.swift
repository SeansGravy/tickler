// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tickler",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "tickler", targets: ["tickler"])
    ],
    targets: [
        .executableTarget(
            name: "tickler",
            path: "tickler",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
