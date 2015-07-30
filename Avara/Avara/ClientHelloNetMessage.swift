//
//  ClientHelloNetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


public class ClientHelloNetMessage: NetMessage {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private(set)    var     name:       NSString?
    
    override public var opcode: NetMessageOpcode {
        get {
            return .ClientHello
        }
    }
    
    /******************************************************************************************************
    MARK:   Public, NetMessage
    ******************************************************************************************************/
    
    override public func encodedWithSequenceNumber(sequenceNumber: UInt32) -> NSData? {
        let encodedData = super.encodedWithSequenceNumber(sequenceNumber) as! NSMutableData
        
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
    
    override internal func parsePayload() {
        NSLog("ClientHelloNetMessage.parsePayload()")
        
        super.parsePayload()
        
        name = pullStringFromPayload()
    }
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    public required init(name: String) {
        self.name = name
        super.init()
    }

    public required init() {
        super.init()
    }
}