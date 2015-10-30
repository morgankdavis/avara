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
let SCN_DEBUG_OPTIONS: SCNDebugOptions =    [.ShowPhysicsShapes, .ShowBoundingBoxes, .ShowWireframe]

let PHYSICS_TIMESTEP =                      1.0/120.0

let NET_SERVER_TICK_RATE =                  CGFloat(30.0) // Hz
let NET_CLIENT_TICK_RATE =                  CGFloat(30.0) // Hz

let DIRECT_MOUSE_ENABLED =                  true
let MOUSE_SENSITIVITY =                     CGFloat(3.0)
let MOUSE_SENSITIVITY_MULTIPLIER =          CGFloat(0.0005)

let NET_SERVER_PORT =                       UInt16(33777)
let NET_MAX_CLIENTS =                       Int(12)
let NET_MAX_CHANNELS =                      UInt8(4)

let NET_CLIENT_ENABLE_RECONCILIATION =      false

enum NetChannel: UInt8 {
    case Signaling =    0
    case Live =         1
}