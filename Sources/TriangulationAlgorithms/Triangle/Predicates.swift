//
//  swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

final class Predicates {
    private let epsilon: REAL, splitter: REAL, resulterrbound: REAL
    private let ccwerrboundA: REAL, ccwerrboundB: REAL, ccwerrboundC: REAL
    private let iccerrboundA: REAL, iccerrboundB: REAL, iccerrboundC: REAL

    // InCircleAdapt workspace:
    private var fin1 = [REAL](repeating: 0, count: 1152), fin2 = [REAL](repeating: 0, count: 1152), abdet = [REAL](repeating: 0, count: 64)
    private var axbc = [REAL](repeating: 0, count: 8), axxbc = [REAL](repeating: 0, count: 16), aybc = [REAL](repeating: 0, count: 8), ayybc = [REAL](repeating: 0, count: 16), adet = [REAL](repeating: 0, count: 32)
    private var bxca = [REAL](repeating: 0, count: 8), bxxca = [REAL](repeating: 0, count: 16), byca = [REAL](repeating: 0, count: 8), byyca = [REAL](repeating: 0, count: 16), bdet = [REAL](repeating: 0, count: 32)
    private var cxab = [REAL](repeating: 0, count: 8), cxxab = [REAL](repeating: 0, count: 16), cyab = [REAL](repeating: 0, count: 8), cyyab = [REAL](repeating: 0, count: 16), cdet  = [REAL](repeating: 0, count: 32)

    private var temp8 = [REAL](repeating: 0, count: 8), temp16a = [REAL](repeating: 0, count: 16), temp16b = [REAL](repeating: 0, count: 16), temp16c = [REAL](repeating: 0, count: 16)
    private var temp32a  = [REAL](repeating: 0, count: 32), temp32b  = [REAL](repeating: 0, count: 32), temp48  = [REAL](repeating: 0, count: 48), temp64  = [REAL](repeating: 0, count: 64)

    private let exact: Bool

    public init(exact: Bool = true) {
        self.exact = exact
        var every_other = true
        let half: REAL = 0.5
        var epsilon: REAL = 1.0
        var splitter: REAL = 1.0
        var check: REAL = 1.0
        var lastcheck: REAL
        // Repeatedly divide 'epsilon' by two until it is too small to add to
        // one without causing roundoff.  (Also check if the sum is equal to
        // the previous sum, for machines that round up instead of using exact
        // rounding.  Not that these routines will work on such machines.)
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
        self.epsilon = epsilon
        self.splitter = splitter
        // Error bounds for orientation and incircle tests.
        self.resulterrbound = (3.0 + 8.0 * epsilon) * epsilon
        self.ccwerrboundA = (3.0 + 16.0 * epsilon) * epsilon
        self.ccwerrboundB = (2.0 + 12.0 * epsilon) * epsilon
        self.ccwerrboundC = (9.0 + 64.0 * epsilon) * epsilon * epsilon
        self.iccerrboundA = (10.0 + 96.0 * epsilon) * epsilon
        self.iccerrboundB = (4.0 + 48.0 * epsilon) * epsilon
        self.iccerrboundC = (44.0 + 576.0 * epsilon) * epsilon * epsilon
    }

    public func counterClockwise(a pa: Vertex, b pb: Vertex, c pc: Vertex) -> REAL {

        let detleft = (pa.x - pc.x) * (pb.y - pc.y)
        let detright = (pa.y - pc.y) * (pb.x - pc.x)
        let det = detleft - detright

        if !exact {
            return det
        }

        let detsum: REAL

        if detleft > 0.0 {
            if detright <= 0.0 {
                return det
            } else {
                detsum = detleft + detright
            }
        } else if detleft < 0.0 {
            if detright >= 0.0 {
                return det
            } else {
                detsum = -detleft - detright
            }
        } else {
            return det
        }

        let errbound = ccwerrboundA * detsum
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        return counterClockwiseAdapt(pa: pa, pb: pb, pc: pc, detsum: detsum)

    }

    public func inCircle(a pa: Vector2, b pb: Vector2, c pc: Vector2, d pd: Vector2) -> REAL {

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

        let det = alift * (bdxcdy - cdxbdy)
            + blift * (cdxady - adxcdy)
            + clift * (adxbdy - bdxady)

        if !exact {
            return det
        }

        let permanent = (abs(bdxcdy) + abs(cdxbdy)) * alift
            + (abs(cdxady) + abs(adxcdy)) * blift
            + (abs(adxbdy) + abs(bdxady)) * clift
        let errbound = iccerrboundA * permanent
        if (det > errbound) || (-det > errbound) {
            return det
        }

        return inCircleAdapt(pa: pa, pb: pb, pc: pc, pd: pd, permanent: permanent)
    }

    public func nonRegular( pa: Vector2, pb: Vector2, pc: Vector2, pd: Vector2) -> REAL {
        return inCircle(a: pa, b: pb, c: pc, d: pd)
    }

