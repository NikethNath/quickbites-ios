// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "QuickBitesCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "QuickBitesCore",
            targets: ["QuickBitesCore"]),
    ],
    targets: [
        .target(
            name: "QuickBitesCore"),
        .testTarget(
            name: "QuickBitesCoreTests",
            dependencies: ["QuickBitesCore"]
        ),
    ]
)
