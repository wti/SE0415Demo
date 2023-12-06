# SE0415Demo
- [SE-0415 function body macro proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0415-function-body-macros.md)
- [SE-0415 function body macro discussion on swift forum](https://forums.swift.org/t/se-0415-function-body-macros)

## Status
- Minimal demo and test of preamble logging macro copied from PR tests
    - with known issues below

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
- `@Log2` Macro name not seen from client module?
    - workaround: declare in client
- Excess [Tests/MacroChecks](Tests/MacroChecks) helpful but not required
