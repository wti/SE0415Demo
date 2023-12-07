import Body
import MacroChecks
@_spi(ExperimentalLanguageFeature) import MacroDefinition
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@_spi(ExperimentalLanguageFeature)
public final class PreambleMacroTests: XCTestCase {

  func testLog2() throws {
    XCTAssert(!MacroCases.log2Tests.isEmpty, "Missing cases")
    try MacroCase.runAllNested(cases: MacroCases.log2Tests)
  }

  /// Static list of test cases (for selecting base cases and generating variants)
  struct MacroCases {
    public static let (log2Type, log2Name) = BodyMacroDecls.log2MacroName
    public static let allTests = [log2_1]
    public static let log2Tests = allTests.filter {
      nil != $0.macros[Self.log2Name]
    }

    public static let log2_1 = MacroCase(
      "log2_1",
      input:
        """
        @\(Self.log2Name)
        func globalPrint() {
          print("hello")
        }
        """,
      output:
        """
        func globalPrint() {
          log2("Entering globalPrint()")
          defer {
            log2("Exiting globalPrint()")
          }
          print("hello")
        }
        """,
      macros: [log2Name: log2Type]
    )
  }
}
