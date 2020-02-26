//
//  Polygon.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

enum Orientation {
    case Clockwise
    case CounterClockwise
}

struct Polygon {

    var edges = [Edge]()
    public private(set) var vertices: [MonotonePolygonAlgorithm.Vertex]
    var startEdge = 0

    init(points: [Vector2]) {
        // Determine which side should have the initial pointer.
        //
        self.vertices = points.enumerated().map({MonotonePolygonAlgorithm.Vertex(point: $0.1, id: $0.0)})

        var start = vertices[0].id
        for i in 1..<points.count {
            let end = vertices[i]
            let (e1, e2) = createEdges(v1: vertices[start], v2: vertices[end.id])
            vertices[i].outEdge = e2

            if vertices[start].outEdge >= 0 {

                edges[e2].next = vertices[start].outEdge
                edges[edges[e2].next].prev = e2
                edges[e1].prev = edges[vertices[start].outEdge].pair
                edges[edges[e1].prev].next = e1
            }
            vertices[start].outEdge = e1
            start = end.id
        }

        let (bridge, bridgePair) = createEdges(v1: vertices[0], v2: vertices[start])

        // Hook up nexts
        //
        edges[bridgePair].next = vertices[0].outEdge
        edges[vertices[0].outEdge].prev = bridgePair

        edges[vertices[start].outEdge].prev = bridge
        edges[bridge].next = vertices[start].outEdge

        // hook up prevs
        //
        edges[bridge].prev = edges[vertices[0].outEdge].pair
        edges[edges[vertices[0].outEdge].pair].next = bridge

        edges[bridgePair].prev = edges[vertices[start].outEdge].pair
        edges[edges[vertices[start].outEdge].pair].next = bridgePair
        vertices[start].outEdge = bridgePair

        if Polygon.orientationOf(points: points) == .CounterClockwise {
            self.startEdge = bridgePair
        } else {
            self.startEdge = bridge
        }

        flipOutEdges()

    }

    public static func orientationOf(points: [Vector2]) -> Orientation {
        let n = points.count
        var A: CGFloat = 0.0
        for q in 0..<n {
            let p = q == 0 ? n - 1 : q - 1
            let P = points[p]
            let Q = points[q]
            A += P.x * Q.y - Q.x * P.y
        }
        return A > 0 ? .CounterClockwise : .Clockwise
    }

    mutating func flipOutEdges() {
        var runner = edges[startEdge]
        repeat {
            vertices[runner.start].outEdge = runner.id
            runner = edges[runner.next]
        } while runner != edges[startEdge]
    }

    var startEdges: [Int] {
        var toVisit = [startEdge]
        var visted = Set<Int>()
        var startPoints = [Int]()

        while let start = toVisit.first {
            startPoints.append(start)

            var runner = start
            repeat {

                visted.insert(runner)
                toVisit.removeAll(where: { $0 == runner})
                if edges[runner].pair >= 0 && !visted.contains(edges[runner].pair) {
                    toVisit.append(edges[runner].pair)
                }
                runner = edges[runner].next
            } while runner != start

        }
        //remove the loop along the outside.
        //will always be the second one since it will be added from the start edge.
        startPoints.remove(at: 1)
        return startPoints
    }

    var triangles: [Int] {
        var triangles = [Int]()
        for e in startEdges {
            var runner = e
            repeat {
                triangles.append(edges[runner].start)
                runner = edges[runner].prev
            } while runner != e

            if triangles.count % 3 != 0 {
                print("invalid triangulation!!")
            }
        }
        return triangles
    }

    mutating func addDiagonalFrom(start v1: MonotonePolygonAlgorithm.Vertex, toVertex v2: MonotonePolygonAlgorithm.Vertex) {
        let (e1, e2) = createEdges(v1: v1, v2: v2)
        v1.connectNew(edge: edges[e1], polygon: &self)
        v2.connectNew(edge: edges[e2], polygon: &self)
    }

    mutating func createEdges(v1: MonotonePolygonAlgorithm.Vertex, v2: MonotonePolygonAlgorithm.Vertex) -> (Int, Int) {
        let dy = v2.y - v1.y
        let dx = v2.x - v1.x

        var e1Angle = atan2(dy, dx)
        if e1Angle < 0 {
             e1Angle += .pi * 2
        }

        var e2Angle = e1Angle - .pi
        if e2Angle < 0 {
            e2Angle += .pi * 2
        }

        let eId = edges.count
        let e1 = Edge(id: eId, pairId: eId + 1, origin: v1.id, angle: e1Angle)
        let e2 = Edge(id: eId + 1, pairId: eId, origin: v2.id, angle: e2Angle)
        edges.append(e1)
        edges.append(e2)
        return (eId, eId + 1)
    }

    var subPolygons: [SubPolygon] {
        return startEdges.map({ return SubPolygon(startEdge: edges[$0]) })
    }

}

struct SubPolygon {
    let startEdge: Edge

    func edgeStarting(at start: MonotonePolygonAlgorithm.Vertex, polygon: Polygon) -> Edge? {
        var runner = startEdge
        repeat {
            if runner.start == start.id {
                return runner
            } else {
                runner = polygon.edges[runner.next]
            }
        } while runner != startEdge
        return nil
    }
}
