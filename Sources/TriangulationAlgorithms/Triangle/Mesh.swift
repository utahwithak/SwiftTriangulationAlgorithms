//
//  Mesh.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Mesh {

    var triangles = [Triangle]()
    var subsegs = [Subsegment]()
    var vertices = [Vertex]()
    var viri = [Triangle]()
    var badSubsegs = [BadSubsegment]()

    /* Variable that maintains the stack of recently flipped triangles.          */

    /* Other variables. */

    var xmin: REAL = 0, xmax: REAL = 0, ymin: REAL = 0, ymax: REAL = 0;                            /* x and y bounds. */
    var invertices = 0                               /* Number of input vertices. */
    var inelements = 0                              /* Number of input triangles. */
    var insegments = 0                               /* Number of input segments. */
    var holes = 0                                       /* Number of input holes. */
    var regions = 0                                   /* Number of input regions. */
    var undeads = 0    /* Number of input vertices that don't appear in the mesh. */
    var edges = 0;                                     /* Number of output edges. */
    var mesh_dim = 0;                                /* Dimension (ought to be 2). */
    var nextras = 0;                           /* Number of attributes per vertex. */
    var eextras = 0;                         /* Number of attributes per triangle. */
    var hullsize = 0;                          /* Number of edges in convex hull. */
    var steinerleft = 0;                 /* Number of Steiner points not yet used. */
    var highorderindex = 0;  /* Index to find extra nodes for high-order elements. */
    var elemattribindex = 0;            /* Index to find attributes of a triangle. */
    var areaboundindex = 0;             /* Index to find area bound of a triangle. */
    var checksegments = false         /* Are there segments in the triangulation yet? */
    var checkquality = false;                  /* Has quality triangulation begun yet? */
    var readnodefile = false;                           /* Has a .node file been read? */
    var samples = 0;              /* Number of random samples for point location. */

    var incirclecount = 0;                 /* Number of incircle tests performed. */
    var counterclockcount = 0;     /* Number of counterclockwise tests performed. */
    var orient3dcount = 0;           /* Number of 3D orientation tests performed. */
    var hyperbolacount = 0;      /* Number of right-of-hyperbola tests performed. */
    var circumcentercount = 0;  /* Number of circumcenter calculations performed. */
    var circletopcount = 0;       /* Number of circle top calculations performed. */

    /* Triangular bounding box vertices.                                         */

    var infvertex1: Vertex?, infvertex2: Vertex?, infvertex3: Vertex?

    /* Pointer to the `triangle' that occupies all of "outer space."             */

    let dummytri = Triangle(id: -1)

    /* Pointer to the omnipresent subsegment.  Referenced by any triangle or     */
    /*   subsegment that isn't really connected to a subsegment at that          */
    /*   location.                                                               */

    let dummysub = Subsegment()

    /* Pointer to a recently visited triangle.  Improves point location if       */
    /*   proximate vertices are inserted sequentially.                           */

    var recenttri: OrientedTriangle?

    func makeTriangle(b: Behavior) -> OrientedTriangle {
        let tri = Triangle(id: triangles.count, adjoining: OrientedTriangle(triangle: dummytri, orient: 0), subsegment: b.usesegments ? OrientedSubsegment(subseg: dummysub, orient: 0) : nil)
        for _ in 0..<eextras {
            tri.attributes.append(0)
        }

        if b.vararea {
            tri.area = -1
        }
        triangles.append(tri)
        return OrientedTriangle(triangle: tri, orient: 0)
    }

    func killTriangle(triangle: Triangle) {
        triangle.killTriangle()
//        triangles.removeAll(where: { $0 === triangle })
    }

    func killSubseg(subseg: Subsegment) {
        subseg.kill()
//        subsegs.removeAll(where: { $0 === subseg })
    }

    func makesubseg() -> OrientedSubsegment {

        let newsubseg = Subsegment()
        /* Initialize the two adjoining subsegments to be the omnipresent */
        /*   subsegment.                                                  */
        newsubseg.adj1 = OrientedSubsegment(subseg: dummysub, orient: 0)
        newsubseg.adj2 = OrientedSubsegment(subseg: dummysub, orient: 0)
        /* Initialize the two adjoining triangles to be "outer space." */
        newsubseg.t1 = OrientedTriangle(triangle: dummytri, orient: 0)
        newsubseg.t2 = OrientedTriangle(triangle: dummytri, orient: 0)
        /* Set the boundary marker to zero. */
        newsubseg.marker = 0
        subsegs.append(newsubseg)
        return OrientedSubsegment(subseg: newsubseg, orient: 0)
    }

    func createVertex(x: REAL, y: REAL, z: REAL = 0) -> Vertex {
        let newVertex = Vertex(id: vertices.count, x: x, y: y, z: z)
        vertices.append(newVertex)
        return newVertex
    }

    func createbadSubSeg(seg: OrientedSubsegment, org: Vertex, dest: Vertex) -> BadSubsegment {
        let newsubseg = BadSubsegment(seg: seg, org: org, dest: dest)
        badSubsegs.append(newsubseg)
        return newsubseg
    }
}
