// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "macos_liquid_glass_ui",
  platforms: [
    .macOS("12.0")
  ],
  products: [
    .library(name: "macos-liquid-glass-ui", targets: ["macos_liquid_glass_ui"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "macos_liquid_glass_ui",
      dependencies: [],
      resources: [
        .process("Resources")
      ]
    )
  ]
)
