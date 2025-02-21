// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RSMultipeerConnectivity",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "RSMultipeerConnectivity",
            targets: ["RSMultipeerConnectivity"]
        ),
    ],
    targets: [
        .target(
            name: "RSMultipeerConnectivity"
        )
    ]
)
