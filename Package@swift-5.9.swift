// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "M3U8Decoder",
  platforms: [
    .iOS(.v12),
    .macOS(.v10_14),
    .tvOS(.v12),
    .visionOS(.v1),
    .watchOS(.v5)
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
        .copy("Resources/master_7_3_fairplay.m3u8"),
        .copy("Resources/video_7_02_3_fairplay.m3u8"),
      ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)

