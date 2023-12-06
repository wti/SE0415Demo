import SwiftBasicFormat
import SwiftDiagnostics
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

/// DRAFT abstraction over string-cleaning variants to customize string-matching preprocessing
/// Currently matching and cleanop overlap semantically b/c search range depends on both
public struct StrClean {
  public static let TRIM_EOL = Self(.trim, .eol)
  public static let DELETE_WHITESPACE = Self(.delete, .whitespace)
  public let op: CleanOp
  public let matcher: StrMatcher
  private init(_ op: CleanOp, _ matcher: StrMatcher) {
    self.matcher = matcher
    self.op = op
  }
  public func clean(_ input: String) -> (changed: Bool, output: String?) {
    return (false, nil)
  }

  public enum StrMatcher {
    case space, eol
    case whitespace
    case range(_ range: ClosedRange<Character>)
    case literal(_ literal: String)
    case regexp(_ regex: Regex<String>)
    public func start(_ input: String) -> String.Index? {
      return nil
    }
  }

  public enum CleanOp {
    /// Remove prefix or suffix
    case trim
    /// Reduce series to a single value
    case collapse
    /// Delete value
    case delete
    /// Replace value
    case replace(with: String)
  }
}
/// assertStringsEqualWithDiff with clean.
/// Source: _SwiftSyntaxTestSupport/AssertEqualWithDiff.swift
/// Source: SwiftSyntaxMacrosTestSupport/Assertions.swift
public struct MacroChecks {
  private static let SKIP_MISSED_ERROR = "" == "no"
  public let nameToType: [String: Macro.Type]
  public let forceCleanFallback: Bool
  public init(
    nameToType: [String: Macro.Type],
    forceCleanFallback: Bool = false
  ) {
    self.nameToType = nameToType
    self.forceCleanFallback = forceCleanFallback
  }

