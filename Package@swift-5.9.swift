// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "M3U8Decoder",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .visionOS(.v1),
    .watchOS(.v6)
  ],
  products: [
    .library(
      name: "M3U8Decoder",
      targets: ["M3U8Decoder"]),
  ],
  targets: [
    .target(
      name: "M3U8Decoder",
      dependencies: []),
    .testTarget(
      name: "M3U8DecoderTests",
      dependencies: ["M3U8Decoder"],
      resources: [
        .copy("m3u8"),
      ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)

