//
//  TriangulateIO.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation
//struct Vector2 {
//    let x: REAL
//    let y: REAL
//};

public struct TriangulateIO {
    public init() {}
    public var pointlist = [Vector2]()
    private var pointattributelist = [REAL]()
    public var pointmarkerlist = [Int]()
    var numberOfPointAttributes = 0

    public var trianglelist = [Int]()                                             /* In / out */
//  REAL *triangleattributelist;                                   /* In / out */
//  REAL *trianglearealist;                                         /* In only */
//  int *neighborlist;                                             /* Out only */
//  int numberoftriangles;                                         /* In / out */
//  int numberofcorners;                                           /* In / out */
//  int numberoftriangleattributes;                                /* In / out */

    public var segmentlist = [Int]()                                              /* In / out */
    public var segmentmarkerlist = [Int]()                                        /* In / out */

//
    var holelist = [Vector2]()                        /* In / pointer to array copied out */
//  int numberofholes;                                      /* In / copied out */
//
    var regionlist = [REAL]()                      /* In / pointer to array copied out */
//  int numberofregions;                                    /* In / copied out */
//
//  int *edgelist;                                                 /* Out only */
//  int *edgemarkerlist;            /* Not used with Voronoi diagram; out only */
//  REAL *normlist;                /* Used only with Voronoi diagram; out only */
//  int numberofedges;                                             /* Out only */

    struct TriangleIndexes {
        let v1: Int, v2: Int, v3: Int
    }

    var triangles: [TriangleIndexes] {
        return stride(from: 0, to: trianglelist.count, by: 3).map { TriangleIndexes(v1: trianglelist[$0], v2: trianglelist[$0 + 1], v3: trianglelist[$0 + 2])}
    }
}
