//
//  EarClippingAlgorithm.swift
//  TriExploration
//
//  Created by Carl Wieland on 10/11/16.
//  Copyright © 2016 Datum Apps. All rights reserved.
//

import Foundation

public struct EarClippingAlgorithm {
    let points: [Vector2]

    public init(points: [Vector2]) {
        self.points = points
    }

    public mutating func triangulate() -> [Int] {
        var indexes = [Int]()
        indexes.reserveCapacity(points.count * 3)


        let n = points.count
        if n < 3 {
            return indexes
        }

        var V = [Int](repeating: 0, count: n)
        if area > 0 {
            for v in 0..<n {
                V[v] = v
            }
        } else {
            for v in 0..<n {
                V[v] = (n - 1) - v
            }
        }
        var remainingPoints = n
        var count = 2 * remainingPoints
        var m = 0
        var v = remainingPoints - 1
        while remainingPoints > 2 {
            count -= 1
            if count <= 0 {
                return indexes
            }

            let u = remainingPoints <= v ? 0 : v;

            v = u + 1;

            if remainingPoints <= v {
                v = 0;
            }

            let w = remainingPoints <= v + 1 ? 0 : v + 1;


            if snip(u: u, v: v, w: w, n: remainingPoints, V: V) {

                let a = V[u];
                let b = V[v];
                let c = V[w];
                indexes.append(a);
                indexes.append(b);
                indexes.append(c);
                m += 1
                for t in (v + 1)..<remainingPoints {
                    V[t - 1] = V[t];
                }
                remainingPoints -= 1
                count = 2 * remainingPoints
            }
        }

        return indexes
    }

    private var area: CGFloat {
        let n = points.count;
        var A: CGFloat = 0.0
        for q in 0..<n {
            let p = q == 0 ? n - 1 : q - 1
            let pval = points[p];
            let qval = points[q];
            A += pval.x * qval.y - qval.x * pval.y;
        }
        return A * 0.5;
    }

    private func snip(u: Int, v: Int,w: Int, n: Int, V: [Int]) -> Bool {

        let A = points[V[u]]
        let B = points[V[v]]
        let C = points[V[w]]
        let first = (B.x - A.x) * (C.y - A.y)
        let second = (B.y - A.y) * (C.x - A.x)

        if CGFloat.ulpOfOne > (first - second) {
            return false
        }

        for p in 0..<n {
            if (p == u) || (p == v) || (p == w) {
                continue;
            }
            let P = points[V[p]];
            if insideTriangle(A: A, B: B, C: C, P: P) {
                return false;
            }
        }
            return true;

    }

    private func insideTriangle(A: Vector2 ,B: Vector2, C:Vector2, P: Vector2) -> Bool {

        let ax = C.x - B.x, ay = C.y - B.y
        let bx = A.x - C.x, by = A.y - C.y
        let cx = B.x - A.x, cy = B.y - A.y
        let apx = P.x - A.x, apy = P.y - A.y
        let bpx = P.x - B.x, bpy = P.y - B.y
        let cpx = P.x - C.x, cpy = P.y - C.y

        let aCROSSbp = ax * bpy - ay * bpx
        let cCROSSap = cx * apy - cy * apx
        let bCROSScp = bx * cpy - by * cpx

        return ((aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0))
    }
}
