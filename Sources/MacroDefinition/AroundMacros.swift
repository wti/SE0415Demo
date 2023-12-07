// Source: https://github.com/DougGregor/swift/blob/380bad4e0743d2b6e1d1b23ee2b02bba04ac9a3d/test/Macros/Inputs/syntax_macro_definitions.swift

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) import SwiftSyntaxMacros

@_spi(ExperimentalLanguageFeature)
public struct AroundBodyMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    // TODO: P2 initializers and accessors
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      return []
    }

    var results = [CodeBlockItemSyntax]()
    if let body = funcDecl.body {
      let me: CodeBlockSyntax = body.detached
      results += me.statements
    }

    let before: [CodeBlockItemSyntax] = [
      "print(\"before\")"
    ]
    let after: [CodeBlockItemSyntax] = [
      "print(\"after\")"
    ]

    return before + results + after
  }
}

