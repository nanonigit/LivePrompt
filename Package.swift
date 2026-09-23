// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "LivePrompt",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "LivePrompt", targets: ["LivePrompt"])],
    targets: [
        .executableTarget(
            name: "LivePrompt",
            path: "Sources/LivePrompt",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
