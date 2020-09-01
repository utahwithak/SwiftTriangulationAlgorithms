//
//  Snork.swift
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

internal struct Snork: Comparable {
    let id: Int, a: Int, b: Int

    static func < (lhs: Snork, rhs: Snork) -> Bool {
        if lhs.a == rhs.a {
            return lhs.b < rhs.b
        }
        return lhs.a < rhs.a
    }
}
