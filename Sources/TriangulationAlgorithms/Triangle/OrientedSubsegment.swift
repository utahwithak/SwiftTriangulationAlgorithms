//
//  OrientedSubsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class OrientedSubsegment {

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

    func ssymself() {
        orient = 1 - orient
    }

    func snextself() {
        let sptr = orient == 0 ? subsegment.adj2 : subsegment.adj1
        subsegment = sptr!.subsegment
        orient = sptr!.orient
    }

    func spivot() -> OrientedSubsegment {
        let sptr: OrientedSubsegment
        switch orient {
        case 0:
            sptr = subsegment.adj1!
        default:
            sptr = subsegment.adj2!
        }
        return sptr
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
            subsegment.adj1 = OrientedSubsegment(subseg: m.dummysub, orient: 0)
        } else {
            subsegment.adj2 = OrientedSubsegment(subseg: m.dummysub, orient: 0)
        }
    }

    func sbond(to osub2: OrientedSubsegment) {
        if orient == 0 {
            subsegment.adj1 = osub2
        } else {
            subsegment.adj2 = osub2
        }

        if osub2.orient == 0 {
            osub2.subsegment.adj1 = self
        } else {
            osub2.subsegment.adj2 = self
        }
    }

    /* Dissolve a bond (from the subsegment side).                               */

    func stdissolve(m: Mesh) {
        if orient == 0 {
            subsegment.t1 = OrientedTriangle(triangle: m.dummytri, orient: 0)
        } else {
            subsegment.t2 = OrientedTriangle(triangle: m.dummytri, orient: 0)
        }
    }

    /* These primitives determine or set the origin or destination of a          */
    /*   subsegment or the segment that includes it.                             */
    var sorg: Vertex? {
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

    var sdest: Vertex? {
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

    var segorg: Vertex? {
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

    var segdest: Vertex? {
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
