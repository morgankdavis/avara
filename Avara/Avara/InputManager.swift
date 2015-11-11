//
//  InputManager.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation


// WARN: Temporary. This mapping will eventually reside as a user preference
public func ButtonInputForKey(key: Key) -> ButtonInput? {
    switch key {
    case .W:                        return .MoveForward
    case .A:                        return .TurnLeft
    case .S:                        return .MoveBackward
    case .D:                        return .TurnRight
    case .Space:                    return .Jump
    case .NumPadClear, .Tilda:      return .ToggleFocus
    case .NumPadStar, .Equal:       return .ToggleFlyover
    case .NumPad0:                  return .FlyoverCamera
    case .NumPad1, .One:            return .HeadCamera
    case .Mouse1:                   return .Fire
    default:                        return nil
    }
}


public enum ButtonInput: UInt8, CustomStringConvertible {
    case MoveForward =      1
    case MoveBackward =     2
    case TurnLeft =         3
    case TurnRight =        4
    case Jump =             5
    case ToggleFocus =      100
    case ToggleFlyover =    101
    case HeadCamera =       150
    case FlyoverCamera =    151
    case Fire =             200
    
    public var description : String {
        get {
            switch self {
            case .MoveForward:      return "MoveForward"
            case .MoveBackward:     return "MoveBackward"
            case .TurnLeft:         return "TurnLeft"
            case .TurnRight:        return "TurnRight"
            case .Jump:             return "Jump"
            case .ToggleFocus:      return "ToggleFocus"
            case .ToggleFlyover:    return "ToggleFlyover"
            case .HeadCamera:       return "HeadCamera"
            case .FlyoverCamera:    return "FlyoverCamera"
            default:                return "[unknown]"
            }
        }
    }
}

public enum Key: Int, CustomStringConvertible {
    case W =                13
    case A =                0
    case S =                1
    case D =                2
    case Space =            49
    case UpArrow =          126
    case DownArrow =        125
    case LeftArrow =        123
    case RightArrow =       124
    case NumPad0 =          82
    case NumPad1 =          83
    case NumPad2 =          84
    case NumPad3 =          85
    case NumPad4 =          86
    case NumPad5 =          87
    case NumPad6 =          88
    case NumPad7 =          89
    case NumPad8 =          90
    case NumPad9 =          91
    case NumPadPlus =       69
    case NumPadMinus =      78
    case NumPadClear =      71
    case NumPadStar =       67
    case Equal =            24
    case Tilda =            50
    case One =              18
    case Two =              19
    case Three =            20
    case Four =             21
    case Five =             23
    case Mouse1 =           500
    
    public var description : String {
        get {
            switch self {
            case .W:                return "W"
            case .A:                return "A"
            case .S:                return "S"
            case .D:                return "D"
            case .Space:            return "Space"
            case .UpArrow:          return "UpArrow"
            case .DownArrow:        return "DownArrow"
            case .LeftArrow:        return "LeftArrow"
            case .RightArrow:       return "RightArrow"
            case .NumPad0:          return "NumPad0"
            case .NumPad1:          return "NumPad1"
            case .NumPad2:          return "NumPad2"
            case .NumPad3:          return "NumPad3"
            case .NumPad4:          return "NumPad4"
            case .NumPad5:          return "NumPad5"
            case .NumPad6:          return "NumPad6"
            case .NumPad7:          return "NumPad7"
            case .NumPad8:          return "NumPad8"
            case .NumPad9:          return "NumPad9"
            case .NumPadPlus:       return "NumPadPlus"
            case .NumPadMinus:      return "NumPadMinus"
            case .NumPadClear:      return "NumPadClear"
            case .NumPadStar:       return "NumPadStar"
            case .Equal:            return "Equal"
            case .Tilda:            return "Tilda"
            case .One:              return "One"
            case .Two:              return "Two"
            case .Three:            return "Three"
            case .Four:             return "Four"
            case .Five:             return "Five"
            case .Mouse1:           return "Mouse1"
            default:                return "[unknown]"
            }
        }
    }
}


public class InputManager: NSObject, MKDDirectMouseHelperDelegate {
    
    /*****************************************************************************************************/
    // MARK:   Types
    /*****************************************************************************************************/
    
    public struct Notifications {
        struct DidStartPressingButton {
            static let name = "DidStartPressingButtonNotification"
            struct UserInfoKeys {
                static let buttonRawValue = "buttonRawValue"
            }
        }
    }
    
//    public struct Notifications {
//        struct DidBeginButtonInput {
//            static let name = "DidBeginButtonInputNotification"
//            struct UserInfoKeys {
//                static let inputRawValue = "inputRawValue"
//            }
//        }
//    }
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private(set)    var directMouseHelper:              MKDDirectMouseHelper?
    //private(set)    var pressedButtons =                Set<ButtonInput>()
    private(set)    var pressedButtons =                [ButtonInput : CGFloat]()   // button:magnitude
    private         var accumulatedMouseDelta =         CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func startDirectMouseCapture() {
        directMouseHelper = MKDDirectMouseHelper(delegate: self)
        directMouseHelper!.findMice()
    }
    
    public func stopDirectMouseCapture() {
        if let helper = directMouseHelper {
            helper.quit()
        }
        directMouseHelper = nil
    }
    
