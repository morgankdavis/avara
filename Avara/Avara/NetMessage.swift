//
//  NetMessage.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public enum NetMessageOpcode: UInt16 {
    case None =                 0
    case ClientHello =          1
    case ClientUpdate =         2
    case ServerUpdate =         3
}


public func NetMessageOpcodeRawValueFromPayloadData(payloadData: NSData) -> UInt16 {
    var opcodeArray = [UInt16](count: 1, repeatedValue: 0)
    payloadData.getBytes(&opcodeArray, range: NSMakeRange(0, 2))
    return UInt16(opcodeArray[0])
}

public func MessageFromPayloadData(payloadData: NSData) -> NetMessage? {
    
    // TODO: There's probably a better way to do this.
    let opcodeInt = NetMessageOpcodeRawValueFromPayloadData(payloadData)
    if let opcode = NetMessageOpcode(rawValue: opcodeInt) {
        switch opcode {
        case NetMessageOpcode.ClientHello:              return ClientHelloNetMessage(payloadData: payloadData)
        case NetMessageOpcode.ClientUpdate:             return ClientUpdateNetMessage(payloadData: payloadData)
        case NetMessageOpcode.ServerUpdate:             return ServerUpdateNetMessage(payloadData: payloadData)
        default:                                        return nil
        }
    }
    else {
        return nil
    }
}


public class NetMessage {

    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var     opcode:             NetMessageOpcode { get { return .None } }
    private(set)    var     payloadData:        NSMutableData?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func encoded() -> NSData? {
        // returns its on-the-wire packet data (before enet molests it)
        // since this is the base class we jsut pack up the opcode and sequenceNumber.
        // subclasses should call this as a starting point and build on it.
        
        var encodedData = NSMutableData()

        pushUInt16(opcode.rawValue, toData: &encodedData)
        
        return encodedData
    }
    
