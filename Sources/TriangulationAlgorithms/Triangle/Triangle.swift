//
//  Triangle.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

struct EncodedSubsegment {
    let ss: Subsegment
    let orientation: Int
}

class Triangle {
    let id: Int
    var t1: OrientedTriangle!, t2: OrientedTriangle!, t3: OrientedTriangle!
    var v1 = -1, v2 = -1, v3 = -1

    var s1: EncodedSubsegment!, s2: EncodedSubsegment!, s3: EncodedSubsegment!

    var infected = false

    init(id: Int) {
        self.id = id
    }

    init(id: Int, adjoining: Triangle, subsegment: Subsegment?) {
        self.id = id
        t1 = OrientedTriangle(triangle: adjoining, orientation: 0)
        t2 = OrientedTriangle(triangle: adjoining, orientation: 0)
        t3 = OrientedTriangle(triangle: adjoining, orientation: 0)
        if let subsegment = subsegment {
            s1 = EncodedSubsegment(ss: subsegment, orientation: 0)
            s2 = EncodedSubsegment(ss: subsegment, orientation: 0)
            s3 = EncodedSubsegment(ss: subsegment, orientation: 0)
        }

    }

    var isDead: Bool {
        return t2 == nil
    }

    func killTriangle() {
        t1 = nil
        t2 = nil
        v1 = -1
        v2 = -1
        v3 = -1
        s1 = nil
        s2 = nil
        s3 = nil
    }

}
