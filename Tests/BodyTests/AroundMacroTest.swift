import Body
import MacroChecks
@_spi(ExperimentalLanguageFeature) import MacroDefinition
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@_spi(ExperimentalLanguageFeature)
public final class AroundMacroTests: XCTestCase {

  func testAround() throws {
    XCTAssert(!MacroCases.aroundTests.isEmpty, "Missing cases")
    try MacroCase.runAllNested(cases: MacroCases.aroundTests)
  }

  /// Static list of test cases (for selecting base cases and generating variants)
  struct MacroCases {
    public static let (aroundType, aroundName) = BodyMacroDecls.aroundMacroName
    public static let allTests = [around_1]
    public static let aroundTests = allTests.filter {
      nil != $0.macros[Self.aroundName]
    }

    public static let around_1 = MacroCase(
      "log2_1",
      input:
        """
        @\(Self.aroundName)
        func f() {
          print("hello")
        }
        """,
      output:
        """
        func f() {
          print("before")
          print("hello")
          print("after")
        }
        """,
      macros: [aroundName: aroundType]
    )
  }
}

