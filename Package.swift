// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "tokenmanager",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "TokenManagerCore", targets: ["TokenManagerCore"]),
        .executable(name: "tokenmanager", targets: ["TokenManagerApp"]),
        .executable(name: "tokenmanagerctl", targets: ["TokenManagerCLI"]),
    ],
    targets: [
        .target(
            name: "TokenManagerCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "TokenManagerCLI",
            dependencies: ["TokenManagerCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "TokenManagerApp",
            dependencies: ["TokenManagerCore"],
            path: "Sources/TokenManagerApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "TokenManagerCoreTests",
            dependencies: ["TokenManagerCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ])
