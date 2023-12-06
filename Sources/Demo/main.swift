@_spi(ExperimentalLanguageFeature) import Body
@_spi(ExperimentalLanguageFeature) import MacroDefinition

// TODO: P1 Unclear why unable to use/see declaration in body
@attached(preamble)
macro Log2() =
  #externalMacro(module: "MacroDefinition", type: "Log2PreambleMacro")

enum Demo {
  static func printfunc(_ s: String, f: StaticString = #function) {
    print("- \(f): \(s)")
  }

  @Log2
  static func hello(name you: String = "World!") -> String {
    let result = "Hello \(you)"
    printfunc(result)
    @Log2
    func goodbye(_ epilog: String) {
      printfunc("\(result) - \(epilog)")
    }
    goodbye(" ... Aloha!")
    return result
  }
  public static func demo() -> [String] {
    var result = [String]()
    result += [hello()]
    result += [hello(name: "Handsome")]
    return result
  }
}

Demo.printfunc("## Demo results:\n" + Demo.demo().joined(separator: "\n"))
