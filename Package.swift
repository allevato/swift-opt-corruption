// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "swift-opt-corruption",
  products: [
    .executable(name: "swift-opt-corruption", targets: ["swift-opt-corruption"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", .revision("swift-DEVELOPMENT-SNAPSHOT-2020-04-01-a")),
  ],
  targets: [
    .target(name: "swift-opt-corruption", dependencies: ["SwiftSyntax"]),
  ]
)
