//
//  BadSubsegment.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

struct BadSubsegment {
    init(seg: EncodedSubsegment, org: Int, dest: Int) {
        enclosedSubsegment = seg
        subsegOrg = org
        subsegDest = dest
    }

    var enclosedSubsegment: EncodedSubsegment
    var subsegOrg: Int, subsegDest: Int
}
