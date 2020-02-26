//
//  Triangulator.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

public typealias REAL = CGFloat
let plus1mod3 = [1, 2, 0]
let minus1mod3 = [2, 0, 1]

public class Triangulator {

    let m = Mesh()

    let b: Behavior

    let inArgs: TriangulateIO

    var generator = Xoshiro()

    private var predicates: Predicates

    public init(b: Behavior, inArgs: TriangulateIO) {
        self.b = b
        self.inArgs = inArgs
        self.predicates = Predicates(exact: !b.noexact)
    }

    public func triangulate() -> TriangulateIO {

        var out = inArgs

        m.steinerleft = b.steiner

        transferNodes(pointlist: inArgs.pointlist, attributes: inArgs.pointattributelist, markerList: inArgs.pointmarkerlist, numberofpointattribs: inArgs.numberOfPointAttributes)

        if b.refine {
            print("TODO")
        } else {
            m.hullsize = delaunay()
        }

        /* Ensure that no vertex can be mistaken for a triangular bounding */
        /*   box vertex in insertvertex().                                 */
        m.infvertex1 = nil
        m.infvertex2 = nil
        m.infvertex3 = nil

        if b.usesegments {
            m.checksegments = true                /* Segments will be introduced next. */
            if !b.refine {
                /* Insert PSLG segments and/or convex hull segments. */
                formskeleton(segmentlist: inArgs.segmentlist, segmentmarkerlist: inArgs.segmentmarkerlist)

            }
        }

        if b.poly && (m.triangles.count > 0) {

            //            holearray = in->holelist;
            //            m.holes = in->numberofholes;
            //            regionarray = in->regionlist;
            //            m.regions = in->numberofregions;

            if !b.refine {
                /* Carve out holes and concavities. */
                carveholes(holelist: inArgs.holelist, regionlist: inArgs.regionlist)
            }
        } else {
            /* Without a PSLG, there can be no holes or regional attributes   */
            /*   or area constraints.  The following are set to zero to avoid */
            /*   an accidental free() later.                                  */
            m.holes = 0
            m.regions = 0
        }
        //
        //
        //
        //        if (b.quality && (m.triangles.items > 0)) {
        //            enforcequality(&m, &b);           /* Enforce angle and area constraints. */
        //        }
        //
        //
        //
        //        /* Calculate the number of edges. */
        //        m.edges = (3l * m.triangles.items + m.hullsize) / 2l;
        //
        //        if (b.order > 1) {
        //            highorder(&m, &b);       /* Promote elements to higher polynomial order. */
        //        }
        //        if (!b.quiet) {
        //            print("");
        //        }
        //
        //
        //        if (b.jettison) {
        //            out->numberofpoints = (int)m.vertices.items - m.undeads;
        //        } else {
        //            out->numberofpoints = (int)m.vertices.items;
        //        }

        /* writenodes() numbers the vertices too. */

        writenodes(pointlist: &out.pointlist, pointmarkerlist: &out.pointmarkerlist)
        writeelements(trianglelist: &out.trianglelist)
        //
        //                /* The -c switch (convex switch) causes a PSLG to be written */
        //                /*   even if none was read.                                  */
        //                if (b.poly || b.convex) {
        //                    /* If not using iteration numbers, don't overwrite the .poly file. */
        //                    if (b.nopolywritten || b.noiterationnum) {
        //                        if (!b.quiet) {
        //
        //                            print("NOT writing segments.");
        //
        //                        }
        //                    } else {
        //
        //                        writepoly(&m, &b, &out->segmentlist, &out->segmentmarkerlist);
        //                        out->numberofholes = m.holes;
        //                        out->numberofregions = m.regions;
        //                        if (b.poly) {
        //                            out->holelist = in->holelist;
        //                            out->regionlist = in->regionlist;
        //                        } else {
        //                            out->holelist = (struct Vector2**) NULL;
        //                            out->regionlist = (REAL *) NULL;
        //                        }
        //
        //                    }
        //                }

        if b.edgesout {

            //                    writeedges(&m, &b, &out->edgelist, &out->edgemarkerlist);

        }
        if b.voronoi {

            //                    writevoronoi(&m, &b, &vorout->pointlist, &vorout->pointattributelist,
            //                                 &vorout->pointmarkerlist, &vorout->edgelist,
            //                                 &vorout->edgemarkerlist, &vorout->normlist);

        }
        if b.neighbors {

            //                    writeneighbors(&m, &b, &out->neighborlist);

        }

        if !b.quiet {
            //                    statistics(&m, &b);
        }

        return out
    }

    /*****************************************************************************/
    /*                                                                           */
    /*  writenodes()   Number the vertices and write them to a .node file.       */
    /*                                                                           */
    /*  To save memory, the vertex numbers are written over the boundary markers */
    /*  after the vertices are written to a file.                                */
    /*                                                                           */
    /*****************************************************************************/
    private func writenodes(pointlist: inout [Vector2], pointmarkerlist: inout [Int]) {

        if !b.quiet {
            print("Writing vertices.")
        }
        /* Allocate memory for output vertices if necessary. */
        pointlist = [Vector2]()

        /* Allocate memory for output vertex markers if necessary. */

        pointmarkerlist = [Int]()

        var vertexnumber = 0

        for i in 0..<m.vertices.count where m.vertices[i].state != .undead {

            /* X and y coordinates. */
            pointlist.append(m.vertices[i].vert)

            pointmarkerlist.append(m.vertices[i].mark)

            m.vertices[i].mark = vertexnumber
            vertexnumber += 1

        }

    }

    /*****************************************************************************/
    /*                                                                           */
    /*  writeelements()   Write the triangles to an .ele file.                   */
    /*                                                                           */
    /*****************************************************************************/
    private func writeelements(trianglelist: inout [Int]) {
        if !b.quiet {
            print("Writing triangles.")
        }
        /* Allocate memory for output triangles if necessary. */
        trianglelist.removeAll(keepingCapacity: true)

        for triangle in m.triangles where !triangle.isDead {
            let triangleloop = OrientedTriangle(triangle: triangle, orientation: 0)
            trianglelist.append(m.vertices[triangleloop.org].mark)
            trianglelist.append(m.vertices[triangleloop.dest].mark)
            trianglelist.append(m.vertices[triangleloop.apex].mark)
        }
    }

    private func transferNodes(pointlist: [Vector2], attributes: [REAL], markerList: [Int], numberofpointattribs: Int) {

        m.invertices = pointlist.count
        m.mesh_dim = 2
        m.nextras = numberofpointattribs

        guard m.invertices >= 3 else {
            fatalError("Error:  Input must have at least three input vertices.")
        }
        if b.verbose {
            print("  Sorting vertices.")
        }

        //        if m.nextras == 0 {
        //            b.weighted = false
        //        }
        m.vertices = pointlist.sorted(by: {  lhs, rhs in
            if lhs.x < rhs.x {
                return true
            } else if lhs.x > rhs.x {
                return false
            } else {
                return lhs.y < rhs.y
            }

        }).alteratedAxes(generator: &generator, dwyer: b.dwyer).enumerated().map({ i, vert in

            var vert = Vertex(id: i, x: vert.x, y: vert.y)

            if !markerList.isEmpty {
                vert.mark = markerList[i]
            } else {
                vert.mark = 0
            }

            if i == 0 {
                m.xmax = vert.x
                m.xmin = vert.x
                m.ymin = vert.y
                m.ymax = vert.y
            } else {
                m.xmin = min(m.xmin, vert.x)
                m.xmax = max(m.xmax, vert.x)
                m.ymin = min(m.ymin, vert.y)
                m.ymax = max(m.ymax, vert.y)
            }
            return vert
        })
    }

    private func delaunay() -> Int {
        var hulledges = 0

        m.eextras = 0
        initalizeDummies(mesh: m, b: b)

        if !b.quiet {
            print("Constructing Delaunay triangulation by divide-and-conquer method.")
        }
        hulledges = divconqdelaunay(m: m, b: b)

        if m.triangles.count == 0 {
            /* The input vertices were all collinear, so there are no triangles. */
            return 0
        } else {
            return hulledges
        }
    }

    private func initalizeDummies(mesh m: Mesh, b: Behavior) {
        let encoded = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        m.dummytri.t1 = encoded
        m.dummytri.t2 = encoded
        m.dummytri.t3 = encoded

        if b.usesegments {
            m.dummysub.adj1 = EncodedSubsegment(ss: m.dummysub, orientation: 0)
            m.dummysub.adj2 = EncodedSubsegment(ss: m.dummysub, orientation: 0)

            m.dummysub.v1 = -1
            m.dummysub.v2 = -1
            m.dummysub.v3 = -1
            m.dummysub.v4 = -1

            m.dummysub.t1 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
            m.dummysub.t2 = OrientedTriangle(triangle: m.dummytri, orientation: 0)

            m.dummysub.marker = 0
            let subSeg = EncodedSubsegment(ss: m.dummysub, orientation: 0)
            m.dummytri.s1 = subSeg
            m.dummytri.s2 = subSeg
            m.dummytri.s3 = subSeg
        }
    }

    private func divconqdelaunay(m: Mesh, b: Behavior) -> Int {

        m.triangles.reserveCapacity(m.vertices.count / 3)

        if b.verbose {
            print("  Forming triangulation.")
        }

        /* Form the Delaunay triangulation. */
        var hullleft = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        var hullright = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        divconqrecurse(at: 0, vertices: m.vertices.count, axis: 0, farleft: &hullleft, farright: &hullright)

        return removeghosts(startghost: hullleft)
    }

    func removeghosts(startghost: OrientedTriangle) -> Int {

        if b.verbose {
            print("  Removing ghost triangles.")
        }
        /* Find an edge on the convex hull to start point location from. */
        var searchedge = startghost.lprev()
        searchedge.symself()
        m.dummytri.t1 = searchedge
        /* Remove the bounding box and count the convex hull edges. */

        var disolveedge = startghost
        var hullsize = 0
        repeat {
            hullsize += 1
            let deadtriangle = disolveedge.lnext()

            disolveedge.lprevself()
            disolveedge.symself()
            /* If no PSLG is involved, set the boundary markers of all the vertices */
            /*   on the convex hull.  If a PSLG is used, this step is done later.   */
            if !b.poly {
                /* Watch out for the case where all the input vertices are collinear. */
                if disolveedge.triangle !== m.dummytri, m.vertices[disolveedge.org].mark == 0 {
                    m.vertices[disolveedge.org].mark = 1
                }
            }
            /* Remove a bounding triangle from a convex hull triangle. */
            disolveedge.disolve(m: m)
            /* Find the next bounding triangle. */
            disolveedge = deadtriangle.sym()
            /* Delete the bounding triangle. */
            //            triangledealloc(m, deadtriangle.tri);
            m.killTriangle(triangle: deadtriangle.triangle)
        } while !disolveedge.otriEquals(other: startghost)
        m.removeAllDeadTriangles()
        return hullsize
    }

    private func divconqrecurse(at start: Int, vertices: Int, axis: Int, farleft: inout OrientedTriangle, farright: inout OrientedTriangle) {
        if b.verbose {
            print("  Triangulating \(vertices) vertices.")
        }

        if vertices == 2 {
            /* The triangulation of two vertices is an edge.  An edge is */
            /*   represented by two bounding triangles.                  */
            let tmpl = m.makeTriangle(b: b)
            farleft.triangle = tmpl.triangle
            farleft.orientation = 0
            farleft.org = start
            farleft.dest = start + 1
            /* The apex is intentionally left NULL. */
            let tmpr = m.makeTriangle(b: b)
            farright.triangle = tmpr.triangle
            farright.orientation = 0
            farright.org = start + 1
            farright.dest = start
            /* The apex is intentionally left NULL. */
            farleft.bond(to: farright)
            farleft.lprevself()
            farright.lnextself()
            farleft.bond(to: farright)
            farleft.lprevself()
            farright.lnextself()
            farleft.bond(to: farright)
            if b.verbose {
                print("  Creating ")
                printtriangle(t: farleft)
                print("  Creating ")
                printtriangle(t: farright)
            }
            farleft = farright.lprev()
            return
        } else if vertices == 3 {
            var midtri = m.makeTriangle(b: b)
            var tri1 = m.makeTriangle(b: b)
            var tri2 = m.makeTriangle(b: b)
            var tri3 = m.makeTriangle(b: b)
            let area = predicates.counterClockwise(a: m.vertices[start], b: m.vertices[start + 1], c: m.vertices[start + 2])

            if area == 0 {
                midtri.org = start
                midtri.dest = start + 1
                tri1.org = start + 1
                tri1.dest = start
                tri2.org  = start + 2
                tri2.dest = start + 1
                tri3.org = start + 1
                tri3.dest = start + 2
                /* All apices are intentionally left NULL. */
                midtri.bond(to: tri1)
                tri2.bond(to: tri3)

                midtri.lnextself()
                tri1.lprevself()
                tri2.lnextself()
                tri3.lprevself()
                midtri.bond(to: tri3)
                tri1.bond(to: tri2)

                midtri.lnextself()
                tri1.lprevself()
                tri2.lnextself()
                tri3.lprevself()
                midtri.bond(to: tri1)
                tri2.bond(to: tri3)

                /* Ensure that the origin of `farleft' is m.vertices[0]. */
                farleft = tri1
                /* Ensure that the destination of `farright' is m.vertices[2]. */
                farright = tri2
            } else {
                /* The three vertices are not collinear; the triangulation is one */
                /*   triangle, namely `midtri'.                                   */
                midtri.org = start
                tri1.dest = start
                tri3.org = start
                /* Apices of tri1, tri2, and tri3 are left NULL. */
                if area > 0.0 {
                    /* The vertices are in counterclockwise order. */
                    midtri.dest = start + 1
                    tri1.org = start + 1
                    tri2.dest = start + 1
                    midtri.apex = start + 2
                    tri2.org = start + 2
                    tri3.dest = start + 2

                } else {
                    /* The vertices are in clockwise order. */
                    midtri.dest = start + 2
                    tri1.org = start + 2
                    tri2.dest = start + 2
                    midtri.apex = start + 1
                    tri2.org = start + 1
                    tri3.dest = start + 1
                }
                /* The topology does not depend on how the vertices are ordered. */

                midtri.bond(to: tri1)
                midtri.lnextself()
                midtri.bond(to: tri2)
                midtri.lnextself()
                midtri.bond(to: tri3)
                tri1.lprevself()
                tri2.lnextself()
                tri1.bond(to: tri2)
                tri1.lprevself()
                tri3.lprevself()
                tri1.bond(to: tri3)
                tri2.lnextself()
                tri3.lprevself()
                tri2.bond(to: tri3)
                /* Ensure that the origin of `farleft' is m.vertices[0]. */
                farleft = tri1
                /* Ensure that the destination of `farright' is m.vertices[2]. */
                if area > 0.0 {
                    farright = tri2
                } else {
                    farright = farleft.lnext()

                }
            }
            if b.verbose {
                print("  Creating ")
                printtriangle(t: midtri)
                print("  Creating ")
                printtriangle(t: tri1)
                print("  Creating ")
                printtriangle(t: tri2)
                print("  Creating ")
                printtriangle(t: tri3)
            }
            return
        } else {
            /* Split the vertices in half. */
            let divider = vertices >> 1
            /* Recursively triangulate each half. */
            var innerleft = OrientedTriangle(triangle: farleft.triangle, orientation: 0)
            var innerright = OrientedTriangle(triangle: farright.triangle, orientation: 0)
            divconqrecurse(at: start, vertices: divider, axis: 1 - axis, farleft: &farleft, farright: &innerleft)
            divconqrecurse(at: (start + divider), vertices: vertices - divider, axis: 1 - axis,
                           farleft: &innerright, farright: &farright)
            if b.verbose {
                print("  Joining triangulations with \(divider) and \(vertices - divider) vertices.")
            }
            /* Merge the two triangulations into one. */
            mergehulls(farleft: &farleft, innerleft: &innerleft, innerright: &innerright, farright: &farright, axis: axis)
        }
    }

