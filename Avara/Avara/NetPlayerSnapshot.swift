//
//  NetPlayerSnapshot.swift
//  Avara
//
//  Created by Morgan Davis on 8/4/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  Much like ServerUpdateNetMessage except for only one player, not all 'dem
//  Makes packing/unpacking and reasoning about individual players easier
//

import Foundation
import SceneKit


public class NetPlayerSnapshot: Equatable, CustomStringConvertible {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var     sequenceNumber:         UInt32
    private(set)    var     id:                     UInt32
    private(set)    var     position:               SCNVector3
    private(set)    var     bodyRotation:           SCNVector4
    private(set)    var     hullEulerAngles:        SCNVector3
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public init(sequenceNumber: UInt32, id: UInt32, position: SCNVector3, bodyRotation: SCNVector4, hullEulerAngles: SCNVector3) {
        self.sequenceNumber = sequenceNumber
        self.id = id
        self.position = position
        self.bodyRotation = bodyRotation
        self.hullEulerAngles = hullEulerAngles
    }
    
    /*****************************************************************************************************/
    // MARK:   CustomStringConvertible
    /*****************************************************************************************************/
    
    public var description: String { get {
        return NSString(format: "[NetPlayerSnapshot] sequenceNumber: %d, id: %d, position: %@, bodyRotation: %@, hullEulerAngles: %@",
            sequenceNumber, id, NSStringFromSCNVector3(position), NSStringFromSCNVector4(bodyRotation), NSStringFromSCNVector3(hullEulerAngles)) as String
        }
    }
}


/*****************************************************************************************************/
// MARK:    Operator Overloads
/*****************************************************************************************************/

public func ==(lhs: NetPlayerSnapshot, rhs: NetPlayerSnapshot) -> Bool {
    return (lhs.id == rhs.id) && (lhs.position == rhs.position) && (lhs.bodyRotation == rhs.bodyRotation) && (lhs.hullEulerAngles == rhs.hullEulerAngles)
}

public func !=(lhs: NetPlayerSnapshot, rhs: NetPlayerSnapshot) -> Bool {
    return !(lhs == rhs)
}
