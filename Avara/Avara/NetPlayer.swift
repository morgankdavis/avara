//
//  NetPlayer.swift
//  Avara
//
//  Created by Morgan Davis on 7/28/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


public class NetPlayer {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var     lastReceivedSequenceNumber =    UInt32(0) // sequence numbers are unique to each server<->client relationship
    private(set)    var     name:                           String
    private(set)    var     id:                             UInt32
    private(set)    var     character:                      Character
    public          var     lastSentNetPlayerSnapshot:      NetPlayerSnapshot?
    private(set)    var     accumButtonInputs =             [ButtonInput: Double]()
    private(set)    var     accumMouseDelta =               CGPointZero
  
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func addInputs(buttonInputs: [ButtonInput: Double]) {
        for (input, duration) in buttonInputs {
            if let total = accumButtonInputs[input] {
                accumButtonInputs[input] = total + duration
            }
            else {
                accumButtonInputs[input] = duration
            }
        }
    }
    
    public func addMouseDelta(delta: CGPoint) {
        accumMouseDelta = CGPoint(
            x: accumMouseDelta.x + delta.x,
            y: accumMouseDelta.y + delta.y)
    }

    public func readAndClearAccums() -> (buttonInputs: [ButtonInput: Double], mouseDelta: CGPoint, largestDuration: Double) { // last element is largest input time
        // calculate largest input duration
        var largestDuration = Double(0)
        for (_, duration) in accumButtonInputs {
            if duration > largestDuration {
                largestDuration = duration
            }
        }
        
        let retval  = (accumButtonInputs, accumMouseDelta, largestDuration)
        
        accumButtonInputs = [ButtonInput: Double]() // leaves old object intact for retval (instead of removeAll())
        accumMouseDelta = CGPointZero
        
        return retval
    }
    
//    public func calculateTotalsAndClear() -> (userInputs: [UserInput: Float32], mouseDelta: CGPoint, deltaTime: Float) {
//        // returns total time spend holding each key (UserInput),
//        // total mouse delta,
//        // and total delta period for all buffered updates,
//        // then clears the client update buffer
//        
//        var userInputTotals = [UserInput: Float32]()
//        var mouseDeltaTotal = CGPointZero
//        var totalDeltaTime = Float(0)
//        
//        for u in updateNetMessages {
//            // add key down totals
//            let activeInputs = u.activeInputs
//            let deltaTime = u.deltaTime
//            for input in activeInputs {
//                if let existing = userInputTotals[input] {
//                    userInputTotals[input] = existing + deltaTime
//                }
//                else {
//                    userInputTotals[input] = deltaTime
//                }
//            }
//            totalDeltaTime += deltaTime
//            
//            // add mouse delta totals
//            let mouseDelta = u.mouseDelta
//            mouseDeltaTotal.x += mouseDelta.x
//            mouseDeltaTotal.y += mouseDelta.y
//        }
//        
//        updateNetMessages.removeAll()
//        
//        return (userInputTotals, mouseDeltaTotal, totalDeltaTime)
//    }
    
    
    
//    private func readMouseDeltaAndClear() -> CGPoint {
//        let delta = accumulatedMouseDelta
//        accumulatedMouseDelta = CGPointZero
//        return delta
//    }
//    
//    
//    
//    public func addMouseDelta(delta: CGPoint) {
//        accumulatedMouseDelta = CGPoint(
//            x: accumulatedMouseDelta.x + delta.x,
//            y: accumulatedMouseDelta.y + delta.y)
//    }
    
    
    
//    public func netPlayerSnapshot() -> NetPlayerSnapshot {
//        if var lastSentSq = lastSentNetPlayerSnapshot?.sequenceNumber {
//            return NetPlayerSnapshot(
//                sequenceNumber: ++lastSentSq,
//                id: id,
//                position: character.bodyNode.position,
//                bodyRotation: character.bodyNode.rotation,
//                headEulerAngles: character.headNode!.eulerAngles)
//        }
//        else {
//            return NetPlayerSnapshot(
//                sequenceNumber: ++lastReceivedSequenceNumber,
//                id: id,
//                position: character.bodyNode.position,
//                bodyRotation: character.bodyNode.rotation,
//                headEulerAngles: character.headNode!.eulerAngles)
//        }
//    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    public required init(id: UInt32, name: String, character: Character) {
        self.id = id
        self.name = name
        self.character = character
    }
}
