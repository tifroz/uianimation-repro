// swift-tools-version: 6.2
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "uianimation-repro",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "SkipUIAnimationRepro", type: .dynamic, targets: ["SkipUIAnimationRepro"]),
    ],
    dependencies: [
        // .package(url: "https://source.skip.tools/skip.git", from: "1.8.9"),
        // .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0")
        .package(path: "/Users/hugo/Swishly/Projects/webvideocast/platforms/skip/libs_os/skip"),
        .package(path: "/Users/hugo/Swishly/Projects/webvideocast/platforms/skip/libs_os/skip-fuse-ui")
    ],
    targets: [
        .target(name: "SkipUIAnimationRepro", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
