//
//  Subsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Subsegment {
    var adj1: EncodedSubsegment?, adj2: EncodedSubsegment?
    var v1 = -1, v2 = -1, v3 = -1, v4 = -1
    var t1: OrientedTriangle?, t2: OrientedTriangle?
    var marker: Int = 0

    func kill() {
        adj1 = nil
        adj2 = nil
        v1 = -1
        v2 = -1
        v3 = -1
        v4 = -1
        t1 = nil
        t2 = nil
    }
}
