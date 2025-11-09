// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeCompanion",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LifeCompanion",
            targets: ["LifeCompanion"]
        ),
    ],
    dependencies: [
        // Add any package dependencies here
    ],
    targets: [
        .target(
            name: "LifeCompanion",
            dependencies: [],
            path: "LifeCompanion"
        ),
        .testTarget(
            name: "LifeCompanionTests", 
            dependencies: ["LifeCompanion"],
            path: "LifeCompanionTests"
        ),
    ]
)