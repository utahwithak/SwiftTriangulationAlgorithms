//
//  OrientedTriangle.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class OrientedTriangle {

    init(triangle: Triangle, orient: Int) {
        self.triangle = triangle
        self.orient = orient
    }

    init(encoded: Triangle.EncodedTriangle) {
        self.triangle = encoded.triangle
        self.orient = encoded.orientation
    }

    var triangle: Triangle
    var orient: Int

    var infected: Bool {
        get {
            return triangle.infected
        }
        set {
            triangle.infected = newValue
        }
    }
    var encodedTriangle: Triangle.EncodedTriangle {
        return Triangle.EncodedTriangle(triangle: triangle, orientation: orient)
    }

    func vertex(at: Int) -> Vertex! {
        switch at {
        case 0:
            return triangle.v1
        case 1:
            return triangle.v2
        default:
            return triangle.v3
        }

    }

    func set(vertex: Vertex?, at: Int) {
        switch at {
        case 0:
            triangle.v1 = vertex
        case 1:
            triangle.v2 = vertex
        default:
            triangle.v3 = vertex
        }
    }

    var org: Vertex? {
        get { vertex(at: plus1mod3[orient])}
        set {
            if let org = newValue {

                print("setting org:\t\(org.x) \(org.y)")
            } else {
                print("clearing org")
            }

            set(vertex: newValue, at: plus1mod3[orient]) }
    }

    var dest: Vertex? {
        get { vertex(at: minus1mod3[orient]) }
        set {
            if let dest = newValue {
                print("setting dest:\t\(dest.x) \(dest.y)")
            } else {
                print("Clearing dest")
            }
            set(vertex: newValue, at: minus1mod3[orient])}
    }

    var apex: Vertex! {
        get { vertex(at: orient) }
        set {
            if let apex = newValue {
                print("setting apex:\t \(apex.x) \(apex.y)")
            } else {
                print("clearing apex")
            }

            set(vertex: newValue, at: orient) }
    }

    func copy(to otri2: OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orient = orient
    }

    func copy() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orient: orient)
    }

    func otriEquals(other otri2: OrientedTriangle) -> Bool {
        return triangle === otri2.triangle && orient == otri2.orient
    }

    func bond(to otri2: OrientedTriangle) {
        let tri1Encoded = encodedTriangle
        let tri2Encoded = otri2.encodedTriangle
        switch orient {
        case 0:
            triangle.t1 = tri2Encoded
        case 1:
            triangle.t2 = tri2Encoded
        default:
            triangle.t3 = tri2Encoded
        }

        switch otri2.orient {
        case 0:
            otri2.triangle.t1 = tri1Encoded
        case 1:
            otri2.triangle.t2 = tri1Encoded
        default:
            otri2.triangle.t3 = tri1Encoded
        }
    }

    func lprevself() {
        orient = minus1mod3[orient]
    }

    func lnextself() {
        orient = plus1mod3[orient]
    }

    func lprev(on otri2: OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orient = minus1mod3[orient]
    }

    func lprev() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orient: minus1mod3[orient])
    }

    func lnext(on otri2: OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orient = plus1mod3[orient]
    }
    func lnext() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orient: plus1mod3[orient])
    }

    func onext() -> OrientedTriangle {
        let prev = lprev()
        prev.symself()
        return prev
    }
    func onextself() {
        lprevself()
        symself()
    }

    func tspivot() -> OrientedSubsegment {
        let sptr: Triangle.EncodedSubsegment
        switch orient {
        case 0:
            sptr = triangle.s1
        case 1:
            sptr = triangle.s2
        default:
            sptr = triangle.s3

        }
        return OrientedSubsegment(subseg: sptr.ss, orient: sptr.orientation)
    }

    func oprev() -> OrientedTriangle {
        let otri2 = sym()
        otri2.lnextself()
        return otri2
    }

    func oprev(to otri2: OrientedTriangle) {
        sym(to: otri2)
        otri2.lnextself()
    }
    func oprevself() {
        symself()
        lnextself()
    }
    func dnextself() {
        symself()
        lprevself()
    }

    func tsbond(to osub: OrientedSubsegment) {
        let encoded = osub.encodedSubsegment
        switch orient {
        case 0:
            triangle.s1 = encoded
        case 1:
            triangle.s2 = encoded
        default:
            triangle.s3 = encoded
        }
        switch osub.orient {
        case 0:
            osub.subsegment.t1 = encodedTriangle
        default:
            osub.subsegment.t2 = encodedTriangle

        }
    }

    func symself() {
        let ptr: Triangle.EncodedTriangle
        switch orient {
        case 0:
            ptr = triangle.t1
        case 1:
            ptr = triangle.t2
        default:
            ptr = triangle.t3
        }
        triangle = ptr.triangle
        orient = ptr.orientation
    }
    /* sym() finds the abutting triangle, on the same edge.  Note that the edge  */
    /*   direction is necessarily reversed, because the handle specified by an   */
    /*   oriented triangle is directed counterclockwise around the triangle.     */

    func sym(to otri2: OrientedTriangle) {
        let ptr: Triangle.EncodedTriangle
        switch orient {
        case 0:
            ptr = triangle.t1
        case 1:
            ptr = triangle.t2
        default:
            ptr = triangle.t3
        }
        otri2.decode(triangle: ptr)
    }

    func sym() -> OrientedTriangle {
        let ptr: Triangle.EncodedTriangle
        switch orient {
        case 0:
            ptr = triangle.t1
        case 1:
            ptr = triangle.t2
        default:
            ptr = triangle.t3
        }
        return OrientedTriangle(triangle: ptr.triangle, orient: ptr.orientation)
    }

    func decode(triangle: Triangle.EncodedTriangle) {
        self.triangle = triangle.triangle
        orient = triangle.orientation
    }

    func disolve(m: Mesh) {
        switch orient {
        case 0:
            triangle.t1 = Triangle.EncodedTriangle(triangle: m.dummytri, orientation: 0)
        case 1:
            triangle.t2 = Triangle.EncodedTriangle(triangle: m.dummytri, orientation: 0)
        default:
            triangle.t3 = Triangle.EncodedTriangle(triangle: m.dummytri, orientation: 0)
        }
    }

    func tsdissolve(m: Mesh) {
        let encoded = Triangle.EncodedSubsegment(ss: m.dummysub, orientation: 0)
        switch orient {
        case 0:
            triangle.s1 = encoded
        case 1:
            triangle.s2 = encoded
        default:
            triangle.s3 = encoded

        }

    }

}
