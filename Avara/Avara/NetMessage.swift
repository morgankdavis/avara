//
//  NetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public enum NetMessageOpcode : UInt16 {
    case None =             0
    case ClientHello =      1
}


public func NetMessageOpcodeRawValueFromPayloadData(payloadData: NSData) -> UInt16 {
    var opcodeArray = [UInt16](count: 1, repeatedValue: 0)
    payloadData.getBytes(&opcodeArray, range: NSMakeRange(0, 2))
    return UInt16(opcodeArray[0])
}

public func MessageFromPayloadData(payloadData: NSData) -> NetMessage? {
    
    let opcodeInt = NetMessageOpcodeRawValueFromPayloadData(payloadData)
    if let opcode = NetMessageOpcode(rawValue: opcodeInt) {
        switch opcode {
        case NetMessageOpcode.ClientHello:
            return ClientHelloNetMessage(payloadData: payloadData)
        default:
            return nil
        }
    }
    else {
        return nil
    }
}


public class NetMessage {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    public          var     sequenceNumber:     UInt32?
    private(set)    var     payloadData:        NSMutableData?
    
    public          var     opcode:             NetMessageOpcode {
        get {
            return .None
        }
    }
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func encodedWithSequenceNumber(sequenceNumber: UInt32) -> NSData? {
        // returns its on-the-wire packet data (before enet molests it)
        // since this is the base class we jsut pack up the opcode and sequenceNumber.
        // subclasses should call this as a starting point and build on it.
        
        var encodedData = NSMutableData()

        appendUInt16(opcode.rawValue, toData: &encodedData)
        appendUInt32(sequenceNumber, toData: &encodedData)
        
        return encodedData
    }
    
    /******************************************************************************************************
    MARK:   Internal
    ******************************************************************************************************/
    
    internal func parsePayload() {
        NSLog("NetMessage.parsePayload()")
        NSLog("payloadData: %@", payloadData!)
        
        // move opcode as it was already inspected to create this instance in the first place
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        sequenceNumber = pullUInt32FromPayload()
    }
    
    internal func appendUInt16(num: UInt16, inout toData data: NSMutableData) {
        var numArray = [UInt16]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(UInt16))
    }
    
    internal func appendUInt32(num: UInt32, inout toData data: NSMutableData) {
        var numArray = [UInt32]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(UInt32))
    }
    
    internal func dataFromNSString(str: NSString) -> NSMutableData? {
        if let strData = str.dataUsingEncoding(NSUTF16StringEncoding) {
            let strLen = UInt16(strData.length)
            
            var data = NSMutableData()
            appendUInt16(strLen, toData:&data)
            data.appendData(strData)
            return data
        }
        else {
            NSLog("Failed to encode string: %@", str)
            return nil
        }
    }
    
    internal func pullUInt32FromPayload() -> UInt32 {
        let numData = payloadData!.subdataWithRange(NSMakeRange(0, sizeof(UInt32)))
        var numArray = [UInt32](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt32))
        let num = numArray[0]
        //let num = CFSwapInt32HostToBig(numArray[0])
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt32)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullStringFromPayload() -> NSString? {
        
        // repalce with pullUInt16FromData {
        let lenData = payloadData!.subdataWithRange(NSMakeRange(0, sizeof(UInt16)))
        var lenArray = [UInt16](count: 1, repeatedValue: 0)
        lenData.getBytes(&lenArray, length: sizeof(UInt16))
        let len = lenArray[0]
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        // }
        
        let str = NSString(data: payloadData!.subdataWithRange(NSMakeRange(0, Int(len))), encoding: NSUTF16StringEncoding)
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, Int(len)), withBytes: nil, length:0)
        
        return str
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
//    private func encodedOpcodeAndSequenceNumber(sequenceNumber: UInt32) -> NSMutableData {
//        // called from encode(). creates the first big of payload data containing <opcode><sequenceNumber>
//        let encodedData = NSMutableData()
//        
//        var opcodeArray = [UInt16]()
//        opcodeArray.append(opcode.rawValue)
//        
//        var sqNumArray = [UInt32]()
//        sqNumArray.append(sequenceNumber)
//        
//        encodedData.appendBytes(&opcodeArray[0], length: sizeof(UInt16))
//        encodedData.appendBytes(&sqNumArray[0], length: sizeof(UInt32))
//        
//        return encodedData
//    }
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    public required init() {
        
    }
    
    public convenience init(payloadData: NSData) {
        self.init()
        self.payloadData = payloadData.mutableCopy() as? NSMutableData
        parsePayload()
    }
}
