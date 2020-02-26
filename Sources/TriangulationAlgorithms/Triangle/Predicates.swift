//
//  Predicates.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class Predicates {

    /* Global constants.                                                         */
    public private(set) static

    var splitter: REAL = 0,        /* Used to split REAL factors for exact multiplication. */
    epsilon: REAL = 0,                             /* Floating-point machine epsilon. */
    resulterrbound: REAL = 0,
    ccwerrboundA: REAL = 0, ccwerrboundB: REAL = 0, ccwerrboundC: REAL = 0,
    iccerrboundA: REAL = 0, iccerrboundB: REAL = 0, iccerrboundC: REAL = 0,
    o3derrboundA: REAL = 0, o3derrboundB: REAL = 0, o3derrboundC: REAL = 0

    public static func exactinit() {
        let half: REAL = 0.5
        var check: REAL = 1.0, lastcheck: REAL = 0
        var every_other = true

        epsilon = 1.0
        splitter = 1.0
        /* Repeatedly divide `epsilon' by two until it is too small to add to      */
        /*   one without causing roundoff.  (Also check if the sum is equal to     */
        /*   the previous sum, for machines that round up instead of using exact   */
        /*   rounding.  Not that these routines will work on such machines.)       */
        repeat {
            lastcheck = check
            epsilon *= half
            if every_other {
                splitter *= 2.0
            }
            every_other = !every_other
            check = 1.0 + epsilon
        } while ((check != 1.0) && (check != lastcheck))
        splitter += 1.0
        /* Error bounds for orientation and incircle tests. */
        resulterrbound = (3.0 + 8.0 * epsilon) * epsilon
        ccwerrboundA = (3.0 + 16.0 * epsilon) * epsilon
        ccwerrboundB = (2.0 + 12.0 * epsilon) * epsilon
        ccwerrboundC = (9.0 + 64.0 * epsilon) * epsilon * epsilon
        iccerrboundA = (10.0 + 96.0 * epsilon) * epsilon
        iccerrboundB = (4.0 + 48.0 * epsilon) * epsilon
        iccerrboundC = (44.0 + 576.0 * epsilon) * epsilon * epsilon
        o3derrboundA = (7.0 + 56.0 * epsilon) * epsilon
        o3derrboundB = (3.0 + 28.0 * epsilon) * epsilon
        o3derrboundC = (26.0 + 288.0 * epsilon) * epsilon * epsilon
    }

    public static func Two_Product_Presplit(_ a: REAL, _ b: REAL, _ bhi: REAL, _ blo: REAL, _ x: inout REAL, _ y: inout REAL) {
        x = a * b
        var ahi: REAL = 0
        var alo: REAL = 0
        Split(a, &ahi, &alo)
        let err1 = x - (ahi * bhi)
        let err2 = err1 - (alo * bhi)
        let err3 = err2 - (ahi * blo)
        y = (alo * blo) - err3
    }

    public static func Two_Product(_ a: REAL, _ b: REAL, _ x: inout REAL, _ y: inout REAL ) {
        x = (a * b)
        Two_Product_Tail(a, b, x, &y)
    }

    public static func Two_Product_Tail(_ a: REAL, _ b: REAL, _ x: REAL, _ y: inout REAL) {
        var ahi: REAL = 0, alo: REAL = 0
        var bhi: REAL = 0, blo: REAL = 0
        Split(a, &ahi, &alo)
        Split(b, &bhi, &blo)
        let err1 = x - (ahi * bhi)
        let err2 = err1 - (alo * bhi)
        let err3 = err2 - (ahi * blo)
        y = (alo * blo) - err3
    }

    public static func Square_Tail(_ a: REAL, _  x: REAL) -> REAL {
        var ahi: REAL = 0, alo: REAL = 0
        Split(a, &ahi, &alo)
        let err1 = x - (ahi * ahi)
        let err3 = err1 - ((ahi + ahi) * alo)
        return (alo * alo) - err3
    }

    public static func Square_Tail(_ a: REAL, _  x: REAL, _ y: inout REAL) {
        y = Square_Tail(a, x)
    }

    public static func Square(_ a: REAL, _ x: inout REAL, _ y: inout REAL) {
        x = a * a
        Square_Tail(a, x, &y)
    }

    public static func Square(_ a: REAL) -> (REAL, REAL) {
        let x = a * a
        return (x, Square_Tail(a, x))
    }

    public static func Split(_ a: REAL, _ ahi: inout REAL, _ alo: inout REAL) {
        let c = (REAL) (splitter * a)
        let abig = (REAL) (c - a)
        ahi = c - abig
        alo = a - ahi
    }
    public static func Two_Sum_Tail(_ a: REAL, _ b: REAL, _ x: REAL, _ y: inout REAL) {
        let bvirt = (REAL) (x - a)
        let avirt = x - bvirt
        let bround = b - bvirt
        let around = a - avirt
        y = around + bround
    }

    public static func Two_Sum(_ a: REAL, _ b: REAL, _ x: inout REAL, _ y: inout REAL) {
        x = a + b
        Two_Sum_Tail(a, b, x, &y)
    }

    public static func Fast_Two_Sum(_ a: REAL, _ b: REAL, _ x: inout REAL, _ y: inout REAL) {
        x = (REAL) (a + b)
        Fast_Two_Sum_Tail(a, b, x, &y)
    }

    public static func Fast_Two_Sum_Tail(_ a: REAL, _ b: REAL, _ x: REAL, _ y: inout REAL) {
        let bvirt = x - a
         y = b - bvirt
    }

    public static func Two_Diff_Tail(_ a: REAL, _  b: REAL, _ x: REAL, _ y: inout REAL) {
        let bvirt = (REAL) (a - x)
        let avirt = x + bvirt
        let bround = bvirt - b
        let around = a - avirt
        y = around + bround
    }

    public static func Two_Diff(_ a: REAL, _ b: REAL, _ x: inout REAL, _ y: inout REAL) {
        x = (REAL) (a - b)
        Two_Diff_Tail(a, b, x, &y)
    }

    public static func Two_One_Sum(_ a1: REAL, _ a0: REAL, _ b: REAL, _ x2: inout REAL, _ x1: inout REAL, _ x0: inout REAL) {
        var i: REAL = 0
        Two_Sum(a0, b, &i, &x0)
        Two_Sum(a1, i, &x2, &x1)
    }

    public static func Two_One_Diff(_ a1: REAL, _ a0: REAL, _ b: REAL, _ x2: inout REAL, _ x1: inout REAL, _ x0: inout REAL) {
        var i: REAL = 0
        Two_Diff(a0, b, &i, &x0)
        Two_Sum( a1, i, &x2, &x1)
    }

    public static func Two_Two_Sum(_ a1: REAL, _ a0: REAL, _ b1: REAL, _ b0: REAL, _ x3: inout REAL, _ x2: inout REAL, _ x1: inout REAL, _ x0: inout REAL) {
        var j: REAL = 0, _0: REAL = 0
        Two_One_Sum(a1, a0, b0, &j, &_0, &x0)
        Two_One_Sum(j, _0, b1, &x3, &x2, &x1)
    }

    public static func Two_Two_Sum(_ a1: REAL, _ a0: REAL, _ b1: REAL, _ b0: REAL) -> [REAL] {
        var j: REAL = 0, _0: REAL = 0
        var x3: REAL = 0
        var x2: REAL = 0
        var x1: REAL = 0
        var x0: REAL = 0
        Two_One_Sum(a1, a0, b0, &j, &_0, &x0)
        Two_One_Sum(j, _0, b1, &x3, &x2, &x1)
        return [x0, x1, x2, x3]
    }

    public static func Two_Two_Diff(_ a1: REAL, _ a0: REAL, _ b1: REAL, _ b0: REAL, _ x3: inout REAL, _ x2: inout REAL, _ x1: inout REAL, _ x0: inout REAL) {
        var j: REAL = 0, _0: REAL = 0
        Two_One_Diff(a1, a0, b0, &j, &_0, &x0)
        Two_One_Diff(j, _0, b1, &x3, &x2, &x1)
    }

    public static func Two_Two_Diff(_ a1: REAL, _ a0: REAL, _ b1: REAL, _ b0: REAL) -> [REAL] {
        var j: REAL = 0, _0: REAL = 0
        var x3: REAL = 0
        var x2: REAL = 0
        var x1: REAL = 0
        var x0: REAL = 0
        Two_One_Diff(a1, a0, b0, &j, &_0, &x0)

        Two_One_Diff(j, _0, b1, &x3, &x2, &x1)
        return [x0, x1, x2, x3]
    }

    public static func fast_expansion_sum_zeroelim(_ e: [REAL], _ f: [REAL]) -> [REAL] {

        var h = [REAL]()
        var enow = e[0]
        var fnow = f[0]
        var eindex = 0, findex = 0
        var Q: REAL
        if (fnow > enow) == (fnow > -enow) {
            Q = enow
            eindex += 1

            if eindex < e.count {
                enow = e[eindex]

            }
        } else {
            Q = fnow
            findex += 1
            if findex < f.count {

                fnow = f[findex]
            }
        }
        if (eindex < e.count) && (findex < f.count) {
            var Qnew: REAL = 0
            var hh: REAL = 0
            if (fnow > enow) == (fnow > -enow) {
                Fast_Two_Sum(enow, Q, &Qnew, &hh)
                eindex += 1
                if eindex < e.count {
                    enow = e[eindex]
                }
            } else {
                Fast_Two_Sum(fnow, Q, &Qnew, &hh)
                findex += 1
                if findex < f.count {
                fnow = f[findex]
                }
            }
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
            while (eindex < e.count) && (findex < f.count) {
                var Qnew: REAL = 0
                var hh: REAL = 0
                if (fnow > enow) == (fnow > -enow) {
                    Two_Sum(Q, enow, &Qnew, &hh)
                    eindex += 1
                    if eindex < e.count {
                        enow = e[eindex]
                    }
                } else {
                    Two_Sum(Q, fnow, &Qnew, &hh)
                    findex += 1
                    if findex < f.count {
                        fnow = f[findex]
                    }
                }
                Q = Qnew
                if hh != 0.0 {
                    h.append(hh)
                }
            }
        }
        while eindex < e.count {
            var Qnew: REAL = 0
            var hh: REAL = 0
            Two_Sum(Q, enow, &Qnew, &hh)
            eindex += 1
            if eindex < e.count {
                enow = e[eindex]
            }
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
        }
        while findex < f.count {
            var Qnew: REAL = 0
            var hh: REAL = 0
            Two_Sum(Q, fnow, &Qnew, &hh)
            findex += 1
            if findex < f.count {
                fnow = f[findex]
            }
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
        }

        if (Q != 0.0) || (h.isEmpty) {
            h.append(Q)
        }
        return h
    }

    public static func incircle(_ m: Mesh, _ b: Behavior, _ pa: Vertex, _ pb: Vertex, _ pc: Vertex, _ pd: Vertex) -> REAL {

        m.incirclecount += 1

        let adx = pa.x - pd.x
        let bdx = pb.x - pd.x
        let cdx = pc.x - pd.x
        let ady = pa.y - pd.y
        let bdy = pb.y - pd.y
        let cdy = pc.y - pd.y

        let bdxcdy = bdx * cdy
        let cdxbdy = cdx * bdy
        let alift = adx * adx + ady * ady

        let cdxady = cdx * ady
        let adxcdy = adx * cdy
        let blift = bdx * bdx + bdy * bdy

        let adxbdy = adx * bdy
        let bdxady = bdx * ady
        let clift = cdx * cdx + cdy * cdy

        let det = alift * (bdxcdy - cdxbdy) + blift * (cdxady - adxcdy) + clift * (adxbdy - bdxady)

        if b.noexact {
            return det
        }

        let permanent = (abs(bdxcdy) + abs(cdxbdy)) * alift + (abs(cdxady) + abs(adxcdy)) * blift + (abs(adxbdy) + abs(bdxady)) * clift
        let errbound = iccerrboundA * permanent
        if (det > errbound) || (-det > errbound) {
            return det
        }

        return incircleadapt(pa, pb, pc, pd, permanent)
    }

    public static func incircleadapt(_ pa: Vertex, _ pb: Vertex, _ pc: Vertex, _ pd: Vertex, _ permanent: REAL ) -> REAL {

        let adx = pa.x - pd.x
        let bdx = pb.x - pd.x
        let cdx = pc.x - pd.x
        let ady = pa.y - pd.y
        let bdy = pb.y - pd.y
        let cdy = pc.y - pd.y
        var bdxcdy1: REAL = 0, bdxcdy0: REAL = 0, cdxbdy1: REAL = 0, cdxbdy0: REAL = 0
        Two_Product(bdx, cdy, &bdxcdy1, &bdxcdy0)
        Two_Product(cdx, bdy, &cdxbdy1, &cdxbdy0)

        let bc = Two_Two_Diff(bdxcdy1, bdxcdy0, cdxbdy1, cdxbdy0)
        let axbc = scale_expansion_zeroelim(e: bc, b: adx)
        let axxbc = scale_expansion_zeroelim(e: axbc, b: adx)
        let aybc = scale_expansion_zeroelim(e: bc, b: ady)
        let ayybc = scale_expansion_zeroelim(e: aybc, b: ady)
        let adet = fast_expansion_sum_zeroelim(axxbc, ayybc)

        var cdxady1: REAL = 0, cdxady0: REAL = 0, adxcdy1: REAL = 0, adxcdy0: REAL = 0
        Two_Product(cdx, ady, &cdxady1, &cdxady0)
        Two_Product(adx, cdy, &adxcdy1, &adxcdy0)
        let ca = Two_Two_Diff(cdxady1, cdxady0, adxcdy1, adxcdy0)

        let bxca = scale_expansion_zeroelim(e: ca, b: bdx)
        let bxxca = scale_expansion_zeroelim(e: bxca, b: bdx)
        let byca = scale_expansion_zeroelim(e: ca, b: bdy)
        let byyca = scale_expansion_zeroelim( e: byca, b: bdy)
        let bdet = fast_expansion_sum_zeroelim(bxxca, byyca)

        var adxbdy1: REAL = 0, adxbdy0: REAL = 0, bdxady1: REAL = 0, bdxady0: REAL = 0
        Two_Product(adx, bdy, &adxbdy1, &adxbdy0)
        Two_Product(bdx, ady, &bdxady1, &bdxady0)
        let ab = Two_Two_Diff(adxbdy1, adxbdy0, bdxady1, bdxady0)

        let cxab = scale_expansion_zeroelim(e: ab, b: cdx)
        let cxxab = scale_expansion_zeroelim(e: cxab, b: cdx)
        let cyab = scale_expansion_zeroelim(e: ab, b: cdy)
        let cyyab = scale_expansion_zeroelim(e: cyab, b: cdy)
        let cdet = fast_expansion_sum_zeroelim(cxxab, cyyab)

        let abdet = fast_expansion_sum_zeroelim(adet, bdet)
        let fin1 = fast_expansion_sum_zeroelim(abdet, cdet)

        var det = fin1.reduce(0, +)
        var errbound = iccerrboundB * permanent
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        var adxtail: REAL = 0, adytail: REAL = 0, bdxtail: REAL = 0, bdytail: REAL = 0, cdxtail: REAL = 0, cdytail: REAL = 0
        Two_Diff_Tail(pa.x, pd.x, adx, &adxtail)
        Two_Diff_Tail(pa.y, pd.y, ady, &adytail)
        Two_Diff_Tail(pb.x, pd.x, bdx, &bdxtail)
        Two_Diff_Tail(pb.y, pd.y, bdy, &bdytail)
        Two_Diff_Tail(pc.x, pd.x, cdx, &cdxtail)
        Two_Diff_Tail(pc.y, pd.y, cdy, &cdytail)
        if (adxtail == 0.0) && (bdxtail == 0.0) && (cdxtail == 0.0)
            && (adytail == 0.0) && (bdytail == 0.0) && (cdytail == 0.0) {
            return det
        }

        errbound = iccerrboundC * permanent + resulterrbound * abs(det)
        det += ((adx * adx + ady * ady) * ((bdx * cdytail + cdy * bdxtail)
                                           - (bdy * cdxtail + cdx * bdytail))
                + 2.0 * (adx * adxtail + ady * adytail) * (bdx * cdy - bdy * cdx))
        + ((bdx * bdx + bdy * bdy) * ((cdx * adytail + ady * cdxtail)
                                      - (cdy * adxtail + adx * cdytail))
           + 2.0 * (bdx * bdxtail + bdy * bdytail) * (cdx * ady - cdy * adx))
        + ((cdx * cdx + cdy * cdy) * ((adx * bdytail + bdy * adxtail)
                                      - (ady * bdxtail + bdx * adytail))
           + 2.0 * (cdx * cdxtail + cdy * cdytail) * (adx * bdy - ady * bdx))
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        var aa = [REAL]()
        var bb = [REAL]()
        var cc = [REAL]()

        if (bdxtail != 0.0) || (bdytail != 0.0) || (cdxtail != 0.0) || (cdytail != 0.0) {
            let (adxadx1, adxadx0) = Square(adx)
            let (adyady1, adyady0) = Square(ady)
            aa = Two_Two_Sum(adxadx1, adxadx0, adyady1, adyady0)
        }
        if (cdxtail != 0.0) || (cdytail != 0.0) || (adxtail != 0.0) || (adytail != 0.0) {
            let (bdxbdx1, bdxbdx0) = Square(bdx)
            let (bdybdy1, bdybdy0) = Square(bdy)
            bb = Two_Two_Sum(bdxbdx1, bdxbdx0, bdybdy1, bdybdy0)
        }
        if (adxtail != 0.0) || (adytail != 0.0) || (bdxtail != 0.0) || (bdytail != 0.0) {
            let (cdxcdx1, cdxcdx0) = Square(cdx)
            let (cdycdy1, cdycdy0) = Square(cdy)
            cc = Two_Two_Sum(cdxcdx1, cdxcdx0, cdycdy1, cdycdy0)

        }
        var finnow = fin1
        var finother = fin1
        var finswap = [REAL]()
        var axtbc = [REAL]()
        if adxtail != 0.0 {
            axtbc  = scale_expansion_zeroelim(e: bc, b: adxtail)
            let temp16a = scale_expansion_zeroelim(e: axtbc, b: 2.0 * adx)

            let axtcc = scale_expansion_zeroelim(e: cc, b: adxtail)
            let temp16b = scale_expansion_zeroelim(e: axtcc, b: bdy)

            let axtbb = scale_expansion_zeroelim(e: bb, b: adxtail)
            let temp16c = scale_expansion_zeroelim(e: axtbb, b: -cdy)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow
            finnow = finother
            finother = finswap
        }

        var aytbc = [REAL]()
        if adytail != 0.0 {
            aytbc = scale_expansion_zeroelim(e: bc, b: adytail)
            let temp16a = scale_expansion_zeroelim(e: aytbc, b: 2.0 * ady)

            let aytbb = scale_expansion_zeroelim(e: bb, b: adytail)
            let temp16b = scale_expansion_zeroelim(e: aytbb, b: cdx)

            let aytcc = scale_expansion_zeroelim(e: cc, b: adytail)
            let temp16c = scale_expansion_zeroelim(e: aytcc, b: -bdx)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow
            finnow = finother
            finother = finswap
        }

        var bxtca = [REAL]()
        if bdxtail != 0.0 {
            bxtca = scale_expansion_zeroelim(e: ca, b: bdxtail)
            let temp16a = scale_expansion_zeroelim(e: bxtca, b: 2.0 * bdx)

            let bxtaa = scale_expansion_zeroelim(e: aa, b: bdxtail)
            let temp16b = scale_expansion_zeroelim(e: bxtaa, b: cdy)

            let bxtcc = scale_expansion_zeroelim(e: cc, b: bdxtail)
            let temp16c = scale_expansion_zeroelim(e: bxtcc, b: -ady)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow; finnow = finother; finother = finswap
        }
        var bytca = [REAL]()
        if bdytail != 0.0 {
            bytca = scale_expansion_zeroelim(e: ca, b: bdytail)
            let temp16a = scale_expansion_zeroelim(e: bytca, b: 2.0 * bdy)

            let bytcc = scale_expansion_zeroelim(e: cc, b: bdytail)
            let temp16b = scale_expansion_zeroelim(e: bytcc, b: adx)

            let bytaa = scale_expansion_zeroelim(e: aa, b: bdytail)
            let temp16c = scale_expansion_zeroelim(e: bytaa, b: -cdx)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow; finnow = finother; finother = finswap
        }

        var cxtab = [REAL]()
        if cdxtail != 0.0 {
            cxtab = scale_expansion_zeroelim(e: ab, b: cdxtail)
            let temp16a = scale_expansion_zeroelim(e: cxtab, b: 2.0 * cdx)

            let cxtbb = scale_expansion_zeroelim(e: bb, b: cdxtail)
            let temp16b = scale_expansion_zeroelim(e: cxtbb, b: ady)

            let cxtaa = scale_expansion_zeroelim(e: aa, b: cdxtail)
            let temp16c = scale_expansion_zeroelim(e: cxtaa, b: -bdy)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow; finnow = finother; finother = finswap
        }
        var cytab = [REAL]()
        if cdytail != 0.0 {
            cytab = scale_expansion_zeroelim(e: ab, b: cdytail)
            let temp16a = scale_expansion_zeroelim(e: cytab, b: 2.0 * cdy)

            let cytaa = scale_expansion_zeroelim(e: aa, b: cdytail)
            let temp16b = scale_expansion_zeroelim(e: cytaa, b: bdx)

            let cytbb = scale_expansion_zeroelim(e: bb, b: cdytail)
            let temp16c = scale_expansion_zeroelim(e: cytbb, b: -adx)

            let temp32a = fast_expansion_sum_zeroelim(temp16a, temp16b)
            let temp48 = fast_expansion_sum_zeroelim(temp16c, temp32a)
            finother = fast_expansion_sum_zeroelim(finnow, temp48)
            finswap = finnow; finnow = finother; finother = finswap
        }

        var ti1: REAL = 0, ti0: REAL = 0, tj1: REAL = 0, tj0: REAL = 0
        var negate: REAL = 0
        var bctt: [REAL]
        var bct: [REAL]
        if (adxtail != 0.0) || (adytail != 0.0) {
            if (bdxtail != 0.0) || (bdytail != 0.0)
                || (cdxtail != 0.0) || (cdytail != 0.0) {
                Two_Product(bdxtail, cdy, &ti1, &ti0)
                Two_Product(bdx, cdytail, &tj1, &tj0)
                let u = Two_Two_Sum(ti1, ti0, tj1, tj0)
                negate = -bdy
                Two_Product(cdxtail, negate, &ti1, &ti0)
                negate = -bdytail
                Two_Product(cdx, negate, &tj1, &tj0)
                let v = Two_Two_Sum(ti1, ti0, tj1, tj0)
                bct = fast_expansion_sum_zeroelim(u, v)

                Two_Product(bdxtail, cdytail, &ti1, &ti0)
                Two_Product(cdxtail, bdytail, &tj1, &tj0)
                bctt = Two_Two_Diff(ti1, ti0, tj1, tj0)
            } else {
                bct = [0]
                bctt = [0]
            }

            if adxtail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: axtbc, b: adxtail)
                let axtbct = scale_expansion_zeroelim(e: bct, b: adxtail)
                var temp32a = scale_expansion_zeroelim(e: axtbct, b: 2.0 * adx)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap
                if bdytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: cc, b: adxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: bdytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if cdytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: bb, b: -adxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: cdytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32a = scale_expansion_zeroelim(e: axtbct, b: adxtail)
                let axtbctt = scale_expansion_zeroelim(e: bctt, b: adxtail)
                temp16a = scale_expansion_zeroelim(e: axtbctt, b: 2.0 * adx)
                let temp16b = scale_expansion_zeroelim(e: axtbctt, b: adxtail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if adytail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: aytbc, b: adytail)
                let aytbct = scale_expansion_zeroelim(e: bct, b: adytail)
                var temp32a = scale_expansion_zeroelim(e: aytbct, b: 2.0 * ady)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap

                temp32a = scale_expansion_zeroelim(e: aytbct, b: adytail)
                let aytbctt = scale_expansion_zeroelim(e: bctt, b: adytail)
                temp16a = scale_expansion_zeroelim(e: aytbctt, b: 2.0 * ady)
                let temp16b = scale_expansion_zeroelim(e: aytbctt, b: adytail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }

        var cat: [REAL]
        var catt: [REAL]
        if (bdxtail != 0.0) || (bdytail != 0.0) {
            if (cdxtail != 0.0) || (cdytail != 0.0)
                || (adxtail != 0.0) || (adytail != 0.0) {
                Two_Product(cdxtail, ady, &ti1, &ti0)
                Two_Product(cdx, adytail, &tj1, &tj0)
                let u = Two_Two_Sum(ti1, ti0, tj1, tj0)

                negate = -cdy
                Two_Product(adxtail, negate, &ti1, &ti0)
                negate = -cdytail
                Two_Product(adx, negate, &tj1, &tj0)
                let v = Two_Two_Sum(ti1, ti0, tj1, tj0)
                cat = fast_expansion_sum_zeroelim(u, v)

                Two_Product(cdxtail, adytail, &ti1, &ti0)
                Two_Product(adxtail, cdytail, &tj1, &tj0)
                catt = Two_Two_Diff(ti1, ti0, tj1, tj0)

            } else {
                cat = [0]
                catt = [0]
            }

            if bdxtail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: bxtca, b: bdxtail)
                let bxtcat = scale_expansion_zeroelim(e: cat, b: bdxtail)
                var temp32a = scale_expansion_zeroelim(e: bxtcat, b: 2.0 * bdx)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap
                if cdytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: aa, b: bdxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: cdytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if adytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: cc, b: -bdxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: adytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32a = scale_expansion_zeroelim(e: bxtcat, b: bdxtail)
                let bxtcatt = scale_expansion_zeroelim(e: catt, b: bdxtail)
                temp16a = scale_expansion_zeroelim(e: bxtcatt, b: 2.0 * bdx)
                let temp16b = scale_expansion_zeroelim(e: bxtcatt, b: bdxtail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if bdytail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: bytca, b: bdytail)
                let bytcat = scale_expansion_zeroelim(e: cat, b: bdytail)
                var temp32a = scale_expansion_zeroelim(e: bytcat, b: 2.0 * bdy)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap

                temp32a = scale_expansion_zeroelim(e: bytcat, b: bdytail)
                let bytcatt = scale_expansion_zeroelim(e: catt, b: bdytail)
                temp16a = scale_expansion_zeroelim(e: bytcatt, b: 2.0 * bdy)
                let temp16b = scale_expansion_zeroelim(e: bytcatt, b: bdytail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }
        var abt: [REAL]
        var abtt: [REAL]

        if (cdxtail != 0.0) || (cdytail != 0.0) {

            if (adxtail != 0.0) || (adytail != 0.0)
                || (bdxtail != 0.0) || (bdytail != 0.0) {
                Two_Product(adxtail, bdy, &ti1, &ti0)
                Two_Product(adx, bdytail, &tj1, &tj0)
                let u = Two_Two_Sum(ti1, ti0, tj1, tj0)
                negate = -ady
                Two_Product(bdxtail, negate, &ti1, &ti0)
                negate = -adytail
                Two_Product(bdx, negate, &tj1, &tj0)
                let v = Two_Two_Sum(ti1, ti0, tj1, tj0)
                abt = fast_expansion_sum_zeroelim(u, v)

                Two_Product(adxtail, bdytail, &ti1, &ti0)
                Two_Product(bdxtail, adytail, &tj1, &tj0)
                abtt = Two_Two_Diff(ti1, ti0, tj1, tj0)

            } else {
                abt = [0]
                abtt = [0]
            }

            if cdxtail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: cxtab, b: cdxtail)
                let cxtabt = scale_expansion_zeroelim(e: abt, b: cdxtail)
                var temp32a = scale_expansion_zeroelim(e: cxtabt, b: 2.0 * cdx)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap
                if adytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: bb, b: cdxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: adytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if bdytail != 0.0 {
                    let temp8 = scale_expansion_zeroelim(e: aa, b: -cdxtail)
                    let temp16a = scale_expansion_zeroelim(e: temp8, b: bdytail)
                    finother = fast_expansion_sum_zeroelim(finnow, temp16a)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32a = scale_expansion_zeroelim(e: cxtabt, b: cdxtail)
                let cxtabtt = scale_expansion_zeroelim(e: abtt, b: cdxtail)
                temp16a = scale_expansion_zeroelim(e: cxtabtt, b: 2.0 * cdx)
                let temp16b = scale_expansion_zeroelim(e: cxtabtt, b: cdxtail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if cdytail != 0.0 {
                var temp16a = scale_expansion_zeroelim(e: cytab, b: cdytail)
                let cytabt = scale_expansion_zeroelim(e: abt, b: cdytail)
                var temp32a = scale_expansion_zeroelim(e: cytabt, b: 2.0 * cdy)
                let temp48 = fast_expansion_sum_zeroelim(temp16a, temp32a)
                finother = fast_expansion_sum_zeroelim(finnow, temp48)
                finswap = finnow; finnow = finother; finother = finswap

                temp32a = scale_expansion_zeroelim(e: cytabt, b: cdytail)
                let cytabtt = scale_expansion_zeroelim(e: abtt, b: cdytail)
                temp16a = scale_expansion_zeroelim(e: cytabtt, b: 2.0 * cdy)
                let temp16b = scale_expansion_zeroelim(e: cytabtt, b: cdytail)
                let temp32b = fast_expansion_sum_zeroelim(temp16a, temp16b)
                let temp64 = fast_expansion_sum_zeroelim(temp32a, temp32b)
                finother = fast_expansion_sum_zeroelim(finnow, temp64)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }

        return finnow.last ?? 0
    }

    public static func scale_expansion_zeroelim(e: [REAL], b: REAL) -> [REAL] {
        var bhi: REAL = 0, blo: REAL = 0
        var hh: REAL = 0
        var h = [REAL]()
        var Q: REAL = 0

        Split(b, &bhi, &blo)
        Two_Product_Presplit(e[0], b, bhi, blo, &Q, &hh)
        if hh != 0 {
            h.append(hh)
        }
        for eindex in 1..<e.count {
            let enow = e[eindex]
            var product1: REAL = 0, sum: REAL = 0, product0: REAL = 0
            Two_Product_Presplit(enow, b, bhi, blo, &product1, &product0)
            Two_Sum(Q, product0, &sum, &hh)
            if hh != 0 {
                h.append(hh)
            }
            Fast_Two_Sum(product1, sum, &Q, &hh)
            if hh != 0 {
                h.append(hh)
            }
        }
        if (Q != 0.0) || h.isEmpty {
            h.append(Q)
        }
        return h
    }

    public static func fast_expansion_sum_zeroelim(e: [REAL], f: [REAL]) -> [REAL] {
        var enow = e[0]
        var fnow = f[0]
        var eindex = 0, findex = 0
        var Q: REAL

        var h = [REAL]()
        var hh: REAL = 0

        if (fnow > enow) == (fnow > -enow) {
            Q = enow
            eindex += 1
            enow = e[eindex]
        } else {
            Q = fnow
            findex += 1
            fnow = f[findex]
        }

        if (eindex < e.count) && (findex < f.count) {
            var Qnew: REAL = 0
            if (fnow > enow) == (fnow > -enow) {
                Fast_Two_Sum(enow, Q, &Qnew, &hh)
                eindex += 1
                enow = e[eindex]
            } else {
                Fast_Two_Sum(fnow, Q, &Qnew, &hh)
                findex += 1
                fnow = f[findex]
            }
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
            while (eindex < e.count) && (findex < f.count) {
                if (fnow > enow) == (fnow > -enow) {
                    Two_Sum(Q, enow, &Qnew, &hh)
                    eindex += 1
                    enow = e[eindex]
                } else {
                    Two_Sum(Q, fnow, &Qnew, &hh)
                    findex += 1
                    fnow = f[findex]
                }
                Q = Qnew
                if hh != 0.0 {
                    h.append(hh)
                }
            }
        }
        while eindex < e.count {
            var Qnew: REAL = 0
            Two_Sum(Q, enow, &Qnew, &hh)
            eindex += 1
            enow = e[eindex]
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
        }
        while findex < f.count {
            var Qnew: REAL = 0
            Two_Sum(Q, fnow, &Qnew, &hh)
            findex += 1
            fnow = f[findex]
            Q = Qnew
            if hh != 0.0 {
                h.append(hh)
            }
        }
        if (Q != 0.0) || (h.isEmpty) {
            h.append(Q)
        }
        return h
    }

}
