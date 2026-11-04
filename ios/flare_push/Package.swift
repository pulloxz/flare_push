// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flare_push",
    platforms: [.iOS("13.0")],
    products: [.library(name: "flare-push", targets: ["flare_push"])],
    dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")],
    targets: [
        .target(
            name: "flare_push",
            dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework")]
        )
    ]
)
