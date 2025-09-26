
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Mortgage-Rate-Tracker",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Mortgage-Rate-Tracker",
            targets: ["Mortgage-Rate-Tracker"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.2")
    ],
    targets: [
        .target(
            name: "Mortgage-Rate-Tracker",
            dependencies: ["SwiftSoup"],
            path: "Mortgage Rate Tracker/Mortgage Rate Tracker"
        )
    ]
)
