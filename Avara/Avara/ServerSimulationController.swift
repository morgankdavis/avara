//
//  ServerSimulationController.swift
//  Avara
//
//  Created by Morgan Davis on 6/17/15.
//  Copyright (c) 2015 goosesensor. All rights reserved.
//

import Foundation
import SceneKit


public class ServerSimulationController: NSObject, SCNPhysicsContactDelegate {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    //private(set)    var inputManager:               InputManager -- replace with network abstraction
    private(set)    var scene =                     SCNScene()
    private         var map:                        Map?
    private         var remoteCharacters =          [Character]()
    private         var gameLoopTimer:              NSTimer? // temporary

    /******************************************************************************************************
    MARK:   SCNPhysicsContactDelegate
    ******************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didUpdateContact: %@)", contact)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginContact: %@)", contact)
        
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didEndContact: %@)", contact)
    }
}