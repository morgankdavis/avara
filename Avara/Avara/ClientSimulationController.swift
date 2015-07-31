//
//  ClientSimulationController.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class ClientSimulationController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, MKDNetClientDelegate {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private         var clientWindowController:     ClientWindowController?
    private(set)    var inputManager:               InputManager
    private(set)    var scene =                     SCNScene()
    private         var map:                        Map?
    private         var localCharacter:             Character?
    private         var remoteCharacters =          [Character]()
    private         var gameLoopTimer:              NSTimer? // temporary
    private         let flyoverCamera =             FlyoverCamera()
    private         var isFlyoverMode =             false
//    private         var lastUpdateTime =            Double(0)
//    private         var deltaTime =                 Double(0)
    private         var netClient:                  MKDNetClient?
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        clientWindowController?.showWindow(self)
        switchToCameraNode(localCharacter!.cameraNode)
        
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoop",
            userInfo: nil,
            repeats: true)
        
        netClient?.connect()
    }
    
    /******************************************************************************************************
    MARK:   Internal
    ******************************************************************************************************/
    
    internal func gameLoop() {
        gameLoop(1.0/60.0)
    }
    
    internal func inputManagerDidBeginInputActionNotification(note: NSNotification) {
        //NSLog("inputManagerDidBeginInputActionNotification()")
        
        if let actionRawValue = note.userInfo?[InputManager.Notifications.DidBeginInputAction.UserInfoKeys.actionRawValue] as? Int {
            if let action = InputAction(rawValue: UInt8(actionRawValue)) {
                NSLog("Action began: %@", action.description)
                
                switch action {
                case .ToggleFocus:      clientWindowController?.toggleIsCursorCaptured()
                case .ToggleFlyover:    toggleFlyoverMode()
                case .HeadCamera:       switchToCameraNode(localCharacter!.cameraNode)
                case .FlyoverCamera:    switchToCameraNode(flyoverCamera.node)
                case .MoveForward, .MoveBackward, .TurnLeft, .TurnRight:
                    break // game loop will process
                default: break
                }
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func setup() {
        NSLog("ClientSimulationController.setup()")
        
        map = Map(scene: scene)
        localCharacter = Character(scene: scene)
        
        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
        flyoverCamera.node.position = SCNVector3(x: 0, y: 0.5, z: 10)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "inputManagerDidBeginInputActionNotification:",
            name: InputManager.Notifications.DidBeginInputAction.name,
            object: nil)
        
        netClient = MKDNetClient(destinationAddress: "127.0.0.1", port: NET_SERVER_PORT, maxChannels: NET_MAX_CHANNELS, delegate: self)
    }
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        if isFlyoverMode {
            flyoverCamera.gameLoopWithActions(inputManager.activeActions, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
            clientWindowController?.renderView?.play(self) // why the fuck must we do this?? (force re-render)
        }
        else {
            localCharacter?.gameLoopWithActions(inputManager.activeActions, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
        }
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("switchToCameraNode() %@", cameraNode.name!)
        
        clientWindowController?.renderView?.pointOfView = cameraNode
        if cameraNode != flyoverCamera.node {
            isFlyoverMode = false
        }
    }
    
    func toggleFlyoverMode() {
        if (isFlyoverMode) {
            isFlyoverMode = false
        }
        else {
            isFlyoverMode = true
            switchToCameraNode(flyoverCamera.node)
        }
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginOrUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginOrUpdateContact: %@)", contact)
        
        // WARN: this is stupid. should be taken are of automatically with floor's collisionBitmask
        guard contact.nodeA.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue
            && contact.nodeB.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue else {
                return
        }
        
        if let character = localCharacter {
            if (contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.Character.rawValue) {
                character.bodyPart(contact.nodeA, mayHaveHitWall:contact.nodeB, withContact:contact)
            }
            if (contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.Character.rawValue) {
                character.bodyPart(contact.nodeB, mayHaveHitWall:contact.nodeA, withContact:contact)
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   SCNSceneRendererDelegate
    ******************************************************************************************************/
    
    public func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
//        NSLog("renderer(updateAtTime:)")
    }

    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
//        NSLog("renderer(didSimulatePhysicsAtTime:)")
//        
//        deltaTime = time - lastUpdateTime
//        lastUpdateTime = time
//        
//        gameLoop(CGFloat(deltaTime))
        
        if let character = localCharacter {
            character.didSimulatePhysicsAtTime(time)
        }
    }
    
    /******************************************************************************************************
    MARK:   SCNPhysicsContactDelegate
    ******************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didUpdateContact: %@)", contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact);
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginContact: %@)", contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact);
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didEndContact: %@)", contact)
    }
    
    /******************************************************************************************************
    MARK:   MKDNetClientDelegate
    ******************************************************************************************************/
    
    public func clientDidConnect(client: MKDNetClient!) {
        NSLog("clientDidConnect(%@)", client)
        
        let hellMessage = ClientHelloNetMessage(name: "gatsby")
        let packtData = hellMessage.encodedWithSequenceNumber(4)
        netClient?.sendPacket(packtData, channel: NetChannel.Control.rawValue , flags: .Reliable)
    }
    
    public func client(client: MKDNetClient!, didFailToConnect error: NSError!) {
        NSLog("client(%@, didFailToConnect: %@)", client, error)
    }
    
    public func clientDidDisconnect(client: MKDNetClient!) {
        NSLog("clientDidDisconnect(%@)")
    }
    
    public func client(client: MKDNetClient!, didRecievePacket packetData: NSData!, channel: UInt8) {
        NSLog("client(%@, didRecievePacket: %@, channel: %d", channel)
    }

    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    required public init(inputManager: InputManager) {
        self.inputManager = inputManager
        super.init()
        setup()
        self.clientWindowController = ClientWindowController(clientSimulationController: self)
    }
}