  /// Asserts that the two strings are equal, providing Unix `diff`-style output if they are not.
  ///
  /// - Parameters:
  ///   - actual: The actual string.
  ///   - expected: The expected string.
  ///   - message: An optional description of the failure.
  ///   - additionalInfo: Additional information about the failed test case that will be printed after the diff
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in
  ///     which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this
  ///     function was called.
  public func assertStringsEqualWithDiff(
    _ actual: String,
    _ expected: String,
    _ message: String = "",
    additionalInfo: @autoclosure () -> String? = nil,
    file: StaticString = #file,
    line: UInt = #line,
    cleanFallback: Bool = false
  ) {
    if actual == expected {
      return
    }
    if cleanFallback || self.forceCleanFallback {
      // normalizing should be enough, but isn't
      func normal(_ s: String) -> String {
        let spaces = #/  */#
        let returns = #/ *\n */#  // greedy problem with multiple newlines?
        let deSpaced = s.replacing(spaces, with: " ")
        return deSpaced.replacing(returns, with: "\n")
      }
      // TODO: P2 false positive from removing all spaces/newlines
      func none(_ s: String) -> String {
        let speol = #/[ \n]+/#
        return s.replacing(speol, with: "")
      }
      let act = none(normal(actual))
      let exp = none(normal(expected))
      if act == exp {
        return
      }
    }
    failStringsEqualWithDiff(
      actual,
      expected,
      message,
      additionalInfo: additionalInfo(),
      file: file,
      line: line
    )
  }
  /// `XCTFail` with `diff`-style output.
  private func failStringsEqualWithDiff(
    _ actual: String,
    _ expected: String,
    _ message: String = "",
    additionalInfo: @autoclosure () -> String? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Use `CollectionDifference` on supported platforms to get `diff`-like line-based output. On
    // older platforms, fall back to simple string comparison.
    if #available(macOS 10.15, *) {
      let actualLines = actual.components(separatedBy: .newlines)
      let expectedLines = expected.components(separatedBy: .newlines)

      let difference = actualLines.difference(from: expectedLines)

      var result = ""
      var ins = 0
      var del = 0

      for change in difference {
        switch change {
        case .insert(let offset, let element, _):
          result += "[\(offset)] + \(element)\n"
          ins += 1
        case .remove(let offset, let element, _):
          result += "[\(offset)] - \(element)\n"
          del += 1
        }
      }
      //      var insertions = [Int: String]()
      //      var removals = [Int: String]()

      //      for change in difference {
      //        switch change {
      //        case .insert(let offset, let element, _):
      //          insertions[offset] = element
      //        case .remove(let offset, let element, _):
      //          removals[offset] = element
      //        }
      //      }
      //
      //      var expectedLine = 0
      //      var actualLine = 0
      //
      //      while expectedLine < expectedLines.count || actualLine < actualLines.count
      //      {
      //        if let removal = removals[expectedLine] {
      //          result += "–\(removal)\n"
      //          expectedLine += 1
      //        } else if let insertion = insertions[actualLine] {
      //          result += "+\(insertion)\n"
      //          actualLine += 1
      //        } else {
      //          result += " \(expectedLines[expectedLine])\n"
      //          expectedLine += 1
      //          actualLine += 1
      //        }
      //      }

      let failureMessage =
        "+\(ins) inserts, -\(del) deletes:\n\(result)"
      var fullMessage =
        message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
      if let additionalInfo = additionalInfo() {
        fullMessage = """
          \(fullMessage)
          \(additionalInfo)
          """
      }
      XCTFail(fullMessage, file: file, line: line)
    } else {
      // Fall back to simple message on platforms that don't support CollectionDifference.
      let failureMessage = "Actual output differed from expected output:"
      let fullMessage =
        message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
      XCTFail(fullMessage, file: file, line: line)
    }
  }
  // MARK: - Note

  /// Describes a diagnostic note that tests expect to be created by a macro expansion.
  public struct NoteSpec {
    /// The expected message of the note
    public let message: String

    /// The line to which the note is expected to point
    public let line: Int

    /// The column to which the note is expected to point
    public let column: Int

    /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    internal let originatorFile: StaticString
    internal let originatorLine: UInt

    /// Creates a new ``NoteSpec`` that describes a note tests are expecting to be generated by a macro expansion.
    ///
    /// - Parameters:
    ///   - message: The expected message of the note
    ///   - line: The line to which the note is expected to point
    ///   - column: The column to which the note is expected to point
    ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    public init(
      message: String,
      line: Int,
      column: Int,
      originatorFile: StaticString = #file,
      originatorLine: UInt = #line
    ) {
      self.message = message
      self.line = line
      self.column = column
      self.originatorFile = originatorFile
      self.originatorLine = originatorLine
    }
  }

  func assertNote(
    _ note: Note,
    in tree: some SyntaxProtocol,
    expected spec: NoteSpec
  ) {
    assertStringsEqualWithDiff(
      note.message,
      spec.message,
      "message of note does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
    let location = note.location(
      converter: SourceLocationConverter(fileName: "", tree: tree)
    )
    XCTAssertEqual(
      location.line,
      spec.line,
      "line of note does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
    XCTAssertEqual(
      location.column,
      spec.column,
      "column of note does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
  }

  // MARK: - Fix-It

  /// Describes a Fix-It that tests expect to be created by a macro expansion.
  ///
  /// Currently, it only compares the message of the Fix-It. In the future, it might
  /// also compare the expected changes that should be performed by the Fix-It.
  public struct FixItSpec {
    /// The expected message of the Fix-It
    public let message: String

    /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    internal let originatorFile: StaticString
    internal let originatorLine: UInt

    /// Creates a new ``FixItSpec`` that describes a Fix-It tests are expecting to be generated by a macro expansion.
    ///
    /// - Parameters:
    ///   - message: The expected message of the note
    ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    public init(
      message: String,
      originatorFile: StaticString = #file,
      originatorLine: UInt = #line
    ) {
      self.message = message
      self.originatorFile = originatorFile
      self.originatorLine = originatorLine
    }
  }

  func assertFixIt(
    _ fixIt: FixIt,
    expected spec: FixItSpec
  ) {
    assertStringsEqualWithDiff(
      fixIt.message.message,
      spec.message,
      "message of Fix-It does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
  }

  // MARK: - Diagnostic

  /// Describes a diagnostic that tests expect to be created by a macro expansion.
  public struct DiagnosticSpec {
    /// If not `nil`, the ID, which the diagnostic is expected to have.
    public let id: MessageID?

    /// The expected message of the diagnostic
    public let message: String

    /// The line to which the diagnostic is expected to point
    public let line: Int

    /// The column to which the diagnostic is expected to point
    public let column: Int

    /// The expected severity of the diagnostic
    public let severity: DiagnosticSeverity

    /// If not `nil`, the text the diagnostic is expected to highlight
    public let highlight: String?

    /// The notes that are expected to be attached to the diagnostic
    public let notes: [NoteSpec]

    /// The messages of the Fix-Its the diagnostic is expected to produce
    public let fixIts: [FixItSpec]

    /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    internal let originatorFile: StaticString
    internal let originatorLine: UInt

    /// Creates a new ``DiagnosticSpec`` that describes a diagnsotic tests are expecting to be generated by a macro expansion.
    ///
    /// - Parameters:
    ///   - id: If not `nil`, the ID, which the diagnostic is expected to have.
    ///   - message: The expected message of the diagnostic
    ///   - line: The line to which the diagnostic is expected to point
    ///   - column: The column to which the diagnostic is expected to point
    ///   - severity: The expected severity of the diagnostic
    ///   - highlight: If not `nil`, the text the diagnostic is expected to highlight
    ///   - notes: The notes that are expected to be attached to the diagnostic
    ///   - fixIts: The messages of the Fix-Its the diagnostic is expected to produce
    ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
    public init(
      id: MessageID? = nil,
      message: String,
      line: Int,
      column: Int,
      severity: DiagnosticSeverity = .error,
      highlight: String? = nil,
      notes: [NoteSpec] = [],
      fixIts: [FixItSpec] = [],
      originatorFile: StaticString = #file,
      originatorLine: UInt = #line
    ) {
      self.id = id
      self.message = message
      self.line = line
      self.column = column
      self.severity = severity
      self.highlight = highlight
      self.notes = notes
      self.fixIts = fixIts
      self.originatorFile = originatorFile
      self.originatorLine = originatorLine
    }
  }

  func assertDiagnostic(
    _ diag: Diagnostic,
    in tree: some SyntaxProtocol,
    expected spec: DiagnosticSpec
  ) {
    if let id = spec.id {
      XCTAssertEqual(
        diag.diagnosticID,
        id,
        "diagnostic ID does not match",
        file: spec.originatorFile,
        line: spec.originatorLine
      )
    }
    assertStringsEqualWithDiff(
      diag.message,
      spec.message,
      "message does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
    let location = diag.location(
      converter: SourceLocationConverter(fileName: "", tree: tree)
    )
    XCTAssertEqual(
      location.line,
      spec.line,
      "line does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
    XCTAssertEqual(
      location.column,
      spec.column,
      "column does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )

    XCTAssertEqual(
      spec.severity,
      diag.diagMessage.severity,
      "severity does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )

    if let highlight = spec.highlight {
      var highlightedCode = ""
      highlightedCode.append(
        diag.highlights.first?.with(\.leadingTrivia, []).description ?? ""
      )
      for highlight in diag.highlights.dropFirst().dropLast() {
        highlightedCode.append(highlight.description)
      }
      if diag.highlights.count > 1 {
        highlightedCode.append(
          diag.highlights.last?.with(\.trailingTrivia, []).description ?? ""
        )
      }

      assertStringsEqualWithDiff(
        highlightedCode,
        highlight,
        "highlight does not match",
        file: spec.originatorFile,
        line: spec.originatorLine
      )
    }
    if diag.notes.count != spec.notes.count {
      XCTFail(
        """
        Expected \(spec.notes.count) notes but received \(diag.notes.count):
        \(diag.notes.map(\.debugDescription).joined(separator: "\n"))
        """,
        file: spec.originatorFile,
        line: spec.originatorLine
      )
    } else {
      for (note, expectedNote) in zip(diag.notes, spec.notes) {
        assertNote(note, in: tree, expected: expectedNote)
      }
    }
    if diag.fixIts.count != spec.fixIts.count {
      XCTFail(
        """
        Expected \(spec.fixIts.count) Fix-Its but received \(diag.fixIts.count):
        \(diag.fixIts.map(\.message.message).joined(separator: "\n"))
        """,
        file: spec.originatorFile,
        line: spec.originatorLine
      )
    } else {
      for (fixIt, expectedFixIt) in zip(diag.fixIts, spec.fixIts) {
        assertFixIt(fixIt, expected: expectedFixIt)
      }
    }
  }

  /// Assert that expanding the given macros in the original source produces
  /// the given expanded source code.
  ///
  /// - Parameters:
  ///   - originalSource: The original source code, which is expected to contain
  ///     macros in various places (e.g., `#stringify(x + y)`).
  ///   - expandedSource: The source code that we expect to see after performing
  ///     macro expansion on the original source.
  ///   - diagnostics: The diagnostics when expanding any macro
  ///   - macros: The macros that should be expanded, provided as a dictionary
  ///     mapping macro names (e.g., `"stringify"`) to implementation types
  ///     (e.g., `StringifyMacro.self`).
  ///   - testModuleName: The name of the test module to use.
  ///   - testFileName: The name of the test file name to use.
  public func assertMacroExpansion(
    from originalSource: String,
    to expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    file: StaticString = #file,
    line: UInt = #line,
    cleanFallback: Bool = false,
    label: String? = nil,
    error: String? = nil
  ) throws {
    let labl = (label?.isEmpty ?? true) ? "" : "\(label!): "
    // Parse the original source file.
    let origSourceFile = Parser.parse(source: originalSource)

    // Expand all macros in the source.
    let context = BasicMacroExpansionContext(
      sourceFiles: [
        origSourceFile: .init(
          moduleName: testModuleName,
          fullFilePath: testFileName
        )
      ]
    )

    let expandedSourceFile = origSourceFile.expand(
      macros: nameToType,
      in: context
    )
    let diags = ParseDiagnosticsGenerator.diagnostics(for: expandedSourceFile)
    if !diags.isEmpty {
      let resultError = DiagnosticsFormatter.annotatedSource(
        tree: expandedSourceFile,
        diags: diags
      )
      if let err = error {
        if resultError.contains(err) {
          return  // got expected error - no other checking
        }
        // report error below
      }
      XCTFail(
        """
        \(labl)Expanded source syntax errors:
        \(resultError)

        Expected error was: \(error ?? "NONE")
        Expanded syntax tree was:
        \(expandedSourceFile.debugDescription)
        """,
        file: file,
        line: line
      )
    } else if let err = error, Self.SKIP_MISSED_ERROR {
      // TODO: P2 skipping tests b/c diagnostics not appearing...
      throw XCTSkip(
        "Halt for diagnostics fix: false negative for error: \n  \(err)"
      )
    }

    let formattedSourceFile = expandedSourceFile.formatted(
      using: BasicFormat(indentationWidth: indentationWidth)
    )
    let actual = formattedSourceFile.description
      .trimmingCharacters(in: .newlines)
    let expected = expandedSource.trimmingCharacters(in: .newlines)
    assertStringsEqualWithDiff(
      expected,
      actual,
      additionalInfo: """
        \(labl)Original source input:
        \(originalSource)
        \(labl)Expanded source file (before format and remove whitespace):
        \(expandedSourceFile)
        \(labl)Expanded source (after format and remove whitespace):
        \(actual)
        \(labl)Expected source:
        \(expected)
        """,
      file: file,
      line: line,
      cleanFallback: cleanFallback
    )

    let expectErrs = diagnostics.count + (nil == error ? 0 : 1)
    if context.diagnostics.count != expectErrs {
      XCTFail(
        """
        \(labl)Expected \(diagnostics.count) diagnostics but received \(context.diagnostics.count):
        \(context.diagnostics.map(\.debugDescription).joined(separator: "\n"))
        """,
        file: file,
        line: line
      )
    } else {
      for (actualDiag, expectedDiag) in zip(context.diagnostics, diagnostics) {
        assertDiagnostic(actualDiag, in: origSourceFile, expected: expectedDiag)
      }
    }
  }

}
