//
//  NetPlayerUpdate.swift
//  Avara
//
//  Created by Morgan Davis on 8/4/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class NetPlayerUpdate: Equatable {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private(set)    var     sequenceNumber:         UInt32
    private(set)    var     id:                     UInt32
    private(set)    var     position:               SCNVector3
    private(set)    var     bodyRotation:           SCNVector4
    private(set)    var     headEulerAngles:        SCNVector3
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public init(sequenceNumber: UInt32, id: UInt32, position: SCNVector3, bodyRotation: SCNVector4, headEulerAngles: SCNVector3) {
        self.sequenceNumber = sequenceNumber
        self.id = id
        self.position = position
        self.bodyRotation = bodyRotation
        self.headEulerAngles = headEulerAngles
    }
}


/*****************************************************************************************************/
// MARK:    Operator Overloads
/*****************************************************************************************************/

public func ==(lhs: NetPlayerUpdate, rhs: NetPlayerUpdate) -> Bool {
    return (lhs.id == rhs.id) && (lhs.position == rhs.position) && (lhs.bodyRotation == rhs.bodyRotation) && (lhs.headEulerAngles == rhs.headEulerAngles)
}

public func !=(lhs: NetPlayerUpdate, rhs: NetPlayerUpdate) -> Bool {
    return !(lhs == rhs)
}
