// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vidp",
    // The AppKit HUD uses NSGlassEffectView, introduced in macOS 26.
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "Vidp", targets: ["Vidp"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/vidp-labs/vidp-engine.git",
            exact: "0.2.1"
        )
    ],
    targets: [
        .systemLibrary(
            name: "CMPV",
            path: "Sources/CMPV",
            pkgConfig: "mpv",
            providers: [.brew(["mpv", "pkg-config"])]
        ),
        .systemLibrary(name: "CPIP", path: "Sources/CPIP"),
        .executableTarget(
            name: "Vidp",
            dependencies: [
                "CMPV",
                "CPIP",
                .product(name: "VidpEngine", package: "vidp-engine"),
            ],
            path: "Sources",
            exclude: ["CMPV", "CPIP"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("MediaPlayer"),
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-Xlinker", "-rpath", "-Xlinker", "/opt/homebrew/opt/mpv/lib",
                    "-Xlinker", "-rpath", "-Xlinker", "/usr/local/opt/mpv/lib",
                ]),
                .linkedFramework("PIP"),
            ]
        ),
    ]
)
