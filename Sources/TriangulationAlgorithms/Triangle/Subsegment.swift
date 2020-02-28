//
//  Subsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Subsegment {
    var adj1: OrientedSubsegment?, adj2: OrientedSubsegment?
    var v1: Vertex?, v2: Vertex?, v3: Vertex?, v4: Vertex?
    var t1: OrientedTriangle?, t2: OrientedTriangle?
    var marker: Int = 0
    var segnum: Int = 0

    func kill() {
        adj1 = nil
        adj2 = nil
        v1 = nil
        v2 = nil
        v3 = nil
        v4 = nil
        t1 = nil
        t2 = nil
    }
}
