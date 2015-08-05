//
//  ClientUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/30/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable client message. Sends player input to server.
//
//  FORMAT: [UINT16ARRAY]<UserInputs>
//

import Foundation


public class ClientUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ClientUpdate } }
    public          var     sequenceNumber:     UInt32?
    private(set)    var     activeInputs =      Set<UserInput>()
    private(set)    var     mouseDelta =        CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        //appendUInt32(sequenceNumber, toData: &encodedData)
        
        // convert UserInput set into UInt8 array
        var actionsRawArray = [UInt8]()
        for a in activeInputs {
            actionsRawArray.append(a.rawValue)
        }
        
        appendUInt8Array(actionsRawArray, toData: &encodedData)
        
        appendCGPoint(mouseDelta, toData: &encodedData)
        
        return encodedData as NSData
    }
    
    override internal func parsePayload() {
        NSLog("ClientUpdateNetMessage.parsePayload()")
        
        super.parsePayload()
        
        sequenceNumber = pullUInt32FromPayload()
        
        let actionsRawArray = pullUInt8ArrayFromPayload()
        for a in actionsRawArray {
            if let action = UserInput(rawValue: a) {
                activeInputs.insert(action)
            }
            else {
                NSLog("Unknown UserInput raw value: %d", a) // this would likely only happen due to encoding/transport error...
            }
        }
        
        mouseDelta = pullCGPointFromPayload()
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(activeActions: Set<UserInput>, mouseDelta: CGPoint, sequenceNumber: UInt32) {
        self.activeInputs = activeActions
        self.mouseDelta = mouseDelta
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
