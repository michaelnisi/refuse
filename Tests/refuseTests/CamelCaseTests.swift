import Testing

@testable import refuse

@Suite("camelCased")
struct CamelCaseTests {

    // Confirmed Xcode separator behaviour
    @Test func underscoreSeparator() { #expect("arrow_back".camelCased() == "arrowBack") }
    @Test func hyphenSeparator()     { #expect("arrow-back".camelCased() == "arrowBack") }
    @Test func dotSeparator()        { #expect("arrow.back".camelCased() == "arrowBack") }
    @Test func spaceSeparator()      { #expect("arrow back".camelCased() == "arrowBack") }

    // Multiple separators
    @Test func multipleComponents()      { #expect("my_fancy_asset".camelCased() == "myFancyAsset") }
    @Test func consecutiveSeparators()   { #expect("my__icon".camelCased() == "myIcon") }
    @Test func mixedSeparators()         { #expect("my_fancy-asset".camelCased() == "myFancyAsset") }

    // Already camelCase / PascalCase — no separators, only first letter lowercased
    @Test func alreadyCamelCase()  { #expect("myIcon".camelCased() == "myIcon") }
    @Test func pascalCase()        { #expect("MyIcon".camelCased() == "myIcon") }

    // Numbers — Xcode behaviour is undocumented; we pin our own output here
    @Test func trailingNumber()    { #expect("icon_2x".camelCased() == "icon2x") }
    @Test func embeddedNumber()    { #expect("my_2x_icon".camelCased() == "my2xIcon") }
    @Test func numberOnly()        { #expect("icon64".camelCased() == "icon64") }
}
