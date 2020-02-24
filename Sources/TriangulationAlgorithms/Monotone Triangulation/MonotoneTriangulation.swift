//
//  MonotoneTriangulation.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

public struct MonotonePolygonAlgorithm {

   public static func triangulate(points: [Vector2]) throws -> [Int] {

        var partitioner = PolygonPartitioner(polygon: Polygon(points: points))

        let subPolygons = try partitioner.sweep()
        var polygon = partitioner.polygon

        var leftChain = [MonotonePolygonAlgorithm.Vertex]()
        var rightChain = [MonotonePolygonAlgorithm.Vertex]()
        var stack = [MonotonePolygonAlgorithm.Vertex]()
        var sequence = [MonotonePolygonAlgorithm.Vertex]()

        for p in subPolygons {

            var lowest = p.startEdge
            var highest = p.startEdge

            sequenceStarting(at: p.startEdge, in: polygon, sequence: &sequence, highest: &highest, lowest: &lowest)

            var runner = highest
            repeat {
                runner = polygon.edges[runner.prev]
                rightChain.append(polygon.vertices[runner.start])
            } while runner != lowest;

            runner = highest

            repeat {
                leftChain.append(polygon.vertices[runner.start])
                runner = polygon.edges[runner.next]
            } while runner != lowest

            stack.append(sequence[0])
            stack.append(sequence[1])
            for i in 2..<(sequence.count - 1) {
                let u = sequence[i]

                if (leftChain.contains(u) && !leftChain.contains(stack.last!)) || (rightChain.contains(u) && !rightChain.contains(stack.last!)){
                    while !stack.isEmpty {
                        let cur = stack.removeLast()

                        //insert into D a diagonal from U to each popped vertex, except the last one
                        if !stack.isEmpty {
                            polygon.addDiagonalFrom(start:u, toVertex:cur)
                        }
                    }

                    //push u-1 and u onto stack
                    stack.append(sequence[i-1])
                    stack.append(u)

                } else {
                    //Pop One vertext from S
                    var popped = stack.removeLast()


                    //pop the other vertices from S as long as the diagonals from u to them are inside P
                    while !stack.isEmpty && sideOfPoints(a: stack.last!, center:popped, andEnd:u) == (leftChain.contains(u) ? 1 : -1)  {

                        popped = stack.removeLast()

                        polygon.addDiagonalFrom(start:u, toVertex:popped)
                    }
                    //push last popped back onto stack, as it is now (or always was) connected to
                    stack.append(popped)
                    stack.append(u)

                }

            }

            if !stack.isEmpty {
                _ = stack.removeLast()
                while !stack.isEmpty {
                    let cur = stack.removeLast()
                    //insert into D a diagonal from U to each poped vertex, except the last one
                    if !stack.isEmpty {
                        polygon.addDiagonalFrom(start: sequence.last!, toVertex: cur)
                    }
                }
            }


            stack.removeAll(keepingCapacity: true)
            rightChain.removeAll(keepingCapacity: true)
            leftChain.removeAll(keepingCapacity: true)
            sequence.removeAll(keepingCapacity: true)
        }

        return polygon.triangles
    }


    private static func sideOfPoints(a:Vertex, center b:Vertex, andEnd c:Vertex) -> Int {
        let v1x = b.x-a.x;
        let v1y = b.y-a.y;

        let v2x = c.x-b.x;
        let v2y = c.y-b.y;

        return (v1x * v2y) - (v1y * v2x) < 0 ? -1 : 1
    }

    static func sequenceStarting(at startEdge: Edge, in polygon: Polygon, sequence: inout [MonotonePolygonAlgorithm.Vertex], highest: inout Edge, lowest: inout Edge) {

        var runner = startEdge
        repeat {
            if polygon.vertices[runner.start] > polygon.vertices[lowest.start] {
                lowest = runner
            } else if polygon.vertices[runner.start] < polygon.vertices[highest.start] {
                highest = runner
            }
            sequence.append(polygon.vertices[runner.start])
            runner = polygon.edges[runner.next];
        } while(runner != startEdge);
        sequence.sort()

    }
}

enum TriangulationError: Error {
case InvalidPolygon
}
