import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MarrowPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    Log2PreambleMacro.self
  ]
}
