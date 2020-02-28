//
//  Behavior.swift
//  SwiftTri
//
//  Created by Carl Wieland on 9/27/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

public struct Behavior {
    public init() {}
    public var poly = false, refine = false, quality = false, vararea = false, fixedarea = false, usertest = false
    public var regionattrib = false, convex = false, weighted = false
    //, jettison = false;
    public var edgesout = false, voronoi = false, neighbors = false, geomview = false
    public var noholes = false, noexact = false, conformdel = false
    public var dwyer = false
    public var splitseg = false
    public var docheck = false
    public var quiet = false, verbose = false
    public var usesegments = false
    var order = false
    var nobisect = 0
    var steiner = 0
    var minangle: REAL = 0, goodangle: REAL = 0, offconstant: REAL = 0
    var maxarea: REAL = 0

    var selfCheck = false
}
