//
//  InputManager.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation


//public typealias MouseDelta = CGPoint


// WARN: Temporary. This mapping will eventually reside as a user preference
public func UserInputForKey(key: Key) -> UserInput? {
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
    default:                        return nil
    }
}


public enum UserInput: UInt8, CustomStringConvertible {
    case MoveForward =      1
    case MoveBackward =     2
    case TurnLeft =         3
    case TurnRight =        4
    case Jump =             5
    case ToggleFocus =      100
    case ToggleFlyover =    101
    case HeadCamera =       150
    case FlyoverCamera =    151
    
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
        struct DidBeginUserInput {
            static let name = "DidBeginUserInputNotification"
            struct UserInfoKeys {
                static let inputRawValue = "inputRawValue"
            }
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private(set)    var directMouseHelper:              MKDDirectMouseHelper?
    private(set)    var activeInputs =                  Set<UserInput>()
    private         var accumulatedMouseDelta =         CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func isInputActive(action: UserInput) -> Bool {
        return activeInputs.contains(action)
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
    
    public func updateKeyCode(keyCode: UInt16, pressed: Bool) {
        if let key = Key(rawValue: Int(keyCode)) {
            if let action = UserInputForKey(key) {
                
                var prevInputs = Set<UserInput>()
                // this is super lame but can't seem to find a better copy/clone method
                for a in activeInputs {
                    prevInputs.insert(a)
                }
                
                if pressed {
                    activeInputs.insert(action)
                }
                else {
                    activeInputs.remove(action)
                }
                
                if activeInputs != prevInputs {
                    let str = NSMutableString()
                    for a in activeInputs {
                        str.appendString(NSString(format: "%@, ", a.description) as String)
                    }
                    //NSLog("Active user inputs: %@", str)
                }
                
                if !prevInputs.contains(action) {
                    didBeginUserInput(action)
                }
            }
            else {
                NSLog("No user input bound to key: %@", key.description)
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
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetButtonUp buttonID: Int32, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetButtonUp: %d, mouseID: %d)", helper, buttonID, mouseID)
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
    
    private func didBeginUserInput(action: UserInput) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            Notifications.DidBeginUserInput.name,
            object: nil,
            userInfo: [Notifications.DidBeginUserInput.UserInfoKeys.inputRawValue: Int(action.rawValue)])
    }
    
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
