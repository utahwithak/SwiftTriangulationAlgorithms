//
//  Tri.swift
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

internal struct Tri {
    var id = 0, keep = 0
    var a = 0, b = 0, c = 0

    // adjacent edges index to neighbouring triangle.
    var ab = 0
    var bc = 0
    var ac = 0

    // visible normal to triangular facet.
    var er: CGFloat = 0, ec: CGFloat = 0, ez: CGFloat = 0

    init() {}

    init(x: Int, y: Int, q: Int) {
        id = 0
        keep = 1
        a = x
        b = y
        c = q
        ab = -1
        bc = -1
        ac = -1
    }
}