    private func mergehulls(farleft: inout OrientedTriangle, innerleft: inout OrientedTriangle, innerright: inout OrientedTriangle, farright: inout OrientedTriangle, axis: Int) {

        var innerleftdest =  m.vertices[innerleft.dest]
        var innerleftapex =  m.vertices[innerleft.apex]
        var innerrightorg =  m.vertices[innerright.org]
        var innerrightapex =  m.vertices[innerright.apex]
        /* Special treatment for horizontal cuts. */
        if b.dwyer && (axis == 1) {
            var farleftpt = m.vertices[farleft.org]
            var farleftapex = m.vertices[farleft.apex]
            var farrightpt = m.vertices[farright.dest]
            /* The pointers to the extremal vertices are shifted to point to the */
            /*   topmost and bottommost vertex of each hull, rather than the     */
            /*   leftmost and rightmost vertices.                                */
            while farleftapex.y < farleftpt.y {
                farleft.lnextself()
                farleft.symself()
                farleftpt = farleftapex
                farleftapex = m.vertices[farleft.apex]
            }

            var checkedge = innerleft.sym()
            var checkvertex =  m.vertices[checkedge.apex]
            while checkvertex.y > innerleftdest.y {
                innerleft = checkedge.lnext()
                innerleftapex = innerleftdest
                innerleftdest = checkvertex
                checkedge = innerleft.sym()
                checkvertex =  m.vertices[checkedge.apex]
            }
            while innerrightapex.y < innerrightorg.y {
                innerright.lnextself()
                innerright.symself()
                innerrightorg = innerrightapex
                innerrightapex =  m.vertices[innerright.apex]
            }
            checkedge = farright.sym()
            checkvertex =  m.vertices[checkedge.apex]
            while checkvertex.y > farrightpt.y {
                farright = checkedge.lnext()
                farrightpt = checkvertex
                checkedge = farright.sym()
                checkvertex =  m.vertices[checkedge.apex]
            }
        }
        /* Find a line tangent to and below both hulls. */
        var changemade = true
        repeat {
            changemade = false
            /* Make innerleftdest the "bottommost" vertex of the left hull. */
            if predicates.counterClockwise(a: innerleftdest, b: innerleftapex, c: innerrightorg) > 0.0 {
                innerleft.lprevself()
                innerleft.symself()
                innerleftdest = innerleftapex
                innerleftapex =  m.vertices[innerleft.apex]
                changemade = true
            }
            /* Make innerrightorg the "bottommost" vertex of the right hull. */
            if predicates.counterClockwise(a: innerrightapex, b: innerrightorg, c: innerleftdest) > 0.0 {
                innerright.lnextself()
                innerright.symself()
                innerrightorg = innerrightapex
                innerrightapex =  m.vertices[innerright.apex]
                changemade = true
            }
        } while (changemade)
        /* Find the two candidates to be the next "gear tooth." */
        var leftcand = innerleft.sym()
        var rightcand = innerright.sym()

        /* Create the bottom new bounding triangle. */
        var baseedge = m.makeTriangle(b: b)
        /* Connect it to the bounding boxes of the left and right triangulations. */
        baseedge.bond(to: innerleft)
        baseedge.lnextself()
        baseedge.bond(to: innerright)

        baseedge.lnextself()
        baseedge.org = innerrightorg.id
        baseedge.dest = innerleftdest.id

        /* Apex is intentionally left NULL. */
        if b.verbose {
            print("  Creating base bounding ")
            printtriangle(t: baseedge)
        }
        /* Fix the extreme triangles if necessary. */
        var farleftpt = farleft.org
        if innerleftdest.id == farleftpt {
            farleft = baseedge.lnext()
        }
        var farrightpt = farright.dest
        if innerrightorg.id == farrightpt {
            farright = baseedge.lprev()
        }
        /* The vertices of the current knitting edge. */
        var lowerleft = innerleftdest
        var lowerright = innerrightorg
        /* The candidate vertices for knitting. */
        var upperleft = leftcand.apex
        var upperright = rightcand.apex
        /* Walk up the gap between the two triangulations, knitting them together. */
        while true {
            /* Have we reached the top?  (This isn't quite the right question,       */
            /*   because even though the left triangulation might seem finished now, */
            /*   moving up on the right triangulation might reveal a new vertex of   */
            /*   the left triangulation.  And vice-versa.)                           */
            let leftfinished = predicates.counterClockwise(a: m.vertices[upperleft], b: lowerleft, c: lowerright) <= 0.0
            let rightfinished = predicates.counterClockwise(a: m.vertices[upperright], b: lowerleft, c: lowerright) <= 0.0
            if leftfinished && rightfinished {
                /* Create the top new bounding triangle. */
                var nextedge = m.makeTriangle(b: b)
                nextedge.org = lowerleft.id
                nextedge.dest = lowerright.id
                /* Apex is intentionally left NULL. */
                /* Connect it to the bounding boxes of the two triangulations. */
                nextedge.bond(to: baseedge)
                nextedge.lnextself()
                nextedge.bond(to: rightcand)
                nextedge.lnextself()
                nextedge.bond(to: leftcand)

                if b.verbose {
                    print("  Creating top bounding ")
                    printtriangle(t: nextedge)
                }
                /* Special treatment for horizontal cuts. */
                if b.dwyer && (axis == 1) {
                    farleftpt =  farleft.org

                    farrightpt = farright.dest
                    var farrightapex = farright.apex
                    var checkedge = farleft.sym()
                    var checkvertex =  m.vertices[checkedge.apex]
                    /* The pointers to the extremal vertices are restored to the  */
                    /*   leftmost and rightmost vertices (rather than topmost and */
                    /*   bottommost).                                             */
                    while checkvertex.x <  m.vertices[farleftpt].x {
                        farleft = checkedge.lprev()

                        farleftpt = checkvertex.id
                        checkedge = farleft.sym()
                        checkvertex =  m.vertices[checkedge.apex]
                    }
                    while  m.vertices[farrightapex].x >  m.vertices[farrightpt].x {
                        farright.lprevself()
                        farright.symself()
                        farrightpt = farrightapex
                        farrightapex = farright.apex
                    }
                }
                return
            }
            /* Consider eliminating edges from the left triangulation. */
            if !leftfinished {
                /* What vertex would be exposed if an edge were deleted? */
                var nextedge = leftcand.lprev()
                nextedge.symself()

                /* If nextapex is NULL, then no vertex would be exposed; the */
                /*   triangulation would have been eaten right through.      */
                if nextedge.apex >= 0 {
                    let nextapex = m.vertices[nextedge.apex]
                    /* Check whether the edge is Delaunay. */
                    var badedge = predicates.inCircle(a: lowerleft.vert, b: lowerright.vert, c: m.vertices[upperleft].vert, d: nextapex.vert) > 0.0
                    while badedge {
                        /* Eliminate the edge with an edge flip.  As a result, the    */
                        /*   left triangulation will have one more boundary triangle. */
                        nextedge.lnextself()
                        let topcasing = nextedge.sym()
                        nextedge.lnextself()
                        let sidecasing = nextedge.sym()
                        nextedge.bond(to: topcasing)
                        leftcand.bond(to: sidecasing)
                        leftcand.lnextself()
                        let outercasing = leftcand.sym()
                        nextedge.lprevself()
                        nextedge.bond(to: outercasing)
                        /* Correct the vertices to reflect the edge flip. */
                        leftcand.org = lowerleft.id
                        leftcand.dest = -1
                        leftcand.apex = nextapex.id
                        nextedge.org = -1
                        nextedge.dest = upperleft
                        nextedge.apex = nextapex.id
                        /* Consider the newly exposed vertex. */
                        upperleft = nextapex.id
                        /* What vertex would be exposed if another edge were deleted? */
                        nextedge = sidecasing
                        if nextapex.id != nextedge.apex {
                            /* Check whether the edge is Delaunay. */
                            badedge = predicates.inCircle(a: lowerleft.vert, b: lowerright.vert, c: m.vertices[upperleft].vert, d: nextapex.vert) > 0.0
                        } else {
                            /* Avoid eating right through the triangulation. */
                            badedge = false
                        }
                    }
                }
            }
            /* Consider eliminating edges from the right triangulation. */
            if !rightfinished {
                /* What vertex would be exposed if an edge were deleted? */
                var nextedge = rightcand.lnext()

                nextedge.symself()

                /* If nextapex is NULL, then no vertex would be exposed; the */
                /*   triangulation would have been eaten right through.      */
                var nextapex = nextedge.apex
                if nextapex >= 0 {
                    /* Check whether the edge is Delaunay. */
                    var badedge = predicates.inCircle(a: lowerleft.vert, b: lowerright.vert, c: m.vertices[upperright].vert, d: m.vertices[nextapex].vert) > 0.0
                    while badedge {
                        /* Eliminate the edge with an edge flip.  As a result, the     */
                        /*   right triangulation will have one more boundary triangle. */
                        nextedge.lprevself()
                        let topcasing = nextedge.sym()
                        nextedge.lprevself()
                        let sideCasing = nextedge.sym()
                        nextedge.bond(to: topcasing)
                        rightcand.bond(to: sideCasing)
                        rightcand.lprevself()
                        let outercasing = rightcand.sym()
                        nextedge.lnextself()
                        nextedge.bond(to: outercasing)

                        /* Correct the vertices to reflect the edge flip. */

                        rightcand.org = -1
                        rightcand.dest = lowerright.id
                        rightcand.apex = nextapex
                        nextedge.org = upperright
                        nextedge.dest = -1
                        nextedge.apex = nextapex
                        /* Consider the newly exposed vertex. */
                        upperright = nextapex
                        /* What vertex would be exposed if another edge were deleted? */
                        nextedge = sideCasing
                        nextapex = nextedge.apex
                        if nextapex != -1 {
                            /* Check whether the edge is Delaunay. */
                            badedge = predicates.inCircle(a: lowerleft.vert, b: lowerright.vert, c: m.vertices[upperright].vert, d: m.vertices[nextapex].vert) > 0.0
                        } else {
                            /* Avoid eating right through the triangulation. */
                            badedge = false
                        }
                    }
                }
            }
            if leftfinished || (!rightfinished && (predicates.inCircle(a: m.vertices[upperleft].vert, b: lowerleft.vert, c: lowerright.vert, d: m.vertices[upperright].vert) > 0.0)) {
                /* Knit the triangulations, adding an edge from `lowerleft' */
                /*   to `upperright'.                                       */
                baseedge.bond(to: rightcand)
                baseedge = rightcand.lprev()
                baseedge.dest = lowerleft.id
                lowerright = m.vertices[upperright]
                rightcand = baseedge.sym()
                upperright = rightcand.apex
            } else {
                /* Knit the triangulations, adding an edge from `upperleft' */
                /*   to `lowerright'.                                       */
                baseedge.bond(to: leftcand)
                baseedge = leftcand.lnext()
                baseedge.org = lowerright.id
                lowerleft = m.vertices[upperleft]
                leftcand = baseedge.sym()
                upperleft = leftcand.apex
            }
            if b.verbose {
                print("  Connecting ")
                printtriangle(t: baseedge)
            }
        }
    }

