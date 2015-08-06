//
//  Configuration.swift
//  Avara
//
//  Created by Morgan Davis on 5/20/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


let CLIENT_WINDOW_SIZE =                    CGSize(width: 800, height: 600)
let SERVER_WINDOW_SIZE =                    CGSize(width: 320, height: 240)
let SCN_DEBUG_OPTIONS: SCNDebugOptions =    [.ShowPhysicsShapes, .ShowBoundingBoxes]

let PHYSICS_TIMESTEP =                      1.0/120.0

let MOUSE_SENSITIVITY =                     CGFloat(400.0)

let NET_SERVER_PORT =                       UInt16(33777)
let NET_MAX_CLIENTS =                       Int(12)
let NET_MAX_CHANNELS =                      UInt8(4)


enum NetChannel: UInt8 {
    case Control =      0
    case Live =         1
}