//
//  ClientSimulationController.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 goosesensor. All rights reserved.
//

import Foundation
import SceneKit


public class ClientSimulationController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private         var gameWindowController:       GameWindowController?
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
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        gameWindowController?.showWindow(self)
        switchToCameraNode(localCharacter!.cameraNode)
        
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoop",
            userInfo: nil,
            repeats: true)
    }
    
    /******************************************************************************************************
    MARK:   Internal
    ******************************************************************************************************/
    
    internal func gameLoop() {
        gameLoop(1.0/60.0)
    }
    
    internal func inputManagerDidPressKeyNotification(note: NSNotification) {
        //NSLog("inputManagerDidPressKeyNotification()")
        
        if let keyCode = note.userInfo?[InputManager.Notifications.DidPressKey.UserInfoKeys.keyCode] as? Int {
            if let key = Key(rawValue: keyCode) {
                NSLog("Key pressed: %@", key.description)
                
                switch key {
                case .NumPad0:                  switchToCameraNode(flyoverCamera.node)
                case .NumPad1, .One:            switchToCameraNode(localCharacter!.cameraNode)
                case .NumPadClear, .Tilda:      gameWindowController?.toggleIsCursorCaptured()
                case .NumPadStar, .Equal:       toggleFlyoverMode()
                case .W, .A, .S, .D, .Space:    break // game loop will see this
                default: break
                }
            }
        }
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        if isFlyoverMode {
            flyoverCamera.gameLoopWithKeysPressed(inputManager.keysPressed, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
            gameWindowController?.gameView?.play(self) // why the fuck must we do this?? (force re-render)
        } else {
            localCharacter?.gameLoopWithKeysPressed(inputManager.keysPressed, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
        }
    }
    
    private func setup() {
        NSLog("ClientSimulationController.setup()")
        
        map = Map(scene: scene)
        localCharacter = Character(scene: scene)
        
        scene.physicsWorld.timeStep = 1.0/120.0
        scene.physicsWorld.contactDelegate = self
        
        flyoverCamera.node.position = SCNVector3(x: 0, y: 0.5, z: 10)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "inputManagerDidPressKeyNotification:",
            name: InputManager.Notifications.DidPressKey.name,
            object: nil)
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("switchToCameraNode() %@", cameraNode.name!)
        
        gameWindowController?.gameView?.pointOfView = cameraNode
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
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginContact: %@)", contact)
        
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
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didEndContact: %@)", contact)
    }
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    required public init(inputManager: InputManager) {
        self.inputManager = inputManager
        super.init()
        setup()
        self.gameWindowController = GameWindowController(clientSimulationController: self)
    }
}
