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
//    private(set)    var     deltaTime =         Float32(0)
//    private(set)    var     activeInputs =      Set<UserInput>()
    private(set)    var     userInputs =        [UserInput: Double]()
    private(set)    var     mouseDelta =        CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        pushUInt32(sequenceNumber!, toData: &encodedData)
        
        let inputCount = UInt8(userInputs.count)
        pushUInt8(inputCount, toData: &encodedData)
        for (input, duration) in userInputs {
            pushUInt8(input.rawValue, toData: &encodedData)
            pushFloat32(Float32(duration), toData: &encodedData)
        }
        
//        // convert UserInput set into UInt8 array
//        var actionsRawArray = [UInt8]()
//        for a in activeInputs {
//            actionsRawArray.append(a.rawValue)
//        }
//
//        pushFloat32(deltaTime, toData: &encodedData)
//        
//        pushUInt8Array(actionsRawArray, toData: &encodedData)
        
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
            
            let inputCount = pullUInt8FromData(&data)
            for _ in 0..<inputCount {
                let inputRaw = pullUInt8FromData(&data)
                if let input = UserInput(rawValue: inputRaw) {
                    userInputs[input] = Double(pullFloat32FromData(&data))
                }
                else {
                    NSLog("Unknown UserInput raw value: %d", inputRaw) // this would likely only happen due to encoding/transport error...
                }
            }
            
//            deltaTime = pullFloat32FromData(&data)
            
//            let actionsRawArray = pullUInt8ArrayFromData(&data)
//            for a in actionsRawArray {
//                if let action = UserInput(rawValue: a) {
//                    activeInputs.insert(action)
//                }
//                else {
//                    NSLog("Unknown UserInput raw value: %d", a) // this would likely only happen due to encoding/transport error...
//                }
//            }
            
            mouseDelta = pullCGPointFromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(userInputs: [UserInput: Double], mouseDelta: CGPoint, sequenceNumber: UInt32) {
//        self.deltaTime = deltaTime
        self.userInputs = userInputs
        self.mouseDelta = mouseDelta
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
