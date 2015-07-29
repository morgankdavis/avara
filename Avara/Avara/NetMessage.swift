//
//  NetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


public enum NetMessageOpcode : Int {
    case ClientHello =      0
}


public class NetMessage {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private(set)    var     opcode:     Int
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    required public init(opcode: Int) {
        self.opcode = opcode
    }
}
