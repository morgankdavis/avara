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
    
    public          var     lastReceivedSequenceNumber =    UInt32(0) // sequence numbers are unique to each server<->client relationship
    public          var     activeInputs =                  Set<UserInput>()
    private(set)    var     accumulatedMouseDelta =         CGPointZero
    //public          var     netPlayerUpdates =              [NetPlayerUpdate]()
    private(set)    var     name:                           String
    private(set)    var     id:                             UInt32
    private(set)    var     character:                      Character
    public          var     lastSentNetPlayerUpdate:        NetPlayerUpdate?
    public          var     lastSentInputActive:            Bool?
  
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
        if var lastSentSq = lastSentNetPlayerUpdate?.sequenceNumber {
            return NetPlayerUpdate(
                sequenceNumber: ++lastSentSq,
                id: id,
                position: character.bodyNode.position,
                bodyRotation: character.bodyNode.rotation,
                headEulerAngles: character.headNode!.eulerAngles)
        }
        else {
            return NetPlayerUpdate(
                sequenceNumber: ++lastReceivedSequenceNumber,
                id: id,
                position: character.bodyNode.position,
                bodyRotation: character.bodyNode.rotation,
                headEulerAngles: character.headNode!.eulerAngles)
        }
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
