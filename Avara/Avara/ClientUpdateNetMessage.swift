//
//  ClientUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/30/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable client message. Sends player input to server.
//
//  FORMAT: [UInt8]TotalInputs[{[UInt8]<UserInput>[Float32]<TotalTime>}][Float32]<MouseDeltaX>[Float32]<MouseDeltaY>
//

import Foundation


public class ClientUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ClientUpdate } }
    public          var     sequenceNumber:     UInt32?
    private(set)    var     buttonInputs =        [ButtonInput: Double]()
    private(set)    var     mouseDelta =        CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        pushUInt32(sequenceNumber!, toData: &encodedData)
        
        let buttonInputCount = UInt8(buttonInputs.count)
        pushUInt8(buttonInputCount, toData: &encodedData)
        for (input, duration) in buttonInputs {
            pushUInt8(input.rawValue, toData: &encodedData)
            pushFloat32(Float32(duration), toData: &encodedData)
        }
        
        pushCGPoint(mouseDelta, toData: &encodedData)
        
        return encodedData as NSData
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal, NetMessage
    /*****************************************************************************************************/
    
    override internal func parsePayload() -> NSMutableData? {
        //NSLog("ClientUpdateNetMessage.parsePayload()")
        
        if var data = super.parsePayload() {
            sequenceNumber = pullUInt32FromData(&data)
            
            let buttonInputCount = pullUInt8FromData(&data)
            for _ in 0..<buttonInputCount {
                let inputRaw = pullUInt8FromData(&data)
                if let input = ButtonInput(rawValue: inputRaw) {
                    buttonInputs[input] = Double(pullFloat32FromData(&data))
                }
                else {
                    NSLog("Unknown UserInput raw value: %d", inputRaw) // this would likely only happen due to encoding/transport error...
                }
            }

            mouseDelta = pullCGPointFromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(buttonInputs: [ButtonInput: Double], mouseDelta: CGPoint, sequenceNumber: UInt32) {
        self.buttonInputs = buttonInputs
        self.mouseDelta = mouseDelta
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
