//
//  OperatorOverloads.swift
//  Avara
//
//  Created by Morgan Davis on 8/5/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


let VECTOR_COMPONENT_EQUALITY_TOLERANCE =        CGFloat(0.0001)


public func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    
    guard abs(lhs.x - rhs.x) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    guard abs(lhs.y - rhs.y) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    guard abs(lhs.z - rhs.z) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    return true
}

public func ==(lhs: SCNVector4, rhs: SCNVector4) -> Bool {
    
    guard abs(lhs.x - rhs.x) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    guard abs(lhs.y - rhs.y) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    guard abs(lhs.z - rhs.z) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    guard abs(lhs.w - rhs.w) < VECTOR_COMPONENT_EQUALITY_TOLERANCE else { return false }
    return true
}
