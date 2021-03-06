//
//  Vertex.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Vertex: Vector2 {
    enum State {
        case input
        case segment
        case free
        case dead
        case undead
    }

    let x: REAL, y: REAL, z: REAL

    var mark = 0

    var state: Vertex.State = .input

    var triangle: OrientedTriangle?
    let id: Int

    init(id: Int, x: REAL, y: REAL, z: REAL) {
        self.id = id
        self.x = x
        self.y = y
        self.z = z
    }

    func realAt(axis: Int) -> REAL {
        switch axis {
        case 0:
            return x
        case 1:
            return y
        default:
            return z

        }
    }
}
