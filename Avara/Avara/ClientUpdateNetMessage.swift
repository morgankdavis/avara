//
//  ClientUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/30/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable client message. Sends player input to server.
//
//  FORMAT: [Float32]DeltaTime[UINT16ARRAY]<UserInputs>[Float32]<mouseDeltaX>[Float32]<mouseDeltaY>
//

import Foundation


public class ClientUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ClientUpdate } }
    public          var     sequenceNumber:     UInt32?
    private(set)    var     deltaTime =         Float32(0)
    private(set)    var     activeInputs =      Set<UserInput>()
    private(set)    var     mouseDelta =        CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        pushUInt32(sequenceNumber!, toData: &encodedData)
        
        // convert UserInput set into UInt8 array
        var actionsRawArray = [UInt8]()
        for a in activeInputs {
            actionsRawArray.append(a.rawValue)
        }
        
        pushFloat32(deltaTime, toData: &encodedData)
        
        pushUInt8Array(actionsRawArray, toData: &encodedData)
        
        pushCGPoint(mouseDelta, toData: &encodedData)
        
        return encodedData as NSData
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal, NetMessage
    /*****************************************************************************************************/
    
    override internal func parsePayload() -> NSMutableData? {
        //NSLog("ClientUpdateNetMessage.parsePayload()")
        
        if var data = super.parsePayload() {
            //var data: NSMutableData = super.parsePayload()!
            
            sequenceNumber = pullUInt32FromData(&data)
            
            deltaTime = pullFloat32FromData(&data)
            
            let actionsRawArray = pullUInt8ArrayFromData(&data)
            for a in actionsRawArray {
                if let action = UserInput(rawValue: a) {
                    activeInputs.insert(action)
                }
                else {
                    NSLog("Unknown UserInput raw value: %d", a) // this would likely only happen due to encoding/transport error...
                }
            }
            
            mouseDelta = pullCGPointFromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(deltaTime: Float32, activeActions: Set<UserInput>, mouseDelta: CGPoint, sequenceNumber: UInt32) {
        self.deltaTime = deltaTime
        self.activeInputs = activeActions
        self.mouseDelta = mouseDelta
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