    private func printtriangle(t: OrientedTriangle) {

        print("triangle \(t.triangle) with orientation \(t.orientation):")
        var printtri = t.triangle.t1!
        if printtri.triangle === m.dummytri {
            print("    [0] = Outer space")
        } else {
            print("    [0] = \(printtri.triangle)  \(printtri.orientation)")
        }
        printtri = t.triangle.t2!
        if printtri.triangle === m.dummytri {
            print("    [1] = Outer space")
        } else {
            print("    [1] = \(printtri.triangle)  \(printtri.orientation)")
        }
        printtri = t.triangle.t3!
        if printtri.triangle === m.dummytri {
            print("    [2] = Outer space")
        } else {
            print("    [2] = \(printtri.triangle)  \(printtri.orientation)")
        }

        if t.org >= 0 {
            let printvertex = m.vertices[t.org]
            print("    Origin[\((t.orientation + 1) % 3 + 3)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Origin[\((t.orientation + 1) % 3 + 3)] = NULL")
        }

        if t.dest >= 0 {
            let printvertex = m.vertices[t.dest]
            print("    Dest  [\((t.orientation + 2) % 3 + 3)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Dest  [\((t.orientation + 2) % 3 + 3)] = NULL")
        }

        if t.apex >= 0 {
            let printvertex = m.vertices[t.apex]
            print("    Apex  [\(t.orientation + 3)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Apex  [\(t.orientation + 3)] = NULL")
        }

        if b.usesegments {

            if let printsh = t.triangle.s1, printsh.ss !== m.dummysub {
                print("    [6] = x%lx  %d", printsh.ss, printsh.orientation)
            }

            if let printsh = t.triangle.s2, printsh.ss !== m.dummysub {
                print("    [7] = x%lx  %d", printsh.ss, printsh.orientation)
            }

            if let printsh = t.triangle.s3, printsh.ss !== m.dummysub {
                print("    [8] = x%lx  %d", printsh.ss, printsh.orientation)
            }
        }

        //        if (b.vararea) {
        //            print("    Area constraint:  %.4g", t.triangle.area);
        //        }
    }

    private func formskeleton(segmentlist: [Int], segmentmarkerlist: [Int]) {

        if b.poly {
            if !b.quiet {
                print("Recovering segments in Delaunay triangulation.")
            }

            m.insegments = segmentlist.count / 2

            /* If the input vertices are collinear, there is no triangulation, */
            /*   so don't try to insert segments.                              */
            if m.triangles.count == 0 {
                return
            }

            /* If segments are to be inserted, compute a mapping */
            /*   from vertices to triangles.                     */
            if m.insegments > 0 {
                makevertexmap(m: m, b: b)
                if b.verbose {
                    print("  Recovering PSLG segments.")
                }
            }

            var boundmarker = 0
            var index = 0
            /* Read and insert the segments. */
            for i in 0..<m.insegments {

                let end1 = segmentlist[index]
                index += 1
                let end2 = segmentlist[index]
                index += 1
                if !segmentmarkerlist.isEmpty {
                    boundmarker = segmentmarkerlist[i]
                }

                if end1 < 0 || (end1 >= m.invertices) {
                    if !b.quiet {
                        print("Warning:  Invalid first endpoint of segment \(i).")
                    }
                } else if end2 < 0 || end2 >= m.invertices {
                    if !b.quiet {
                        print("Warning:  Invalid second endpoint of segment \(i)")
                    }
                } else {
                    /* Find the vertices numbered `end1' and `end2'. */
                    let endpoint1 = m.vertices[end1]
                    let endpoint2 = m.vertices[end2]
                    if (endpoint1.x == endpoint2.x) && (endpoint1.y == endpoint2.y) {
                        if !b.quiet {
                            print("Warning:  Endpoints of segment \(i) are coincident in %s.")
                        }
                    } else {
                        insertsegment(endpoint1: endpoint1, endpoint2: endpoint2, newmark: boundmarker)
                    }
                }
            }
        } else {
            m.insegments = 0
        }
        if b.convex || !b.poly {
            /* Enclose the convex hull with subsegments. */
            if b.verbose {
                print("  Enclosing convex hull with segments.")
            }
            markhull(m: m, b: b)
        }
    }

    private func markhull(m: Mesh, b: Behavior) {

        /* Find a triangle handle on the hull. */
        var hulltri = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        hulltri.symself()

        /* Remember where we started so we know when to stop. */
        let starttri = hulltri
        /* Go once counterclockwise around the convex hull. */
        repeat {
            /* Create a subsegment if there isn't already one here. */
            insertsubseg(tri: hulltri, subsegmark: 1)
            /* To find the next hull edge, go clockwise around the next vertex. */
            hulltri.lnextself()
            var nexttri = hulltri.oprev()
            while nexttri.triangle !== m.dummytri {
                hulltri = nexttri
                nexttri = hulltri.oprev()
            }
        } while (!hulltri.otriEquals(other: starttri))
    }

    private func makevertexmap(m: Mesh, b: Behavior) {

        if b.verbose {
            print("    Constructing mapping from vertices to triangles.")
        }
        for triangle in m.triangles where !triangle.isDead {
            /* Check all three vertices of the triangle. */
            for i in 0..<3 {
                let oriented = OrientedTriangle(triangle: triangle, orientation: i)
                m.vertices[oriented.org].triangle = Vertex.TriIndex(id: triangle.id, orientation: i)
            }
        }
    }
    private func insertsegment(endpoint1 ep1: Vertex, endpoint2 ep2: Vertex, newmark: Int) {
        var endpoint1 = ep1
        var endpoint2 = ep2
        if b.verbose {
            print("  Connecting (\(endpoint1.x), \(endpoint1.y)) to (\(endpoint2.x), \(endpoint2.y)).")
        }

        /* Find a triangle whose origin is the segment's first endpoint. */
        var checkvertex: Vertex?
        var searchtri1 = OrientedTriangle(triangle: m.dummytri, orientation: 0)

        if let encodedtri = endpoint1.triangle {
            searchtri1 = OrientedTriangle(triangle: m.triangles[encodedtri.id], orientation: encodedtri.orientation)
            checkvertex = m.vertices[searchtri1.org]
        }
        if checkvertex?.id != endpoint1.id {
            /* Find a boundary triangle to search from. */
            searchtri1 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
            searchtri1.orientation = 0
            searchtri1.symself()

            /* Search for the segment's first endpoint by point location. */
            if locate(searchpoint: endpoint1, searchtri: &searchtri1) != .onVertex {
                print( "Internal error in insertsegment():  Unable to locate PSLG vertex")
                print("  (\(endpoint1.x), \(endpoint1.y)) in triangulation.")
                fatalError("Couldn't locate endpoint")
            }
        }
        /* Remember this triangle to improve subsequent point location. */
        m.recenttri = searchtri1.copy()

        /* Scout the beginnings of a path from the first endpoint */
        /*   toward the second.                                   */
        if scoutsegment(searchtri: &searchtri1, endpoint2: endpoint2, newmark: newmark) {
            /* The segment was easily inserted. */
            return
        }
        /* The first endpoint may have changed if a collision with an intervening */
        /*   vertex on the segment occurred.                                      */
        endpoint1 = m.vertices[searchtri1.org]

        /* Find a triangle whose origin is the segment's second endpoint. */
        checkvertex = nil
        var searchtri2: OrientedTriangle!
        if let encodedtri = endpoint2.triangle {
            searchtri2 = OrientedTriangle(triangle: m.triangles[encodedtri.id], orientation: encodedtri.orientation)
            checkvertex = m.vertices[searchtri2.org]
        }
        if checkvertex != endpoint2 {
            /* Find a boundary triangle to search from. */
            searchtri2 = OrientedTriangle(triangle: m.dummytri, orientation: 0)
            searchtri2.symself()
            /* Search for the segment's second endpoint by point location. */
            if locate(searchpoint: endpoint2, searchtri: &searchtri2) != .onVertex {
                print("Internal error in insertsegment():  Unable to locate PSLG vertex")
                print("  (\(endpoint2.x), \(endpoint2.y)) in triangulation.")
                fatalError()
            }
        }
        /* Remember this triangle to improve subsequent point location. */
        m.recenttri = searchtri2.copy()
        /* Scout the beginnings of a path from the second endpoint */
        /*   toward the first.                                     */
        if scoutsegment(searchtri: &searchtri2, endpoint2: endpoint1, newmark: newmark) {
            /* The segment was easily inserted. */
            return
        }
        /* The second endpoint may have changed if a collision with an intervening */
        /*   vertex on the segment occurred.                                       */
        endpoint2 = m.vertices[searchtri2.org]

        /* Insert the segment directly into the triangulation. */
        constrainededge(starttri: searchtri1, endpoint2: endpoint2, newmark: newmark)
    }

    private func constrainededge(starttri: OrientedTriangle, endpoint2: Vertex, newmark: Int) {

        let endpoint1 = starttri.org
        var fixuptri = starttri.lnext()
        flip(flipedge: &fixuptri)
        /* `collision' indicates whether we have found a vertex directly */
        /*   between endpoint1 and endpoint2.                            */
        var collision = false
        var done = false
        repeat {
            let farvertex = m.vertices[fixuptri.org]
            /* `farvertex' is the extreme point of the polygon we are "digging" */
            /*   to get from endpoint1 to endpoint2.                           */
            if (farvertex.x == endpoint2.x) && (farvertex.y == endpoint2.y) {
                var fixuptri2 = fixuptri.oprev()
                /* Enforce the Delaunay condition around endpoint2. */
                delaunayfixup(fixuptri: &fixuptri, leftside: false)
                delaunayfixup(fixuptri: &fixuptri2, leftside: true)
                done = true
            } else {
                /* Check whether farvertex is to the left or right of the segment */
                /*   being inserted, to decide which edge of fixuptri to dig      */
                /*   through next.                                                */
                let area = predicates.counterClockwise(a: m.vertices[endpoint1], b: endpoint2, c: farvertex)
                if area == 0.0 {
                    /* We've collided with a vertex between endpoint1 and endpoint2. */
                    collision = true
                    var fixuptri2 = fixuptri.oprev()
                    /* Enforce the Delaunay condition around farvertex. */
                    delaunayfixup(fixuptri: &fixuptri, leftside: false)
                    delaunayfixup(fixuptri: &fixuptri2, leftside: true)
                    done = true
                } else {
                    if area > 0.0 {        /* farvertex is to the left of the segment. */
                        var fixuptri2 = fixuptri.oprev()
                        /* Enforce the Delaunay condition around farvertex, on the */
                        /*   left side of the segment only.                        */
                        delaunayfixup(fixuptri: &fixuptri2, leftside: true)
                        /* Flip the edge that crosses the segment.  After the edge is */
                        /*   flipped, one of its endpoints is the fan vertex, and the */
                        /*   destination of fixuptri is the fan vertex.               */
                        fixuptri.lprevself()
                    } else {                /* farvertex is to the right of the segment. */
                        delaunayfixup(fixuptri: &fixuptri, leftside: false)
                        /* Flip the edge that crosses the segment.  After the edge is */
                        /*   flipped, one of its endpoints is the fan vertex, and the */
                        /*   destination of fixuptri is the fan vertex.               */
                        fixuptri.oprevself()
                    }
                    /* Check for two intersecting segments. */
                    var crosssubseg = fixuptri.tspivot()
                    if crosssubseg.subsegment === m.dummysub {
                        flip(flipedge: &fixuptri);    /* May create inverted triangle at left. */
                    } else {
                        /* We've collided with a segment between endpoint1 and endpoint2. */
                        collision = true
                        /* Insert a vertex at the intersection. */
                        segmentintersection(splittri: &fixuptri, splitsubseg: &crosssubseg, endpoint2: endpoint2)
                        done = true
                    }
                }
            }
        } while (!done)
        /* Insert a subsegment to make the segment permanent. */
        insertsubseg(tri: fixuptri, subsegmark: newmark)
        /* If there was a collision with an interceding vertex, install another */
        /*   segment connecting that vertex with endpoint2.                     */
        if collision {
            /* Insert the remainder of the segment. */
            if !scoutsegment(searchtri: &fixuptri, endpoint2: endpoint2, newmark: newmark) {
                constrainededge(starttri: fixuptri, endpoint2: endpoint2, newmark: newmark)
            }
        }
    }

    private func flip(flipedge: inout OrientedTriangle) {

        /* Identify the vertices of the quadrilateral. */
        let rightvertex = flipedge.org
        let leftvertex = flipedge.dest
        let botvertex = flipedge.apex
        var top = flipedge.sym()
        //    #ifdef SELF_CHECK
        //        if (top.tri == m->dummytri) {
        //            printf("Internal error in flip():  Attempt to flip on boundary.\n");
        //            lnextself(*flipedge);
        //            return;
        //        }
        //        if (m->checksegments) {
        //            tspivot(*flipedge, toplsubseg);
        //            if (toplsubseg.ss != m->dummysub) {
        //                printf("Internal error in flip():  Attempt to flip a segment.\n");
        //                lnextself(*flipedge);
        //                return;
        //            }
        //        }
        //    #endif /* SELF_CHECK */
        let farvertex = top.apex

        /* Identify the casing of the quadrilateral. */

        let topleft = top.lprev()
        let toplcasing = topleft.sym()
        let topright = top.lnext()
        let toprcasing = topright.sym()
        let botleft = flipedge.lnext()
        let botlcasing = botleft.sym()
        let botright = flipedge.lprev()
        let botrcasing = botright.sym()

        /* Rotate the quadrilateral one-quarter turn counterclockwise. */

        topleft.bond(to: botlcasing)
        botleft.bond(to: botrcasing)
        botright.bond(to: toprcasing)
        topright.bond(to: toplcasing)

        if m.checksegments {
            /* Check for subsegments and rebond them to the quadrilateral. */
            let toplsubseg = topleft.tspivot()
            let botlsubseg = botleft.tspivot()
            let botrsubseg = botright.tspivot()
            let toprsubseg = topright.tspivot()

            if toplsubseg.subsegment === m.dummysub {
                topright.tsdissolve(m: m)
            } else {
                topright.tsbond(to: toplsubseg)
            }
            if botlsubseg.subsegment === m.dummysub {
                topleft.tsdissolve(m: m)
            } else {
                topleft.tsbond(to: botlsubseg)
            }
            if botrsubseg.subsegment === m.dummysub {
                botleft.tsdissolve(m: m)
            } else {
                botleft.tsbond(to: botrsubseg)
            }
            if toprsubseg.subsegment === m.dummysub {
                botright.tsdissolve(m: m)
            } else {
                botright.tsbond(to: toprsubseg)
            }
        }

        /* New vertex assignments for the rotated quadrilateral. */
        flipedge.org = farvertex
        flipedge.dest = botvertex
        flipedge.apex = rightvertex
        top.org = botvertex
        top.dest = farvertex
        top.apex = leftvertex
        if b.verbose {
            print("  Edge flip results in left ")
            printtriangle(t: top)
            print("  and right ")
            printtriangle(t: flipedge)
        }
    }

