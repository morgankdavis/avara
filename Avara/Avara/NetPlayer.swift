//
//  NetPlayer.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


public class NetPlayer {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var     sequenceNumber =            UInt32(0) // sequence numbers are unique to each server<->client relationship
    public          var     activeInputs =              Set<UserInput>()
    private(set)    var     name:                       String
    private(set)    var     id:                         UInt32
    private(set)    var     character:                  Character
    private(set)    var     accumulatedMouseDelta =     CGPointZero
  
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func readMouseDeltaAndClear() -> CGPoint {
        let delta = accumulatedMouseDelta
        accumulatedMouseDelta = CGPointZero
        return delta
    }
    
    public func addMouseDelta(delta: CGPoint) {
        accumulatedMouseDelta = CGPoint(
            x: accumulatedMouseDelta.x + delta.x,
            y: accumulatedMouseDelta.y + delta.y)
    }
    
    public func netPlayerUpdate() -> NetPlayerUpdate {
//        let rot = character.bodyNode.rotation
//        NSLog("netPlayerUpdate(): character.bodyNode.rotation: %.2f, %.2f, %.2f, %.2f", rot.x, rot.y, rot.z, rot.w)
        return NetPlayerUpdate(
            sequenceNumber: sequenceNumber,
            id: id,
            position: character.bodyNode.position,
            bodyRotation: character.bodyNode.rotation,
            headEulerAngles: character.headNode!.eulerAngles)
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(id: UInt32, name: String, character: Character) {
        self.id = id
        self.name = name
        self.character = character
    }
}
