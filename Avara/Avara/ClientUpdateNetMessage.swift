//
//  ClientUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/30/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable message. Sends player input to server.
//
//  FORMAT: [UINT16ARRAY]<inputActions>
//

import Foundation


public class ClientUpdateNetMessage: NetMessage {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ClientUpdate } }
    private(set)    var     activeActions =     Set<InputAction>()
    
    /******************************************************************************************************
    MARK:   Public, NetMessage
    ******************************************************************************************************/
    
    override public func encodedWithSequenceNumber(sequenceNumber: UInt32) -> NSData? {
        var encodedData = super.encodedWithSequenceNumber(sequenceNumber) as! NSMutableData
        
//        guard inputActions != nil else {
//            NSLog("'inputActions' is nil")
//            return nil
//        }
        
        // convert InputAction set into UInt8 array
        var actionsRawArray = [UInt8]()
        for a in activeActions {
            actionsRawArray.append(a.rawValue)
        }
        
        appendUInt8Array(actionsRawArray, toData: &encodedData)
        
        return encodedData as NSData
    }
    
    override internal func parsePayload() {
        NSLog("ClientUpdateNetMessage.parsePayload()")
        
        super.parsePayload()
        
        let actionsRawArray = pullUInt8ArrayFromPayload()
        for a in actionsRawArray {
            if let action = InputAction(rawValue: a) {
                activeActions.insert(action)
            }
            else {
                NSLog("Unknown InputAction raw value: %d", a) // this would likely only happen due to encoding/transport error...
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    public required init(activeActions: Set<InputAction>) {
        self.activeActions = activeActions
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