    private func delaunayfixup(fixuptri: inout OrientedTriangle, leftside: Bool) {

        var neartri = fixuptri.lnext()
        var fartri = neartri.sym()
        /* Check if the edge opposite the origin of fixuptri can be flipped. */
        if fartri.triangle === m.dummytri {
            return
        }
        let faredge = neartri.tspivot()
        if faredge.subsegment !== m.dummysub {
            return
        }
        /* Find all the relevant vertices. */
        let nearvertex = m.vertices[neartri.apex]
        let leftvertex = m.vertices[neartri.org]
        let rightvertex = m.vertices[neartri.dest]
        let farvertex = m.vertices[fartri.apex]
        /* Check whether the previous polygon vertex is a reflex vertex. */
        if leftside {
            if predicates.counterClockwise(a: nearvertex, b: leftvertex, c: farvertex) <= 0.0 {
                /* leftvertex is a reflex vertex too.  Nothing can */
                /*   be done until a convex section is found.      */
                return
            }
        } else {
            if predicates.counterClockwise(a: farvertex, b: rightvertex, c: nearvertex) <= 0.0 {
                /* rightvertex is a reflex vertex too.  Nothing can */
                /*   be done until a convex section is found.       */
                return
            }
        }
        if predicates.counterClockwise(a: rightvertex, b: leftvertex, c: farvertex) > 0.0 {
            /* fartri is not an inverted triangle, and farvertex is not a reflex */
            /*   vertex.  As there are no reflex vertices, fixuptri isn't an     */
            /*   inverted triangle, either.  Hence, test the edge between the    */
            /*   triangles to ensure it is locally Delaunay.                     */
            if predicates.inCircle(a: leftvertex.vert, b: farvertex.vert, c: rightvertex.vert, d: nearvertex.vert) <=
                0.0 {
                return
            }
            /* Not locally Delaunay; go on to an edge flip. */
        }        /* else fartri is inverted; remove it from the stack by flipping. */
        flip(flipedge: &neartri)
        fixuptri.lprevself();    /* Restore the origin of fixuptri after the flip. */
        /* Recursively process the two triangles that result from the flip. */
        delaunayfixup(fixuptri: &fixuptri, leftside: leftside)
        delaunayfixup(fixuptri: &fartri, leftside: leftside)
    }

    /* Labels that signify the result of point location.  The result of a        */
    /*   search indicates that the point falls in the interior of a triangle, on */
    /*   an edge, on a vertex, or outside the mesh.                              */

    enum LocateResult {
        case inTriangle
        case onEdge
        case onVertex
        case outside

    }

    private func locate(searchpoint: Vertex, searchtri: inout OrientedTriangle) -> LocateResult {

        if b.verbose {
            print("  Randomly sampling for a triangle near point (\(searchpoint.x), \(searchpoint.y)).")
        }
        /* Record the distance from the suggested starting triangle to the */
        /*   point we seek.                                                */
        var torg = m.vertices[searchtri.org]
        let dx = (searchpoint.x - torg.x)
        let dy = (searchpoint.y - torg.y)
        var searchdist = (dx * dx) + (dy * dy)
        if b.verbose {
            print("    Boundary triangle has origin (\( torg.x), \(torg.y)).")
        }

        /* If a recently encountered triangle has been recorded and has not been */
        /*   deallocated, test it as a good starting point.                      */
        if let recent = m.recenttri, !recent.triangle.isDead {
            torg = m.vertices[recent.org]
            if (torg.x == searchpoint.x) && (torg.y == searchpoint.y) {
                searchtri = recent
                return .onVertex
            }

            let dist = (searchpoint.x - torg.x) * (searchpoint.x - torg.x) +
                (searchpoint.y - torg.y) * (searchpoint.y - torg.y)
            if dist < searchdist {
                searchtri = recent
                searchdist = dist
                if b.verbose {
                    print("    Choosing recent triangle with origin (\(torg.x), \(torg.y)).")
                }
            }

        }
        var sampletri = OrientedTriangle(triangle: searchtri.triangle, orientation: 0)
        for triange in m.triangles {
            sampletri.triangle = triange
            torg = m.vertices[sampletri.org]
            let dist = (searchpoint.x - torg.x) * (searchpoint.x - torg.x) + (searchpoint.y - torg.y) * (searchpoint.y - torg.y)
            if dist < searchdist {
                sampletri.copy(to: &searchtri)
                searchdist = dist
                if b.verbose {
                    print("    Choosing triangle with origin (\(torg.x), \(torg.y)).")
                }
            }

        }

        /* Where are we? */
        torg = m.vertices[searchtri.org]
        let tdest = m.vertices[searchtri.dest]
        /* Check the starting triangle's vertices. */
        if (torg.x == searchpoint.x) && (torg.y == searchpoint.y) {
            return .onVertex
        }
        if (tdest.x == searchpoint.x) && (tdest.y == searchpoint.y) {
            searchtri.lnextself()
            return .onVertex
        }
        /* Orient `searchtri' to fit the preconditions of calling preciselocate(). */
        let ahead = predicates.counterClockwise(a: torg, b: tdest, c: searchpoint)
        if ahead < 0.0 {
            /* Turn around so that `searchpoint' is to the left of the */
            /*   edge specified by `searchtri'.                        */
            searchtri.symself()
        } else if ahead == 0.0 {
            //             Check if `searchpoint' is between `torg' and `tdest'.
            if ((torg.x < searchpoint.x) == (searchpoint.x < tdest.x)) && ((torg.y < searchpoint.y) == (searchpoint.y < tdest.y)) {
                return .onEdge
            }
        }
        return preciselocate(searchpoint: searchpoint, searchtri: &searchtri, stopatsubsegment: false)
    }

    private func preciselocate(searchpoint: Vertex, searchtri: inout OrientedTriangle, stopatsubsegment: Bool) -> LocateResult {

        if b.verbose {
            print("  Searching for point ( \(searchpoint.x), \(searchpoint.y)).")
        }
        /* Where are we? */
        var forg = m.vertices[searchtri.org]
        var fdest = m.vertices[searchtri.dest]
        var fapex = m.vertices[searchtri.apex]
        while true {
            if b.verbose {
                print("    At ( \(forg.x), \(forg.y)) (\(fdest.x), \(fdest.y)) (\(fapex.x), \(fapex.y))")
            }
            /* Check whether the apex is the point we seek. */
            if (fapex.x == searchpoint.x) && (fapex.y == searchpoint.y) {
                searchtri.lprevself()
                return .onVertex
            }
            /* Does the point lie on the other side of the line defined by the */
            /*   triangle edge opposite the triangle's destination?            */
            let destorient = predicates.counterClockwise(a: forg, b: fapex, c: searchpoint)
            /* Does the point lie on the other side of the line defined by the */
            /*   triangle edge opposite the triangle's origin?                 */
            let orgorient = predicates.counterClockwise(a: fapex, b: fdest, c: searchpoint)
            let moveleft: Bool
            if destorient > 0.0 {
                if orgorient > 0.0 {
                    /* Move left if the inner product of (fapex - searchpoint) and  */
                    /*   (fdest - forg) is positive.  This is equivalent to drawing */
                    /*   a line perpendicular to the line (forg, fdest) and passing */
                    /*   through `fapex', and determining which side of this line   */
                    /*   `searchpoint' falls on.                                    */
                    moveleft = (fapex.x - searchpoint.x) * (fdest.x - forg.x) + (fapex.y - searchpoint.y) * (fdest.y - forg.y) > 0.0
                } else {
                    moveleft = true
                }
            } else {
                if orgorient > 0.0 {
                    moveleft = false
                } else {
                    /* The point we seek must be on the boundary of or inside this */
                    /*   triangle.                                                 */
                    if destorient == 0.0 {
                        searchtri.lprevself()
                        return .onEdge
                    }
                    if orgorient == 0.0 {
                        searchtri.lnextself()
                        return .onEdge
                    }
                    return .inTriangle
                }
            }

            var backtracktri = searchtri.copy()
            /* Move to another triangle.  Leave a trace `backtracktri' in case */
            /*   floating-point roundoff or some such bogey causes us to walk  */
            /*   off a boundary of the triangulation.                          */
            if moveleft {
                searchtri.lprev(on: &backtracktri)
                fdest = fapex
            } else {
                searchtri.lnext(on: &backtracktri)
                forg = fapex
            }
            backtracktri.sym(to: &searchtri)

            if m.checksegments && stopatsubsegment {
                /* Check for walking through a subsegment. */
                let checkedge = backtracktri.tspivot()
                if checkedge.subsegment !== m.dummysub {
                    /* Go back to the last triangle. */
                    backtracktri.copy(to: &searchtri)

                    return .outside
                }
            }
            /* Check for walking right out of the triangulation. */
            if searchtri.triangle === m.dummytri {
                /* Go back to the last triangle. */
                backtracktri.copy(to: &searchtri)
                return .outside
            }

            fapex = m.vertices[searchtri.apex]
        }
    }

    private func scoutsegment(searchtri: inout OrientedTriangle, endpoint2: Vertex, newmark: Int) -> Bool {

        let collinear = finddirection(searchtri: &searchtri, searchpoint: endpoint2)
        let rightvertex = m.vertices[searchtri.dest]
        let leftvertex = m.vertices[searchtri.apex]
        if ((leftvertex.x == endpoint2.x) && (leftvertex.y == endpoint2.y)) || ((rightvertex.x == endpoint2.x) && (rightvertex.y == endpoint2.y)) {
            /* The segment is already an edge in the mesh. */
            if (leftvertex.x == endpoint2.x) && (leftvertex.y == endpoint2.y) {
                searchtri.lprevself()
            }
            /* Insert a subsegment, if there isn't already one there. */
            insertsubseg(tri: searchtri, subsegmark: newmark)
            return true
        } else if collinear == .leftCollinear {
            /* We've collided with a vertex between the segment's endpoints. */
            /* Make the collinear vertex be the triangle's origin. */
            searchtri.lprevself()
            insertsubseg(tri: searchtri, subsegmark: newmark)
            /* Insert the remainder of the segment. */
            return scoutsegment(searchtri: &searchtri, endpoint2: endpoint2, newmark: newmark)
        } else if collinear == .rightCollinear {
            /* We've collided with a vertex between the segment's endpoints. */
            insertsubseg(tri: searchtri, subsegmark: newmark)
            /* Make the collinear vertex be the triangle's origin. */
            searchtri.lnextself()
            /* Insert the remainder of the segment. */
            return scoutsegment(searchtri: &searchtri, endpoint2: endpoint2, newmark: newmark)
        } else {
            var crosstri = searchtri.lnext()
            var crosssubseg = crosstri.tspivot()

            /* Check for a crossing segment. */
            if crosssubseg.subsegment === m.dummysub {
                return false
            } else {
                /* Insert a vertex at the intersection. */
                segmentintersection(splittri: &crosstri, splitsubseg: &crosssubseg, endpoint2: endpoint2)
                searchtri = crosstri
                insertsubseg(tri: searchtri, subsegmark: newmark)
                /* Insert the remainder of the segment. */
                return scoutsegment(searchtri: &searchtri, endpoint2: endpoint2, newmark: newmark)
            }
        }
    }

