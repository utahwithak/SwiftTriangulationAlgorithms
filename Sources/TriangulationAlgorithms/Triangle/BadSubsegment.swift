//
//  BadSubsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class BadSubsegment {
    init(seg: OrientedSubsegment, org: Vertex, dest: Vertex) {
        enclosedSubsegment = seg
        subsegOrg = org
        subsegDest = dest
    }

    var enclosedSubsegment: OrientedSubsegment
    var subsegOrg: Vertex, subsegDest: Vertex
}
