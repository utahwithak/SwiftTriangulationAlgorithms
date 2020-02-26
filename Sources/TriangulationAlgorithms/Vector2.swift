//
//  Vector2.swift
//  
//
//  Created by Carl Wieland on 2/24/20.
//

import Foundation

#if os(iOS)
import QuartzCore
#endif

public protocol Vector2 {
    var x: CGFloat { get }
    var y: CGFloat { get }
}

extension CGPoint: Vector2 {}
