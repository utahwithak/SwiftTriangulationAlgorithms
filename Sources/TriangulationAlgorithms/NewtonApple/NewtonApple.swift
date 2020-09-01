//
//  NewtonApple.swift
//  NewtonApple
//
//  Created by Carl Wieland on 8/27/20.
//

/* copyright 2017 Dr David Sinclair
 david@newtonapples.net
 all rights reserved.
 
 
 version of 22-mar-2017.
 
 
 this code is released under GPL3,
 a copy of the license can be found at
 http://www.gnu.org/licenses/gpl-3.0.html
 
 you can purchase a un-restricted license from
 http://newtonapples.net
 
 where algorithm details are explained.
 
 If you do choose to purchase a license you might also like
 Newton Apple Chocolates!,
 the cleverest chocolates on the Internet.
 
 
 
 */

import Foundation

public struct NewtonApple {

    public static func triangulate(points: [CGPoint], pointsOut: inout [CGPoint]) -> [Int] {
        var r3s = points.enumerated().map { R3(id: $0.offset, pt: $0.element) }
        for (index, pt) in points.enumerated() {
            print("""
                pt.id = \(index);
                pt.r = \(pt.x);
                pt.c = \(pt.y);
                pt.z = \(pt.x * pt.x + pt.y * pt.y);
                pts.push_back(pt);
                """)
        }
        let tris = delaunayTriangulation(of: &r3s)

        pointsOut = r3s.map { CGPoint(x: $0.x, y: $0.y) }
        return tris.flatMap({ [$0.a, $0.b, $0.c ]})

    }

    internal static func delaunayTriangulation(of pts: inout [R3]) -> [Tri] {

        pts.sort()

        let fullHull = constructHull3D(from: pts)
        var hull = [Tri]()

        // just pick out the hull triangles and renumber.
        var taken = [Int](repeating: -1, count: fullHull.count)

        var cnt = 0
        for t in 0..<fullHull.count where fullHull[t].keep > 0 {  // create an index from old tri-id to new tri-id.
            taken[t] = cnt
            cnt += 1
        }

        // create an index from old tri-id to new tri-id.
        // point index remains unchanged.
        for t in 0..<fullHull.count where fullHull[t].keep > 0 {

            var T = fullHull[t]
            T.id = taken[t]
            if taken[T.ab] < 0 {
                //print("broken hull")
                return []
            }

            T.ab = taken[T.ab]

            if taken[T.bc] < 0 {
                //print("broken hull")
                return []
            }
            T.bc = taken[T.bc]

            if taken[T.ac] < 0 {
                //print("broken hull")
                return []
            }
            T.ac = taken[T.ac]

            // look at the normal to the triangle
            if fullHull[t].ez < 0 {
                hull.append(T)
            }

        }
        return hull
    }