    private func segmentintersection(splittri: inout OrientedTriangle, splitsubseg: inout OrientedSubsegment, endpoint2: Vertex) {

        /* Find the other three segment endpoints. */
        let endpoint1 = m.vertices[splittri.apex]
        let torg = m.vertices[splittri.org]
        let tdest = m.vertices[splittri.dest]
        /* Segment intersection formulae; see the Antonio reference. */
        let tx = tdest.x - torg.x
        let ty = tdest.y - torg.y
        let ex = endpoint2.x - endpoint1.x
        let ey = endpoint2.y - endpoint1.y
        let etx = torg.x - endpoint2.x
        let ety = torg.y - endpoint2.y
        let denom = ty * ex - tx * ey
        if denom == 0.0 {
            print("Internal error in segmentintersection():")
            print("  Attempt to find intersection of parallel segments.\n")
            fatalError("Internal error in segmentintersection()")
        }
        let split = (ey * etx - ex * ety) / denom

        /* Interpolate its coordinate and attributes. */
        let x = torg.x + split * (tdest.x - torg.x)
        let y = torg.y + split * (tdest.y - torg.y)
        //        let z = torg.z + split * (tdest.z - torg.z);

        /* Create the new vertex. */
        var newvertex = m.createVertex(x: x, y: y)

        if m.nextras > 1 {
            print("THIS NEED TO BE FIXED!")
            //        ORIGINAL CODE:
            //        for (i = 0; i < 2 + m.nextras; i++) {
            //            newvertex[i] = torg[i] + split * (tdest[i] - torg[i]);
            //        }
        }

        newvertex.mark = splitsubseg.mark
        newvertex.state = .input
        if b.verbose {
            print("  Splitting subsegment (\(torg.x), \(torg.y)) (\(tdest.x), \(tdest.y)) at (\(newvertex.x), \(newvertex.y)).")
        }
        /* Insert the intersection vertex.  This should always succeed. */
        let success = insertvertex(newvertex: newvertex, searchtri: &splittri, splitseg: splitsubseg, segmentflaws: false, triflaws: false)
        if success != .successful {
            print("Internal error in segmentintersection():\n")
            print("  Failure to split a segment.\n")
            fatalError("Internal error in segmentintersection \(#line)")
        }
        /* Record a triangle whose origin is the new vertex. */
        newvertex.triangle = Vertex.TriIndex(id: splittri.triangle.id, orientation: splittri.orientation)
        if m.steinerleft > 0 {
            m.steinerleft -= 1
        }

        m.vertices[newvertex.id] = newvertex
        /* Divide the segment into two, and correct the segment endpoints. */

        splitsubseg.ssymself()
        var opposubseg = splitsubseg.spivot()
        splitsubseg.sdissolve(m: m)
        opposubseg.sdissolve(m: m)

        repeat {
            splitsubseg.segorg = newvertex.id
            splitsubseg.snextself()
        } while (splitsubseg.subsegment !== m.dummysub)
        repeat {
            opposubseg.segorg = newvertex.id
            opposubseg.snextself()
        } while (opposubseg.subsegment !== m.dummysub)

        /* Inserting the vertex may have caused edge flips.  We wish to rediscover */
        /*   the edge connecting endpoint1 to the new intersection vertex.         */
        _ = finddirection(searchtri: &splittri, searchpoint: endpoint1)
        let rightvertex = m.vertices[splittri.dest]
        let leftvertex = m.vertices[splittri.apex]
        if (leftvertex.x == endpoint1.x) && (leftvertex.y == endpoint1.y) {
            splittri.onextself()
        } else if (rightvertex.x != endpoint1.x) || (rightvertex.y != endpoint1.y) {
            print("Internal error in segmentintersection():\n")
            print("  Topological inconsistency after splitting a segment.\n")
            fatalError("Internal error in segmentintersection")
        }
        /* `splittri' should have destination endpoint1. */
    }

    enum FindDirectionResult {
        case within
        case leftCollinear
        case rightCollinear
    }

    private func finddirection(searchtri: inout OrientedTriangle, searchpoint: Vertex) -> FindDirectionResult {

        let startvertex = m.vertices[searchtri.org]
        var rightvertex = m.vertices[searchtri.dest]
        var leftvertex = m.vertices[searchtri.apex]
        /* Is `searchpoint' to the left? */
        var leftccw = predicates.counterClockwise(a: searchpoint, b: startvertex, c: leftvertex)
        var leftflag = leftccw > 0.0
        /* Is `searchpoint' to the right? */
        var rightccw = predicates.counterClockwise(a: startvertex, b: searchpoint, c: rightvertex)
        var rightflag = rightccw > 0.0
        if leftflag && rightflag {
            /* `searchtri' faces directly away from `searchpoint'.  We could go left */
            /*   or right.  Ask whether it's a triangle or a boundary on the left.   */
            let checktri = searchtri.onext()
            if checktri.triangle === m.dummytri {
                leftflag = false
            } else {
                rightflag = false
            }
        }
        while leftflag {
            /* Turn left until satisfied. */
            searchtri.onextself()
            if searchtri.triangle === m.dummytri {
                print("Internal error in finddirection():  Unable to find a\n")
                print("  triangle leading from (\(startvertex.x),\(startvertex.y)) to  (\(searchpoint.x), \(searchpoint.y))." )
                fatalError("Invalid")
            }
            leftvertex = m.vertices[searchtri.apex]
            rightccw = leftccw
            leftccw = predicates.counterClockwise(a: searchpoint, b: startvertex, c: leftvertex)
            leftflag = leftccw > 0.0
        }
        while rightflag {
            /* Turn right until satisfied. */
            searchtri.oprevself()
            if searchtri.triangle === m.dummytri {
                print("Internal error in finddirection():  Unable to find a\n")
                print("  triangle leading from (\(startvertex.x),\(startvertex.y)) to  (\(searchpoint.x), \(searchpoint.y))." )
                fatalError("Invalid")
            }
            rightvertex = m.vertices[searchtri.dest]
            leftccw = rightccw
            rightccw = predicates.counterClockwise(a: startvertex, b: searchpoint, c: rightvertex)
            rightflag = rightccw > 0.0
        }
        if leftccw == 0.0 {
            return .leftCollinear
        } else if rightccw == 0.0 {
            return .rightCollinear
        } else {
            return .within
        }
    }

    private func insertsubseg(tri: OrientedTriangle, subsegmark: Int) {

        let triorg = tri.org
        let tridest = tri.dest
        /* Mark vertices if possible. */
        if triorg >= 0, m.vertices[triorg].mark == 0 {
            m.vertices[triorg].mark = subsegmark
        }
        if tridest >= 0, m.vertices[tridest].mark == 0 {
            m.vertices[tridest].mark = subsegmark
        }
        /* Check if there's already a subsegment here. */
        var newsubseg = tri.tspivot()
        if newsubseg.subsegment === m.dummysub {
            /* Make new subsegment and initialize its vertices. */
            var newsubseg = m.makesubseg()
            newsubseg.sorg = tridest
            newsubseg.sdest = triorg
            newsubseg.segorg = tridest
            newsubseg.segdest = triorg

            /* Bond new subsegment to the two triangles it is sandwiched between. */
            /*   Note that the facing triangle `oppotri' might be equal to        */
            /*   `dummytri' (outer space), but the new subsegment is bonded to it */
            /*   all the same.                                                    */

            tri.tsbond(to: newsubseg)
            let oppotri = tri.sym()
            newsubseg.ssymself()
            oppotri.tsbond(to: newsubseg)
            newsubseg.mark = subsegmark
            if b.verbose {
                print("  Inserting new ")
                printsubseg(s: newsubseg)
            }
        } else {
            if newsubseg.mark == 0 {
                newsubseg.mark = subsegmark
            }
        }
    }

    private func printsubseg(s: OrientedSubsegment) {
        print("subsegment \(s.subsegment) with orientation \(s.orient) and mark \(s.subsegment.marker):")

        if let printsh = s.subsegment.adj1 {
            if printsh.ss === m.dummysub {
                print("    [0] = No subsegment")
            } else {
                print("    [0] = \(printsh.ss)  \(printsh.orientation)")
            }
        }

        if let printsh = s.subsegment.adj2 {
            if printsh.ss === m.dummysub {
                print("    [1] = No subsegment")
            } else {
                print("    [1] = \(printsh.ss)  \(printsh.orientation)")
            }
        }

        if s.sorg >= 0 {
            let printvertex = m.vertices[s.sorg]
            print("    Origin[\(2 + s.orient)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Origin[\(2 + s.orient)] = NULL")
        }

        if s.sdest >= 0 {
            let printvertex = m.vertices[s.sdest]
            print("    Dest  [\(3 - s.orient)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")

        } else {
            print("    Dest  [\(3 - s.orient)] = NULL")
        }

        if let printtri = s.subsegment.t1 {
            if printtri.triangle === m.dummytri {
                print("    [6] = Outer space")
            } else {
                print("    [6] = \(printtri.triangle)  \(printtri.orientation)")
            }
        }

        if let printtri = s.subsegment.t2 {
            if printtri.triangle === m.dummytri {
                print("    [7] = Outer space\n")
            } else {
                print("    [7] = \(printtri.triangle)  \(printtri.orientation)")
            }
        }

        if s.segorg >= 0 {
            let printvertex = m.vertices[s.segorg]
            print("    Segment origin[\(4 + s.orient)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Segment origin[\(4 + s.orient)] = NULL")
        }

        if s.segdest >= 0 {
            let printvertex = m.vertices[s.segdest]
            print("    Segment dest  [\(5 - s.orient)] = \(printvertex)  (\(printvertex.x), \(printvertex.y))")
        } else {
            print("    Segment dest  [\(5 - s.orient)] = NULL")
        }

    }

    enum InsertVertexResult {
        case successful
        case encroaching
        case violating
        case duplicate
    }

