//
//  Vertex.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

extension MonotonePolygonAlgorithm {
    enum EventType {
        case start
        case end
        case split
        case merge
        case regular
    }

    struct Vertex {

        let x: Double
        let y: Double

        let id: Int

        var outEdge: Int = -1

        var isMergeVertex = false
        
        init(point: Vector2, id: Int) {
            self.x = Double(point.x)
            self.y = Double(point.y)
            self.id = id
        }

        private func turnAngle(a: Vertex, center b: Vertex, end c: Vertex) -> Double {
            let d1x = b.x - a.x;
            let d1y = b.y - a.y;

            let d2x = c.x - b.x;
            let d2y = c.y - b.y;

            var d2Ang = atan2(d2y,d2x);
            while d2Ang < 0  {
                d2Ang += .pi * 2
            }

            var d1Ang = atan2(d1y,d1x);
            while d1Ang < 0 {
                d1Ang += .pi * 2
            }

            let angle = d2Ang - d1Ang;
            if angle < 0 {
                return  angle + (.pi * 2)
            } else {
                return angle;
            }
        }

        mutating func generateEvent(polygon: Polygon) -> EventType {
            let prev = polygon.vertices[polygon.edges[polygon.edges[polygon.edges[polygon.edges[outEdge].pair].next].pair].start]
            let next = polygon.vertices[polygon.edges[polygon.edges[outEdge].pair].start]

            let interiorAngle  = self.turnAngle(a:prev, center:self, end:next)
            if prev > self && next > self {
                if interiorAngle < .pi {
                    return .start;
                }
                else if interiorAngle > .pi {
                    return .split;
                }

            } else if self > next && self > prev {
                if interiorAngle < .pi {
                    return .end;
                }
                else if interiorAngle > .pi {
                    isMergeVertex = true
                    return .merge;
                }

            }
            return .regular;
        }

        func connectNew(edge: Edge, polygon: inout Polygon) {
            guard outEdge >= 0 else {
                fatalError("Invalid State!")
            }
            var runner = polygon.edges[outEdge]
            

            while runner.radAngle > edge.radAngle {
                runner = polygon.edges[polygon.edges[runner.pair].next]
                if runner.radAngle < polygon.edges[polygon.edges[runner.pair].next].radAngle || runner.id == polygon.edges[runner.pair].next {
                    break;
                }
            }

            while (runner.radAngle < edge.radAngle) {
                runner = polygon.edges[polygon.edges[runner.prev].pair]
                if((runner.radAngle < edge.radAngle && polygon.edges[polygon.edges[runner.prev].pair].radAngle < runner.radAngle) || runner.id == polygon.edges[runner.prev].pair){
                    runner = polygon.edges[polygon.edges[runner.prev].pair]
                    break//we just went all the way around!
                }
            }
            //we found the insert location!
            polygon.edges[polygon.edges[runner.pair].next].prev = edge.pair
            polygon.edges[edge.pair].next = polygon.edges[runner.pair].next

            polygon.edges[runner.pair].next = edge.id
            polygon.edges[runner.pair].next = edge.id

            polygon.edges[edge.id].prev = runner.pair;

        }

    }
}

extension MonotonePolygonAlgorithm.Vertex: Hashable {
    func hash(into hasher: inout Hasher) {
        x.hash(into: &hasher)
        y.hash(into: &hasher)
    }
}

extension MonotonePolygonAlgorithm.Vertex: Comparable {

    public static func ==(lhs: MonotonePolygonAlgorithm.Vertex, rhs: MonotonePolygonAlgorithm.Vertex) -> Bool {
        let yDif = lhs.y - rhs.y
        let xDif = lhs.x - rhs.x
        return (yDif > -1e-6 && yDif < 1e-6) && ( xDif > -1e-6 && xDif < 1e-6)
    }

    public static func <(lhs: MonotonePolygonAlgorithm.Vertex, rhs: MonotonePolygonAlgorithm.Vertex) -> Bool {
        let yDif = lhs.y - rhs.y
        let xDif = lhs.x - rhs.x

        if (yDif > -1e-6 && yDif < 1e-6) {
            if xDif > -1e-6 && xDif < 1e-6 {
                return false
            }
            return lhs.x < rhs.x
        }
        return lhs.y > rhs.y

    }
}
