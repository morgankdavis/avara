//
//  Configuration.swift
//  Avara
//
//  Created by Morgan Davis on 5/20/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


#if os(OSX)
    public typealias MKDFloat = CGFloat
    public typealias MKDColor = NSColor
    public typealias MKDImage = NSImage
#else
    public typealias MKDFloat = Float
    public typealias MKDColor = UIColor
    public typealias MKDImage = UIImage
#endif


let CLIENT_WINDOW_SIZE =                    CGSize(width: 800, height: 600)
let SERVER_WINDOW_SIZE =                    CGSize(width: 320, height: 240)
let SCN_DEBUG_OPTIONS: SCNDebugOptions =    [.ShowPhysicsShapes, .ShowBoundingBoxes, .ShowWireframe]

let SERVER_VIEW_ENABLED =                   true

let PHYSICS_TIMESTEP =                      1.0/120.0

let NET_SERVER_TICK_RATE =                  CGFloat(30.0) // Hz
let NET_CLIENT_TICK_RATE =                  CGFloat(30.0) // Hz

let DIRECT_MOUSE_ENABLED =                  true
let MOUSELOOK_SENSITIVITY =                 CGFloat(3.0)
let MOUSELOOK_SENSITIVITY_MULTIPLIER =      CGFloat(0.0005)

let THUMBLOOK_SENSITIVITY =                 CGFloat(3.0)
let THUMBLOOK_SENSITIVITY_MULTIPLIER =      CGFloat(0.01)

let NET_SERVER_PORT =                       UInt16(33777)
let NET_MAX_CLIENTS =                       Int(12)
let NET_MAX_CHANNELS =                      UInt8(4)

let NET_CLIENT_RECONCILIATION_ENABLED =     false

let COLLISION_DETECTION_ENABLED =           true

enum NetChannel: UInt8 {
    case Signaling =    0
    case Live =         1
}