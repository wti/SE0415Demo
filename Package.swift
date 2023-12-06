// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

func depSyntax(_ pack: String) -> PackageDescription.Target.Dependency {
  .product(name: pack, package: "swift-syntax")
}
let package = Package(
  name: "SE0415Demo",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .library(name: "Body", targets: ["Body"]),
    .executable(name: "Demo", targets: ["Demo"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-syntax",
      // After https://github.com/apple/swift-syntax/pull/2384
      revision: "06b57f3eab7ddf15ddf13d015e14d51739b4a433"
      // non-semVer tag: "swift-5.10-DEVELOPMENT-SNAPSHOT-2023-12-05-a"
    ),
  ],
  targets: [
    .macro(
      name: "MacroDefinition",
      dependencies: [
        depSyntax("SwiftOperators"),
        depSyntax("SwiftParser"),
        depSyntax("SwiftParserDiagnostics"),
        depSyntax("SwiftCompilerPlugin"),
        depSyntax("SwiftSyntax"),
        depSyntax("SwiftSyntaxMacros"),
        depSyntax("SwiftSyntaxMacroExpansion"),
      ],
      swiftSettings: [ .enableExperimentalFeature("BodyMacros")]
    ),
    .target(
      name: "Body",
      dependencies: ["MacroDefinition"],
      swiftSettings: [ .enableExperimentalFeature("BodyMacros")]
    ),
    .executableTarget(
      name: "Demo",
      dependencies: ["Body"],
      swiftSettings: [ .enableExperimentalFeature("BodyMacros")]
    ),
    .target(
      name: "MacroChecks",
      dependencies: [
        depSyntax("SwiftSyntaxMacroExpansion"),
        depSyntax("SwiftSyntaxMacrosTestSupport"),
        ],
      path: "Tests/MacroChecks"),
    .testTarget(
      name: "BodyTests",
      dependencies: [
        "Body",
        "MacroDefinition",
        "MacroChecks",
        depSyntax("SwiftSyntaxMacrosTestSupport"),
      ],
      swiftSettings: [ .enableExperimentalFeature("BodyMacros")]
    ),
  ]
)
