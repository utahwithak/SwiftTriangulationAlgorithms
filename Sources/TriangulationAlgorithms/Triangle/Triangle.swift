//
//  Triangle.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Triangle {
    struct EncodedTriangle {
        let triangle: Triangle
        let orientation: Int
    }

    struct EncodedSubsegment {
        let ss: Subsegment
        let orientation: Int
    }

    var t1: EncodedTriangle!, t2: EncodedTriangle!, t3: EncodedTriangle!
    var v1: Vertex?, v2: Vertex?, v3: Vertex?

    var s1: EncodedSubsegment!, s2: EncodedSubsegment!, s3: EncodedSubsegment!

    var infected = false

    init() {
    }
    init(adjoining: Triangle, subsegment: Subsegment?) {
        t1 = EncodedTriangle(triangle: adjoining, orientation: 0)
        t2 = EncodedTriangle(triangle: adjoining, orientation: 0)
        t3 = EncodedTriangle(triangle: adjoining, orientation: 0)
        if let subsegment = subsegment {
            s1 = EncodedSubsegment(ss: subsegment, orientation: 0)
            s2 = EncodedSubsegment(ss: subsegment, orientation: 0)
            s3 = EncodedSubsegment(ss: subsegment, orientation: 0)
        }

    }

    var attributes = [REAL]()
    var area: REAL = 0

    var isDead: Bool {
        return t2 == nil
    }

    func killTriangle() {
        t1 = nil
        t2 = nil
        v1 = nil
        v2 = nil
        v3 = nil
        s1 = nil
        s2 = nil
        s3 = nil

    }

}