    private func insertvertex(newvertex: Vertex, searchtri: inout OrientedTriangle, splitseg: OrientedSubsegment?, segmentflaws: Bool, triflaws: Bool) -> InsertVertexResult {

        if b.verbose {
            print("  Inserting (\(newvertex.x), \(newvertex.y)).")
        }

        var intersect: LocateResult
        var horiz: OrientedTriangle

        if splitseg != nil {
            /* The calling routine provides the subsegment in which */
            /*   the vertex is inserted.                             */
            horiz = searchtri.copy()
            intersect = .onEdge
        } else {
            /* Find the location of the vertex to be inserted.  Check if a good */
            /*   starting triangle has already been provided by the caller.     */
            if searchtri.triangle === m.dummytri {
                /* Find a boundary triangle. */
                horiz = OrientedTriangle(triangle: m.dummytri, orientation: 0)
                horiz.symself()
                /* Search for a triangle containing `newvertex'. */
                intersect = locate(searchpoint: newvertex, searchtri: &horiz)
            } else {
                /* Start searching from the triangle provided by the caller. */
                horiz = searchtri.copy()
                intersect = preciselocate(searchpoint: newvertex, searchtri: &horiz, stopatsubsegment: true)
            }
        }

        if intersect == .onVertex {
            /* There's already a vertex there.  Return in `searchtri' a triangle */
            /*   whose origin is the existing vertex.                            */
            searchtri = horiz
            m.recenttri = horiz.copy()

            return .duplicate
        }

        if intersect == .onEdge || intersect == .outside {
            /* The vertex falls on an edge or boundary. */
            if m.checksegments && splitseg == nil {
                /* Check whether the vertex falls on a subsegment. */
                let brokensubseg = horiz.tspivot()
                if brokensubseg.subsegment !== m.dummysub {
                    /* The vertex falls on a subsegment, and hence will not be inserted. */
                    if segmentflaws {
                        var enq = b.nobisect != 2
                        if enq && (b.nobisect == 1) {
                            /* This subsegment may be split only if it is an */
                            /*   internal boundary.                          */

                            let testtri = horiz.sym()
                            enq = testtri.triangle !== m.dummytri
                        }

                        if enq {
                            /* Add the subsegment to the list of encroached subsegments. */
                            let encroached = m.createbadSubSeg(seg: brokensubseg.encodedSubsegment, org: brokensubseg.sorg, dest: brokensubseg.sdest)
                            if b.verbose {
                                let enc = m.vertices[encroached.subsegOrg]
                                let dest = m.vertices[encroached.subsegDest]
                                print("  Queueing encroached subsegment (\(enc.x), \(enc.y)) (\(dest.x), \(dest.y)).")
                            }
                        }
                    }
                    /* Return a handle whose primary edge contains the vertex, */
                    /*   which has not been inserted.                          */
                    searchtri = horiz
                    m.recenttri = horiz
                    return .violating
                }
            }

            /* Insert the vertex on an edge, dividing one triangle into two (if */
            /*   the edge lies on a boundary) or two triangles into four.       */

            let botright = horiz.lprev()
            let botrcasing = botright.sym()
            var topright = horiz.sym()
            var toprcasing: OrientedTriangle!
            var newtopright: OrientedTriangle!
            /* Is there a second triangle?  (Or does this edge lie on a boundary?) */
            let mirrorflag = topright.triangle !== m.dummytri
            if mirrorflag {
                topright.lnextself()
                toprcasing = topright.sym()
                newtopright = m.makeTriangle(b: b)
            } else {
                /* Splitting a boundary edge increases the number of boundary edges. */
                m.hullsize += 1
            }
            var newbotright = m.makeTriangle(b: b)

            /* Set the vertices of changed and new triangles. */
            let rightvertex = horiz.org
            //            var leftvertex = horiz.dest
            let botvertex = horiz.apex
            newbotright.org = botvertex
            newbotright.dest = rightvertex
            newbotright.apex = newvertex.id
            horiz.org = newvertex.id

            /* Set the element attributes of a new triangle. */
            //            newbotright.triangle.attributes = botright.triangle.attributes

            //            if (b.vararea) {
            //                /* Set the area constraint of a new triangle. */
            //                newbotright.triangle.area = botright.triangle.area
            //            }
            if mirrorflag {
                let topvertex = topright.dest
                newtopright.org = rightvertex
                newtopright.dest = topvertex
                newtopright.apex = newvertex.id
                topright.org = newvertex.id

                /* Set the element attributes of another new triangle. */
                //                newtopright.triangle.attributes = topright.triangle.attributes

                //                if b.vararea {
                //                    /* Set the area constraint of another new triangle. */
                //                    newtopright.triangle.area = topright.triangle.area
                //                }
            }

            /* There may be subsegments that need to be bonded */
            /*   to the new triangle(s).                       */
            if m.checksegments {
                let botrsubseg = botright.tspivot()
                if botrsubseg.subsegment !== m.dummysub {
                    botright.tsdissolve(m: m)
                    newbotright.tsbond(to: botrsubseg)

                }
                if mirrorflag {
                    let toprsubseg = topright.tspivot()
                    if toprsubseg.subsegment !== m.dummysub {
                        topright.tsdissolve(m: m)
                        newtopright.tsbond(to: toprsubseg)
                    }
                }
            }

            /* Bond the new triangle(s) to the surrounding triangles. */
            newbotright.bond(to: botrcasing)
            newbotright.lprevself()
            newbotright.bond(to: botright)
            newbotright.lprevself()
            if mirrorflag {
                newtopright.bond(to: toprcasing)
                newtopright.lnextself()
                newtopright.bond(to: topright)
                newtopright.lnextself()
                newtopright.bond(to: newbotright)
            }

            if var splitseg = splitseg {
                /* Split the subsegment into two. */
                splitseg.sdest = newvertex.id
                let segmentorg = splitseg.segorg
                let segmentdest = splitseg.segdest
                splitseg.ssymself()
                var rightsubseg = splitseg.spivot()
                insertsubseg(tri: newbotright, subsegmark: splitseg.mark)
                var newsubseg = newbotright.tspivot()
                newsubseg.segorg = segmentorg
                newsubseg.segdest = segmentdest
                splitseg.sbond(to: &newsubseg)

                newsubseg.ssymself()
                newsubseg.sbond(to: &rightsubseg)
                splitseg.ssymself()
                /* Transfer the subsegment's boundary marker to the vertex */
                /*   if required.                                          */
                if newvertex.mark == 0 {
                    m.vertices[newvertex.id].mark = splitseg.mark
                }
            }

            //            if (m.checkquality) {
            //                poolrestart(&m.flipstackers);
            //                m.lastflip = (struct flipstacker *) poolalloc(&m.flipstackers);
            //                m.lastflip->flippedtri = encode(horiz);
            //                m.lastflip->prevflip = (struct flipstacker *) &insertvertex;
            //            }

            //    #ifdef SELF_CHECK
            //            if (counterclockwise(m, b, rightvertex, leftvertex, botvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print(
            //                       "  Clockwise triangle prior to edge vertex insertion (bottom).\n");
            //            }
            //            if (mirrorflag) {
            //                if (counterclockwise(m, b, leftvertex, rightvertex, topvertex) < 0.0) {
            //                    print("Internal error in insertvertex():\n");
            //                    print("  Clockwise triangle prior to edge vertex insertion (top).\n");
            //                }
            //                if (counterclockwise(m, b, rightvertex, topvertex, newvertex) < 0.0) {
            //                    print("Internal error in insertvertex():\n");
            //                    print(
            //                           "  Clockwise triangle after edge vertex insertion (top right).\n");
            //                }
            //                if (counterclockwise(m, b, topvertex, leftvertex, newvertex) < 0.0) {
            //                    print("Internal error in insertvertex():\n");
            //                    print(
            //                           "  Clockwise triangle after edge vertex insertion (top left).\n");
            //                }
            //            }
            //            if (counterclockwise(m, b, leftvertex, botvertex, newvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print(
            //                       "  Clockwise triangle after edge vertex insertion (bottom left).\n");
            //            }
            //            if (counterclockwise(m, b, botvertex, rightvertex, newvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print(
            //                       "  Clockwise triangle after edge vertex insertion (bottom right).\n");
            //            }
            //    #endif /* SELF_CHECK */
            if b.verbose {
                print("  Updating bottom left ")
                printtriangle(t: botright)
                if mirrorflag {
                    print("  Updating top left ")
                    printtriangle(t: topright)
                    print("  Creating top right ")
                    printtriangle(t: newtopright)
                }
                print("  Creating bottom right ")
                printtriangle(t: newbotright)
            }

            /* Position `horiz' on the first edge to check for */
            /*   the Delaunay property.                        */
            horiz.lnextself()
        } else {
            /* Insert the vertex in a triangle, splitting it into three. */
            let botleft = horiz.lnext()
            let botright = horiz.lprev()
            let botlcasing = botleft.sym()
            let botrcasing = botright.sym()
            var newbotleft = m.makeTriangle(b: b)
            var newbotright = m.makeTriangle(b: b)

            /* Set the vertices of changed and new triangles. */
            let rightvertex = horiz.org
            let leftvertex = horiz.dest
            let botvertex = horiz.apex
            newbotleft.org = leftvertex
            newbotleft.dest = botvertex
            newbotleft.apex = newvertex.id
            newbotright.org = botvertex
            newbotright.dest = rightvertex
            newbotright.apex = newvertex.id
            horiz.apex = newvertex.id
            //            newbotleft.triangle.attributes = horiz.triangle.attributes
            //            newbotright.triangle.attributes = horiz.triangle.attributes

            //            if b.vararea {
            //                /* Set the area constraint of the new triangles. */
            //                let area = horiz.triangle.area
            //                newbotleft.triangle.area = area
            //                newbotright.triangle.area = area
            //            }

            /* There may be subsegments that need to be bonded */
            /*   to the new triangles.                         */
            if m.checksegments {
                let botlsubseg = botleft.tspivot()
                if botlsubseg.subsegment !== m.dummysub {
                    botleft.tsdissolve(m: m)
                    newbotleft.tsbond(to: botlsubseg)
                }
                let botrsubseg = botright.tspivot()
                if botrsubseg.subsegment !== m.dummysub {
                    botright.tsdissolve(m: m)
                    newbotright.tsbond(to: botrsubseg)

                }
            }

            /* Bond the new triangles to the surrounding triangles. */

            newbotleft.bond(to: botlcasing)
            newbotright.bond(to: botrcasing)
            newbotleft.lnextself()
            newbotright.lprevself()
            newbotleft.bond(to: newbotright)
            newbotleft.lnextself()
            botleft.bond(to: newbotleft)
            newbotright.lprevself()
            botright.bond(to: newbotright)

            //            if (m.checkquality) {
            //                poolrestart(&m.flipstackers);
            //                m.lastflip = (struct flipstacker *) poolalloc(&m.flipstackers);
            //                m.lastflip->flippedtri = encode(horiz);
            //                m.lastflip->prevflip = (struct flipstacker *) NULL;
            //            }

            //    #ifdef SELF_CHECK
            //            if (counterclockwise(m, b, rightvertex, leftvertex, botvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print("  Clockwise triangle prior to vertex insertion.\n");
            //            }
            //            if (counterclockwise(m, b, rightvertex, leftvertex, newvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print("  Clockwise triangle after vertex insertion (top).\n");
            //            }
            //            if (counterclockwise(m, b, leftvertex, botvertex, newvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print("  Clockwise triangle after vertex insertion (left).\n");
            //            }
            //            if (counterclockwise(m, b, botvertex, rightvertex, newvertex) < 0.0) {
            //                print("Internal error in insertvertex():\n");
            //                print("  Clockwise triangle after vertex insertion (right).\n");
            //            }
            //    #endif /* SELF_CHECK */
            if b.verbose {
                print("  Updating top ")
                printtriangle(t: horiz)
                print("  Creating left ")
                printtriangle(t: newbotleft)
                print("  Creating right ")
                printtriangle(t: newbotright)
            }
        }

        /* The insertion is successful by default, unless an encroached */
        /*   subsegment is found.                                       */
        var success = InsertVertexResult.successful
        /* Circle around the newly inserted vertex, checking each edge opposite */
        /*   it for the Delaunay property.  Non-Delaunay edges are flipped.     */
        /*   `horiz' is always the edge being checked.  `first' marks where to  */
        /*   stop circling.                                                     */
        let first = m.vertices[horiz.org]
        var rightvertex = first
        var leftvertex = m.vertices[horiz.dest]
        /* Circle until finished. */
        while true {
            /* By default, the edge will be flipped. */
            var doflip = true

            if m.checksegments {
                /* Check for a subsegment, which cannot be flipped. */
                let checksubseg = horiz.tspivot()
                if checksubseg.subsegment !== m.dummysub {
                    /* The edge is a subsegment and cannot be flipped. */
                    doflip = false
                    if segmentflaws {
                        /* Does the new vertex encroach upon this subsegment? */
                        if checkseg4encroach(testsubseg: checksubseg) != 0 {
                            success = .encroaching
                        }
                    }

                }
            }

            if doflip {
                /* Check if the edge is a boundary edge. */
                var top = horiz.sym()
                if top.triangle === m.dummytri {
                    /* The edge is a boundary edge and cannot be flipped. */
                    doflip = false
                } else {
                    /* Find the vertex on the other side of the edge. */
                    let farvertex = m.vertices[top.apex]
                    /* In the incremental Delaunay triangulation algorithm, any of      */
                    /*   `leftvertex', `rightvertex', and `farvertex' could be vertices */
                    /*   of the triangular bounding box.  These vertices must be        */
                    /*   treated as if they are infinitely distant, even though their   */
                    /*   "coordinates" are not.                                         */
                    if (leftvertex == m.infvertex1) || (leftvertex == m.infvertex2) || (leftvertex == m.infvertex3) {
                        /* `leftvertex' is infinitely distant.  Check the convexity of  */
                        /*   the boundary of the triangulation.  'farvertex' might be   */
                        /*   infinite as well, but trust me, this same condition should */
                        /*   be applied.                                                */
                        doflip = predicates.counterClockwise(a: newvertex, b: rightvertex, c: farvertex) > 0.0
                    } else if rightvertex == m.infvertex1 || rightvertex == m.infvertex2 || rightvertex == m.infvertex3 {
                        /* `rightvertex' is infinitely distant.  Check the convexity of */
                        /*   the boundary of the triangulation.  'farvertex' might be   */
                        /*   infinite as well, but trust me, this same condition should */
                        /*   be applied.                                                */
                        doflip = predicates.counterClockwise(a: farvertex, b: leftvertex, c: newvertex) > 0.0
                    } else if farvertex == m.infvertex1 || farvertex == m.infvertex2 || farvertex == m.infvertex3 {
                        /* `farvertex' is infinitely distant and cannot be inside */
                        /*   the circumcircle of the triangle `horiz'.            */
                        doflip = false
                    } else {
                        /* Test whether the edge is locally Delaunay. */
                        doflip = predicates.inCircle(a: leftvertex.vert, b: newvertex.vert, c: rightvertex.vert, d: farvertex.vert) > 0.0
                    }
                    if doflip {
                        /* We made it!  Flip the edge `horiz' by rotating its containing */
                        /*   quadrilateral (the two triangles adjacent to `horiz').      */
                        /* Identify the casing of the quadrilateral. */
                        var topleft = top.lprev()
                        let toplcasing = topleft.sym()
                        let topright = top.lnext()
                        let toprcasing = topright.sym()
                        let botleft = horiz.lnext()
                        let botlcasing = botleft.sym()
                        let botright = horiz.lprev()
                        let botrcasing = botright.sym()

                        /* Rotate the quadrilateral one-quarter turn counterclockwise. */
                        topleft.bond(to: botlcasing)
                        botleft.bond(to: botrcasing)
                        botright.bond(to: toprcasing)
                        topright.bond(to: toplcasing)
                        if m.checksegments {
                            /* Check for subsegments and rebond them to the quadrilateral. */
                            let toplsubseg = topleft.tspivot()
                            let botlsubseg = botleft.tspivot()
                            let botrsubseg = botright.tspivot()
                            let toprsubseg = topright.tspivot()
                            if toplsubseg.subsegment === m.dummysub {
                                topright.tsdissolve(m: m)
                            } else {
                                topright.tsbond(to: toplsubseg)
                            }
                            if botlsubseg.subsegment === m.dummysub {
                                topleft.tsdissolve(m: m)
                            } else {
                                topleft.tsbond(to: botlsubseg)
                            }
                            if botrsubseg.subsegment === m.dummysub {
                                botleft.tsdissolve(m: m)
                            } else {
                                botleft.tsbond(to: botrsubseg)
                            }
                            if toprsubseg.subsegment === m.dummysub {
                                botright.tsdissolve(m: m)
                            } else {
                                botright.tsbond(to: toprsubseg)
                            }
                        }
                        /* New vertex assignments for the rotated quadrilateral. */
                        horiz.org = farvertex.id
                        horiz.dest = newvertex.id
                        horiz.apex = rightvertex.id
                        top.org = newvertex.id
                        top.dest = farvertex.id
                        top.apex = leftvertex.id
                        //                        for i in 0..<m.eextras {
                        //                            /* Take the average of the two triangles' attributes. */
                        //                            let attrib = 0.5 * (top.triangle.attributes[i] + horiz.triangle.attributes[i]);
                        //                            top.triangle.attributes[i] = attrib
                        //                            horiz.triangle.attributes[i] = attrib
                        //                        }
                        //                        if b.vararea {
                        //                            let area: REAL
                        //                            if top.triangle.area <= 0.0 || horiz.triangle.area <= 0.0 {
                        //                                area = -1.0
                        //                            } else {
                        //                                /* Take the average of the two triangles' area constraints.    */
                        //                                /*   This prevents small area constraints from migrating a     */
                        //                                /*   long, long way from their original location due to flips. */
                        //                                area = 0.5 * (top.triangle.area + horiz.triangle.area);
                        //                            }
                        //                            top.triangle.area = area
                        //                            horiz.triangle.area = area
                        //                        }

                        //                        if (m.checkquality) {
                        //                            newflip = (struct flipstacker *) poolalloc(&m.flipstackers);
                        //                            newflip->flippedtri = encode(horiz);
                        //                            newflip->prevflip = m.lastflip;
                        //                            m.lastflip = newflip;
                        //                        }

                        //    #ifdef SELF_CHECK
                        //                        if (newvertex != (vertex) NULL) {
                        //                            if (counterclockwise(m, b, leftvertex, newvertex, rightvertex) <
                        //                                0.0) {
                        //                                print("Internal error in insertvertex():\n");
                        //                                print("  Clockwise triangle prior to edge flip (bottom).\n");
                        //                            }
                        //                            /* The following test has been removed because constrainededge() */
                        //                            /*   sometimes generates inverted triangles that insertvertex()  */
                        //                            /*   removes.                                                    */
                        //                            /*
                        //                             if (counterclockwise(m, b, rightvertex, farvertex, leftvertex) <
                        //                             0.0) {
                        //                             print("Internal error in insertvertex():\n");
                        //                             print("  Clockwise triangle prior to edge flip (top).\n");
                        //                             }
                        //                             */
                        //                            if (counterclockwise(m, b, farvertex, leftvertex, newvertex) <
                        //                                0.0) {
                        //                                print("Internal error in insertvertex():\n");
                        //                                print("  Clockwise triangle after edge flip (left).\n");
                        //                            }
                        //                            if (counterclockwise(m, b, newvertex, rightvertex, farvertex) <
                        //                                0.0) {
                        //                                print("Internal error in insertvertex():\n");
                        //                                print("  Clockwise triangle after edge flip (right).\n");
                        //                            }
                        //                        }
                        //    #endif /* SELF_CHECK */
                        if b.verbose {
                            print("  Edge flip results in left ")
                            topleft.lnextself()
                            printtriangle(t: topleft)
                            print("  and right ")
                            printtriangle(t: horiz)
                        }
                        /* On the next iterations, consider the two edges that were  */
                        /*   exposed (this is, are now visible to the newly inserted */
                        /*   vertex) by the edge flip.                               */
                        horiz.lprevself()
                        leftvertex = farvertex
                    }
                }
            }
            if !doflip {
                /* The handle `horiz' is accepted as locally Delaunay. */
                if triflaws {
                    /* Check the triangle `horiz' for quality. */
                    testtriangle(testtri: horiz)
                }

                /* Look for the next edge around the newly inserted vertex. */
                horiz.lnextself()
                let testtri = horiz.sym()
                /* Check for finishing a complete revolution about the new vertex, or */
                /*   falling outside  of the triangulation.  The latter will happen   */
                /*   when a vertex is inserted at a boundary.                         */
                if (leftvertex == first) || (testtri.triangle === m.dummytri) {
                    /* We're done.  Return a triangle whose origin is the new vertex. */
                    searchtri = horiz.lnext()
                    m.recenttri = horiz.lnext()
                    return success
                }
                /* Finish finding the next edge around the newly inserted vertex. */

                testtri.lnext(on: &horiz)
                rightvertex = leftvertex
                leftvertex = m.vertices[horiz.dest]
            }
        }
    }

