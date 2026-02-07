// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-desktopia",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DesktopiaProX",
            targets: ["DesktopiaProX"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sgade/SwiftSerial", exact: "0.2.0"),
    ],
    targets: [
        .target(
            name: "DesktopiaProX",
            dependencies: [
                .product(name: "SwiftSerial", package: "SwiftSerial")
            ]
        )
    ]
)
