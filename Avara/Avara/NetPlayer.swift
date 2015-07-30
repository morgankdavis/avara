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
    
    public          var     lastSequenceNumber:     UInt32 // stores last sent OR received sequence number for this particular player
    private(set)    var     name:                   String
    private(set)    var     id:                     UInt32
    private(set)    var     character:              Character
    
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