    private static func constructHull3D(from pts: [R3]) -> [Tri] {
        let nump = pts.count

        var hull = [Tri]()
        var norts = [Snork]()

        hull.reserveCapacity(nump * 4)
        var mr: CGFloat = 0, mc: CGFloat = 0, mz: CGFloat = 0

        var T1 = Tri(x: 0, y: 1, q: 2)
        let r0 = pts[0].x, c0 = pts[0].y, z0 = pts[0].z
        let r1 = pts[1].x, c1 = pts[1].y, z1 = pts[1].z
        let r2 = pts[2].x, c2 = pts[2].y, z2 = pts[2].z

        var Mr = r0+r1+r2
        var Mc = c0+c1+c2
        var Mz = z0+z1+z2

        // check for colinearity
        let r01 = r1-r0, r02 = r2-r0
        let c01 = c1-c0, c02 = c2-c0
        let z01 = z1-z0, z02 = z2-z0

        let e0 = c01*z02 - c02*z01
        let e1 = -r01*z02 + r02*z01
        let e2 = r01*c02 - r02*c01

        if e0 == 0 && e1 == 0 && e2 == 0 { // do not add a facet.
            //print("Invalid input!")
            return []
        }

        T1.id = 0
        T1.er = e0
        T1.ec = e1
        T1.ez = e2

        T1.ab = 1;   // adjacent facet id number
        T1.ac = 1
        T1.bc = 1

        hull.append(T1)

        T1.id = 1
        T1.er = -e0
        T1.ec = -e1
        T1.ez = -e2

        T1.ab = 0
        T1.ac = 0
        T1.bc = 0
        hull.append(T1)

        var xList = [Int]()
        var Tnew = Tri()

        for p in 3..<nump {
            let pt = pts[p]

            Mr += pt.x; mr = Mr/CGFloat(p + 1)
            Mc += pt.y; mc = Mc/CGFloat(p + 1)
            Mz += pt.z; mz = Mz/CGFloat(p + 1)

            // find the first visible plane.
            let numh = hull.count
            var hvis = -1
            let r = pt.x
            let c = pt.y
            let z = pt.z
            xList.removeAll(keepingCapacity: true)
            for h in stride(from: numh - 1, through: 0, by: -1) {
                let t = hull[h]
                let R1 = pts[t.a].x
                let C1 = pts[t.a].y
                let Z1 = pts[t.a].z

                let dr = r - R1
                let dc = c - C1
                let dz = z - Z1

                let d = dr * t.er + dc * t.ec + dz * t.ez

                if d > 0 {
                    hvis = h
                    hull[h].keep = 0
                    xList.append(hvis)
                    break
                }
            }
            if hvis < 0 {
                addCoplanar(pts: pts, hull: &hull, p: p)
            } else {
                // new triangular facets are formed from neighbouring invisible planes.
                let numh = hull.count
                var numx = xList.count
                var x = 0
                while x < numx {
                    //print("x:\(x)")

                    let xid = xList[x]
                    let ab = hull[xid].ab     // facet adjacent to line ab
                    let tAB = hull[ab]

                    var R1 = pts[tAB.a].x  // point on next triangle
                    var C1 = pts[tAB.a].y
                    var Z1 = pts[tAB.a].z

                    var dr = r - R1
                    var dc = c - C1
                    var dz = z - Z1

                    var d = dr * tAB.er + dc * tAB.ec + dz * tAB.ez

                    if d > 0 { // add to xList.
                        if hull[ab].keep == 1 {
                            hull[ab].keep = 0
                            //print("Adding ab:\(ab)")
                            xList.append(ab)
                            numx += 1
                        }
                    } else { // spawn a new triangle.
                        Tnew.id = hull.count
                        Tnew.keep = 2
                        Tnew.a = p
                        Tnew.b = hull[xid].a
                        Tnew.c = hull[xid].b

                        Tnew.ab = -1
                        Tnew.ac = -1
                        Tnew.bc = ab

                        // make normal vector.
                        let dr1 = pts[Tnew.a].x - pts[Tnew.b].x, dr2 = pts[Tnew.a].x - pts[Tnew.c].x
                        let dc1 = pts[Tnew.a].y - pts[Tnew.b].y, dc2 = pts[Tnew.a].y - pts[Tnew.c].y
                        let dz1 = pts[Tnew.a].z - pts[Tnew.b].z, dz2 = pts[Tnew.a].z - pts[Tnew.c].z

                        let er =   dc1 * dz2 - dc2 * dz1
                        let ec = -(dr1 * dz2 - dr2 * dz1)
                        let ez =   dr1 * dc2 - dr2 * dc1

                        dr = mr - r; // points from new facet towards [mr,mc,mz]
                        dc = mc - c
                        dz = mz - z
                        // make it point outwards.

                        let dromadery = dr * er +  dc * ec + dz * ez

                        if dromadery > 0 {
                            Tnew.er = -er
                            Tnew.ec = -ec
                            Tnew.ez = -ez
                        } else {
                            Tnew.er = er
                            Tnew.ec = ec
                            Tnew.ez = ez
                        }

                        // update the touching triangle tAB
                        let A = hull[xid].a, B = hull[xid].b
                        if (tAB.a == A && tAB.b == B ) || (tAB.a == B && tAB.b == A ) {
                            //print("Setting:\(ab) ab.AB = \(hull.count)")
                            hull[ab].ab =  hull.count
                        } else if (tAB.a == A && tAB.c == B ) || (tAB.a == B && tAB.c == A ) {
                            hull[ab].ac = hull.count
                        } else if (tAB.b == A && tAB.c == B ) || (tAB.b == B && tAB.c == A ) {
                            hull[ab].bc = hull.count
                        } else {
                            //print("Invalid hull!")
                        }

                        hull.append(Tnew)

                    }

                    // second side of the struck out triangle

                    let ac = hull[xid].ac;     // facet adjacent to line ac
                    let tAC = hull[ac]

                    R1 = pts[tAC.a].x;  // point on next triangle
                    C1 = pts[tAC.a].y
                    Z1 = pts[tAC.a].z

                    dr = r - R1
                    dc = c - C1
                    dz = z - Z1

                    d = dr * tAC.er + dc * tAC.ec + dz * tAC.ez

                    if  d > 0 { // add to xList.
                        if  hull[ac].keep == 1 {
                            hull[ac].keep = 0
                            //print("Adding ac:\(ac)")

                            xList.append(ac)
                            numx  += 1
                        }
                    } else { // spawn a new triangle.
                        Tnew.id = hull.count
                        Tnew.keep = 2
                        Tnew.a = p
                        Tnew.b = hull[xid].a
                        Tnew.c = hull[xid].c

                        Tnew.ab = -1
                        Tnew.ac = -1
                        Tnew.bc = ac

                        // make normal vector.
                        let dr1 = pts[Tnew.a].x - pts[Tnew.b].x, dr2 = pts[Tnew.a].x - pts[Tnew.c].x
                        let dc1 = pts[Tnew.a].y - pts[Tnew.b].y, dc2 = pts[Tnew.a].y - pts[Tnew.c].y
                        let dz1 = pts[Tnew.a].z - pts[Tnew.b].z, dz2 = pts[Tnew.a].z - pts[Tnew.c].z

                        let er =  (dc1 * dz2 - dc2 * dz1)
                        let ec = -(dr1 * dz2 - dr2 * dz1)
                        let ez =  (dr1 * dc2 - dr2 * dc1)

                        dr = mr - r; // points from new facet towards [mr,mc,mz]
                        dc = mc - c
                        dz = mz - z
                        // make it point outwards.

                        let dromadery = dr * er +  dc * ec + dz * ez

                        if  dromadery > 0 {
                            Tnew.er = -er
                            Tnew.ec = -ec
                            Tnew.ez = -ez
                        } else {
                            Tnew.er = er
                            Tnew.ec = ec
                            Tnew.ez = ez
                        }
                        // update the touching triangle tAC
                        let A = hull[xid].a, C = hull[xid].c
                        if (tAC.a == A && tAC.b == C ) || (tAC.a == C && tAC.b == A ) {
                            //print("Setting ac.AB = \(hull.count)")

                            hull[ac].ab = hull.count
                        } else if (tAC.a == A && tAC.c == C ) || (tAC.a == C && tAC.c == A ) {
                            hull[ac].ac = hull.count
                        } else if (tAC.b == A && tAC.c == C ) || (tAC.b == C && tAC.c == A ) {
                            hull[ac].bc = hull.count
                        } else {
                            //print("Invalid Hull!");
                        }

                        hull.append(Tnew)
                    }

                    // third side of the struck out triangle

                    let bc = hull[xid].bc;     // facet adjacent to line ac
                    let tBC = hull[bc]

                    R1 = pts[tBC.a].x;  // point on next triangle
                    C1 = pts[tBC.a].y
                    Z1 = pts[tBC.a].z

                    dr = r - R1
                    dc = c - C1
                    dz = z - Z1

                    d = dr*tBC.er + dc*tBC.ec + dz*tBC.ez

                    if  d > 0 { // add to xList.
                        if  hull[bc].keep == 1 {
                            hull[bc].keep = 0
                            //print("Adding bc:\(bc)")

                            xList.append(bc)
                            numx  += 1
                        }
                    } else { // spawn a new triangle.
                        Tnew.id = hull.count
                        Tnew.keep = 2
                        Tnew.a = p
                        Tnew.b = hull[xid].b
                        Tnew.c = hull[xid].c

                        Tnew.ab = -1
                        Tnew.ac = -1
                        Tnew.bc = bc

                        // make normal vector.
                        let dr1 = pts[Tnew.a].x - pts[Tnew.b].x, dr2 = pts[Tnew.a].x - pts[Tnew.c].x
                        let dc1 = pts[Tnew.a].y - pts[Tnew.b].y, dc2 = pts[Tnew.a].y - pts[Tnew.c].y
                        let dz1 = pts[Tnew.a].z - pts[Tnew.b].z, dz2 = pts[Tnew.a].z - pts[Tnew.c].z

                        let er = (dc1*dz2-dc2*dz1)
                        let ec = -(dr1*dz2-dr2*dz1)
                        let ez = (dr1*dc2-dr2*dc1)

                        dr = mr-r; // points from new facet towards [mr,mc,mz]
                        dc = mc-c
                        dz = mz-z
                        // make it point outwards.

                        let dromadery = dr * er +  dc * ec + dz * ez

                        if  dromadery > 0 {
                            Tnew.er = -er
                            Tnew.ec = -ec
                            Tnew.ez = -ez
                        } else {
                            Tnew.er = er
                            Tnew.ec = ec
                            Tnew.ez = ez
                        }

                        // update the touching triangle tBC
                        let B = hull[xid].b, C = hull[xid].c
                        if (tBC.a == B && tBC.b == C ) || (tBC.a == C && tBC.b == B ) {
                            //print("Setting bc.AB = \(hull.count)")

                            hull[bc].ab = hull.count
                        } else if (tBC.a == B && tBC.c == C ) || (tBC.a == C && tBC.c == B ) {
                            hull[bc].ac = hull.count
                        } else if (tBC.b == B && tBC.c == C ) || (tBC.b == C && tBC.c == B ) {
                            hull[bc].bc = hull.count
                        } else {
                            //print("Invalid Hull!");
                        }

                        hull.append(Tnew)
                    }
                    x += 1

                }
                // patch up the new triangles in hull.
                norts.removeAll(keepingCapacity: true)

                for q in stride(from: hull.count - 1, through: numh, by: -1) where hull[q].keep > 1 {
                    norts.append( Snork(id: q, a: hull[q].b, b: 1))
                    norts.append( Snork(id: q, a: hull[q].c, b: 0))
                    hull[q].keep = 1
                }

                norts.sort()
                if  norts.count >= 2 {
                    for s in 0..<norts.count-1 {
                        let nortS = norts[s]
                        let nortsP1 = norts[s + 1]
                        if  nortS.a == nortsP1.a {
                            // link triangle sides.
                            if  nortS.b == 1 {
                                hull[nortS.id].ab = nortsP1.id
                            } else {
                                hull[nortS.id].ac = nortsP1.id
                            }

                            if nortsP1.b == 1 {
                                hull[nortsP1.id].ab = nortS.id
                            } else {
                                hull[nortsP1.id].ac = nortS.id
                            }
                        }
                    }
                }

            }

        }

        return hull
    }

