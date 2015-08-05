//
//  NetPlayerUpdate.swift
//  Avara
//
//  Created by Morgan Davis on 8/4/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class NetPlayerUpdate {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private(set)    var     sequenceNumber:         UInt32
    private(set)    var     id:                     UInt32
    private(set)    var     position:               SCNVector3
    private(set)    var     legsOrientation:        SCNVector4
    private(set)    var     headOrientation:        SCNVector4
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public init(sequenceNumber: UInt32, id: UInt32, position: SCNVector3, legsOrientation: SCNVector4, headOrientation: SCNVector4) {
        self.sequenceNumber = sequenceNumber
        self.id = id
        self.position = position
        self.legsOrientation = legsOrientation
        self.headOrientation = headOrientation
    }
}
