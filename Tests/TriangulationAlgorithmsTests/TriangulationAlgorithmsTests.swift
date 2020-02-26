import XCTest
@testable import TriangulationAlgorithms

final class TriangulationAlgorithmsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: 1, y: 0)]
        var clipper = EarClippingAlgorithm(points: points)

        XCTAssertEqual(clipper.triangulate().count, 6)
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
