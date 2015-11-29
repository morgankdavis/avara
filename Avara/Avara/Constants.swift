//
//  Constants.swift
//  Avara
//
//  Created by Morgan Davis on 11/26/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


enum NetChannel: UInt8 {
    case Signaling =    0
    case Live =         1
}

enum CollisionCategory: Int {
    case Character =    0b00000001
    case Wall =         0b00000010
    case Floor =        0b00000100
    case Movable =      0b00001000
}

enum NodeCategory: Int {
    case Projectile =   0b10000000
}

let VECTOR_COMPONENT_EQUALITY_TOLERANCE =   MKDFloat(0.000001)

let MOUSELOOK_SENSITIVITY_MULTIPLIER =      CGFloat(0.0005)
let THUMBLOOK_SENSITIVITY_MULTIPLIER =      CGFloat(0.01)
