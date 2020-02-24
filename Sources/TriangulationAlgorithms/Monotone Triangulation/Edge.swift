//
//  Edge.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

struct Edge {

    var next: Int = -1
    var prev: Int = -1
    let id: Int
    let pair: Int
    let start: Int
    let radAngle: Double

    init(id: Int, pairId: Int, origin: Int, angle: Double) {
        pair = pairId
        self.id = id
        start = origin
        radAngle = angle
    }

    func intersectsLine(at lineY: Double, polygon: Polygon) -> Bool {
        let start = polygon.vertices[self.start]
        let end = polygon.vertices[polygon.edges[pair].start]
        return (start.y >= lineY && end.y <= lineY) || (start.y <= lineY && end.y >= lineY);
    }

    func leftIntersectionOfLine(at lineY: Double, polygon: Polygon) -> Double {

        let start = polygon.vertices[self.start]
        let end = polygon.vertices[polygon.edges[pair].start]
        if start.y == lineY {
            if end.y == lineY && end.x < start.x {
                return end.x;
            } else {
                return start.x;
            }
        }
        if end.y == lineY {
            return end.x;
        }

        let val = start.x + (((end.x - start.x) / (end.y - start.y) * (lineY - start.y)));

        return val;
    }
}

extension Edge: Equatable {
    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Edge: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}
