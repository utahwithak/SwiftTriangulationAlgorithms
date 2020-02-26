//
//  Array+AlternateAxes.swift
//  SwiftTriangle
//
//  Created by Carl Wieland on 2/25/20.
//  Copyright © 2020 Datum Apps. All rights reserved.
//

import Foundation

extension Array where Element == Vector2 {
    func alteratedAxes<T: RandomNumberGenerator>(generator: inout T, dwyer: Bool) -> [Vector2] {
        var copy = self
        /* Discard duplicate vertices, which can really mess up the algorithm. */
        var i = 0
        for j in 1..<copy.count {
            if (copy[i].x == copy[j].x) && (copy[i].y == copy[j].y) {
                print("Warning:  A duplicate vertex at (\(copy[j].x), \(copy[j].y)) appeared and was ignored.")
            } else {
                i += 1
                copy[i] = copy[j]
            }
        }
        i += 1
        if count - i != 0 {
            copy.removeLast(count - i)
        }
        if dwyer {
            /* Re-sort the array of vertices to accommodate alternating cuts. */
            let divider = i >> 1
            if i - divider >= 2 {
                if divider >= 2 {
                    copy.alternateAxes(at: 0, arraysize: divider, axis: 1, generator: &generator)
                }
                copy.alternateAxes(at: divider, arraysize: copy.count - divider, axis: 1, generator: &generator)
            }
        }

        return copy
    }

    private mutating func alternateAxes<T: RandomNumberGenerator>(at start: Int, arraysize: Int, axis axisIn: Int, generator: inout T) {
        var divider = 0
        var axis = axisIn
        divider = arraysize >> 1
        if arraysize <= 3 {
            axis = 0
        }
        /* Partition with a horizontal or vertical cut. */
        if axis == 0 {
            vertexMedianX(at: start, arraysize: arraysize, median: divider, generator: &generator)
        } else {
            vertexMedianY(at: start, arraysize: arraysize, median: divider, generator: &generator)
        }

        /* Recursively partition the subsets with a cross cut. */
        if arraysize - divider >= 2 {
            if divider >= 2 {
                alternateAxes(at: start, arraysize: divider, axis: 1 - axis, generator: &generator)
            }
            alternateAxes(at: start + divider, arraysize: arraysize - divider, axis: 1 - axis, generator: &generator)
        }
    }

    private mutating func vertexMedianX<T: RandomNumberGenerator>(at start: Int, arraysize: Int, median: Int, generator: inout T) {

        if count == 2 {
            let startVert = self[start]
            let nextVert = self[start + 1]
            /* Recursive base case. */
            if (startVert.x > nextVert.x) ||
                ((startVert.x == nextVert.x) &&
                    (startVert.y > nextVert.y)) {
                self[start + 1] = startVert
                self[start] = nextVert
            }
            return
        }
        /* Choose a random pivot to split the array. */
        let pivot = Int.random(in: 0..<arraysize, using: &generator)

        let pivot1 = self[start + pivot].x
        let pivot2 = self[start + pivot].y
        /* Split the array. */
        var left = -1
        var right = arraysize
        while left < right {
            /* Search for a vertex whose x-coordinate is too large for the left. */
            repeat {
                left += 1
            } while ((left <= right) && ((self[start + left].x < pivot1) ||
                ((self[start + left].x == pivot1) &&
                    (self[start + left].y < pivot2))))
            /* Search for a vertex whose x-coordinate is too small for the right. */
            repeat {
                right -= 1
            } while ((left <= right) && ((self[start + right].x > pivot1) ||
                ((self[start + right].x == pivot1) &&
                    (self[start + right].y > pivot2))))
            if left < right {
                /* Swap the left and right vertices. */
                self.swapAt(start + left, start + right)
            }
        }
        /* Unlike in vertexsort(), at most one of the following */
        /*   conditionals is true.                             */
        if left > median {
            /* Recursively shuffle the left subset. */
            vertexMedianX(at: start, arraysize: left, median: median, generator: &generator)
        }
        if right < median - 1 {
            /* Recursively shuffle the right subset. */
            vertexMedianX(at: (start + (right + 1)), arraysize: arraysize - right - 1,
                          median: median - right - 1, generator: &generator)
        }
    }

    private mutating func vertexMedianY<T: RandomNumberGenerator>(at start: Int, arraysize: Int, median: Int, generator: inout T) {

        if self.count == 2 {
            let startVert = self[start]
            let nextVert = self[start + 1]
            /* Recursive base case. */
            if (startVert.y > nextVert.y) ||
                ((startVert.y == nextVert.y) &&
                    (startVert.x > nextVert.x)) {
                self[start + 1] = startVert
                self[start] = nextVert
            }
            return
        }
        /* Choose a random pivot to split the array. */
        let pivot = Int.random(in: 0..<arraysize, using: &generator)
        let pivot1 = self[start + pivot].y
        let pivot2 = self[start + pivot].x
        /* Split the array. */
        var left = -1
        var right = arraysize
        while left < right {
            /* Search for a vertex whose x-coordinate is too large for the left. */
            repeat {
                left += 1
            } while ((left <= right) && ((self[start + left].y < pivot1) ||
                ((self[start + left].y == pivot1) &&
                    (self[start + left].x < pivot2))))
            /* Search for a vertex whose x-coordinate is too small for the right. */
            repeat {
                right -= 1
            } while ((left <= right) && ((self[start + right].y > pivot1) ||
                ((self[start + right].y == pivot1) &&
                    (self[start + right].x > pivot2))))
            if left < right {
                /* Swap the left and right vertices. */
                self.swapAt(start + left, start + right)
            }
        }
        /* Unlike in vertexsort(), at most one of the following */
        /*   conditionals is true.                             */
        if left > median {
            /* Recursively shuffle the left subset. */
            vertexMedianY(at: start, arraysize: left, median: median, generator: &generator)
        }
        if right < median - 1 {
            /* Recursively shuffle the right subset. */
            vertexMedianY(at: (start + (right + 1)), arraysize: arraysize - right - 1,
                          median: median - right - 1, generator: &generator)
        }
    }
}
