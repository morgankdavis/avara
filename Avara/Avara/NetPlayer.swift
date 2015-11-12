//
//  NetPlayer.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class NetPlayer {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var     lastReceivedSequenceNumber =    UInt32(0) // sequence numbers are unique to each server<->client relationship
    private(set)    var     name:                           String
    private(set)    var     id:                             UInt32
    private(set)    var     character:                      Character
    public          var     lastSentNetPlayerSnapshot:      NetPlayerSnapshot?
    private         var     accumButtonEntries =            [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
    public          var     lastReceivedHullEulerAngles =   SCNVector3Zero
  
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func addButtonEntries(entries: [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]) {
        accumButtonEntries.appendContentsOf(entries)
    }
    
    public func readAndClearButtonEntries() -> (buttonEntries: [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)], totalDuration: MKDFloat) {
        // convenience method returns accumButtonEntries, but also calculates total duration (for sanity/cheat checking) and resets accum
        
        var totalDuration = MKDFloat(0)
        for (_, duration) in accumButtonEntries {
            totalDuration += duration
        }
        
        let retval  = (accumButtonEntries, totalDuration)
        
        accumButtonEntries = [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
        
        return retval
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
