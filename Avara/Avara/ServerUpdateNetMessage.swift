//
//  ServerUpdateNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/31/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  The ganddaddy unreliable server message. Sends player state to clients.
//
//  FORMAT: [UINT8]<NumPlayers>{[UInt32]<sequenceNumber>[UInt32]<clientID>[VEC3]<position>[VEC4]<headOrientation>[VEC4]<bodyOrientation>}
//

import Foundation


public class ServerUpdateNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:             NetMessageOpcode { get { return .ServerUpdate } }
    private(set)    var     playerUpdates =     [NetPlayerUpdate]()

    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        var encodedData = super.encoded() as! NSMutableData
        
        let updateCount = playerUpdates.count
        appendUInt8(UInt8(updateCount), toData: &encodedData)
        
        for u in playerUpdates {
            appendUInt32(u.sequenceNumber, toData: &encodedData)
            appendUInt32(u.id, toData: &encodedData)
            appendVector3(u.position, toData: &encodedData)
            appendVector4(u.legsOrientation, toData: &encodedData)
            appendVector4(u.headOrientation, toData: &encodedData)
        }

        return encodedData as NSData
    }
    
    override internal func parsePayload() {
        NSLog("ClientUpdateNetMessage.parsePayload()")
        
        super.parsePayload()
        
        let updateCount = Int(pullUInt16FromPayload())
        
        var updates = [NetPlayerUpdate]()
        for (var i=0; i<updateCount; i++) {
            let sequenceNumber = pullUInt32FromPayload()
            let clientID = pullUInt32FromPayload()
            let position = pullVector3FromPayload()
            let legsOrientation = pullVector4FromPayload()
            let headOrientation = pullVector4FromPayload()
            
            let update = NetPlayerUpdate(
                sequenceNumber: sequenceNumber,
                id: clientID,
                position: position,
                legsOrientation: legsOrientation,
                headOrientation: headOrientation)
            
            updates.append(update)
        }
        playerUpdates = updates
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public convenience init(netPlayers: [NetPlayer]) {
        var playerUpdates = [NetPlayerUpdate]()
        
        for p in netPlayers {
            let u = NetPlayerUpdate(
                sequenceNumber: p.sequenceNumber,
                id: p.id,
                position: p.character.bodyNode.position,
                legsOrientation: p.character.legsNode!.orientation,
                headOrientation: p.character.headNode!.orientation)
            playerUpdates.append(u)
        }
        
        self.init(playerUpdates: playerUpdates)
    }
    
    public required init(playerUpdates: [NetPlayerUpdate]) {
        self.playerUpdates = playerUpdates
        super.init()
    }
    
    public required init() {
        super.init()
    }
}