//
//  ClientHelloNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//
//  Sent after socket connection to establish player identifiy and start sequence number.
//
//  FORMAT: [STRING]<name>
//

import Foundation


public class ClientHelloNetMessage: NetMessage {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    override public var     opcode:     NetMessageOpcode { get { return .ClientHello } }
    private(set)    var     name:       NSString?

    /*****************************************************************************************************/
    // MARK:   Public, NetMessage
    /*****************************************************************************************************/
    
    override public func encoded() -> NSData? {
        let encodedData = super.encoded() as! NSMutableData
        
        guard name != nil else {
            NSLog("'name' is nil")
            return nil
        }
        
        if let nameData = dataFromNSString(name!) {
            encodedData.appendData(nameData)
        }
        else {
            NSLog("Failed to encode 'name'")
            return nil
        }
        
        return encodedData as NSData
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal, NetMessage
    /*****************************************************************************************************/
    
    override internal func parsePayload() -> NSMutableData? {
        //NSLog("ClientHelloNetMessage.parsePayload()")

        if var data = super.parsePayload() {
            name = pullStringFromData(&data)
        }
        return nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(name: String) {
        self.name = name
        super.init()
    }

    public required init() {
        super.init()
    }
}