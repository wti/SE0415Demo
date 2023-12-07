// Source: https://github.com/DougGregor/swift/blob/380bad4e0743d2b6e1d1b23ee2b02bba04ac9a3d/test/Macros/Inputs/syntax_macro_definitions.swift

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) import SwiftSyntaxMacros

// RESTORE
//@_spi(ExperimentalLanguageFeature)
//public struct RemoteBodyMacro: BodyMacro {
//  public static func expansion(
//    of node: AttributeSyntax,
//    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
//    in context: some MacroExpansionContext
//  ) throws -> [CodeBlockItemSyntax] {
//    // FIXME: Should be able to support (de-)initializers and accessors as
//    // well, but this is a lazy implementation.
//    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
//      return []
//    }
//
//    let funcBaseName = funcDecl.name.text
//    let paramNames = funcDecl.signature.parameterClause.parameters.map { param in
//      param.parameterName ?? TokenSyntax(.wildcard, presence: .present)
//    }
//
//    let passedArgs = DictionaryExprSyntax(
//      content: .elements(
//        DictionaryElementListSyntax {
//          for paramName in paramNames {
//            DictionaryElementSyntax(
//              key: ExprSyntax("\(literal: paramName.text)"),
//              value: DeclReferenceExprSyntax(baseName: paramName)
//            )
//          }
//        }
//      )
//    )
//
//    return [
//      """
//      return try await remoteCall(function: \(literal: funcBaseName), arguments: \(passedArgs))
//      """
//    ]
//  }
//}

// RESTORE
//@_spi(ExperimentalLanguageFeature)
//public struct TracedPreambleMacro: PreambleMacro {
//  public static func expansion(
//    of node: AttributeSyntax,
//    providingPreambleFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
//    in context: some MacroExpansionContext
//  ) throws -> [CodeBlockItemSyntax] {
//    // FIXME: Should be able to support (de-)initializers and accessors as
//    // well, but this is a lazy implementation.
//    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
//      return []
//    }
//
//    let funcBaseName = funcDecl.name
//    let paramNames = funcDecl.signature.parameterClause.parameters.map { param in
//      param.parameterName?.text ?? "_"
//    }
//
//    let passedArgs = paramNames.map { "\($0): \\(\($0))" }.joined(separator: ", ")
//
//    let entry: CodeBlockItemSyntax = """
//      log("Entering \(funcBaseName)(\(raw: passedArgs))")
//      """
//
//    let argLabels = paramNames.map { "\($0):" }.joined()
//
//    let exit: CodeBlockItemSyntax = """
//      log("Exiting \(funcBaseName)(\(raw: argLabels))")
//      """
//
//    return [
//      entry,
//      """
//      defer {
//        \(exit)
//      }
//      """,
//    ]
//  }
//}

@_spi(ExperimentalLanguageFeature)
public struct Log2PreambleMacro: PreambleMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPreambleFor declaration: some DeclSyntaxProtocol
      & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    // TODO: P2 initializers and accessors
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      return []
    }

    let funcBaseName = funcDecl.name
    let paramNames = funcDecl.signature.parameterClause.parameters.map {
      param in
      param.secondName?.text ?? "_"
    }

    let passedArgs = paramNames.map { "\($0): \\(\($0))" }.joined(
      separator: ", "
    )

    let entry: CodeBlockItemSyntax = """
      log2("Entering \(funcBaseName)(\(raw: passedArgs))")
      """

    let argLabels = paramNames.map { "\($0):" }.joined()

    let exit: CodeBlockItemSyntax = """
      log2("Exiting \(funcBaseName)(\(raw: argLabels))")
      """

    return [
      entry,
      """
      defer {
        \(exit)
      }
      """,
    ]
  }
}
