import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

/// Test case for macro takes input and expected output or error, and testing options
public struct MacroCase {
  /// Run all cases with options, in nesting variants
  ///
  /// - Parameters:
  ///   - cases: Array of MacroCase
  ///   - outers: Array of String for outer context declarations (default: empty, struct, class)
  ///   - options: Array of ``Option`` used to create each MacroCase
  public static func runAllNested(
    cases: [MacroCase],
    nesting outers: [String] = ["", "struct T", "class T"],
    options: [MacroCase.Option] = [.CleanBeforeCompare, .UseMarrowAsserts]
  ) throws {
    func nest(outer: String, inner: String) -> String {
      outer.isEmpty ? inner : "\(outer) {\n\(inner)\n}\n"
    }
    for next in cases {
      for outer in outers {
        let input = nest(outer: outer, inner: next.input)
        let output = nest(outer: outer, inner: next.output)
        let label = next.label + " [outer: \"\(outer)\"]"
        let test = next.with(
          label: label,
          input: input,
          output: output,
          options: options
        )
        try test.check()  // <------------- test
      }
    }
  }

  public enum Option {
    /// Use our local asserts (with some fixes)
    case UseMarrowAsserts

    /// When using local assert, clean white space etc. after generating code
    /// to avoid false negatives (janky)
    case CleanBeforeCompare

    public func activeIn(_ options: [Self]) -> Bool {
      options.contains(self)
    }

    public static let DEFAULTS: [Self] = [
      .UseMarrowAsserts, .CleanBeforeCompare,
    ]
  }
  public let label: String
  public let input: String
  public let output: String
  public let macros: [String: Macro.Type]
  public let errorInfix: String?
  public let options: [Option]
  public init(
    _ label: String,
    input: String,
    output: String,
    macros: [String: Macro.Type] = [:],
    error: String? = nil,
    options: [Option] = Option.DEFAULTS
  ) {
    self.label = label
    self.input = input
    self.output = output
    self.macros = macros
    self.errorInfix = error
    self.options = options
  }

  /// Factory to create another from self with specified variants
  public func with(
    label: String? = nil,
    input: String? = nil,
    output: String? = nil,
    macros: [String: Macro.Type]? = nil,
    error: String? = nil,
    options: [Option]? = nil
  ) -> MacroCase {
    MacroCase(
      label ?? self.label,
      input: input ?? self.input,
      output: output ?? self.output,
      macros: macros ?? self.macros,
      error: error ?? self.errorInfix,
      options: options ?? self.options
    )
  }

  /// Run macro test, applying options
  public func check(
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    if options.contains(.UseMarrowAsserts) {
      let mc = MacroChecks(nameToType: macros)
      try mc.assertMacroExpansion(
        from: input,
        to: output,
        file: file,
        line: line,
        cleanFallback: options.contains(.CleanBeforeCompare),
        label: label,
        error: errorInfix
      )
    } else {
      assertMacroExpansion(
        input,
        expandedSource: output,
        macros: macros,
        indentationWidth: .spaces(2),
        file: file,
        line: line
      )
    }
  }
}
