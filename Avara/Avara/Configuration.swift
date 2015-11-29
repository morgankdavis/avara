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
let SCN_DEBUG_OPTIONS: SCNDebugOptions =    []//[.ShowPhysicsShapes, .ShowBoundingBoxes, .ShowWireframe]

let PHYSICS_TIMESTEP =                      1.0/600.0

let COLLISION_DETECTION_ENABLED =           true

let DIRECT_MOUSE_ENABLED =                  true
let MOUSELOOK_SENSITIVITY =                 CGFloat(3.0)
let THUMBLOOK_SENSITIVITY =                 CGFloat(3.0)
let THUMBLOOK_INVERSION_ENABLED =           false

let SERVER_VIEW_ENABLED =                   true

let NET_SERVER_TICK_RATE =                  CGFloat(30.0) // Hz
let NET_CLIENT_TICK_RATE =                  CGFloat(60.0) // Hz
let NET_SERVER_PORT =                       UInt16(33777)
let NET_MAX_CLIENTS =                       Int(12)
let NET_MAX_CHANNELS =                      UInt8(4)
let NET_CLIENT_RECONCILIATION_ENABLED =     true
let NET_CLIENT_PACKET_DUP =                 UInt8(3)
let NET_SERVER_PACKET_DUP =                 UInt8(1)
