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
    
    override public var     opcode:                     NetMessageOpcode { get { return .ClientUpdate } }
    public          var     sequenceNumber:             UInt32?
    private(set)    var     hullEulerAngles =           SCNVector3Zero
    
    //private(set)    var     buttonEntriesLockQueue =    dispatch_queue_create("com.morgankdavis.buttonEntriesLockQueue", nil)
    private(set)    var     buttonEntries:              [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]?
    
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
                for (button, force) in buttons {
                    pushUInt8(button.rawValue, toData: &encodedData)
                    pushFloat32(Float32(force), toData: &encodedData)
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
            
            buttonEntries = [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
            
            let buttonEntriesCount = pullUInt8FromData(&data)
            for _ in 0..<buttonEntriesCount {
                var buttons = [(button: ButtonInput, force: MKDFloat)]()
                let numPairs = pullUInt8FromData(&data)
                for _ in 0..<numPairs {
                    let buttonRaw = pullUInt8FromData(&data)
                    if let button = ButtonInput(rawValue: buttonRaw) {
                        let force = MKDFloat(pullFloat32FromData(&data))
                        buttons.append((button, force))
                    }
                    else {
                        pullFloat32FromData(&data) // pull the force off.
                        NSLog("Unknown UserInput raw value: %d", buttonRaw) // this would likely only happen due to encoding/transport error...
                    }
                }
                let duration = MKDFloat(pullFloat32FromData(&data))
                //dispatch_sync(buttonEntriesLockQueue) {
                    buttonEntries!.append((buttons, duration))
                //}
            }

            hullEulerAngles = pullVector3FromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(buttonEntries: [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)],
        hullEulerAngles: SCNVector3, sequenceNumber: UInt32) {
        self.buttonEntries = buttonEntries
        self.hullEulerAngles = hullEulerAngles
        self.sequenceNumber = sequenceNumber
        super.init()
    }
    
    public required init() {
        super.init()
    }
}
