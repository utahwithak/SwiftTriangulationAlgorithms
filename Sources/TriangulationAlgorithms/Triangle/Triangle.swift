//
//  Triangle.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Triangle {

    let id: Int

    var t1: OrientedTriangle!, t2: OrientedTriangle!, t3: OrientedTriangle!
    var v1: Vertex?, v2: Vertex?, v3: Vertex?

    var s1: OrientedSubsegment!, s2: OrientedSubsegment!, s3: OrientedSubsegment!

    var infected = false

    init(id: Int) {
        self.id = id
    }
    init(id: Int, adjoining: OrientedTriangle, subsegment: OrientedSubsegment?) {
        self.id = id
        t1 = adjoining
        t2 = adjoining
        t3 = adjoining
        s1 = subsegment
        s2 = subsegment
        s3 = subsegment

    }

    var attributes = [REAL]()
    var area: REAL = 0

    var isDead: Bool {
        return t2 == nil
    }

    func killTriangle() {
        t1 = nil
        t2 = nil
        t3 = nil
        v1 = nil
        v2 = nil
        v3 = nil
        s1 = nil
        s2 = nil
        s3 = nil

    }

}
