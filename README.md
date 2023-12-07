# SE0415Demo
- [SE-0415 function body macro proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0415-function-body-macros.md)
- [SE-0415 function body macro discussion on swift forum](https://forums.swift.org/t/se-0415-function-body-macros)

## Status
- Minimal demo and test of preamble and body macro adapted from PR tests

## Getting started
- Download and install [trunk/main toolchain snapshot](https://www.swift.org/download/#snapshots)
- Clone this git repository locally
- Building in Xcode: 
    - Select toolchain (Xcode/toolchains) before building

## Tips
- `swiftSettings: [ .enableExperimentalFeature("BodyMacros")]` on each 
  [Package.swift](Package.swift) target
- `@_spi() import ...` on client code

## Known issues
- P1 Macro names not seen from client module?
    - workaround: declare in client
    - possibly d/t `@_spi`
- P1 Body macro statements duplicated, resulting in dangling closure
- Excess [Tests/MacroChecks](Tests/MacroChecks) helpful but not required

## Development
- `// Source: ` indicates code copied from and copyrighted by Apple
