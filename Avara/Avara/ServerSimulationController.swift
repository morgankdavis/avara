//
//  ServerSimulationController.swift
//  Avara
//
//  Created by Morgan Davis on 6/17/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class ServerSimulationController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, MKDNetServerDelegate {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    //private(set)    var inputManager:               InputManager -- replace with network abstraction
    private(set)    var scene =                     SCNScene()
    private(set)    var gameView:                   GameView? // *** TEMPORARY ***
    private         var map:                        Map?
    //private         var characters =                [Character]()
    private         var clients =                   [UInt32:NetClient]()
    private         var gameLoopTimer:              NSTimer? // temporary
    private         var networkTickTimer:           NSTimer?
    private         var netServer:                  MKDNetServer?
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoop",
            userInfo: nil,
            repeats: true)
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/

    private func setup() {
        NSLog("ServerSimulationController.setup()")
        
        map = Map(scene: scene)

        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
        // *** TEMPORARY ***
        // setup an SCNView to do our server rendering in. This SHOULD DEFINITLY not actually need to be rendered.
        
        gameView = GameView(frame: CGRect(origin: CGPointZero, size: WINDOW_SIZE) as NSRect)
        gameView?.scene = scene
        gameView?.delegate = self
        
        netServer = MKDNetServer(port: UInt16(SERVER_PORT), maxClients: 12, maxChannels: 4, delegate: self)
    }
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        // check for input and move characters
        //localCharacter?.gameLoopWithKeysPressed(inputManager.keysPressed, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginOrUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginOrUpdateContact: %@)", contact)
        
        // WARN: this is stupid. should be taken are of automatically with floor's collisionBitmask
        guard contact.nodeA.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue
            && contact.nodeB.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue else {
                return
        }
        
        // TODO: match node to a client character and update accordingly
//        if let character = localCharacter {
//            if (contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.Character.rawValue) {
//                character.bodyPart(contact.nodeA, mayHaveHitWall:contact.nodeB, withContact:contact)
//            }
//            if (contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.Character.rawValue) {
//                character.bodyPart(contact.nodeB, mayHaveHitWall:contact.nodeA, withContact:contact)
//            }
//        }
    }
    
    private func parseClientPacket(packetData: NSData, clientID: UInt32) {
        NSLog("parseClientPacket(%@, clientID: %d", packetData, clientID)
        
//        let plist = NSPropertyListSerialization.propertyListWithData(
//            packetData,
//            options: Int(NSPropertyListMutabilityOptions.Immutable.rawValue),
//            format: NSPropertyListFormat(0))
//
//        let plist = NSPropertyListSerialization.propertyListWithData(packetData, options: Int(NSPropertyListMutabilityOptions.Immutable.rawValue), format: nil)
    }
    
    /******************************************************************************************************
    MARK:   SCNSceneRendererDelegate
    ******************************************************************************************************/
    
    public func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        NSLog("renderer(updateAtTime:)")
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        NSLog("renderer(didSimulatePhysicsAtTime:)")

//        for character in characters {
//            character.didSimulatePhysicsAtTime(time)
//        }
    }
    
    /******************************************************************************************************
    MARK:   SCNPhysicsContactDelegate
    ******************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didUpdateContact: %@)", contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginContact: %@)", contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didEndContact: %@)", contact)
    }
    
    /******************************************************************************************************
    MARK:   MKDNetServerDelegate
    ******************************************************************************************************/
    
    public func server(server: MKDNetServer!, didConnectClient client: UInt32) {
        NSLog("server(%@, didConnectClient: %d", server)
    }
    
    public func server(server: MKDNetServer!, didDisconnectClient client: UInt32) {
        NSLog("server(%@, didDisconnectClient: %d", server)
    }
    
    public func server(server: MKDNetServer!, didRecievePacket packetData: NSData!, fromClient client: UInt32, channel: UInt8) {
        NSLog("server(%@, didRecievePacket: %@ fromClient: %d channel: %d", server, packetData, channel)
    }

    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    override required public init() {
        super.init()
        setup()
    }
}