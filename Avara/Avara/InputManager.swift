//
//  InputManager.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 goosesensor. All rights reserved.
//

import Foundation


public enum Key: Int, CustomStringConvertible {
    case W = 13
    case A = 0
    case S = 1
    case D = 2
    case Space = 49
    case UpArrow = 126
    case DownArrow = 125
    case LeftArrow = 123
    case RightArrow = 124
    case NumPad0 = 82
    case NumPad1 = 83
    case NumPad2 = 84
    case NumPad3 = 85
    case NumPad4 = 86
    case NumPad5 = 87
    case NumPad6 = 88
    case NumPad7 = 89
    case NumPad8 = 90
    case NumPad9 = 91
    case NumPadPlus = 69
    case NumPadMinus = 78
    case NumPadClear = 71
    case NumPadStar = 67
    case Equal = 24
    case Tilda = 50
    case One = 18
    case Two = 19
    case Three = 20
    case Four = 21
    case Five = 23
    
    public var description : String {
        get {
            switch self {
            case .W: return "W"
            case .A: return "A"
            case .S: return "S"
            case .D: return "D"
            case .Space: return "Space"
            case .UpArrow: return "UpArrow"
            case .DownArrow: return "DownArrow"
            case .LeftArrow: return "LeftArrow"
            case .RightArrow: return "RightArrow"
            case .NumPad0: return "NumPad0"
            case .NumPad1: return "NumPad1"
            case .NumPad2: return "NumPad2"
            case .NumPad3: return "NumPad3"
            case .NumPad4: return "NumPad4"
            case .NumPad5: return "NumPad5"
            case .NumPad6: return "NumPad6"
            case .NumPad7: return "NumPad7"
            case .NumPad8: return "NumPad8"
            case .NumPad9: return "NumPad9"
            case .NumPadPlus: return "NumPadPlus"
            case .NumPadMinus: return "NumPadMinus"
            case .NumPadClear: return "NumPadClear"
            case .NumPadStar: return "NumPadStar"
            case .Equal: return "Equal"
            case .Tilda: return "Tilda"
            case .One: return "One"
            case .Two: return "Two"
            case .Three: return "Three"
            case .Four: return "Four"
            case .Five: return "Five"
            default: return "[unknown]"
            }
        }
    }
}


public class InputManager {
    
    /******************************************************************************************************
    MARK:   Types
    ******************************************************************************************************/
    
    public struct Notifications {
        struct DidPressKey {
            static let name = "DidPressKeyNotification"
            struct UserInfoKeys {
                static let keyCode = "keyCode"
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private(set)    var keysPressed =                   Set<Key>()
    private         var accumulatedCursorDelta =        CGPointZero
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func isKeyPressed(key: Key) -> Bool {
        return keysPressed.contains(key)
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
    
    public func updateKey(key: Key, pressed: Bool) {
        var prevKeys = Set<Key>()
        // this is super lame but can't seem to find a better copy/clone method
        for k in keysPressed {
            prevKeys.insert(k)
        }
        
        if pressed {
            keysPressed.insert(key)
        }
        else {
            keysPressed.remove(key)
        }
        
        if keysPressed != prevKeys {
            let str = NSMutableString()
            for k in keysPressed {
                str.appendString(NSString(format: "%@, ", k.description) as String)
            }
           // NSLog("Pressed keys: %@", str)
        }
        
        if !prevKeys.contains(key) {
            didPressKey(key)
        }
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func didPressKey(key: Key) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            Notifications.DidPressKey.name,
            object: nil,
            userInfo: [Notifications.DidPressKey.UserInfoKeys.keyCode: Int(key.rawValue)])
    }
}
