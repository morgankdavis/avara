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
    case None =                 0
    case ClientHello =          1
    case ClientUpdate =         2
}


public func NetMessageOpcodeRawValueFromPayloadData(payloadData: NSData) -> UInt16 {
    var opcodeArray = [UInt16](count: 1, repeatedValue: 0)
    payloadData.getBytes(&opcodeArray, range: NSMakeRange(0, 2))
    return UInt16(opcodeArray[0])
}

public func MessageFromPayloadData(payloadData: NSData) -> NetMessage? {
    
    // TODO: There is no doubt a better way to do this.
    let opcodeInt = NetMessageOpcodeRawValueFromPayloadData(payloadData)
    if let opcode = NetMessageOpcode(rawValue: opcodeInt) {
        switch opcode {
        case NetMessageOpcode.ClientHello:              return ClientHelloNetMessage(payloadData: payloadData)
        case NetMessageOpcode.ClientUpdate:             return ClientUpdateNetMessage(payloadData: payloadData)
        default:                                        return nil
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
    
    public          var     opcode:             NetMessageOpcode { get { return .None } }
    public          var     sequenceNumber:     UInt32?
    private(set)    var     payloadData:        NSMutableData?
    
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
    
    internal func appendInt16(num: Int16, inout toData data: NSMutableData) {
        var numArray = [Int16]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(Int16))
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
    
    internal func appendFloat32(num: Float32, inout toData data: NSMutableData) {
        let whole = Int16(num)
        let fraction = UInt16(Float32(fabs(num - Float32(whole))) * Float32(UINT16_MAX))
        
        var wholeArray = [Int16]()
        var fractionArray = [UInt16]()
        
        wholeArray.append(whole)
        fractionArray.append(fraction)
        
        data.appendBytes(&wholeArray[0], length: sizeof(Int16))
        data.appendBytes(&fractionArray[0], length: sizeof(UInt16))
    }
    
    internal func appendCGPoint(point: CGPoint, inout toData data: NSMutableData) {
        appendFloat32(Float32(point.x), toData: &data)
        appendFloat32(Float32(point.y), toData: &data)
    }
    
    internal func appendUInt8Array(array: [UInt8], inout toData data: NSMutableData) {
        var numArray = [UInt16]()
        numArray.append(UInt16(array.count))
        data.appendBytes(&numArray[0], length: sizeof(UInt16))
        
        var arrayCopy = array // must be declared "var" for inout reference in appendBytes()
        for i in 0..<array.count {
            data.appendBytes(&arrayCopy[i], length: sizeof(UInt8))
        }
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
    
    internal func pullUInt8ArrayFromPayload() -> [UInt8] {
        let count = pullUInt16FromPayload()
        
        let dataLen = sizeof(UInt8) * Int(count)
        let arrayData = payloadData!.subdataWithRange(NSMakeRange(0, dataLen))
        var array = [UInt8](count: Int(count), repeatedValue: 0)
        arrayData.getBytes(&array, length: dataLen)
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, dataLen), withBytes: nil, length:0)
        
        return array
    }
    
    internal func pullUInt16FromPayload() -> UInt16 {
        let numData = payloadData!.subdataWithRange(NSMakeRange(0, sizeof(UInt16)))
        var numArray = [UInt16](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt16))
        let num = numArray[0]
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullUInt32FromPayload() -> UInt32 {
        let numData = payloadData!.subdataWithRange(NSMakeRange(0, sizeof(UInt32)))
        var numArray = [UInt32](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt32))
        let num = numArray[0]
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt32)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullFloat32FromPayload() -> Float32 {
        let wholeData = payloadData!.subdataWithRange(NSMakeRange(0, sizeof(Int16)))
        let fractionData = payloadData!.subdataWithRange(NSMakeRange(sizeof(Int16), sizeof(UInt16)))
        
        var wholeArray = [Int16](count: 1, repeatedValue: 0)
        var fractionArray = [UInt16](count: 1, repeatedValue: 0)
        
        wholeData.getBytes(&wholeArray, length: sizeof(Int16))
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(Int16)), withBytes: nil, length:0)
        
        fractionData.getBytes(&fractionArray, length: sizeof(UInt16))
        
        payloadData!.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        let whole = wholeArray[0]
        let fraction = fractionArray[0]
        
        return Float32(Float32(whole) + (Float32(fraction) / Float32(UINT16_MAX)))
    }
    
    internal func pullCGPointFromPayload() -> CGPoint {
        return CGPoint(x: CGFloat(pullFloat32FromPayload()), y: CGFloat(pullFloat32FromPayload()))
    }
    
//    internal func appendFloat32(num: Float32, inout toData data: NSMutableData) {
//        let whole = Int16(num)
//        let fraction = UInt16(Float32(fabs(num - Float32(whole))) * Float32(UINT16_MAX))
//        
//        var wholeArray = [Int16]()
//        var fractionArray = [UInt16]()
//        
//        wholeArray.append(whole)
//        fractionArray.append(fraction)
//        
//        data.appendBytes(&wholeArray[0], length: sizeof(Int16))
//        data.appendBytes(&fractionArray[0], length: sizeof(UInt16))
//    }
    
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
