//
//  InputManager.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import CoreGraphics
import GameController


// WARN: Temporary. This mapping will eventually reside as a user preference
public func ButtonInputForKey(key: Key) -> ButtonInput? {
    switch key {
    case .W,                    .GamePadLThumbU:        return .MoveForward
    case .A,                    .GamePadLThumbL:        return .TurnLeft
    case .S,                    .GamePadLThumbD:        return .MoveBackward
    case .D,                    .GamePadLThumbR:        return .TurnRight
    case .Space,                .GamePadL2:             return .Jump
    case                        .GamePadRThumbU:        return .LookUp
    case                        .GamePadRThumbD:        return .LookDown
    case                        .GamePadRThumbL:        return .LookLeft
    case                        .GamePadRThumbR:        return .LookRight
    case .NumPadClear, .Tilda:                          return .ToggleFocus
    case .NumPadStar, .Equal,   .GamePadDPadU:          return .ToggleFlyover
    case .NumPad0,              .GamePadDPadR:          return .FlyoverCamera
    case .NumPad1, .One,        .GamePadDPadD:          return .HeadCamera
    case .Mouse1,               .GamePadR2:             return .Fire
    default:                                            return nil
    }
}


public enum ButtonInput: UInt8, CustomStringConvertible {
    case MoveForward =      1
    case MoveBackward =     2
    case TurnLeft =         3
    case TurnRight =        4
    case Jump =             5
    case LookUp =           6
    case LookDown =         7
    case LookLeft =         8
    case LookRight =        9
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
            case .LookUp:           return "LookUp"
            case .LookDown:         return "LookDown"
            case .LookLeft:         return "LookLeft"
            case .LookRight:        return "LookRight"
            case .ToggleFocus:      return "ToggleFocus"
            case .ToggleFlyover:    return "ToggleFlyover"
            case .HeadCamera:       return "HeadCamera"
            case .FlyoverCamera:    return "FlyoverCamera"
            case .Fire:             return "Fire"
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
    
    case GamePadL1 =        1000
    case GamePadL2 =        1001
    case GamePadR1 =        1002
    case GamePadR2 =        1003
    case GamePadDPadU =     1004
    case GamePadDPadD =     1005
    case GamePadDPadL =     1006
    case GamePadDPadR =     1007
    case GamePadA =         1008
    case GamePadB =         1009
    case GamePadX =         1010
    case GamePadY =         1011
    case GamePadLThumbU =   1012
    case GamePadLThumbD =   1013
    case GamePadLThumbL =   1014
    case GamePadLThumbR =   1015
    case GamePadRThumbU =   1016
    case GamePadRThumbD =   1017
    case GamePadRThumbL =   1018
    case GamePadRThumbR =   1019
    case GamePadPause =     1020
    
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
                
            case .GamePadL1:        return "GamePadL1"
            case .GamePadL2:        return "GamePadL2"
            case .GamePadR1:        return "GamePadR1"
            case .GamePadR2:        return "GamePadR2"
            case .GamePadDPadU:     return "GamePadDPadU"
            case .GamePadDPadD:     return "GamePadDPadD"
            case .GamePadDPadL:     return "GamePadDPadL"
            case .GamePadDPadR:     return "GamePadDPadR"
            case .GamePadA:         return "GamePadA"
            case .GamePadB:         return "GamePadB"
            case .GamePadX:         return "GamePadX"
            case .GamePadY:         return "GamePadY"
            case .GamePadLThumbU:   return "GamePadLThumbU"
            case .GamePadLThumbD:   return "GamePadLThumbD"
            case .GamePadLThumbL:   return "GamePadLThumbL"
            case .GamePadLThumbR:   return "GamePadLThumbR"
            case .GamePadRThumbU:   return "GamePadRThumbU"
            case .GamePadRThumbD:   return "GamePadRThumbD"
            case .GamePadRThumbL:   return "GamePadRThumbL"
            case .GamePadRThumbR:   return "GamePadRThumbR"
            case .GamePadPause:     return "GamePadPause"
                
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
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private(set)    var directMouseHelper:              MKDDirectMouseHelper?
    private(set)    var pressedButtons =                [ButtonInput : MKDFloat]()   // button:force
    private         var accumulatedMouseDelta =         CGPointZero
    private         var gameController:                 GCController?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    #if os(OSX)
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
    #endif

