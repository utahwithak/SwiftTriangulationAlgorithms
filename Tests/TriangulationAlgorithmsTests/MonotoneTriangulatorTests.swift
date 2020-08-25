import XCTest
@testable import TriangulationAlgorithms

final class MonotoneTriangulatorTests: XCTestCase {
    func testFailingExample() {
        let points = [
            CGPoint(x: 196.30672764888544, y: 251.7828663402471),
            CGPoint(x: 218.83451806954758, y: 258.39557054019895),
            CGPoint(x: 227.36272160331396, y: 252.27239539896016),
            CGPoint(x: 224.0356371401757, y: 263.51012842439775),
            CGPoint(x: 229.021962098657, y: 269.42162857350377),
            CGPoint(x: 223.82474814020344, y: 300.4268550851856),
            //            CGPoint(x: 205.1343841667101, y: 300.4268550851856),
            CGPoint(x: 205.1343841667101, y: 300.4268550851856),
            CGPoint(x: 190.25766563737488, y: 294.69570900284384)]

        do {
            let tris = try MonotonePolygonAlgorithm.triangulate(points: points)
            XCTAssert(!tris.isEmpty)
            XCTAssert(tris.count % 3 == 0)

        } catch {
            XCTFail("Should triangulate!")
        }

    }

    func testInvalidTriangulation() {
        let points = [CGPoint(x: -234.0891692103836, y: 215.90117964790088),
                      CGPoint(x: -234.0891692103836, y: 197.11769621739316),
                      CGPoint(x: -251.52201931647178, y: 196.84471532564396),
                      CGPoint(x: -274.1893149057149, y: 220.71659164822108),
                      CGPoint(x: -269.6321269905487, y: 227.6462238488641),
                      CGPoint(x: -270.635080924655, y: 233.25603642313547),
                      CGPoint(x: -220.11217169040998, y: 261.10328616317236)]
        do {
            let tris = try MonotonePolygonAlgorithm.triangulate(points: points)
            XCTAssert(!tris.isEmpty)
            XCTAssert(tris.count % 3 == 0)
        } catch {
            XCTFail("Should triangulate!")
        }
    }
}
