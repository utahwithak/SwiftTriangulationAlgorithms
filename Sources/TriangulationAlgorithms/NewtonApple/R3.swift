//
//  R3.swift
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

internal struct R3: Comparable {
    var id: Int
    var x: CGFloat, y: CGFloat, z: CGFloat
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        id = -1
        self.x = x
        self.y = y
        self.z = z
    }
    init(id: Int = -1, pt: CGPoint) {
        self.id = id
        self.x = pt.x
        self.y = pt.y
        z = x * x + y * y
    }

    init(x: CGFloat, y: CGFloat) {
        id = -1
        self.x = x
        self.y = y
        z = x * x + y * y
    }

    static func < (lhs: R3, rhs: R3) -> Bool {
        if lhs.z == rhs.z {
          if lhs.x == rhs.x {
            return lhs.y < rhs.y
          }
          return lhs.x < rhs.x
        }
        return lhs.z < rhs.z
    }
}