    public func updateKeyCode(keyCode: UInt16, force: MKDFloat) {
        if let key = Key(rawValue: Int(keyCode)) {
            updateKey(key, force: force)
        }
        else {
            NSLog("Unknown key code: %d", keyCode)
        }
    }
    
    public func controllerDidConnectNotification(note: NSNotification) {
        //NSLog("controllerDidConnectNotification(%@)", note)
        
        if (note.object as! GCController).vendorName != "Remote" {
            gameController = note.object as? GCController
            setupGamepadHandlers()
        }
    }
    
    public func controllerDidDisconnectNotification(note: NSNotification) {
        //NSLog("controllerDidDisconnectNotification(%@)", note)
        
        gameController = nil
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func updateKey(key: Key, force: MKDFloat) {
        //NSLog("updateKey(%@, force: %f)", key.description, force)
        
        if let button = ButtonInputForKey(key) {
            var prevInputs = pressedButtons // Swift dictionaries are Structs, so this *should* copy the old dict
            
            if force > 0 {
                pressedButtons[button] = force
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
                for (b, f) in pressedButtons {
                    str.appendString(NSString(format: "(%@, %f), ", b.description, f) as String)
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
    
    private func didStartPressingButton(button: ButtonInput) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            Notifications.DidStartPressingButton.name,
            object: nil,
            userInfo: [Notifications.DidStartPressingButton.UserInfoKeys.buttonRawValue: Int(button.rawValue)])
    }
    
    private func setupGamepadHandlers() {
        NSLog("setupGamepadHandlers()")
        
        gameController?.controllerPausedHandler = gameControllerPausedHandler
        
        if let motion = gameController?.motion {
            motion.valueChangedHandler = gamepadMotionChangedHandler
        }
        
        if let gamepad = gameController?.extendedGamepad {
            gamepad.buttonA.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.buttonB.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.buttonX.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.buttonY.valueChangedHandler = gamepadButtonValueChangedHandler
            
            gamepad.leftShoulder.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.rightShoulder.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.leftTrigger.valueChangedHandler = gamepadButtonValueChangedHandler
            gamepad.rightTrigger.valueChangedHandler = gamepadButtonValueChangedHandler
            
            gamepad.dpad.valueChangedHandler = gamepadDirectionPadValueChangedHandler
            
            gamepad.leftThumbstick.valueChangedHandler = gamepadDirectionPadValueChangedHandler
            gamepad.rightThumbstick.valueChangedHandler = gamepadDirectionPadValueChangedHandler
        }
    }
    
    private func gameControllerPausedHandler(controller: GCController) {
        NSLog("gameControllerPausedHandler(%@)", controller)
        // WARN: handle differently?
    }
    
    private func gamepadMotionChangedHandler(motion: GCMotion) {
        NSLog("gamepadMotionChangedHandler(%@)", motion)
        // WARN: not used
    }
    
    private func gamepadButtonValueChangedHandler(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        NSLog("gamepadButtonValueChangedHandler(%@, %f, %@)", button, value, (pressed ? "true" : "false"))
        
        if let gamepad = gameController?.extendedGamepad {
            switch button {
            case gamepad.buttonA:
                updateKey(.GamePadA, force: MKDFloat(button.value))
                break
            case gamepad.buttonB:
                updateKey(.GamePadB, force: MKDFloat(button.value))
                break
            case gamepad.buttonX:
                updateKey(.GamePadX, force: MKDFloat(button.value))
                break
            case gamepad.buttonY:
                updateKey(.GamePadY, force: MKDFloat(button.value))
                break
            case gamepad.leftShoulder:
                updateKey(.GamePadL1, force: MKDFloat(button.value))
                break
            case gamepad.leftTrigger:
                updateKey(.GamePadL2, force: MKDFloat(button.value))
                break
            case gamepad.rightShoulder:
                updateKey(.GamePadR1, force: MKDFloat(button.value))
                break
            case gamepad.rightTrigger:
                updateKey(.GamePadR2, force: MKDFloat(button.value))
                break
            default: break
            }
        }
    }
    
    private func gamepadDirectionPadValueChangedHandler(dpad: GCControllerDirectionPad, xValue: Float, yValue: Float) {
        NSLog("gamepadDirectionPadValueChangedHandler(%@, {%f, %f})", dpad, xValue, yValue)
        
        if let gamepad = gameController?.extendedGamepad {
            switch dpad {
            case gamepad.dpad:
                updateKey(.GamePadDPadU, force: MKDFloat(dpad.up.value))
                updateKey(.GamePadDPadD, force: MKDFloat(dpad.down.value))
                updateKey(.GamePadDPadL, force: MKDFloat(dpad.left.value))
                updateKey(.GamePadDPadR, force: MKDFloat(dpad.right.value))
                break
            case gamepad.leftThumbstick:
                updateKey(.GamePadLThumbU, force: MKDFloat(dpad.up.value))
                updateKey(.GamePadLThumbD, force: MKDFloat(dpad.down.value))
                updateKey(.GamePadLThumbL, force: MKDFloat(dpad.left.value))
                updateKey(.GamePadLThumbR, force: MKDFloat(dpad.right.value))
                break
            case gamepad.rightThumbstick:
                updateKey(.GamePadRThumbU, force: MKDFloat(dpad.up.value))
                updateKey(.GamePadRThumbD, force: MKDFloat(dpad.down.value))
                updateKey(.GamePadRThumbL, force: MKDFloat(dpad.left.value))
                updateKey(.GamePadRThumbR, force: MKDFloat(dpad.right.value))
                break
            default: break
            }
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   MKDDirectMouseHelperDelegate
    /*****************************************************************************************************/
     
     //#if os(OSX)
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didFindMouseID mouseID: Int32, name: String!, driverName: String!) {
        NSLog("directMouseHelper(%@, didFindMouseID: %d, name: %@, driverName: %@)", helper, mouseID, name, driverName)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetRelativeMotion delta: Int32, axis: MKDDirectMouseAxis, mouseID: Int32) {
        //NSLog("directMouseHelper(%@, didGetRelativeMotion: %d, axis: %d, mouseID: %d)", helper, delta, axis.rawValue, mouseID)
        
        #if os(OSX)
            addMouseDelta(CGPointMake(CGFloat((axis == .X ? -delta : 0)), CGFloat((axis == .Y ? delta : 0))))
        #endif
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetButtonDown buttonID: Int32, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetButtonDown: %d, mouseID: %d)", helper, buttonID, mouseID)
        
        updateKeyCode(UInt16(buttonID), force: 1.0)
    }
    
    public func directMouseHelper(helper: MKDDirectMouseHelper!, didGetButtonUp buttonID: Int32, mouseID: Int32) {
        NSLog("directMouseHelper(%@, didGetButtonUp: %d, mouseID: %d)", helper, buttonID, mouseID)
        
        updateKeyCode(UInt16(buttonID), force: 0.0)
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
    
    //#endif
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    override init() {
        super.init()
        if DIRECT_MOUSE_ENABLED {
            self.directMouseHelper = MKDDirectMouseHelper(delegate: self)
            self.directMouseHelper!.findMice()
        }
        
        // setup gamepad
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controllerDidConnectNotification:", name: GCControllerDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controllerDidDisconnectNotification:", name: GCControllerDidDisconnectNotification, object: nil)
        
        GCController.startWirelessControllerDiscoveryWithCompletionHandler { () -> Void in
            NSLog("startWirelessControllerDiscoveryWithCompletionHandler()")
            
            if GCController.controllers().count > 0 {
                self.gameController = GCController.controllers().first
                NSLog("gameController: %@", self.gameController!)
            }
            else {
                NSLog("No controllers")
            }
        }
    }
}