    private func checkseg4encroach(testsubseg: OrientedSubsegment) -> Int {

        let eorg = m.vertices[testsubseg.sorg]
        let edest = m.vertices[testsubseg.sdest]
        /* Check one neighbor of the subsegment. */
        var neighbortri = testsubseg.stpivot()
        /* Does the neighbor exist, or is this a boundary edge? */
        var sides = 0

        var encroached = 0

        if neighbortri.triangle !== m.dummytri {
            sides += 1
            /* Find a vertex opposite this subsegment. */
            let eapex = m.vertices[neighbortri.apex]
            /* Check whether the apex is in the diametral lens of the subsegment */
            /*   (the diametral circle if `conformdel' is set).  A dot product   */
            /*   of two sides of the triangle is used to check whether the angle */
            /*   at the apex is greater than (180 - 2 `minangle') degrees (for   */
            /*   lenses; 90 degrees for diametral circles).                      */
            let dotproduct = (eorg.x - eapex.x) * (edest.x - eapex.x) + (eorg.y - eapex.y) * (edest.y - eapex.y)
            if dotproduct < 0.0 {
                if b.conformdel ||
                    (dotproduct * dotproduct >=
                        (2.0 * b.goodangle - 1.0) * (2.0 * b.goodangle - 1.0) *
                        ((eorg.x - eapex.x) * (eorg.x - eapex.x) +
                            (eorg.y - eapex.y) * (eorg.y - eapex.y)) *
                        ((edest.x - eapex.x) * (edest.x - eapex.x) +
                            (edest.y - eapex.y) * (edest.y - eapex.y))) {
                    encroached += 1
                }
            }
        }
        /* Check the other neighbor of the subsegment. */
        let testsym = testsubseg.ssym()
        neighbortri = testsym.stpivot()
        /* Does the neighbor exist, or is this a boundary edge? */
        if neighbortri.triangle !== m.dummytri {
            sides += 1
            /* Find the other vertex opposite this subsegment. */
            let eapex = m.vertices[neighbortri.apex]
            /* Check whether the apex is in the diametral lens of the subsegment */
            /*   (or the diametral circle, if `conformdel' is set).              */
            let dotproduct = (eorg.x - eapex.x) * (edest.x - eapex.x) + (eorg.y - eapex.y) * (edest.y - eapex.y)
            if dotproduct < 0.0 {
                if b.conformdel ||
                    (dotproduct * dotproduct >=
                        (2.0 * b.goodangle - 1.0) * (2.0 * b.goodangle - 1.0) *
                        ((eorg.x - eapex.x) * (eorg.x - eapex.x) +
                            (eorg.y - eapex.y) * (eorg.y - eapex.y)) *
                        ((edest.x - eapex.x) * (edest.x - eapex.x) +
                            (edest.y - eapex.y) * (edest.y - eapex.y))) {
                    encroached += 2
                }
            }
        }

        if encroached != 0 && (b.nobisect == 0 || ((b.nobisect == 1) && (sides == 2))) {
            if b.verbose {
                print("  Queueing encroached subsegment (\(eorg.x), \(eorg.y)) (\(edest.x),\(edest.y)).")
            }
            /* Add the subsegment to the list of encroached subsegments. */
            /*   Be sure to get the orientation right.                   */

            if encroached == 1 {
                _ = m.createbadSubSeg(seg: testsubseg.encodedSubsegment, org: eorg.id, dest: edest.id)
            } else {
                _ = m.createbadSubSeg(seg: testsym.encodedSubsegment, org: edest.id, dest: eorg.id)
            }
        }

        return encroached
    }

    private func testtriangle(testtri: OrientedTriangle) {

        let torg = m.vertices[testtri.org]
        let tdest = m.vertices[testtri.dest]
        let tapex = m.vertices[testtri.apex]
        let dxod = torg.x - tdest.x
        let dyod = torg.y - tdest.y
        let dxda = tdest.x - tapex.x
        let dyda = tdest.y - tapex.y
        let dxao = tapex.x - torg.x
        let dyao = tapex.y - torg.y
        let dxod2 = dxod * dxod
        let dyod2 = dyod * dyod
        let dxda2 = dxda * dxda
        let dyda2 = dyda * dyda
        let dxao2 = dxao * dxao
        let dyao2 = dyao * dyao
        /* Find the lengths of the triangle's three edges. */
        let apexlen = dxod2 + dyod2
        let orglen = dxda2 + dyda2
        let destlen = dxao2 + dyao2

        var tri1: OrientedTriangle
        let base1: Vertex
        let base2: Vertex
        var angle: REAL
        let minedge: REAL
        if (apexlen < orglen) && (apexlen < destlen) {
            /* The edge opposite the apex is shortest. */
            minedge = apexlen
            /* Find the square of the cosine of the angle at the apex. */
            angle = dxda * dxao + dyda * dyao
            angle = angle * angle / (orglen * destlen)
            base1 = torg
            base2 = tdest
            tri1 = testtri.copy()
        } else if orglen < destlen {
            /* The edge opposite the origin is shortest. */
            minedge = orglen
            /* Find the square of the cosine of the angle at the origin. */
            angle = dxod * dxao + dyod * dyao
            angle = angle * angle / (apexlen * destlen)
            base1 = tdest
            base2 = tapex
            tri1 = testtri.lnext()
        } else {
            /* The edge opposite the destination is shortest. */
            minedge = destlen
            /* Find the square of the cosine of the angle at the destination. */
            angle = dxod * dxda + dyod * dyda
            angle = angle * angle / (apexlen * orglen)
            base1 = tapex
            base2 = torg
            tri1 = testtri.lprev()
        }

        if b.vararea || b.fixedarea || b.usertest {
            print("TODO FIX THIS:\(minedge)  \(#file) \(#line)")
            //            /* Check whether the area is larger than permitted. */
            //            let area = 0.5 * (dxod * dyda - dyod * dxda);
            //            if (b.fixedarea && (area > b.maxarea)) {
            //                /* Add this triangle to the list of bad triangles. */
            //                enqueuebadtri(m, b, testtri, minedge, tapex, torg, tdest);
            //                return;
            //            }
            //
            //            /* Nonpositive area constraints are treated as unconstrained. */
            //            if ((b.vararea) && (area > testtri.triangle.area) &&
            //                (testtri.triangle.area > 0.0)) {
            //                /* Add this triangle to the list of bad triangles. */
            //                enqueuebadtri(m, b, testtri, minedge, tapex, torg, tdest);
            //                return;
            //            }
            //
            //            if (b.usertest) {
            //                /* Check whether the user thinks this triangle is too large. */
            //                if (triunsuitable(torg, tdest, tapex, area)) {
            //                    enqueuebadtri(m, b, testtri, minedge, tapex, torg, tdest);
            //                    return;
            //                }
            //            }
        }

        /* Check whether the angle is smaller than permitted. */
        if angle > b.goodangle {
            /* Use the rules of Miller, Pav, and Walkington to decide that certain */
            /*   triangles should not be split, even if they have bad angles.      */
            /*   A skinny triangle is not split if its shortest edge subtends a    */
            /*   small input angle, and both endpoints of the edge lie on a        */
            /*   concentric circular shell.  For convenience, I make a small       */
            /*   adjustment to that rule:  I check if the endpoints of the edge    */
            /*   both lie in segment interiors, equidistant from the apex where    */
            /*   the two segments meet.                                            */
            /* First, check if both points lie in segment interiors.               */
            if base1.state == .segment && base2.state == .segment {
                /* Check if both points lie in a common segment.  If they do, the */
                /*   skinny triangle is enqueued to be split as usual.            */
                var testsub = tri1.tspivot()
                if testsub.subsegment === m.dummysub {
                    /* No common segment.  Find a subsegment that contains `torg'. */
                    var tri2 = tri1.copy()
                    repeat {
                        tri1.oprevself()
                        testsub = tri1.tspivot()
                    } while (testsub.subsegment === m.dummysub)
                    /* Find the endpoints of the containing segment. */
                    let org1 = testsub.segorg
                    let dest1 = testsub.segdest
                    /* Find a subsegment that contains `tdest'. */
                    repeat {
                        tri2.dnextself()
                        testsub = tri2.tspivot()
                    } while (testsub.subsegment === m.dummysub)
                    /* Find the endpoints of the containing segment. */
                    let org2 = testsub.segorg
                    let dest2 = testsub.segdest
                    /* Check if the two containing segments have an endpoint in common. */
                    var joinvertex: Vertex?
                    if m.vertices[dest1].x == m.vertices[org2].x && m.vertices[dest1].y == m.vertices[org2].y {
                        joinvertex = m.vertices[dest1]
                    } else if m.vertices[org1].x == m.vertices[dest2].x && m.vertices[org1].y == m.vertices[dest2].y {
                        joinvertex = m.vertices[org1]
                    }
                    if let joinvertex = joinvertex {
                        /* Compute the distance from the common endpoint (of the two  */
                        /*   segments) to each of the endpoints of the shortest edge. */
                        let dist1 = ((base1.x - joinvertex.x) * (base1.x - joinvertex.x) +
                            (base1.y - joinvertex.y) * (base1.y - joinvertex.y))
                        let dist2 = ((base2.x - joinvertex.x) * (base2.x - joinvertex.x) +
                            (base2.y - joinvertex.y) * (base2.y - joinvertex.y))
                        /* If the two distances are equal, don't split the triangle. */
                        if (dist1 < 1.001 * dist2) && (dist1 > 0.999 * dist2) {
                            /* Return now to avoid enqueueing the bad triangle. */
                            return
                        }
                    }
                }
            }

            /* Add this triangle to the list of bad triangles. */
            print("TODO FIX THIS: enqueuebadtri(m, b, testtri, minedge, tapex, torg, tdest);")
            //            enqueuebadtri(m, b, testtri, minedge, tapex, torg, tdest);
        }
    }

