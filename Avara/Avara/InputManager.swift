//
//  InputManager.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation


// WARN: Temporary. This will eventually reside as a user preference
public func InputActionForKey(key: Key) -> InputAction? {
    switch key {
    case .W:                        return .MoveForward
    case .A:                        return .TurnLeft
    case .S:                        return .MoveBackward
    case .D:                        return .TurnRight
    case .Space:                    return .CrouchJump
    case .NumPadClear, .Tilda:      return .ToggleFocus
    case .NumPadStar, .Equal:       return .ToggleFlyover
    case .NumPad0:                  return .FlyoverCamera
    case .NumPad1, .One:            return .HeadCamera
    default:                        return nil
    }
}


public enum InputAction: UInt8, CustomStringConvertible {
    case MoveForward =      1
    case MoveBackward =     2
    case TurnLeft =         3
    case TurnRight =        4
    case CrouchJump =       5
    
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
            case .CrouchJump:       return "CrouchJump"
                
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


public class InputManager {
    
    /******************************************************************************************************
    MARK:   Types
    ******************************************************************************************************/
    
    public struct Notifications {
        struct DidBeginInputAction {
            static let name = "DidBeginInputActionNotification"
            struct UserInfoKeys {
                static let actionRawValue = "actionRawValue"
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private(set)    var activeActions =                 Set<InputAction>()
    private         var accumulatedCursorDelta =        CGPointZero
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func isActionActive(action: InputAction) -> Bool {
        return activeActions.contains(action)
    }
    
    public func readMouseDeltaAndClear() -> CGPoint {
        let delta = accumulatedCursorDelta
        accumulatedCursorDelta = CGPointZero
        return delta
    }
    
    public func addMouseDelta(delta: CGPoint) {
        accumulatedCursorDelta = CGPoint(
            x: accumulatedCursorDelta.x + delta.x,
            y: accumulatedCursorDelta.y + delta.y)
    }
    
    public func updateKeyCode(keyCode: UInt16, pressed: Bool) {
        if let key = Key(rawValue: Int(keyCode)) {
            if let action = InputActionForKey(key) {
                
                var prevActions = Set<InputAction>()
                // this is super lame but can't seem to find a better copy/clone method
                for a in activeActions {
                    prevActions.insert(a)
                }
                
                if pressed {
                    activeActions.insert(action)
                }
                else {
                    activeActions.remove(action)
                }
                
                if activeActions != prevActions {
                    let str = NSMutableString()
                    for a in activeActions {
                        str.appendString(NSString(format: "%@, ", a.description) as String)
                    }
                    NSLog("Active input actions: %@", str)
                }
                
                if !prevActions.contains(action) {
                    didBeginInputAction(action)
                }
            }
            else {
                NSLog("No action bound to key: %@", key.description)
            }
        }
        else {
            NSLog("Unknown key code: %d", keyCode)
        }
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func didBeginInputAction(action: InputAction) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            Notifications.DidBeginInputAction.name,
            object: nil,
            userInfo: [Notifications.DidBeginInputAction.UserInfoKeys.actionRawValue: Int(action.rawValue)])
    }
}