    private static func addCoplanar(pts: [R3], hull: inout [Tri], p: Int) {
        let numh = hull.count
        var er: CGFloat = 0, ec: CGFloat = 0, ez: CGFloat = 0
        for k in 0..<numh {
            //find vizible edges. from external edges.
            if hull[k].c == hull[hull[k].ab].c { // ->  ab is an external edge.
                // test this edge for visibility from new point pts[id].
                let A = hull[k].a
                let B = hull[k].b
                let C = hull[k].c

                let zot = crossTest( A: pts[A], B: pts[B], C: pts[C], X: pts[p], er: &er, ec: &ec, ez: &ez)

                if  zot < 0 { // visible edge facet, create 2 new hull plates.
                    var up = Tri()
                    var down = up
                    up.keep = 2
                    up.id = hull.count
                    up.a = p
                    up.b = A
                    up.c = B

                    up.er = er; up.ec = ec; up.ez = ez
                    up.ab = -1; up.ac = -1

                    down.keep = 2
                    down.id = hull.count + 1
                    down.a = p
                    down.b = A
                    down.c = B

                    down.ab = -1; down.ac = -1
                    down.er = -er; down.ec = -ec; down.ez = -ez

                    let xx = hull[k].er*er + hull[k].ec*ec + hull[k].ez*ez
                    if xx > 0 {
                        up.bc = k
                        down.bc = hull[k].ab

                        hull[k].ab = up.id
                        hull[down.bc].ab = down.id
                    } else {
                        down.bc = k
                        up.bc = hull[k].ab

                        hull[k].ab = down.id
                        hull[up.bc].ab = up.id
                    }

                    hull.append(up)
                    hull.append(down)
                }
            }

            if  hull[k].a == hull[hull[k].bc].a {   // bc is an external edge.
                // test this edge for visibility from new point pts[id].
                let A = hull[k].b
                let B = hull[k].c
                let C = hull[k].a

                let zot = crossTest(A: pts[A], B: pts[B], C: pts[C], X: pts[p], er: &er, ec: &ec, ez: &ez)

                if  zot < 0 { // visible edge facet, create 2 new hull plates.
                    var up = Tri()
                    var down = up
                    up.keep = 2
                    up.id = hull.count
                    up.a = p
                    up.b = A
                    up.c = B

                    up.er = er; up.ec = ec; up.ez = ez
                    up.ab = -1; up.ac = -1

                    down.keep = 2
                    down.id = hull.count + 1
                    down.a = p
                    down.b = A
                    down.c = B

                    down.ab = -1; down.ac = -1
                    down.er = -er; down.ec = -ec; down.ez = -ez

                    let xx = hull[k].er*er + hull[k].ec*ec + hull[k].ez*ez
                    if xx > 0 {
                        up.bc = k
                        down.bc = hull[k].bc

                        hull[k].bc = up.id
                        hull[down.bc].bc = down.id
                    } else {
                        down.bc = k
                        up.bc = hull[k].bc

                        hull[k].bc = down.id
                        hull[up.bc].bc = up.id
                    }

                    hull.append(up)
                    hull.append(down)
                }
            }

            if  hull[k].b == hull[hull[k].ac].b {   // ac is an external edge.
                // test this edge for visibility from new point pts[id].
                let A = hull[k].a
                let B = hull[k].c
                let C = hull[k].b

                let zot = crossTest(A: pts[A], B: pts[B], C: pts[C], X: pts[p], er: &er, ec: &ec, ez: &ez)

                if  zot < 0 { // visible edge facet, create 2 new hull plates.
                    var up = Tri()
                    var down = up
                    up.keep = 2
                    up.id = hull.count
                    up.a = p
                    up.b = A
                    up.c = B

                    up.er = er; up.ec = ec; up.ez = ez
                    up.ab = -1; up.ac = -1

                    down.keep = 2
                    down.id = hull.count + 1
                    down.a = p
                    down.b = A
                    down.c = B

                    down.ab = -1; down.ac = -1
                    down.er = -er; down.ec = -ec; down.ez = -ez

                    let xx = hull[k].er*er + hull[k].ec*ec + hull[k].ez*ez
                    if xx > 0 {
                        up.bc = k
                        down.bc = hull[k].ac

                        hull[k].ac = up.id
                        hull[down.bc].ac = down.id
                    } else {
                        down.bc = k
                        up.bc = hull[k].ac

                        hull[k].ac = down.id
                        hull[up.bc].ac = up.id
                    }

                    hull.append(up)
                    hull.append(down)
                }
            }

        }

        // fix up the non asigned hull adjecencies (correctly).

        let numN = hull.count
        var norts = [Snork]()
        for q in stride(from: numN - 1, through: numh, by: -1) where hull[q].keep > 1 {
            norts.append(Snork(id: q, a: hull[q].b, b: 1))
            norts.append(Snork(id: q, a: hull[q].c, b: 0))
            hull[q].keep = 1
        }
        norts.sort()
        let nums = norts.count
        norts.append(Snork(id: -1, a: -1, b: -1))
        norts.append(Snork(id: -2, a: -2, b: -2))

        if nums >= 2 {
            var s = 0
            while s < nums-1 {
                if norts[s].a == norts[s+1].a {
                    // link triangle sides.
                    if  norts[s].a != norts[s+2].a { // edge of figure case
                        if  norts[s].b == 1 {
                            hull[norts[s].id].ab = norts[s+1].id
                        } else {
                            hull[norts[s].id].ac = norts[s+1].id
                        }

                        if  norts[s+1].b == 1 {
                            hull[norts[s+1].id].ab = norts[s].id
                        } else {
                            hull[norts[s+1].id].ac = norts[s].id
                        }
                        s += 1
                    } else { // internal figure boundary 4 junction case.
                        var s1 = s+1, s2 = s+2, s3 = s+3
                        let id = norts[s].id
                        var id1 = norts[s1].id
                        var id2 = norts[s2].id
                        var id3 = norts[s3].id

                        // check normal directions of id and id1..3
                        var barf = hull[id].er*hull[id1].er + hull[id].ec*hull[id1].ec + hull[id].ez*hull[id1].ez
                        if  barf > 0 {
                        } else {
                            barf = hull[id].er*hull[id2].er + hull[id].ec*hull[id2].ec + hull[id].ez*hull[id2].ez
                            if  barf > 0 {
                                var tmp = id2; id2 = id1; id1 = tmp
                                tmp = s2; s2 = s1; s1 = tmp
                            } else {
                                barf = hull[id].er*hull[id3].er + hull[id].ec*hull[id3].ec + hull[id].ez*hull[id3].ez
                                if  barf > 0 {
                                    var tmp = id3; id3 = id1; id1 = tmp
                                    tmp = s3; s3 = s1; s1 = tmp
                                }
                            }
                        }

                        if  norts[s].b == 1 {
                            hull[norts[s].id].ab = norts[s1].id
                        } else {
                            hull[norts[s].id].ac = norts[s1].id
                        }

                        if  norts[s1].b == 1 {
                            hull[norts[s1].id].ab = norts[s].id
                        } else {
                            hull[norts[s1].id].ac = norts[s].id
                        }

                        // use s2 and s3

                        if  norts[s2].b == 1 {
                            hull[norts[s2].id].ab = norts[s3].id
                        } else {
                            hull[norts[s2].id].ac = norts[s3].id
                        }

                        if  norts[s3].b == 1 {
                            hull[norts[s3].id].ab = norts[s2].id
                        } else {
                            hull[norts[s3].id].ac = norts[s2].id
                        }

                        s += 3
                    }

                }
                s += 1
            }
        }
    }