    private var bc = [REAL](repeating: 0, count: 4), ca = [REAL](repeating: 0, count: 4), ab = [REAL](repeating: 0, count: 4)
    private var aa = [REAL](repeating: 0, count: 4), bb = [REAL](repeating: 0, count: 4), cc = [REAL](repeating: 0, count: 4)
    private var u = [REAL](repeating: 0, count: 5), v = [REAL](repeating: 0, count: 5)
    private var axtbctt = [REAL](repeating: 0, count: 8), aytbctt = [REAL](repeating: 0, count: 8), bxtcatt = [REAL](repeating: 0, count: 8)
    private var bytcatt = [REAL](repeating: 0, count: 8), cxtabtt = [REAL](repeating: 0, count: 8), cytabtt = [REAL](repeating: 0, count: 8)
    private var abtt = [REAL](repeating: 0, count: 4), bctt = [REAL](repeating: 0, count: 4), catt = [REAL](repeating: 0, count: 4)
    private var abt = [REAL](repeating: 0, count: 8), bct = [REAL](repeating: 0, count: 8), cat = [REAL](repeating: 0, count: 8)
    private var axtbct = [REAL](repeating: 0, count: 16), aytbct = [REAL](repeating: 0, count: 16), bxtcat = [REAL](repeating: 0, count: 16), bytcat = [REAL](repeating: 0, count: 16), cxtabt = [REAL](repeating: 0, count: 16), cytabt = [REAL](repeating: 0, count: 16)
    private var axtbb = [REAL](repeating: 0, count: 8), axtcc = [REAL](repeating: 0, count: 8), aytbb = [REAL](repeating: 0, count: 8), aytcc = [REAL](repeating: 0, count: 8)
    private var axtbblen = 0, axtcclen = 0, aytbblen = 0, aytcclen = 0
    private var bxtaa = [REAL](repeating: 0, count: 8), bxtcc = [REAL](repeating: 0, count: 8), bytaa = [REAL](repeating: 0, count: 8), bytcc = [REAL](repeating: 0, count: 8)
    private var bxtaalen = 0, bxtcclen = 0, bytaalen = 0, bytcclen = 0
    private var cxtaa = [REAL](repeating: 0, count: 8), cxtbb = [REAL](repeating: 0, count: 8), cytaa = [REAL](repeating: 0, count: 8), cytbb = [REAL](repeating: 0, count: 8)
    private var cxtaalen = 0, cxtbblen = 0, cytaalen = 0, cytbblen = 0
    private var axtbc = [REAL](repeating: 0, count: 8), aytbc = [REAL](repeating: 0, count: 8), bxtca = [REAL](repeating: 0, count: 8), bytca = [REAL](repeating: 0, count: 8), cxtab = [REAL](repeating: 0, count: 8), cytab = [REAL](repeating: 0, count: 8)
    private func inCircleAdapt(pa: Vector2, pb: Vector2, pc: Vector2, pd: Vector2, permanent: REAL) -> REAL {

        var adx: REAL = 0, bdx: REAL = 0, cdx: REAL = 0, ady: REAL = 0, bdy: REAL = 0, cdy: REAL = 0
        var det: REAL = 0, errbound: REAL = 0

        var bdxcdy1: REAL = 0, cdxbdy1: REAL = 0, cdxady1: REAL = 0, adxcdy1: REAL = 0, adxbdy1: REAL = 0, bdxady1: REAL = 0
        var bdxcdy0: REAL = 0, cdxbdy0: REAL = 0, cdxady0: REAL = 0, adxcdy0: REAL = 0, adxbdy0: REAL = 0, bdxady0: REAL = 0
        var bc3: REAL = 0, ca3: REAL = 0, ab3: REAL = 0
        var axbclen = 0, axxbclen = 0, aybclen = 0, ayybclen = 0, alen = 0
        var bxcalen = 0, bxxcalen = 0, bycalen = 0, byycalen = 0, blen = 0
        var cxablen = 0, cxxablen = 0, cyablen = 0, cyyablen = 0, clen = 0
        var ablen = 0
        var finnow: [REAL], finother: [REAL], finswap: [REAL]
        var finlength = 0

        var adxtail: REAL = 0, bdxtail: REAL = 0, cdxtail: REAL = 0, adytail: REAL = 0, bdytail: REAL = 0, cdytail: REAL = 0
        var adxadx1: REAL = 0, adyady1: REAL = 0, bdxbdx1: REAL = 0, bdybdy1: REAL = 0, cdxcdx1: REAL = 0, cdycdy1: REAL = 0
        var adxadx0: REAL = 0, adyady0: REAL = 0, bdxbdx0: REAL = 0, bdybdy0: REAL = 0, cdxcdx0: REAL = 0, cdycdy0: REAL = 0
        var aa3: REAL = 0, bb3: REAL = 0, cc3: REAL = 0
        var ti1: REAL = 0, tj1: REAL = 0
        var ti0: REAL = 0, tj0: REAL = 0
        // Edited to work around index out of range exceptions (changed array length from 4 to 5).
        // See unsafe indexing in FastExpansionSumZeroElim.
        var u3: REAL = 0, v3: REAL = 0
        var temp8len = 0, temp16alen = 0, temp16blen = 0, temp16clen = 0
        var temp32alen = 0, temp32blen = 0, temp48len = 0, temp64len = 0

        var axtbclen = 0, aytbclen = 0, bxtcalen = 0, bytcalen = 0, cxtablen = 0, cytablen = 0
        var axtbctlen = 0, aytbctlen = 0, bxtcatlen = 0, bytcatlen = 0, cxtabtlen = 0, cytabtlen = 0
        var axtbcttlen = 0, aytbcttlen = 0, bxtcattlen = 0, bytcattlen = 0, cxtabttlen = 0, cytabttlen = 0
        var abtlen = 0, bctlen = 0, catlen = 0
        var abttlen = 0, bcttlen = 0, cattlen = 0
        var abtt3: REAL = 0, bctt3: REAL = 0, catt3: REAL = 0
        var negate: REAL = 0

        var bvirt: REAL = 0
        var avirt: REAL = 0, bround: REAL = 0, around: REAL = 0
        var c: REAL = 0
        var abig: REAL = 0
        var ahi: REAL = 0, alo: REAL = 0, bhi: REAL = 0, blo: REAL = 0
        var err1: REAL = 0, err2: REAL = 0, err3: REAL = 0
        var _i: REAL = 0, _j: REAL = 0
        var _0: REAL = 0

        adx = (pa.x - pd.x)
        bdx = (pb.x - pd.x)
        cdx = (pc.x - pd.x)
        ady = (pa.y - pd.y)
        bdy = (pb.y - pd.y)
        cdy = (pc.y - pd.y)

        adx = (pa.x - pd.x)
        bdx = (pb.x - pd.x)
        cdx = (pc.x - pd.x)
        ady = (pa.y - pd.y)
        bdy = (pb.y - pd.y)
        cdy = (pc.y - pd.y)

        bdxcdy1 = (bdx * cdy); c = (splitter * bdx); abig = (c - bdx); ahi = c - abig; alo = bdx - ahi; c = (splitter * cdy); abig = (c - cdy); bhi = c - abig; blo = cdy - bhi; err1 = bdxcdy1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); bdxcdy0 = (alo * blo) - err3
        cdxbdy1 = (cdx * bdy); c = (splitter * cdx); abig = (c - cdx); ahi = c - abig; alo = cdx - ahi; c = (splitter * bdy); abig = (c - bdy); bhi = c - abig; blo = bdy - bhi; err1 = cdxbdy1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); cdxbdy0 = (alo * blo) - err3
        _i = (bdxcdy0 - cdxbdy0); bvirt = (bdxcdy0 - _i); avirt = _i + bvirt; bround = bvirt - cdxbdy0; around = bdxcdy0 - avirt; bc[0] = around + bround; _j = (bdxcdy1 + _i); bvirt = (_j - bdxcdy1); avirt = _j - bvirt; bround = _i - bvirt; around = bdxcdy1 - avirt; _0 = around + bround; _i = (_0 - cdxbdy1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - cdxbdy1; around = _0 - avirt; bc[1] = around + bround; bc3 = (_j + _i); bvirt = (bc3 - _j); avirt = bc3 - bvirt; bround = _i - bvirt; around = _j - avirt; bc[2] = around + bround
        bc[3] = bc3
        axbclen = scaleExpansionZeroElim(elen: 4, e: bc, b: adx, h: &axbc)
        axxbclen = scaleExpansionZeroElim(elen: axbclen, e: axbc, b: adx, h: &axxbc)
        aybclen = scaleExpansionZeroElim(elen: 4, e: bc, b: ady, h: &aybc)
        ayybclen = scaleExpansionZeroElim(elen: aybclen, e: aybc, b: ady, h: &ayybc)
        alen = fastExpansionSumZeroElim(elen: axxbclen, e: axxbc, flen: ayybclen, f: ayybc, h: &adet)

        cdxady1 = (cdx * ady); c = (splitter * cdx); abig = (c - cdx); ahi = c - abig; alo = cdx - ahi; c = (splitter * ady); abig = (c - ady); bhi = c - abig; blo = ady - bhi; err1 = cdxady1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); cdxady0 = (alo * blo) - err3
        adxcdy1 = (adx * cdy); c = (splitter * adx); abig = (c - adx); ahi = c - abig; alo = adx - ahi; c = (splitter * cdy); abig = (c - cdy); bhi = c - abig; blo = cdy - bhi; err1 = adxcdy1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); adxcdy0 = (alo * blo) - err3
        _i = (cdxady0 - adxcdy0); bvirt = (cdxady0 - _i); avirt = _i + bvirt; bround = bvirt - adxcdy0; around = cdxady0 - avirt; ca[0] = around + bround; _j = (cdxady1 + _i); bvirt = (_j - cdxady1); avirt = _j - bvirt; bround = _i - bvirt; around = cdxady1 - avirt; _0 = around + bround; _i = (_0 - adxcdy1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - adxcdy1; around = _0 - avirt; ca[1] = around + bround; ca3 = (_j + _i); bvirt = (ca3 - _j); avirt = ca3 - bvirt; bround = _i - bvirt; around = _j - avirt; ca[2] = around + bround
        ca[3] = ca3
        bxcalen = scaleExpansionZeroElim(elen: 4, e: ca, b: bdx, h: &bxca)
        bxxcalen = scaleExpansionZeroElim(elen: bxcalen, e: bxca, b: bdx, h: &bxxca)
        bycalen = scaleExpansionZeroElim(elen: 4, e: ca, b: bdy, h: &byca)
        byycalen = scaleExpansionZeroElim(elen: bycalen, e: byca, b: bdy, h: &byyca)
        blen = fastExpansionSumZeroElim(elen: bxxcalen, e: bxxca, flen: byycalen, f: byyca, h: &bdet)

        adxbdy1 = (adx * bdy); c = (splitter * adx); abig = (c - adx); ahi = c - abig; alo = adx - ahi; c = (splitter * bdy); abig = (c - bdy); bhi = c - abig; blo = bdy - bhi; err1 = adxbdy1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); adxbdy0 = (alo * blo) - err3
        bdxady1 = (bdx * ady); c = (splitter * bdx); abig = (c - bdx); ahi = c - abig; alo = bdx - ahi; c = (splitter * ady); abig = (c - ady); bhi = c - abig; blo = ady - bhi; err1 = bdxady1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); bdxady0 = (alo * blo) - err3
        _i = (adxbdy0 - bdxady0); bvirt = (adxbdy0 - _i); avirt = _i + bvirt; bround = bvirt - bdxady0; around = adxbdy0 - avirt; ab[0] = around + bround; _j = (adxbdy1 + _i); bvirt = (_j - adxbdy1); avirt = _j - bvirt; bround = _i - bvirt; around = adxbdy1 - avirt; _0 = around + bround; _i = (_0 - bdxady1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - bdxady1; around = _0 - avirt; ab[1] = around + bround; ab3 = (_j + _i); bvirt = (ab3 - _j); avirt = ab3 - bvirt; bround = _i - bvirt; around = _j - avirt; ab[2] = around + bround
        ab[3] = ab3
        cxablen = scaleExpansionZeroElim(elen: 4, e: ab, b: cdx, h: &cxab)
        cxxablen = scaleExpansionZeroElim(elen: cxablen, e: cxab, b: cdx, h: &cxxab)
        cyablen = scaleExpansionZeroElim(elen: 4, e: ab, b: cdy, h: &cyab)
        cyyablen = scaleExpansionZeroElim(elen: cyablen, e: cyab, b: cdy, h: &cyyab)
        clen = fastExpansionSumZeroElim(elen: cxxablen, e: cxxab, flen: cyyablen, f: cyyab, h: &cdet)

        ablen = fastExpansionSumZeroElim(elen: alen, e: adet, flen: blen, f: bdet, h: &abdet)
        finlength = fastExpansionSumZeroElim(elen: ablen, e: abdet, flen: clen, f: cdet, h: &fin1)

        det = estimate(elen: finlength, e: fin1)
        errbound = iccerrboundB * permanent
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        bvirt = (pa.x - adx); avirt = adx + bvirt; bround = bvirt - pd.x; around = pa.x - avirt; adxtail = around + bround
        bvirt = (pa.y - ady); avirt = ady + bvirt; bround = bvirt - pd.y; around = pa.y - avirt; adytail = around + bround
        bvirt = (pb.x - bdx); avirt = bdx + bvirt; bround = bvirt - pd.x; around = pb.x - avirt; bdxtail = around + bround
        bvirt = (pb.y - bdy); avirt = bdy + bvirt; bround = bvirt - pd.y; around = pb.y - avirt; bdytail = around + bround
        bvirt = (pc.x - cdx); avirt = cdx + bvirt; bround = bvirt - pd.x; around = pc.x - avirt; cdxtail = around + bround
        bvirt = (pc.y - cdy); avirt = cdy + bvirt; bround = bvirt - pd.y; around = pc.y - avirt; cdytail = around + bround
        if (adxtail == 0.0) && (bdxtail == 0.0) && (cdxtail == 0.0)
            && (adytail == 0.0) && (bdytail == 0.0) && (cdytail == 0.0) {
            return det
        }

        errbound = iccerrboundC * permanent + resulterrbound * ((det) >= 0.0 ? (det) : -(det))
        det += ((adx * adx + ady * ady) * ((bdx * cdytail + cdy * bdxtail) - (bdy * cdxtail + cdx * bdytail))
            + 2.0 * (adx * adxtail + ady * adytail) * (bdx * cdy - bdy * cdx))
            + ((bdx * bdx + bdy * bdy) * ((cdx * adytail + ady * cdxtail) - (cdy * adxtail + adx * cdytail))
                + 2.0 * (bdx * bdxtail + bdy * bdytail) * (cdx * ady - cdy * adx))
            + ((cdx * cdx + cdy * cdy) * ((adx * bdytail + bdy * adxtail) - (ady * bdxtail + bdx * adytail))
                + 2.0 * (cdx * cdxtail + cdy * cdytail) * (adx * bdy - ady * bdx))
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        finnow = fin1
        finother = fin2

        if (bdxtail != 0.0) || (bdytail != 0.0) || (cdxtail != 0.0) || (cdytail != 0.0) {
            adxadx1 = (adx * adx); c = (splitter * adx); abig = (c - adx); ahi = c - abig; alo = adx - ahi; err1 = adxadx1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); adxadx0 = (alo * alo) - err3
            adyady1 = (ady * ady); c = (splitter * ady); abig = (c - ady); ahi = c - abig; alo = ady - ahi; err1 = adyady1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); adyady0 = (alo * alo) - err3
            _i = (adxadx0 + adyady0); bvirt = (_i - adxadx0); avirt = _i - bvirt; bround = adyady0 - bvirt; around = adxadx0 - avirt; aa[0] = around + bround; _j = (adxadx1 + _i); bvirt = (_j - adxadx1); avirt = _j - bvirt; bround = _i - bvirt; around = adxadx1 - avirt; _0 = around + bround; _i = (_0 + adyady1); bvirt = (_i - _0); avirt = _i - bvirt; bround = adyady1 - bvirt; around = _0 - avirt; aa[1] = around + bround; aa3 = (_j + _i); bvirt = (aa3 - _j); avirt = aa3 - bvirt; bround = _i - bvirt; around = _j - avirt; aa[2] = around + bround
            aa[3] = aa3
        }
        if (cdxtail != 0.0) || (cdytail != 0.0) || (adxtail != 0.0) || (adytail != 0.0) {
            bdxbdx1 = (bdx * bdx); c = (splitter * bdx); abig = (c - bdx); ahi = c - abig; alo = bdx - ahi; err1 = bdxbdx1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); bdxbdx0 = (alo * alo) - err3
            bdybdy1 = (bdy * bdy); c = (splitter * bdy); abig = (c - bdy); ahi = c - abig; alo = bdy - ahi; err1 = bdybdy1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); bdybdy0 = (alo * alo) - err3
            _i = (bdxbdx0 + bdybdy0); bvirt = (_i - bdxbdx0); avirt = _i - bvirt; bround = bdybdy0 - bvirt; around = bdxbdx0 - avirt; bb[0] = around + bround; _j = (bdxbdx1 + _i); bvirt = (_j - bdxbdx1); avirt = _j - bvirt; bround = _i - bvirt; around = bdxbdx1 - avirt; _0 = around + bround; _i = (_0 + bdybdy1); bvirt = (_i - _0); avirt = _i - bvirt; bround = bdybdy1 - bvirt; around = _0 - avirt; bb[1] = around + bround; bb3 = (_j + _i); bvirt = (bb3 - _j); avirt = bb3 - bvirt; bround = _i - bvirt; around = _j - avirt; bb[2] = around + bround
            bb[3] = bb3
        }
        if (adxtail != 0.0) || (adytail != 0.0) || (bdxtail != 0.0) || (bdytail != 0.0) {
            cdxcdx1 = (cdx * cdx); c = (splitter * cdx); abig = (c - cdx); ahi = c - abig; alo = cdx - ahi; err1 = cdxcdx1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); cdxcdx0 = (alo * alo) - err3
            cdycdy1 = (cdy * cdy); c = (splitter * cdy); abig = (c - cdy); ahi = c - abig; alo = cdy - ahi; err1 = cdycdy1 - (ahi * ahi); err3 = err1 - ((ahi + ahi) * alo); cdycdy0 = (alo * alo) - err3
            _i = (cdxcdx0 + cdycdy0); bvirt = (_i - cdxcdx0); avirt = _i - bvirt; bround = cdycdy0 - bvirt; around = cdxcdx0 - avirt; cc[0] = around + bround; _j = (cdxcdx1 + _i); bvirt = (_j - cdxcdx1); avirt = _j - bvirt; bround = _i - bvirt; around = cdxcdx1 - avirt; _0 = around + bround; _i = (_0 + cdycdy1); bvirt = (_i - _0); avirt = _i - bvirt; bround = cdycdy1 - bvirt; around = _0 - avirt; cc[1] = around + bround; cc3 = (_j + _i); bvirt = (cc3 - _j); avirt = cc3 - bvirt; bround = _i - bvirt; around = _j - avirt; cc[2] = around + bround
            cc[3] = cc3
        }

        if adxtail != 0.0 {
            axtbclen = scaleExpansionZeroElim(elen: 4, e: bc, b: adxtail, h: &axtbc)
            temp16alen = scaleExpansionZeroElim(elen: axtbclen, e: axtbc, b: 2.0 * adx, h: &temp16a)

            axtcclen = scaleExpansionZeroElim(elen: 4, e: cc, b: adxtail, h: &axtcc)
            temp16blen = scaleExpansionZeroElim(elen: axtcclen, e: axtcc, b: bdy, h: &temp16b)

            axtbblen = scaleExpansionZeroElim(elen: 4, e: bb, b: adxtail, h: &axtbb)
            temp16clen = scaleExpansionZeroElim(elen: axtbblen, e: axtbb, b: -cdy, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }
        if adytail != 0.0 {
            aytbclen = scaleExpansionZeroElim(elen: 4, e: bc, b: adytail, h: &aytbc)
            temp16alen = scaleExpansionZeroElim(elen: aytbclen, e: aytbc, b: 2.0 * ady, h: &temp16a)

            aytbblen = scaleExpansionZeroElim(elen: 4, e: bb, b: adytail, h: &aytbb)
            temp16blen = scaleExpansionZeroElim(elen: aytbblen, e: aytbb, b: cdx, h: &temp16b)

            aytcclen = scaleExpansionZeroElim(elen: 4, e: cc, b: adytail, h: &aytcc)
            temp16clen = scaleExpansionZeroElim(elen: aytcclen, e: aytcc, b: -bdx, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }
        if bdxtail != 0.0 {
            bxtcalen = scaleExpansionZeroElim(elen: 4, e: ca, b: bdxtail, h: &bxtca)
            temp16alen = scaleExpansionZeroElim(elen: bxtcalen, e: bxtca, b: 2.0 * bdx, h: &temp16a)

            bxtaalen = scaleExpansionZeroElim(elen: 4, e: aa, b: bdxtail, h: &bxtaa)
            temp16blen = scaleExpansionZeroElim(elen: bxtaalen, e: bxtaa, b: cdy, h: &temp16b)

            bxtcclen = scaleExpansionZeroElim(elen: 4, e: cc, b: bdxtail, h: &bxtcc)
            temp16clen = scaleExpansionZeroElim(elen: bxtcclen, e: bxtcc, b: -ady, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }
        if bdytail != 0.0 {
            bytcalen = scaleExpansionZeroElim(elen: 4, e: ca, b: bdytail, h: &bytca)
            temp16alen = scaleExpansionZeroElim(elen: bytcalen, e: bytca, b: 2.0 * bdy, h: &temp16a)

            bytcclen = scaleExpansionZeroElim(elen: 4, e: cc, b: bdytail, h: &bytcc)
            temp16blen = scaleExpansionZeroElim(elen: bytcclen, e: bytcc, b: adx, h: &temp16b)

            bytaalen = scaleExpansionZeroElim(elen: 4, e: aa, b: bdytail, h: &bytaa)
            temp16clen = scaleExpansionZeroElim(elen: bytaalen, e: bytaa, b: -cdx, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }
        if cdxtail != 0.0 {
            cxtablen = scaleExpansionZeroElim(elen: 4, e: ab, b: cdxtail, h: &cxtab)
            temp16alen = scaleExpansionZeroElim(elen: cxtablen, e: cxtab, b: 2.0 * cdx, h: &temp16a)

            cxtbblen = scaleExpansionZeroElim(elen: 4, e: bb, b: cdxtail, h: &cxtbb)
            temp16blen = scaleExpansionZeroElim(elen: cxtbblen, e: cxtbb, b: ady, h: &temp16b)

            cxtaalen = scaleExpansionZeroElim(elen: 4, e: aa, b: cdxtail, h: &cxtaa)
            temp16clen = scaleExpansionZeroElim(elen: cxtaalen, e: cxtaa, b: -bdy, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }
        if cdytail != 0.0 {
            cytablen = scaleExpansionZeroElim(elen: 4, e: ab, b: cdytail, h: &cytab)
            temp16alen = scaleExpansionZeroElim(elen: cytablen, e: cytab, b: 2.0 * cdy, h: &temp16a)

            cytaalen = scaleExpansionZeroElim(elen: 4, e: aa, b: cdytail, h: &cytaa)
            temp16blen = scaleExpansionZeroElim(elen: cytaalen, e: cytaa, b: bdx, h: &temp16b)

            cytbblen = scaleExpansionZeroElim(elen: 4, e: bb, b: cdytail, h: &cytbb)
            temp16clen = scaleExpansionZeroElim(elen: cytbblen, e: cytbb, b: -adx, h: &temp16c)

            temp32alen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32a)
            temp48len = fastExpansionSumZeroElim(elen: temp16clen, e: temp16c, flen: temp32alen, f: temp32a, h: &temp48)
            finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
            finswap = finnow; finnow = finother; finother = finswap
        }

        if (adxtail != 0.0) || (adytail != 0.0) {
            if (bdxtail != 0.0) || (bdytail != 0.0)
                || (cdxtail != 0.0) || (cdytail != 0.0) {
                ti1 = (bdxtail * cdy); c = (splitter * bdxtail); abig = (c - bdxtail); ahi = c - abig; alo = bdxtail - ahi; c = (splitter * cdy); abig = (c - cdy); bhi = c - abig; blo = cdy - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (bdx * cdytail); c = (splitter * bdx); abig = (c - bdx); ahi = c - abig; alo = bdx - ahi; c = (splitter * cdytail); abig = (c - cdytail); bhi = c - abig; blo = cdytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; u[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
                u[3] = u3
                negate = -bdy
                ti1 = (cdxtail * negate); c = (splitter * cdxtail); abig = (c - cdxtail); ahi = c - abig; alo = cdxtail - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                negate = -bdytail
                tj1 = (cdx * negate); c = (splitter * cdx); abig = (c - cdx); ahi = c - abig; alo = cdx - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; v[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; v[1] = around + bround; v3 = (_j + _i); bvirt = (v3 - _j); avirt = v3 - bvirt; bround = _i - bvirt; around = _j - avirt; v[2] = around + bround
                v[3] = v3
                bctlen = fastExpansionSumZeroElim(elen: 4, e: u, flen: 4, f: v, h: &bct)

                ti1 = (bdxtail * cdytail); c = (splitter * bdxtail); abig = (c - bdxtail); ahi = c - abig; alo = bdxtail - ahi; c = (splitter * cdytail); abig = (c - cdytail); bhi = c - abig; blo = cdytail - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (cdxtail * bdytail); c = (splitter * cdxtail); abig = (c - cdxtail); ahi = c - abig; alo = cdxtail - ahi; c = (splitter * bdytail); abig = (c - bdytail); bhi = c - abig; blo = bdytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 - tj0); bvirt = (ti0 - _i); avirt = _i + bvirt; bround = bvirt - tj0; around = ti0 - avirt; bctt[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 - tj1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - tj1; around = _0 - avirt; bctt[1] = around + bround; bctt3 = (_j + _i); bvirt = (bctt3 - _j); avirt = bctt3 - bvirt; bround = _i - bvirt; around = _j - avirt; bctt[2] = around + bround
                bctt[3] = bctt3
                bcttlen = 4
            } else {
                bct[0] = 0.0
                bctlen = 1
                bctt[0] = 0.0
                bcttlen = 1
            }

            if adxtail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: axtbclen, e: axtbc, b: adxtail, h: &temp16a)
                axtbctlen = scaleExpansionZeroElim(elen: bctlen, e: bct, b: adxtail, h: &axtbct)
                temp32alen = scaleExpansionZeroElim(elen: axtbctlen, e: axtbct, b: 2.0 * adx, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
                if bdytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: cc, b: adxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: bdytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if cdytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: bb, b: -adxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: cdytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32alen = scaleExpansionZeroElim(elen: axtbctlen, e: axtbct, b: adxtail, h: &temp32a)
                axtbcttlen = scaleExpansionZeroElim(elen: bcttlen, e: bctt, b: adxtail, h: &axtbctt)
                temp16alen = scaleExpansionZeroElim(elen: axtbcttlen, e: axtbctt, b: 2.0 * adx, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: axtbcttlen, e: axtbctt, b: adxtail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if adytail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: aytbclen, e: aytbc, b: adytail, h: &temp16a)
                aytbctlen = scaleExpansionZeroElim(elen: bctlen, e: bct, b: adytail, h: &aytbct)
                temp32alen = scaleExpansionZeroElim(elen: aytbctlen, e: aytbct, b: 2.0 * ady, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap

                temp32alen = scaleExpansionZeroElim(elen: aytbctlen, e: aytbct, b: adytail, h: &temp32a)
                aytbcttlen = scaleExpansionZeroElim(elen: bcttlen, e: bctt, b: adytail, h: &aytbctt)
                temp16alen = scaleExpansionZeroElim(elen: aytbcttlen, e: aytbctt, b: 2.0 * ady, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: aytbcttlen, e: aytbctt, b: adytail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }
        if (bdxtail != 0.0) || (bdytail != 0.0) {
            if (cdxtail != 0.0) || (cdytail != 0.0)
                || (adxtail != 0.0) || (adytail != 0.0) {
                ti1 = (cdxtail * ady); c = (splitter * cdxtail); abig = (c - cdxtail); ahi = c - abig; alo = cdxtail - ahi; c = (splitter * ady); abig = (c - ady); bhi = c - abig; blo = ady - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (cdx * adytail); c = (splitter * cdx); abig = (c - cdx); ahi = c - abig; alo = cdx - ahi; c = (splitter * adytail); abig = (c - adytail); bhi = c - abig; blo = adytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; u[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
                u[3] = u3
                negate = -cdy
                ti1 = (adxtail * negate); c = (splitter * adxtail); abig = (c - adxtail); ahi = c - abig; alo = adxtail - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                negate = -cdytail
                tj1 = (adx * negate); c = (splitter * adx); abig = (c - adx); ahi = c - abig; alo = adx - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; v[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; v[1] = around + bround; v3 = (_j + _i); bvirt = (v3 - _j); avirt = v3 - bvirt; bround = _i - bvirt; around = _j - avirt; v[2] = around + bround
                v[3] = v3
                catlen = fastExpansionSumZeroElim(elen: 4, e: u, flen: 4, f: v, h: &cat)

                ti1 = (cdxtail * adytail); c = (splitter * cdxtail); abig = (c - cdxtail); ahi = c - abig; alo = cdxtail - ahi; c = (splitter * adytail); abig = (c - adytail); bhi = c - abig; blo = adytail - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (adxtail * cdytail); c = (splitter * adxtail); abig = (c - adxtail); ahi = c - abig; alo = adxtail - ahi; c = (splitter * cdytail); abig = (c - cdytail); bhi = c - abig; blo = cdytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 - tj0); bvirt = (ti0 - _i); avirt = _i + bvirt; bround = bvirt - tj0; around = ti0 - avirt; catt[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 - tj1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - tj1; around = _0 - avirt; catt[1] = around + bround; catt3 = (_j + _i); bvirt = (catt3 - _j); avirt = catt3 - bvirt; bround = _i - bvirt; around = _j - avirt; catt[2] = around + bround
                catt[3] = catt3
                cattlen = 4
            } else {
                cat[0] = 0.0
                catlen = 1
                catt[0] = 0.0
                cattlen = 1
            }

            if bdxtail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: bxtcalen, e: bxtca, b: bdxtail, h: &temp16a)
                bxtcatlen = scaleExpansionZeroElim(elen: catlen, e: cat, b: bdxtail, h: &bxtcat)
                temp32alen = scaleExpansionZeroElim(elen: bxtcatlen, e: bxtcat, b: 2.0 * bdx, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
                if cdytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: aa, b: bdxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: cdytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if adytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: cc, b: -bdxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: adytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32alen = scaleExpansionZeroElim(elen: bxtcatlen, e: bxtcat, b: bdxtail, h: &temp32a)
                bxtcattlen = scaleExpansionZeroElim(elen: cattlen, e: catt, b: bdxtail, h: &bxtcatt)
                temp16alen = scaleExpansionZeroElim(elen: bxtcattlen, e: bxtcatt, b: 2.0 * bdx, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: bxtcattlen, e: bxtcatt, b: bdxtail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if bdytail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: bytcalen, e: bytca, b: bdytail, h: &temp16a)
                bytcatlen = scaleExpansionZeroElim(elen: catlen, e: cat, b: bdytail, h: &bytcat)
                temp32alen = scaleExpansionZeroElim(elen: bytcatlen, e: bytcat, b: 2.0 * bdy, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap

                temp32alen = scaleExpansionZeroElim(elen: bytcatlen, e: bytcat, b: bdytail, h: &temp32a)
                bytcattlen = scaleExpansionZeroElim(elen: cattlen, e: catt, b: bdytail, h: &bytcatt)
                temp16alen = scaleExpansionZeroElim(elen: bytcattlen, e: bytcatt, b: 2.0 * bdy, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: bytcattlen, e: bytcatt, b: bdytail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }
        if (cdxtail != 0.0) || (cdytail != 0.0) {
            if (adxtail != 0.0) || (adytail != 0.0)
                || (bdxtail != 0.0) || (bdytail != 0.0) {
                ti1 = (adxtail * bdy); c = (splitter * adxtail); abig = (c - adxtail); ahi = c - abig; alo = adxtail - ahi; c = (splitter * bdy); abig = (c - bdy); bhi = c - abig; blo = bdy - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (adx * bdytail); c = (splitter * adx); abig = (c - adx); ahi = c - abig; alo = adx - ahi; c = (splitter * bdytail); abig = (c - bdytail); bhi = c - abig; blo = bdytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; u[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
                u[3] = u3
                negate = -ady
                ti1 = (bdxtail * negate); c = (splitter * bdxtail); abig = (c - bdxtail); ahi = c - abig; alo = bdxtail - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                negate = -adytail
                tj1 = (bdx * negate); c = (splitter * bdx); abig = (c - bdx); ahi = c - abig; alo = bdx - ahi; c = (splitter * negate); abig = (c - negate); bhi = c - abig; blo = negate - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 + tj0); bvirt = (_i - ti0); avirt = _i - bvirt; bround = tj0 - bvirt; around = ti0 - avirt; v[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 + tj1); bvirt = (_i - _0); avirt = _i - bvirt; bround = tj1 - bvirt; around = _0 - avirt; v[1] = around + bround; v3 = (_j + _i); bvirt = (v3 - _j); avirt = v3 - bvirt; bround = _i - bvirt; around = _j - avirt; v[2] = around + bround
                v[3] = v3
                abtlen = fastExpansionSumZeroElim(elen: 4, e: u, flen: 4, f: v, h: &abt)

                ti1 = (adxtail * bdytail); c = (splitter * adxtail); abig = (c - adxtail); ahi = c - abig; alo = adxtail - ahi; c = (splitter * bdytail); abig = (c - bdytail); bhi = c - abig; blo = bdytail - bhi; err1 = ti1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); ti0 = (alo * blo) - err3
                tj1 = (bdxtail * adytail); c = (splitter * bdxtail); abig = (c - bdxtail); ahi = c - abig; alo = bdxtail - ahi; c = (splitter * adytail); abig = (c - adytail); bhi = c - abig; blo = adytail - bhi; err1 = tj1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); tj0 = (alo * blo) - err3
                _i = (ti0 - tj0); bvirt = (ti0 - _i); avirt = _i + bvirt; bround = bvirt - tj0; around = ti0 - avirt; abtt[0] = around + bround; _j = (ti1 + _i); bvirt = (_j - ti1); avirt = _j - bvirt; bround = _i - bvirt; around = ti1 - avirt; _0 = around + bround; _i = (_0 - tj1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - tj1; around = _0 - avirt; abtt[1] = around + bround; abtt3 = (_j + _i); bvirt = (abtt3 - _j); avirt = abtt3 - bvirt; bround = _i - bvirt; around = _j - avirt; abtt[2] = around + bround
                abtt[3] = abtt3
                abttlen = 4
            } else {
                abt[0] = 0.0
                abtlen = 1
                abtt[0] = 0.0
                abttlen = 1
            }

            if cdxtail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: cxtablen, e: cxtab, b: cdxtail, h: &temp16a)
                cxtabtlen = scaleExpansionZeroElim(elen: abtlen, e: abt, b: cdxtail, h: &cxtabt)
                temp32alen = scaleExpansionZeroElim(elen: cxtabtlen, e: cxtabt, b: 2.0 * cdx, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
                if adytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: bb, b: cdxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: adytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }
                if bdytail != 0.0 {
                    temp8len = scaleExpansionZeroElim(elen: 4, e: aa, b: -cdxtail, h: &temp8)
                    temp16alen = scaleExpansionZeroElim(elen: temp8len, e: temp8, b: bdytail, h: &temp16a)
                    finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp16alen, f: temp16a, h: &finother)
                    finswap = finnow; finnow = finother; finother = finswap
                }

                temp32alen = scaleExpansionZeroElim(elen: cxtabtlen, e: cxtabt, b: cdxtail, h: &temp32a)
                cxtabttlen = scaleExpansionZeroElim(elen: abttlen, e: abtt, b: cdxtail, h: &cxtabtt)
                temp16alen = scaleExpansionZeroElim(elen: cxtabttlen, e: cxtabtt, b: 2.0 * cdx, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: cxtabttlen, e: cxtabtt, b: cdxtail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
            if cdytail != 0.0 {
                temp16alen = scaleExpansionZeroElim(elen: cytablen, e: cytab, b: cdytail, h: &temp16a)
                cytabtlen = scaleExpansionZeroElim(elen: abtlen, e: abt, b: cdytail, h: &cytabt)
                temp32alen = scaleExpansionZeroElim(elen: cytabtlen, e: cytabt, b: 2.0 * cdy, h: &temp32a)
                temp48len = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp32alen, f: temp32a, h: &temp48)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp48len, f: temp48, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap

                temp32alen = scaleExpansionZeroElim(elen: cytabtlen, e: cytabt, b: cdytail, h: &temp32a)
                cytabttlen = scaleExpansionZeroElim(elen: abttlen, e: abtt, b: cdytail, h: &cytabtt)
                temp16alen = scaleExpansionZeroElim(elen: cytabttlen, e: cytabtt, b: 2.0 * cdy, h: &temp16a)
                temp16blen = scaleExpansionZeroElim(elen: cytabttlen, e: cytabtt, b: cdytail, h: &temp16b)
                temp32blen = fastExpansionSumZeroElim(elen: temp16alen, e: temp16a, flen: temp16blen, f: temp16b, h: &temp32b)
                temp64len = fastExpansionSumZeroElim(elen: temp32alen, e: temp32a, flen: temp32blen, f: temp32b, h: &temp64)
                finlength = fastExpansionSumZeroElim(elen: finlength, e: finnow, flen: temp64len, f: temp64, h: &finother)
                finswap = finnow; finnow = finother; finother = finswap
            }
        }

        return finnow[finlength - 1]
    }

    public func findCircumcenter(org: Vertex, dest: Vertex, apex: Vertex, xi: inout REAL, eta: inout REAL) -> Vertex {

        // Compute the circumcenter of the triangle.
        let xdo = dest.x - org.x
        let ydo = dest.y - org.y
        let xao = apex.x - org.x
        let yao = apex.y - org.y
        let dodist = xdo * xdo + ydo * ydo
        let aodist = xao * xao + yao * yao

        let denominator: REAL
        if !exact {
            denominator = 0.5 / (xdo * yao - xao * ydo)
        } else {
            // Use the counterclockwise() routine to ensure a positive (and
            // reasonably accurate) result, avoiding any possibility of
            // division by zero.
            denominator = 0.5 / counterClockwise(a: dest, b: apex, c: org)
            // Don't count the above as an orientation test.
        }

        let dx = (yao * dodist - ydo * aodist) * denominator
        let dy = (xdo * aodist - xao * dodist) * denominator

        // To interpolate vertex attributes for the new vertex inserted at
        // the circumcenter, define a coordinate system with a xi-axis,
        // directed from the triangle's origin to its destination, and
        // an eta-axis, directed from its origin to its apex.
        // Calculate the xi and eta coordinates of the circumcenter.
        xi = (yao * dx - xao * dy) * (2.0 * denominator)
        eta = (xdo * dy - ydo * dx) * (2.0 * denominator)

        return Vertex(id: -1, x: org.x + dx, y: org.y + dy, z: 0)
    }

    public func findCircumcenter(org: Vertex, dest: Vertex, apex: Vertex, xi: inout REAL, eta: inout REAL, offconstant: REAL) -> Vertex {

        // Compute the circumcenter of the triangle.
        let xdo = dest.x - org.x
        let ydo = dest.y - org.y
        let xao = apex.x - org.x
        let yao = apex.y - org.y
        let dodist = xdo * xdo + ydo * ydo
        let aodist = xao * xao + yao * yao
        let dadist = (dest.x - apex.x) * (dest.x - apex.x) +
            (dest.y - apex.y) * (dest.y - apex.y)

        let denominator: REAL
        if !exact {
            denominator = 0.5 / (xdo * yao - xao * ydo)
        } else {
            // Use the counterclockwise() routine to ensure a positive (and
            // reasonably accurate) result, avoiding any possibility of
            // division by zero.
            denominator = 0.5 / counterClockwise(a: dest, b: apex, c: org)
            // Don't count the above as an orientation test.
        }

        var dx = (yao * dodist - ydo * aodist) * denominator
        var dy = (xdo * aodist - xao * dodist) * denominator

        // Find the (squared) length of the triangle's shortest edge.  This
        // serves as a conservative estimate of the insertion radius of the
        // circumcenter's parent. The estimate is used to ensure that
        // the algorithm terminates even if very small angles appear in
        // the input PSLG.
        if (dodist < aodist) && (dodist < dadist) {
            if offconstant > 0.0 {
                // Find the position of the off-center, as described by Alper Ungor.
                let dxoff = 0.5 * xdo - offconstant * ydo
                let dyoff = 0.5 * ydo + offconstant * xdo
                // If the off-center is closer to the origin than the
                // circumcenter, use the off-center instead.
                if dxoff * dxoff + dyoff * dyoff < dx * dx + dy * dy {
                    dx = dxoff
                    dy = dyoff
                }
            }
        } else if aodist < dadist {
            if offconstant > 0.0 {
                let dxoff = 0.5 * xao + offconstant * yao
                let dyoff = 0.5 * yao - offconstant * xao
                // If the off-center is closer to the origin than the
                // circumcenter, use the off-center instead.
                if dxoff * dxoff + dyoff * dyoff < dx * dx + dy * dy {
                    dx = dxoff
                    dy = dyoff
                }
            }
        } else {
            if offconstant > 0.0 {
                let dxoff = 0.5 * (apex.x - dest.x) - offconstant * (apex.y - dest.y)
                let dyoff = 0.5 * (apex.y - dest.y) + offconstant * (apex.x - dest.x)
                // If the off-center is closer to the destination than the
                // circumcenter, use the off-center instead.
                if dxoff * dxoff + dyoff * dyoff <
                    (dx - xdo) * (dx - xdo) + (dy - ydo) * (dy - ydo) {
                    dx = xdo + dxoff
                    dy = ydo + dyoff
                }
            }
        }

        // To interpolate vertex attributes for the new vertex inserted at
        // the circumcenter, define a coordinate system with a xi-axis,
        // directed from the triangle's origin to its destination, and
        // an eta-axis, directed from its origin to its apex.
        // Calculate the xi and eta coordinates of the circumcenter.
        xi = (yao * dx - xao * dy) * (2.0 * denominator)
        eta = (xdo * dy - ydo * dx) * (2.0 * denominator)

        return Vertex(id: -2, x: org.x + dx, y: org.y + dy, z: 0)
    }

    private func counterClockwiseAdapt(pa: Vertex, pb: Vertex, pc: Vertex, detsum: REAL) -> REAL {

        // Edited to work around index out of range exceptions (changed array length from 4 to 5).
        // See unsafe indexing in FastExpansionSumZeroElim.
        var B = [REAL](repeating: 0, count: 5), u = [REAL](repeating: 0, count: 5)
        var C1 = [REAL](repeating: 0, count: 5), C2 = [REAL](repeating: 0, count: 12), D = [REAL](repeating: 0, count: 16)
        var acxtail: REAL = 0, acytail: REAL = 0, bcxtail: REAL = 0, bcytail: REAL = 0
        var detlefttail: REAL = 0, detrighttail: REAL = 0
        var det: REAL = 0, errbound: REAL = 0

        let acx = (pa.x - pc.x)
        let bcx = (pb.x - pc.x)
        let acy = (pa.y - pc.y)
        let bcy = (pb.y - pc.y)
        var B3: REAL = 0
        var c1length = 0, c2length = 0, dlength = 0

        var u3: REAL = 0
        var s1 = REAL(0), t1 = REAL(0)
        var s0 = REAL(0), t0 = REAL(0)

        var bvirt = REAL(0)
        var avirt = REAL(0), bround = REAL(0), around = REAL(0)
        var c = REAL(0)
        var abig = REAL(0)
        var ahi = REAL(0), alo = REAL(0), bhi = REAL(0), blo = REAL(0)
        var err1 = REAL(0), err2 = REAL(0), err3 = REAL(0)
        var _i = REAL(0), _j = REAL(0)
        var _0 = REAL(0)

        let detleft = (acx * bcy); c = (splitter * acx); abig = (c - acx); ahi = c - abig; alo = acx - ahi; c = (splitter * bcy); abig = (c - bcy); bhi = c - abig; blo = bcy - bhi; err1 = detleft - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); detlefttail = (alo * blo) - err3
        let detright = (acy * bcx); c = (splitter * acy); abig = (c - acy); ahi = c - abig; alo = acy - ahi; c = (splitter * bcx); abig = (c - bcx); bhi = c - abig; blo = bcx - bhi; err1 = detright - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); detrighttail = (alo * blo) - err3

        _i = (detlefttail - detrighttail); bvirt = (detlefttail - _i); avirt = _i + bvirt; bround = bvirt - detrighttail; around = detlefttail - avirt; B[0] = around + bround; _j = (detleft + _i); bvirt = (_j - detleft); avirt = _j - bvirt; bround = _i - bvirt; around = detleft - avirt; _0 = around + bround; _i = (_0 - detright); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - detright; around = _0 - avirt; B[1] = around + bround; B3 = (_j + _i); bvirt = (B3 - _j); avirt = B3 - bvirt; bround = _i - bvirt; around = _j - avirt; B[2] = around + bround

        B[3] = B3

        det = estimate(elen: 4, e: B)
        errbound = ccwerrboundB * detsum
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        bvirt = (pa.x - acx); avirt = acx + bvirt; bround = bvirt - pc.x; around = pa.x - avirt; acxtail = around + bround
        bvirt = (pb.x - bcx); avirt = bcx + bvirt; bround = bvirt - pc.x; around = pb.x - avirt; bcxtail = around + bround
        bvirt = (pa.y - acy); avirt = acy + bvirt; bround = bvirt - pc.y; around = pa.y - avirt; acytail = around + bround
        bvirt = (pb.y - bcy); avirt = bcy + bvirt; bround = bvirt - pc.y; around = pb.y - avirt; bcytail = around + bround

        if (acxtail == 0.0) && (acytail == 0.0)
            && (bcxtail == 0.0) && (bcytail == 0.0) {
            return det
        }

        errbound = ccwerrboundC * detsum + resulterrbound * ((det) >= 0.0 ? (det) : -(det))
        det += (acx * bcytail + bcy * acxtail)
            - (acy * bcxtail + bcx * acytail)
        if (det >= errbound) || (-det >= errbound) {
            return det
        }

        s1 = (acxtail * bcy); c = (splitter * acxtail); abig = (c - acxtail); ahi = c - abig; alo = acxtail - ahi; c = (splitter * bcy); abig = (c - bcy); bhi = c - abig; blo = bcy - bhi; err1 = s1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); s0 = (alo * blo) - err3
        t1 = (acytail * bcx); c = (splitter * acytail); abig = (c - acytail); ahi = c - abig; alo = acytail - ahi; c = (splitter * bcx); abig = (c - bcx); bhi = c - abig; blo = bcx - bhi; err1 = t1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); t0 = (alo * blo) - err3
        _i = (s0 - t0); bvirt = (s0 - _i); avirt = _i + bvirt; bround = bvirt - t0; around = s0 - avirt; u[0] = around + bround; _j = (s1 + _i); bvirt = (_j - s1); avirt = _j - bvirt; bround = _i - bvirt; around = s1 - avirt; _0 = around + bround; _i = (_0 - t1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - t1; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
        u[3] = u3
        c1length = fastExpansionSumZeroElim(elen: 4, e: B, flen: 4, f: u, h: &C1)

        s1 = (acx * bcytail); c = (splitter * acx); abig = (c - acx); ahi = c - abig; alo = acx - ahi; c = (splitter * bcytail); abig = (c - bcytail); bhi = c - abig; blo = bcytail - bhi; err1 = s1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); s0 = (alo * blo) - err3
        t1 = (acy * bcxtail); c = (splitter * acy); abig = (c - acy); ahi = c - abig; alo = acy - ahi; c = (splitter * bcxtail); abig = (c - bcxtail); bhi = c - abig; blo = bcxtail - bhi; err1 = t1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); t0 = (alo * blo) - err3
        _i = (s0 - t0); bvirt = (s0 - _i); avirt = _i + bvirt; bround = bvirt - t0; around = s0 - avirt; u[0] = around + bround; _j = (s1 + _i); bvirt = (_j - s1); avirt = _j - bvirt; bround = _i - bvirt; around = s1 - avirt; _0 = around + bround; _i = (_0 - t1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - t1; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
        u[3] = u3
        c2length = fastExpansionSumZeroElim(elen: c1length, e: C1, flen: 4, f: u, h: &C2)

        s1 = (acxtail * bcytail); c = (splitter * acxtail); abig = (c - acxtail); ahi = c - abig; alo = acxtail - ahi; c = (splitter * bcytail); abig = (c - bcytail); bhi = c - abig; blo = bcytail - bhi; err1 = s1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); s0 = (alo * blo) - err3
        t1 = (acytail * bcxtail); c = (splitter * acytail); abig = (c - acytail); ahi = c - abig; alo = acytail - ahi; c = (splitter * bcxtail); abig = (c - bcxtail); bhi = c - abig; blo = bcxtail - bhi; err1 = t1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); t0 = (alo * blo) - err3
        _i = (s0 - t0); bvirt = (s0 - _i); avirt = _i + bvirt; bround = bvirt - t0; around = s0 - avirt; u[0] = around + bround; _j = (s1 + _i); bvirt = (_j - s1); avirt = _j - bvirt; bround = _i - bvirt; around = s1 - avirt; _0 = around + bround; _i = (_0 - t1); bvirt = (_0 - _i); avirt = _i + bvirt; bround = bvirt - t1; around = _0 - avirt; u[1] = around + bround; u3 = (_j + _i); bvirt = (u3 - _j); avirt = u3 - bvirt; bround = _i - bvirt; around = _j - avirt; u[2] = around + bround
        u[3] = u3
        dlength = fastExpansionSumZeroElim(elen: c2length, e: C2, flen: 4, f: u, h: &D)

        return (D[dlength - 1])
    }

    private func scaleExpansionZeroElim(elen: Int, e: [REAL], b: REAL, h: inout [REAL]) -> Int {
        var Q: REAL = 0, sum: REAL = 0
        var hh: REAL = 0
        var product1: REAL = 0
        var product0: REAL = 0
        var hindex = 0
        var enow: REAL = 0
        var bvirt: REAL = 0
        var avirt: REAL = 0, bround: REAL = 0, around: REAL = 0
        var c: REAL = 0
        var abig: REAL = 0
        var ahi: REAL = 0, alo: REAL = 0, bhi: REAL = 0, blo: REAL = 0
        var err1: REAL = 0, err2: REAL = 0, err3: REAL = 0

        c = (splitter * b); abig = (c - b); bhi = c - abig; blo = b - bhi
        Q = (e[0] * b); c = (splitter * e[0]); abig = (c - e[0]); ahi = c - abig; alo = e[0] - ahi; err1 = Q - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); hh = (alo * blo) - err3
        hindex = 0
        if hh != 0 {
            h[hindex] = hh
            hindex += 1
        }
        for eindex in 1..<elen {
            enow = e[eindex]
            product1 = (enow * b); c = (splitter * enow); abig = (c - enow); ahi = c - abig; alo = enow - ahi; err1 = product1 - (ahi * bhi); err2 = err1 - (alo * bhi); err3 = err2 - (ahi * blo); product0 = (alo * blo) - err3
            sum = (Q + product0); bvirt = (sum - Q); avirt = sum - bvirt; bround = product0 - bvirt; around = Q - avirt; hh = around + bround
            if hh != 0 {
                h[hindex] = hh
                hindex += 1
            }
            Q = (product1 + sum); bvirt = Q - product1; hh = sum - bvirt
            if hh != 0 {
                h[hindex] = hh
                hindex += 1
            }
        }
        if (Q != 0.0) || (hindex == 0) {
            h[hindex] = Q
            hindex += 1
        }
        return hindex
    }

    private func estimate( elen: Int, e: [REAL]) -> REAL {
        return e[0..<elen].reduce(0, +)
    }

    private func fastExpansionSumZeroElim(elen: Int, e: [REAL], flen: Int, f: [REAL], h: inout [REAL]) -> Int {

        var enow = e[0]
        var fnow = f[0]
        var eindex = 0
        var findex = 0
        var Q: REAL
        if (fnow > enow) == (fnow > -enow) {
            Q = enow
            eindex += 1
            enow = e[eindex]
        } else {
            Q = fnow
            findex += 1
            fnow = f[findex]
        }
        var hindex = 0
        var Qnew = Q
        var hh: REAL = 0
        var bvirt: REAL = 0
        var avirt: REAL = 0, bround: REAL = 0, around: REAL = 0

        if (eindex < elen) && (findex < flen) {
            if (fnow > enow) == (fnow > -enow) {
                Qnew = (enow + Q); bvirt = Qnew - enow; hh = Q - bvirt
                eindex += 1
                enow = e[eindex]
            } else {
                Qnew = (fnow + Q); bvirt = Qnew - fnow; hh = Q - bvirt
                findex += 1
                fnow = f[findex]
            }
            Q = Qnew
            if hh != 0.0 {
                h[hindex] = hh
                hindex += 1
            }
            while (eindex < elen) && (findex < flen) {
                if (fnow > enow) == (fnow > -enow) {
                    Qnew = (Q + enow)
                    bvirt = (Qnew - Q)
                    avirt = Qnew - bvirt
                    bround = enow - bvirt
                    around = Q - avirt
                    hh = around + bround
                    eindex += 1
                    enow = e[eindex]
                } else {
                    Qnew = (Q + fnow)
                    bvirt = (Qnew - Q)
                    avirt = Qnew - bvirt
                    bround = fnow - bvirt
                    around = Q - avirt
                    hh = around + bround
                    findex += 1
                    fnow = f[findex]
                }
                Q = Qnew
                if hh != 0.0 {
                    h[hindex] = hh
                    hindex += 1
                }
            }
        }
        while eindex < elen {
            Qnew = (Q + enow)
            bvirt = (Qnew - Q)
            avirt = Qnew - bvirt
            bround = enow - bvirt
            around = Q - avirt
            hh = around + bround
            eindex += 1
            enow = e[eindex]
            Q = Qnew
            if hh != 0.0 {
                h[hindex] = hh
                hindex += 1
            }
        }
        while findex < flen {
            Qnew = (Q + fnow)
            bvirt = (Qnew - Q)
            avirt = Qnew - bvirt
            bround = fnow - bvirt
            around = Q - avirt
            hh = around + bround
            findex += 1
            fnow = f[findex]
            Q = Qnew
            if hh != 0.0 {
                h[hindex] = hh
                hindex += 1
            }
        }
        if (Q != 0.0) || (hindex == 0) {
            h[hindex] = Q
            hindex += 1
        }
        return hindex
    }
}
