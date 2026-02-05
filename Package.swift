// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CursorHighlight",
    platforms: [.macOS(.v10_15)],
    targets: [
        .executableTarget(
            name: "CursorHighlight",
            path: "Sources/CursorHighlight"
        )
    ]
)