    /******************************************************w***********************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func parsePayload() -> NSMutableData? {
        //NSLog("NetMessage.parsePayload()")

        // trim opcode as it was already inspected to create this instance in the first place
        return payloadData!.subdataWithRange(NSMakeRange(sizeof(UInt16), payloadData!.length - sizeof(UInt16))).mutableCopy() as? NSMutableData
    }
    
    internal func pushUInt8(num: UInt8, inout toData data: NSMutableData) {
        var numArray = [UInt8]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(UInt8))
    }
    
    internal func pushInt16(num: Int16, inout toData data: NSMutableData) {
        var numArray = [Int16]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(Int16))
    }
    
    internal func pushUInt16(num: UInt16, inout toData data: NSMutableData) {
        var numArray = [UInt16]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(UInt16))
    }
    
    internal func pushUInt32(num: UInt32, inout toData data: NSMutableData) {
        var numArray = [UInt32]()
        numArray.append(num)
        data.appendBytes(&numArray[0], length: sizeof(UInt32))
    }
    
    internal func pushFloat64(num: Float64, inout toData data: NSMutableData) {
        // WARN: This is a shitty way to do sign
        let sign = (num < 0 ? Int8(-1) : Int8(1))
//        let whole = UInt16(nwwum)q
//        let fraction = UInt16(Float64(fabs(num - Float64(whole))) * Float64(UINT16_MAX))
        
        let (numInt, numFract) = modf(num)
        let whole = UInt16(fabs(numInt))
        let fraction = UInt16(round(Float(fabs(numFract)) * Float(UINT16_MAX)))
        
        var signArray = [Int8]()
        var wholeArray = [UInt16]()
        var fractionArray = [UInt16]()
        
        signArray.append(sign)
        wholeArray.append(whole)
        fractionArray.append(fraction)
        
        data.appendBytes(&signArray[0], length: sizeof(Int8))
        data.appendBytes(&wholeArray[0], length: sizeof(UInt16))
        data.appendBytes(&fractionArray[0], length: sizeof(UInt16))
    }
    
    internal func pushCGPoint(point: CGPoint, inout toData data: NSMutableData) {
        pushFloat64(Float64(point.x), toData: &data)
        pushFloat64(Float64(point.y), toData: &data)
    }
    
    internal func pushVector3(vec: SCNVector3, inout toData data: NSMutableData) {
        pushFloat64(Float64(vec.x), toData: &data)
        pushFloat64(Float64(vec.y), toData: &data)
        pushFloat64(Float64(vec.z), toData: &data)
    }
    
    internal func pushVector4(vec: SCNVector4, inout toData data: NSMutableData) {
        pushFloat64(Float64(vec.x), toData: &data)
        pushFloat64(Float64(vec.y), toData: &data)
        pushFloat64(Float64(vec.z), toData: &data)
        pushFloat64(Float64(vec.w), toData: &data)
    }
    
    internal func pushUInt8Array(array: [UInt8], inout toData data: NSMutableData) {
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
            pushUInt16(strLen, toData:&data)
            data.appendData(strData)
            return data
        }
        else {
            NSLog("Failed to encode string: %@", str)
            return nil
        }
    }
    
    internal func pullUInt8ArrayFromData(inout data: NSMutableData) -> [UInt8] {
        let count = pullUInt16FromData(&data)
        
        let dataLen = sizeof(UInt8) * Int(count)
        let arrayData = data.subdataWithRange(NSMakeRange(0, dataLen))
        var array = [UInt8](count: Int(count), repeatedValue: 0)
        arrayData.getBytes(&array, length: dataLen)
        
        data.replaceBytesInRange(NSMakeRange(0, dataLen), withBytes: nil, length:0)
        
        return array
    }
    
    internal func pullUInt8FromData(inout data: NSMutableData) -> UInt8 {
        let numData = data.subdataWithRange(NSMakeRange(0, sizeof(UInt8)))
        var numArray = [UInt8](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt8))
        let num = numArray[0]
        
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt8)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullUInt16FromData(inout data: NSMutableData) -> UInt16 {
        let numData = data.subdataWithRange(NSMakeRange(0, sizeof(UInt16)))
        var numArray = [UInt16](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt16))
        let num = numArray[0]
        
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullUInt32FromData(inout data: NSMutableData) -> UInt32 {
        let numData = data.subdataWithRange(NSMakeRange(0, sizeof(UInt32)))
        var numArray = [UInt32](count: 1, repeatedValue: 0)
        numData.getBytes(&numArray, length: sizeof(UInt32))
        let num = numArray[0]
        
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt32)), withBytes: nil, length:0)
        
        return num
    }
    
    internal func pullFloat64FromData(inout data: NSMutableData) -> Float64 {
        let signData = data.subdataWithRange(NSMakeRange(0, sizeof(Int8)))
        let wholeData = data.subdataWithRange(NSMakeRange(sizeof(Int8), sizeof(UInt16)))
        let fractionData = data.subdataWithRange(NSMakeRange(sizeof(Int8) + sizeof(UInt16), sizeof(UInt16)))
        
        var signArray = [Int8](count: 1, repeatedValue: 0)
        var wholeArray = [UInt16](count: 1, repeatedValue: 0)
        var fractionArray = [UInt16](count: 1, repeatedValue: 0)
        
        signData.getBytes(&signArray, length: sizeof(Int8))
        data.replaceBytesInRange(NSMakeRange(0, sizeof(Int8)), withBytes: nil, length:0)
        
        wholeData.getBytes(&wholeArray, length: sizeof(UInt16))
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        fractionData.getBytes(&fractionArray, length: sizeof(UInt16))
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        
        let sign = signArray[0]
        let whole = wholeArray[0]
        let fraction = fractionArray[0]
        
        return Float64(sign) * (Float64(whole) + (Float64(fraction) / Float64(UINT16_MAX)))
    }
    
    internal func pullCGPointFromData(inout data: NSMutableData) -> CGPoint {
        return CGPoint(
            x: CGFloat(pullFloat64FromData(&data)),
            y: CGFloat(pullFloat64FromData(&data)))
    }
    
    internal func pullVector3FromData(inout data: NSMutableData) -> SCNVector3 {
        return SCNVector3(
            x: CGFloat(pullFloat64FromData(&data)),
            y: CGFloat(pullFloat64FromData(&data)),
            z: CGFloat(pullFloat64FromData(&data)))
    }
    
    internal func pullVector4FromData(inout data: NSMutableData) -> SCNVector4 {
        return SCNVector4(
            x: CGFloat(pullFloat64FromData(&data)),
            y: CGFloat(pullFloat64FromData(&data)),
            z: CGFloat(pullFloat64FromData(&data)),
            w: CGFloat(pullFloat64FromData(&data)))
    }
    
    internal func pullStringFromData(inout data: NSMutableData) -> NSString? {
        
        // repalce with pullUInt16FromData {
        let lenData = data.subdataWithRange(NSMakeRange(0, sizeof(UInt16)))
        var lenArray = [UInt16](count: 1, repeatedValue: 0)
        lenData.getBytes(&lenArray, length: sizeof(UInt16))
        let len = lenArray[0]
        
        data.replaceBytesInRange(NSMakeRange(0, sizeof(UInt16)), withBytes: nil, length:0)
        // }
        
        let str = NSString(data: data.subdataWithRange(NSMakeRange(0, Int(len))), encoding: NSUTF16StringEncoding)
        
        data.replaceBytesInRange(NSMakeRange(0, Int(len)), withBytes: nil, length:0)
        
        return str
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init() {
        
    }
    
    public convenience init(payloadData: NSData) {
        self.init()
        self.payloadData = payloadData.mutableCopy() as? NSMutableData
        parsePayload()
    }
}
