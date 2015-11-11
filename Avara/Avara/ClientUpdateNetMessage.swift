//
//  ClientUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/30/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable client message. Sends player input to server.
//
//  FORMAT: [UInt8]<NumEntries>{[UInt8]<NumButtonMagPairs>{[UInt8]<ButtonInput>[Float32]<Magnitude>}[Float32]<Duration>}[SVNVector3]<HullEulerAngles>
//

import Foundation
import SceneKit


public class ClientUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ClientUpdate } }
    public          var     sequenceNumber:     UInt32?
    private(set)    var     buttonEntries:      [(buttons: [(button: ButtonInput, magnitude: CGFloat)], dT: CGFloat)]?
    private(set)    var     hullEulerAngles =   SCNVector3Zero
    
    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        pushUInt32(sequenceNumber!, toData: &encodedData)
        
        if let entries = buttonEntries {
            let buttonEntriesCount = UInt8(entries.count)
            pushUInt8(buttonEntriesCount, toData: &encodedData)
            for (buttons, duration) in entries {
                pushUInt8(UInt8(buttons.count), toData: &encodedData)
                for (button, magnitude) in buttons {
                    pushUInt8(button.rawValue, toData: &encodedData)
                    pushFloat32(Float32(magnitude), toData: &encodedData)
                }
                pushFloat32(Float32(duration), toData: &encodedData)
            }
        }
        
        pushVector3(hullEulerAngles, toData: &encodedData)
        
        return encodedData as NSData
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal, NetMessage
    /*****************************************************************************************************/
    
    override internal func parsePayload() -> NSMutableData? {
        //NSLog("ClientUpdateNetMessage.parsePayload()")
        
        if var data = super.parsePayload() {
            sequenceNumber = pullUInt32FromData(&data)
            
//            let buttonInputCount = pullUInt8FromData(&data)
//            for _ in 0..<buttonInputCount {
//                let inputRaw = pullUInt8FromData(&data)
//                if let input = ButtonInput(rawValue: inputRaw) {
//                    buttonInputs[input] = Double(pullFloat32FromData(&data))
//                }
//                else {
//                    NSLog("Unknown UserInput raw value: %d", inputRaw) // this would likely only happen due to encoding/transport error...
//                }
//            }
            
            buttonEntries = [(buttons: [(button: ButtonInput, magnitude: CGFloat)], dT: CGFloat)]()
            
            let buttonEntriesCount = pullUInt8FromData(&data)
            for _ in 0..<buttonEntriesCount {
                var buttons = [(button: ButtonInput, magnitude: CGFloat)]()
                let numPairs = pullUInt8FromData(&data)
                for _ in 0..<numPairs {
                    let buttonRaw = pullUInt8FromData(&data)
                    if let button = ButtonInput(rawValue: buttonRaw) {
                        let magnitude = CGFloat(pullFloat32FromData(&data))
                        buttons.append((button, magnitude))
                    }
                    else {
                        pullFloat32FromData(&data) // pull the magnitude off.
                        NSLog("Unknown UserInput raw value: %d", buttonRaw) // this would likely only happen due to encoding/transport error...
                    }
                }
                let duration = CGFloat(pullFloat32FromData(&data))
                buttonEntries!.append((buttons, duration))
            }

            hullEulerAngles = pullVector3FromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
//    public required init(buttonInputs: [ButtonInput: Double], hullEulerAngles: SCNVector3, sequenceNumber: UInt32) {
    public required init(buttonEntries: [(buttons: [(button: ButtonInput, magnitude: CGFloat)], dT: CGFloat)],
        hullEulerAngles: SCNVector3, sequenceNumber: UInt32) {
//        self.buttonInputs = buttonInputs
        self.buttonEntries = buttonEntries
        //self.mouseDelta = mouseDelta
        self.hullEulerAngles = hullEulerAngles
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
