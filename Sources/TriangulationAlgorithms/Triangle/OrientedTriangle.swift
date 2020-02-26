//
//  OrientedTriangle.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

struct OrientedTriangle {
    var triangle: Triangle
    var orientation: Int

    var id: Int {
        return triangle.id
    }

    init(triangle: Triangle, orientation: Int) {
        self.triangle = triangle
        self.orientation = orientation
    }

    private func vertex(at: Int) -> Int {
        switch at {
        case 0:
            return triangle.v1
        case 1:
            return triangle.v2
        default:
            return triangle.v3
        }

    }

    mutating func set(vertex: Int, at: Int) {
        switch at {
        case 0:
            triangle.v1 = vertex
        case 1:
            triangle.v2 = vertex
        default:
            triangle.v3 = vertex
        }
    }

    var org: Int {
        get { vertex(at: plus1mod3[orientation])}
        set { set(vertex: newValue, at: plus1mod3[orientation]) }
    }

    var dest: Int {
        get { vertex(at: minus1mod3[orientation]) }
        set { set(vertex: newValue, at: minus1mod3[orientation])}
    }

    var apex: Int {
        get { vertex(at: orientation) }
        set { set(vertex: newValue, at: orientation) }
    }

    func copy(to otri2: inout OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orientation = orientation
    }

    func copy() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orientation: orientation)
    }

    func otriEquals(other otri2: OrientedTriangle) -> Bool {
        return triangle === otri2.triangle && orientation == otri2.orientation
    }

    func bond(to otri2: OrientedTriangle) {
        switch orientation {
        case 0:
            triangle.t1 = otri2
        case 1:
            triangle.t2 = otri2
        default:
            triangle.t3 = otri2
        }

        switch otri2.orientation {
        case 0:
            otri2.triangle.t1 = self
        case 1:
            otri2.triangle.t2 = self
        default:
            otri2.triangle.t3 = self
        }
    }

    mutating func lprevself() {
        orientation = minus1mod3[orientation]
    }

    mutating func lnextself() {
        orientation = plus1mod3[orientation]
    }

    func lprev(on otri2: inout OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orientation = minus1mod3[orientation]
    }

    func lprev() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orientation: minus1mod3[orientation])
    }

    func lnext(on otri2: inout OrientedTriangle) {
        otri2.triangle = triangle
        otri2.orientation = plus1mod3[orientation]
    }
    func lnext() -> OrientedTriangle {
        return OrientedTriangle(triangle: triangle, orientation: plus1mod3[orientation])
    }

    func onext() -> OrientedTriangle {
        var prev = lprev()
        prev.symself()
        return prev
    }
    mutating func onextself() {
        lprevself()
        symself()
    }

    func tspivot() -> OrientedSubsegment {
        let sptr: EncodedSubsegment
        switch orientation {
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
        var otri2 = sym()
        otri2.lnextself()
        return otri2
    }

    func oprev(to otri2: inout OrientedTriangle) {
        sym(to: &otri2)
        otri2.lnextself()
    }

    mutating func oprevself() {
        symself()
        lnextself()
    }

    mutating func dnextself() {
        symself()
        lprevself()
    }

    func tsbond(to osub: OrientedSubsegment) {

        switch orientation {
        case 0:
            triangle.s1 = osub.encodedSubsegment
        case 1:
            triangle.s2 = osub.encodedSubsegment
        default:
            triangle.s3 = osub.encodedSubsegment
        }
        switch osub.orient {
        case 0:
            osub.subsegment.t1 = self
        default:
            osub.subsegment.t2 = self

        }
    }

    mutating func symself() {
        let ptr: OrientedTriangle
        switch orientation {
        case 0:
            ptr = triangle.t1
        case 1:
            ptr = triangle.t2
        default:
            ptr = triangle.t3
        }
        triangle = ptr.triangle
        orientation = ptr.orientation
    }
    /* sym() finds the abutting triangle, on the same edge.  Note that the edge  */
    /*   direction is necessarily reversed, because the handle specified by an   */
    /*   oriented triangle is directed counterclockwise around the triangle.     */

    func sym(to otri2: inout OrientedTriangle) {
        let ptr: OrientedTriangle
        switch orientation {
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
        switch orientation {
        case 0:
            return triangle.t1
        case 1:
            return triangle.t2
        default:
            return triangle.t3
        }

    }

    mutating func decode(triangle: OrientedTriangle) {
        self.triangle = triangle.triangle
        orientation = triangle.orientation
    }

    func disolve(m: Mesh) {
        switch orientation {
        case 0:
            triangle.t1 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        case 1:
            triangle.t2 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        default:
            triangle.t3 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        }
    }

    func tsdissolve(m: Mesh) {
        let encoded = EncodedSubsegment(ss: m.dummysub, orientation: 0)
        switch orientation {
        case 0:
            triangle.s1 = encoded
        case 1:
            triangle.s2 = encoded
        default:
            triangle.s3 = encoded

        }

    }

}