    private func carveholes(holelist: [Vector2], regionlist: [REAL]) {

        if !(b.quiet || (b.noholes && b.convex)) {
            print("Removing unwanted triangles.")
            if b.verbose && (holelist.count > 0) {
                print("  Marking holes for elimination.")
            }
        }

        //        if (regionlist.count > 0) {
        //            /* Allocate storage for the triangles in which region points fall. */
        //            regiontris = (struct otri *) trimalloc(regions *
        //                                                   (int) sizeof(struct otri));
        //        } else {
        //            regiontris = (struct otri *) NULL;
        //        }

        //        if (((holes > 0) && !b->noholes) || !b->convex || (regions > 0)) {
        //            /* Initialize a pool of viri to be used for holes, concavities, */
        //            /*   regional attributes, and/or regional area constraints.     */
        //            poolinit(&m->viri, sizeof(triangle *), VIRUSPERBLOCK, VIRUSPERBLOCK, 0);
        //        }

        if !b.convex {
            /* Mark as infected any unprotected triangles on the boundary. */
            /*   This is one way by which concavities are created.         */
            infecthull(m: m, b: b)
        }

        if holelist.count > 0 && !b.noholes {
            /* Infect each triangle in which a hole lies. */
            for vert in holelist {
                /* Ignore holes that aren't within the bounds of the mesh. */
                if (vert.x >= m.xmin) && (vert.x <= m.xmax) && (vert.y >= m.ymin) && (vert.y <= m.ymax) {
                    /* Start searching from some triangle on the outer boundary. */
                    var searchtri = OrientedTriangle(triangle: m.dummytri, orientation: 0)
                    searchtri.symself()

                    /* Ensure that the hole is to the left of this boundary edge; */
                    /*   otherwise, locate() will falsely report that the hole    */
                    /*   falls within the starting triangle.                      */
                    let searchorg = m.vertices[searchtri.org]
                    let searchdest = m.vertices[searchtri.dest]
                    let tmpVert = Vertex(id: -1, x: vert.x, y: vert.y)
                    if predicates.counterClockwise(a: searchorg, b: searchdest, c: tmpVert) > 0.0 {
                        /* Find a triangle that contains the hole. */
                        let intersect = locate(searchpoint: tmpVert, searchtri: &searchtri)
                        if (intersect != .outside) && (!m.triangles[searchtri.id].infected) {
                            /* Infect the triangle.  This is done by marking the triangle  */
                            /*   as infected and including the triangle in the virus pool. */
                            m.triangles[searchtri.id].infected = true
                            m.viri.append(searchtri.triangle)
                        }
                    }
                }
            }
        }

        //        /* Now, we have to find all the regions BEFORE we carve the holes, because */
        //        /*   locate() won't work when the triangulation is no longer convex.       */
        //        /*   (Incidentally, this is the reason why regional attributes and area    */
        //        /*   constraints can't be used when refining a preexisting mesh, which     */
        //        /*   might not be convex; they can only be used with a freshly             */
        //        /*   triangulated PSLG.)                                                   */
        //        if (regions > 0) {
        //            /* Find the starting triangle for each region. */
        //            for (i = 0; i < regions; i++) {
        //                regiontris[i].tri = m->dummytri;
        //                /* Ignore region points that aren't within the bounds of the mesh. */
        //                if ((regionlist[4 * i] >= m->xmin) && (regionlist[4 * i] <= m->xmax) &&
        //                    (regionlist[4 * i + 1] >= m->ymin) &&
        //                    (regionlist[4 * i + 1] <= m->ymax)) {
        //                    /* Start searching from some triangle on the outer boundary. */
        //                    searchtri.tri = m->dummytri;
        //                    searchtri.orient = 0;
        //                    symself(&searchtri);
        //                    /* Ensure that the region point is to the left of this boundary */
        //                    /*   edge; otherwise, locate() will falsely report that the     */
        //                    /*   region point falls within the starting triangle.           */
        //                    searchorg = org(searchtri);
        //                    searchdest = dest(searchtri);
        //                    struct vertex tmpVert = (struct vertex) {regionlist[4 * i], regionlist[4 * i + 1] };
        //                    if (counterclockwise(m, b, *searchorg, *searchdest, tmpVert) >
        //                        0.0) {
        //                        /* Find a triangle that contains the region point. */
        //                        intersect = locate(m, b, &tmpVert, &searchtri);
        //                        if ((intersect != OUTSIDE) && (!infected(&searchtri))) {
        //                            /* Record the triangle for processing after the */
        //                            /*   holes have been carved.                    */
        //                            otricopy(&searchtri, &regiontris[i]);
        //                        }
        //                    }
        //                }
        //            }
        //        }

        if m.viri.count > 0 {
            /* Carve the holes and concavities. */
            plague(m: m, b: b)
        }
        /* The virus pool should be empty now. */
        //
        //        if (regions > 0) {
        //            if (!b->quiet) {
        //                if (b->regionattrib) {
        //                    if (b->vararea) {
        //                        printf("Spreading regional attributes and area constraints.\n");
        //                    } else {
        //                        printf("Spreading regional attributes.\n");
        //                    }
        //                } else {
        //                    printf("Spreading regional area constraints.\n");
        //                }
        //            }
        //            if (b->regionattrib && !b->refine) {
        //                /* Assign every triangle a regional attribute of zero. */
        //                traversalinit(&m->triangles);
        //                triangleloop.orient = 0;
        //                triangleloop.tri = triangletraverse(m);
        //                while (triangleloop.tri != (triangle *) NULL) {
        //                    setelemattribute(&triangleloop, m->eextras, 0.0);
        //                    triangleloop.tri = triangletraverse(m);
        //                }
        //            }
        //            for (i = 0; i < regions; i++) {
        //                if (regiontris[i].tri != m->dummytri) {
        //                    /* Make sure the triangle under consideration still exists. */
        //                    /*   It may have been eaten by the virus.                   */
        //                    if (!deadtri(regiontris[i].tri)) {
        //                        /* Put one triangle in the virus pool. */
        //                        infect(&regiontris[i]);
        //                        regiontri = (triangle **) poolalloc(&m->viri);
        //                        *regiontri = regiontris[i].tri;
        //                        /* Apply one region's attribute and/or area constraint. */
        //                        regionplague(m, b, regionlist[4 * i + 2], regionlist[4 * i + 3]);
        //                        /* The virus pool should be empty now. */
        //                    }
        //                }
        //            }
        //            if (b->regionattrib && !b->refine) {
        //                /* Note the fact that each triangle has an additional attribute. */
        //                m->eextras++;
        //            }
        //        }
    }

    private func infecthull(m: Mesh, b: Behavior) {
        if b.verbose {
            print("  Marking concavities (external triangles) for elimination.")
        }
        /* Find a triangle handle on the hull. */
        var hulltri = OrientedTriangle(triangle: m.dummytri, orientation: 0)
        hulltri.symself()

        /* Remember where we started so we know when to stop. */
        let starttri = hulltri.copy()

        /* Go once counterclockwise around the convex hull. */
        repeat {
            /* Ignore triangles that are already infected. */
            if !m.triangles[hulltri.id].infected {
                /* Is the triangle protected by a subsegment? */
                var hullsubseg = hulltri.tspivot()
                if hullsubseg.subsegment === m.dummysub {
                    /* The triangle is not protected; infect it. */
                    if !m.triangles[hulltri.id].infected {
                        m.triangles[hulltri.id].infected = true
                        m.viri.append(hulltri.triangle)
                    }
                } else {
                    /* The triangle is protected; set boundary markers if appropriate. */
                    if hullsubseg.mark == 0 {
                        hullsubseg.mark = 1
                        let horg = hulltri.org
                        let hdest = hulltri.dest
                        if horg >= 0 && m.vertices[horg].mark == 0 {
                            m.vertices[horg].mark = 1
                        }
                        if hdest >= 0 && m.vertices[hdest].mark == 0 {
                            m.vertices[hdest].mark = 1
                        }
                    }
                }
            }
            /* To find the next hull edge, go clockwise around the next vertex. */

            hulltri.lnextself()
            var nexttri = hulltri.oprev()
            while nexttri.triangle !== m.dummytri {

                nexttri.copy(to: &hulltri)
                hulltri.oprev(to: &nexttri)
            }
        } while !hulltri.otriEquals(other: starttri)
    }

    /*****************************************************************************/
    /*                                                                           */
    /*  plague()   Spread the virus from all infected triangles to any neighbors */
    /*             not protected by subsegments.  Delete all infected triangles. */
    /*                                                                           */
    /*  This is the procedure that actually creates holes and concavities.       */
    /*                                                                           */
    /*  This procedure operates in two phases.  The first phase identifies all   */
    /*  the triangles that will die, and marks them as infected.  They are       */
    /*  marked to ensure that each triangle is added to the virus pool only      */
    /*  once, so the procedure will terminate.                                   */
    /*                                                                           */
    /*  The second phase actually eliminates the infected triangles.  It also    */
    /*  eliminates orphaned vertices.                                            */
    /*                                                                           */
    /*****************************************************************************/

    private func plague(m: Mesh, b: Behavior) {
        if b.verbose {
            print("  Marking neighbors of marked triangles.\n")
        }
        var tovisit = m.viri
        while !tovisit.isEmpty {
            let virusloop = tovisit.removeFirst()
            var testtri = OrientedTriangle(triangle: virusloop, orientation: 0)
            /* A triangle is marked as infected by messing with one of its pointers */
            /*   to subsegments, setting it to an illegal value.  Hence, we have to */
            /*   temporarily uninfect this triangle so that we can examine its      */
            /*   adjacent subsegments.                                              */
            m.triangles[testtri.id].infected = false

            if b.verbose {
                /* Assign the triangle an orientation for convenience in */
                /*   checking its vertices.                              */
                testtri.orientation = 0
                let deadorg = m.vertices[testtri.org]
                let deaddest = m.vertices[testtri.dest]
                let deadapex = m.vertices[testtri.apex]
                print("    Checking (\(deadorg.x). \(deadorg.y)) (\(deaddest.x),\(deaddest.y)) (\(deadapex.x) \(deadapex.y))")
            }
            /* Check each of the triangle's three neighbors. */
            for i in 0..<3 {
                testtri.orientation = i
                /* Find the neighbor. */
                let neighbor = testtri.sym()
                /* Check for a subsegment between the triangle and its neighbor. */
                var neighborsubseg = testtri.tspivot()
                /* Check if the neighbor is nonexistent or already infected. */
                if neighbor.triangle === m.dummytri || m.triangles[neighbor.id].infected {
                    if neighborsubseg.subsegment !== m.dummysub {
                        /* There is a subsegment separating the triangle from its      */
                        /*   neighbor, but both triangles are dying, so the subsegment */
                        /*   dies too.                                                 */
                        m.killSubseg(subseg: neighborsubseg.subsegment)
                        if neighbor.triangle !== m.dummytri {
                            /* Make sure the subsegment doesn't get deallocated again */
                            /*   later when the infected neighbor is visited.         */
                            neighbor.tsdissolve(m: m)
                        }
                    }
                } else {                   /* The neighbor exists and is not infected. */
                    if neighborsubseg.subsegment === m.dummysub {
                        /* There is no subsegment protecting the neighbor, so */
                        /*   the neighbor becomes infected.                   */
                        if b.verbose {
                            let deadorg = m.vertices[neighbor.org]
                            let deaddest = m.vertices[neighbor.dest]
                            let deadapex = m.vertices[neighbor.apex]
                            print("    Marking (\(deadorg.x). \(deadorg.y)) (\(deaddest.x),\(deaddest.y)) (\(deadapex.x) \(deadapex.y))")

                        }
                        m.triangles[neighbor.id].infected = true
                        /* Ensure that the neighbor's neighbors will be infected. */
                        m.viri.append(neighbor.triangle)
                        tovisit.append(neighbor.triangle)
                    } else {               /* The neighbor is protected by a subsegment. */
                        /* Remove this triangle from the subsegment. */
                        neighborsubseg.stdissolve(m: m)
                        /* The subsegment becomes a boundary.  Set markers accordingly. */
                        if neighborsubseg.mark == 0 {
                            neighborsubseg.mark = 1
                        }

                        if neighbor.org >= 0 && m.vertices[neighbor.org].mark == 0 {
                            m.vertices[neighbor.org].mark = 1
                        }
                        if neighbor.dest >= 0 && m.vertices[neighbor.dest].mark == 0 {
                            m.vertices[neighbor.dest].mark = 1
                        }
                    }
                }
            }
            /* Remark the triangle as infected, so it doesn't get added to the */
            /*   virus pool again.                                             */
            m.triangles[testtri.id].infected = true
        }

        if b.verbose {
            print("  Deleting marked triangles.\n")
        }

        tovisit = m.viri
        while !tovisit.isEmpty {
            let virusloop = tovisit.removeFirst()
            var testtri = OrientedTriangle(triangle: virusloop, orientation: 0)

            /* Check each of the three corners of the triangle for elimination. */
            /*   This is done by walking around each vertex, checking if it is  */
            /*   still connected to at least one live triangle.                 */
            for i in 0..<3 {
                testtri.orientation = i

                /* Check if the vertex has already been tested. */
                if testtri.org >= 0 {
                    let testvertex = testtri.org
                    var killorg = true
                    /* Mark the corner of the triangle as having been tested. */
                    testtri.org = -1
                    /* Walk counterclockwise about the vertex. */
                    var neighbor = testtri.onext()
                    /* Stop upon reaching a boundary or the starting triangle. */
                    while neighbor.triangle !== m.dummytri && !neighbor.otriEquals(other: testtri) {
                        if m.triangles[neighbor.id].infected {
                            /* Mark the corner of this triangle as having been tested. */
                            neighbor.org = -1
                        } else {
                            /* A live triangle.  The vertex survives. */
                            killorg = false
                        }
                        /* Walk counterclockwise about the vertex. */
                        neighbor.onextself()
                    }
                    /* If we reached a boundary, we must walk clockwise as well. */
                    if neighbor.triangle === m.dummytri {
                        /* Walk clockwise about the vertex. */
                        var neighbor = testtri.oprev()
                        /* Stop upon reaching a boundary. */
                        while neighbor.triangle !== m.dummytri {
                            if m.triangles[neighbor.id].infected {
                                /* Mark the corner of this triangle as having been tested. */
                                neighbor.org = -1
                            } else {
                                /* A live triangle.  The vertex survives. */
                                killorg = false
                            }
                            /* Walk clockwise about the vertex. */
                            neighbor.oprevself()
                        }
                    }
                    if killorg {
                        if b.verbose {
                            let dlVert = m.vertices[testvertex]
                            print("    Deleting vertex (\(dlVert.x), \(dlVert.y))")

                        }
                        m.vertices[testvertex].state = .undead
                        m.undeads += 1
                    }
                }
            }

            /* Record changes in the number of boundary edges, and disconnect */
            /*   dead triangles from their neighbors.                         */
            for i in 0..<3 {
                testtri.orientation = i
                let neighbor = testtri.sym()
                if neighbor.triangle === m.dummytri {
                    /* There is no neighboring triangle on this edge, so this edge    */
                    /*   is a boundary edge.  This triangle is being deleted, so this */
                    /*   boundary edge is deleted.                                    */
                    m.hullsize -= 1
                } else {
                    /* Disconnect the triangle from its neighbor. */
                    neighbor.disolve(m: m)
                    /* There is a neighboring triangle on this edge, so this edge */
                    /*   becomes a boundary edge when this triangle is deleted.   */
                    m.hullsize += 1
                }
            }
            /* Return the dead triangle to the pool of triangles. */
            m.killTriangle(triangle: testtri.triangle)
        }
        m.removeAllDeadTriangles()
        m.viri.removeAll(keepingCapacity: false)
    }
}
