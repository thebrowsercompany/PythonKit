// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "PythonKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "PythonKit",
            targets: ["PythonKit"]
        )
    ],
    targets: [
        .target(
            name: "PythonKit",
            path: "PythonKit"
        ),
        .testTarget(
            name: "PythonKitTests",
            dependencies: ["PythonKit"]
        ),
    ]
)
