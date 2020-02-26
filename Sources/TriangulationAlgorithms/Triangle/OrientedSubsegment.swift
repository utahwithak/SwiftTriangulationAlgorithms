//
//  OrientedSubsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

struct OrientedSubsegment {

    init(subseg: Subsegment, orient: Int) {
        self.subsegment = subseg
        self.orient = orient
    }

    var subsegment: Subsegment
    var orient: Int

    var mark: Int {
        get { return subsegment.marker }
        set { subsegment.marker = newValue }
    }

    var encodedSubsegment: EncodedSubsegment {
        return EncodedSubsegment(ss: subsegment, orientation: orient)
    }

    mutating func ssymself() {
        orient = 1 - orient
    }

    mutating func snextself() {
        let sptr = orient == 0 ? subsegment.adj2 : subsegment.adj1
        subsegment = sptr!.ss
        orient = sptr!.orientation
    }

    func spivot() -> OrientedSubsegment {
        let sptr: EncodedSubsegment
        switch orient {
        case 0:
            sptr = subsegment.adj1!
        default:
            sptr = subsegment.adj2!
        }
        return OrientedSubsegment(subseg: sptr.ss, orient: sptr.orientation)
    }

    func stpivot() -> OrientedTriangle {
        let ptr = orient == 0 ? subsegment.t1 : subsegment.t2
        return ptr!
    }

    func ssym() -> OrientedSubsegment {
        return OrientedSubsegment( subseg: subsegment, orient: 1 - orient)
    }

    func sdissolve(m: Mesh) {
        if orient == 0 {
            subsegment.adj1 = EncodedSubsegment(ss: m.dummysub, orientation: 0)
        } else {
            subsegment.adj2 = EncodedSubsegment(ss: m.dummysub, orientation: 0)
        }
    }

    func sbond(to osub2: inout OrientedSubsegment) {
        if orient == 0 {
            subsegment.adj1 = osub2.encodedSubsegment
        } else {
            subsegment.adj2 = osub2.encodedSubsegment
        }

        if osub2.orient == 0 {
            osub2.subsegment.adj1 = encodedSubsegment
        } else {
            osub2.subsegment.adj2 = encodedSubsegment
        }
    }

    /* Dissolve a bond (from the subsegment side).                               */

    func stdissolve(m: Mesh) {
        if orient == 0 {
            subsegment.t1 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        } else {
            subsegment.t2 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        }
    }

    /* These primitives determine or set the origin or destination of a          */
    /*   subsegment or the segment that includes it.                             */
    var sorg: Int {
        get {
            if orient == 0 {
                return subsegment.v1
            } else {
                return subsegment.v2
            }
        }
        set {
            if orient == 0 {
                subsegment.v1 = newValue
            } else {
                subsegment.v2 = newValue
            }
        }

    }

    var sdest: Int {
        get {
            if orient == 0 {
                return subsegment.v2
            } else {
                return subsegment.v1
            }
        }
        set {
            if orient == 0 {
                subsegment.v2 = newValue
            } else {
                subsegment.v1 = newValue
            }
        }
    }

    var segorg: Int {
        get {
            if orient == 0 {
                return subsegment.v3
            } else {
                return subsegment.v4
            }
        }
        set {
            if orient == 0 {
                subsegment.v3 = newValue
            } else {
                subsegment.v4 = newValue
            }
        }
    }

    var segdest: Int {
        get {
            if orient == 0 {
                return subsegment.v4
            } else {
                return subsegment.v3
            }
        }
        set {
            if orient == 0 {
                subsegment.v4 = newValue
            } else {
                subsegment.v3 = newValue
            }
        }
    }
}
