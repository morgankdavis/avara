//
//  NetPlayer.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


public class NetPlayer {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    public          var     lastSequenceNumber:     UInt32 // sequence numbers are unique to each server<->client relationship
    public          var     activeInputs =          Set<UserInput>()
    private(set)    var     name:                   String
    private(set)    var     id:                     UInt32
    private(set)    var     character:              Character
    private         var     accumulatedMouseDelta = CGPointZero
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
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
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    public required init(id: UInt32, name: String, character: Character, lastSequenceNumber: UInt32) {
        self.id = id
        self.name = name
        self.character = character
        self.lastSequenceNumber = lastSequenceNumber
    }
}