    private static func crossTest(A: R3, B: R3, C: R3, X: R3,
                                  er: inout CGFloat, ec: inout CGFloat, ez: inout CGFloat) -> Int {

        let Ar = A.x
        let Ac = A.y
        let Az = A.z

        let Br = B.x
        let Bc = B.y
        let Bz = B.z

        let Cr = C.x
        let Cc = C.y
        let Cz = C.z

        let Xr = X.x
        let Xc = X.y
        let Xz = X.z

        let ABr = Br - Ar
        let ABc = Bc - Ac
        let ABz = Bz - Az

        let ACr = Cr - Ar
        let ACc = Cc - Ac
        let ACz = Cz - Az

        let AXr = Xr - Ar
        let AXc = Xc - Ac
        let AXz = Xz - Az

        er =  (ABc * AXz - ABz * AXc)
        ec = -(ABr * AXz - ABz * AXr)
        ez =  (ABr * AXc - ABc * AXr)

        let kr =  (ABc * ACz - ABz * ACc)
        let kc = -(ABr * ACz - ABz * ACr)
        let kz =  (ABr * ACc - ABc * ACr)

        //  look at sign of (ab x ac).(ab x ax)

        let globit =  kr * er +  kc * ec + kz * ez

        if globit > 0 { return(1) }
        if globit == 0 { return(0) }
        return -1

    }

}
