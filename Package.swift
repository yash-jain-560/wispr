// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OptionStatusChip",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "OptionStatusChipCore", targets: ["OptionStatusChipCore"]),
        .executable(name: "OptionStatusChipCoreTestsRunner", targets: ["OptionStatusChipCoreTestsRunner"])
    ],
    targets: [
        .target(
            name: "OptionStatusChipCore",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "OptionStatusChipCoreTestsRunner",
            dependencies: ["OptionStatusChipCore"],
            path: "Tests/OptionStatusChipCoreTestsRunner"
        )
    ]
)
