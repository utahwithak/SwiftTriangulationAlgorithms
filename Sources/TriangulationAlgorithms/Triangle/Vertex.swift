//
//  Vertex.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

struct Vertex: Equatable {
    enum State {
        case input
        case segment
        case free
        case dead
        case undead
    }

    let id: Int

    let x: REAL, y: REAL

    var mark = 0

    var state = Vertex.State.input

    struct TriIndex {
        let id: Int
        let orientation: Int
    }

    var triangle: TriIndex?

    init(id: Int, x: REAL, y: REAL) {
        self.id = id
        self.x = x
        self.y = y
    }

    var vert: Vector2 {
        CGPoint(x: x, y: y)
    }

    static func == (lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.id == rhs.id
    }
}