    public func readMouseDeltaAndClear() -> CGPoint {
        let delta = accumulatedMouseDelta
        accumulatedMouseDelta = CGPointZero
        return delta
    }
    
    public func addMouseDelta(delta: CGPoint) {
        accumulatedMouseDelta = CGPoint(
            x: accumulatedMouseDelta.x + delta.x,
            y: accumulatedMouseDelta.y + delta.y)
    }
    
//    public func updateKeyCode(keyCode: UInt16, pressed: Bool) {
//        if let key = Key(rawValue: Int(keyCode)) {
//            if let action = ButtonInputForKey(key) {
//                
//                var prevInputs = Set<ButtonInput>()
//                // this is super lame but can't seem to find a better copy/clone method
//                for a in pressedButtons {
//                    prevInputs.insert(a)
//                }
//                
//                if pressed {
//                    pressedButtons.insert(action)
//                }
//                else {
//                    pressedButtons.remove(action)
//                }
//                
//                if pressedButtons != prevInputs {
//                    let str = NSMutableString()
//                    for a in pressedButtons {
//                        str.appendString(NSString(format: "%@, ", a.description) as String)
//                    }
//                    //NSLog("Active user inputs: %@", str)
//                }
//                
//                if !prevInputs.contains(action) {
//                    didBeginUserInput(action)
//                }
//            }
//            else {
//                NSLog("No button input bound to key: %@", key.description)
//            }
//        }
//        else {
//            NSLog("Unknown key code: %d", keyCode)
//        }
//    }
    
    public func updateKeyCode(keyCode: UInt16, pressed: Bool) {
        if let key = Key(rawValue: Int(keyCode)) {
            if let button = ButtonInputForKey(key) {
                
                var prevInputs = pressedButtons // Swift dictionaries are Structs, so this *should* copy the old dict
                
                if pressed {
                    pressedButtons[button] = 1.0
                }
                else {
                    pressedButtons.removeValueForKey(button)
                }
                
                // print input if changed
                var changed = false
                for (b, _) in pressedButtons {
                    if prevInputs[b] == nil {
                        changed = true
                        break
                    }
                }
                if !changed {
                    for (b, _) in prevInputs {
                        if pressedButtons[b] == nil {
                            changed = true
                            break
                        }
                    }
                }
                if changed {
                    let str = NSMutableString()
                    for (b, m) in pressedButtons {
                        str.appendString(NSString(format: "(%@, %f), ", b.description, m) as String)
                    }
                    NSLog("Pushed buttons: %@", str)
                }
                
                if prevInputs[button] == nil {
                    didStartPressingButton(button)
                }
            }
            else {
                NSLog("No button input bound to key: %@", key.description)
            }
        }
        else {
            NSLog("Unknown key code: %d", keyCode)
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   MKDDirectMouseHelperDelegate
    /*****************************************************************************************************/
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didFindMouseID mouseID: Int32, name: String!, driverName: String!) {
        NSLog("directMouseHelper(%@, didFindMouseID: %d, name: %@, driverName: %@)", helper, mouseID, name, driverName)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetRelativeMotion delta: Int32, axis: MKDDirectMouseAxis, mouseID: Int32) {
        //NSLog("directMouseHelper(%@, didGetRelativeMotion: %d, axis: %d, mouseID: %d)", helper, delta, axis.rawValue, mouseID)
        
        addMouseDelta(CGPointMake(CGFloat((axis == .X ? -delta : 0)), CGFloat((axis == .Y ? delta : 0))))
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetButtonDown buttonID: Int32, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetButtonDown: %d, mouseID: %d)", helper, buttonID, mouseID)
        
        updateKeyCode(UInt16(buttonID), pressed: true)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetButtonUp buttonID: Int32, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetButtonUp: %d, mouseID: %d)", helper, buttonID, mouseID)
        
        updateKeyCode(UInt16(buttonID), pressed: false)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetVerticalScroll direction: MKDDirectMouseVerticalScrollDirection, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetVerticalScroll: %d, mouseID: %d)", helper, direction.rawValue, mouseID)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetHorizontalScroll direction: MKDDirectMouseHorizontalScrollDirection, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetHorizontalScroll: %d, mouseID: %d)", helper, direction.rawValue, mouseID)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didFailWithError error: Int32) {
        NSLog("directMouseHelper(%@, didFailWithError: %d)", helper, error)
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func didStartPressingButton(button: ButtonInput) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            Notifications.DidStartPressingButton.name,
            object: nil,
            userInfo: [Notifications.DidStartPressingButton.UserInfoKeys.buttonRawValue: Int(button.rawValue)])
    }
    
//    private func didBeginUserInput(action: ButtonInput) {
//        NSNotificationCenter.defaultCenter().postNotificationName(
//            Notifications.DidBeginButtonInput.name,
//            object: nil,
//            userInfo: [Notifications.DidBeginButtonInput.UserInfoKeys.inputRawValue: Int(action.rawValue)])
//    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    override init() {
        super.init()
        if DIRECT_MOUSE_ENABLED {
            self.directMouseHelper = MKDDirectMouseHelper(delegate: self)
            self.directMouseHelper!.findMice()
        }
    }
}
