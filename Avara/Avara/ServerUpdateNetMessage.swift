//
//  ServerUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/31/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable server message. Sends player state to clients.
//
//  FORMAT: [UINT8]<NumPlayers>{[UInt32]<sequenceNumber>[UInt32]<clientID>[VEC3]<position>[VEC4]<bodyOrientation>[VEC4]<headOrientation>}
//

import Foundation


public class ServerUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ServerUpdate } }
    private(set)    var     playerSnapshots =   [NetPlayerSnapshot]()

    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        let snapshotsCount = playerSnapshots.count
        pushUInt8(UInt8(snapshotsCount), toData: &encodedData)
        
        for u in playerSnapshots {
            pushUInt32(u.sequenceNumber, toData: &encodedData)
            pushUInt32(u.id, toData: &encodedData)
            pushVector3(u.position, toData: &encodedData)
            pushVector4(u.bodyRotation, toData: &encodedData)
            pushVector3(u.headEulerAngles, toData: &encodedData)
        }

        return encodedData as NSData
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal, NetMessage
    /*****************************************************************************************************/
    
    override internal func parsePayload() -> NSMutableData? {
        //NSLog("ServerUpdateNetMessage.parsePayload()")
        
        if var data = super.parsePayload() {
            
            let snapshotsCount = Int(pullUInt8FromData(&data))
            
            var snapshots = [NetPlayerSnapshot]()
            for (var i=0; i<snapshotsCount; i++) {
                let sequenceNumber = pullUInt32FromData(&data)
                let clientID = pullUInt32FromData(&data)
                let position = pullVector3FromData(&data)
                let bodyRotation = pullVector4FromData(&data)
                let headEulerAngles = pullVector3FromData(&data)
                
                let snapshot = NetPlayerSnapshot(
                    sequenceNumber: sequenceNumber,
                    id: clientID,
                    position: position,
                    bodyRotation: bodyRotation,
                    headEulerAngles: headEulerAngles)
                
                snapshots.append(snapshot)
            }
            playerSnapshots = snapshots
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(playerSnapshots: [NetPlayerSnapshot]) {
        self.playerSnapshots = playerSnapshots
        super.init()
    }
    
    public required init() {
        super.init()
    }
}