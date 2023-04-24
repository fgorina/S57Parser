import XCTest
@testable import S57Parser

final class S57ParserTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let url = Bundle.module.url(forResource: "ES539411", withExtension: "002")
        XCTAssertNotNil(url)
        
        var  parser = S57Parser(url: url!)
        try parser.parse()
        XCTAssertTrue(parser.features.count > 0)
        
    }
}
