// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VidmarkStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VidmarkStudio", targets: ["VidmarkStudio"])
    ],
    targets: [
        .executableTarget(
            name: "VidmarkStudio"
        )
    ]
)
