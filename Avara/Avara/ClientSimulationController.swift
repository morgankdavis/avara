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
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private         var windowController:           ClientWindowController?
    private(set)    var inputManager:               InputManager
    private(set)    var scene =                     SCNScene()
    private         var map:                        Map?
    private         var localCharacter:             Character?
//    private         var remoteCharacters =          [Character]()
    private         var gameLoopTimer:              NSTimer? // temporary
    private         let flyoverCamera =             FlyoverCamera()
    private         var isFlyoverMode =             false
//    private         var lastUpdateTime =            Double(0)
//    private         var deltaTime =                 Double(0)
    
    
    private         var netClient:                  MKDNetClient?
    private         var sequenceNumber =            UInt32(0)
    
    private         var lastActiveInput:            Set<UserInput>?
    private         var lastMouseDelta:             CGPoint?
    
    private         var inputActive =               false
    private         var serverOverrideUpdate:       NetPlayerUpdate?
    
//    private         var receivedNetPlayerUpdates =  [UInt32:NetPlayerUpdate]() // sequenceNum:update
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        windowController?.showWindow(self)
        switchToCameraNode(localCharacter!.cameraNode)
        
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoop",
            userInfo: nil,
            repeats: true)
        
        netClient?.connect()
    }

    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func gameLoop() {
        gameLoop(1.0/60.0)
    }
    
    internal func inputManagerDidBeginUserInputNotification(note: NSNotification) {
        //NSLog("inputManagerDidBeginUserInputNotification()")
        
        if let inputRawValue = note.userInfo?[InputManager.Notifications.DidBeginUserInput.UserInfoKeys.inputRawValue] as? Int {
            if let input = UserInput(rawValue: UInt8(inputRawValue)) {
                NSLog("Input began: %@", input.description)
                
                switch input {
                case .ToggleFocus:      windowController?.toggleIsCursorCaptured()
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

    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("ClientSimulationController.setup()")
        
        map = Map(scene: scene)
        localCharacter = Character(scene: scene)
        localCharacter!.isRemote = true
        
        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
        flyoverCamera.node.position = SCNVector3(x: 0, y: 0.5, z: 10)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "inputManagerDidBeginUserInputNotification:",
            name: InputManager.Notifications.DidBeginUserInput.name,
            object: nil)
        
        netClient = MKDNetClient(destinationAddress: "127.0.0.1", port: NET_SERVER_PORT, maxChannels: NET_MAX_CHANNELS, delegate: self)
    }
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        if windowController!.isCursorCaptured {
            if let directMouseHelper = inputManager.directMouseHelper {
                directMouseHelper.pump()
            }
        }
        
        if isFlyoverMode {
            flyoverCamera.gameLoopWithInputs(inputManager.activeInputs, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
            windowController?.renderView?.play(self) // why the fuck must we do this?? (force re-render)
        }
        else {
            let activeInput = inputManager.activeInputs
            let mouseDelta = inputManager.readMouseDeltaAndClear()
            
            
            // check for server overrides before applying stuff
            if let u = serverOverrideUpdate {
                NSLog("-- Server override --")
                localCharacter?.applyServerOverrideUpdate(u)
                serverOverrideUpdate = nil
            }
//            else {
                localCharacter?.gameLoopWithInputs(activeInput, mouseDelta: mouseDelta, dT: dT)
                
                let inputChanged = (lastActiveInput == nil) || (lastMouseDelta == nil) || (activeInput != lastActiveInput!) || (mouseDelta != lastMouseDelta!)
                if inputChanged {
                    // send new state to server
                    if let client = netClient {
                        if client.isConnected {
                            NSLog("-- Client sending --")
                            ++sequenceNumber
                            let updateMessage = ClientUpdateNetMessage(activeActions: inputManager.activeInputs, mouseDelta: mouseDelta, sequenceNumber:sequenceNumber)
                            
                            let packtData = updateMessage.encoded()
                            client.sendPacket(packtData, channel: NetChannel.Control.rawValue , flags: .Reliable) // WARN: change to unreliable
                        }
                    }
                    
                    inputActive = (activeInput.count > 0) || (mouseDelta != CGPointZero)
                    NSLog("inputActive: %@", (inputActive ? "true" : "false"))
                }
                
                lastActiveInput = activeInput
                lastMouseDelta = mouseDelta
//            }
        }
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("switchToCameraNode() %@", cameraNode.name!)
        
        windowController?.renderView?.pointOfView = cameraNode
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
    
    private func parseServerPacket(packetData: NSData) {
        //NSLog("ClientSimulationController.parseServerPacket(%@)", packetData)
        
        if let message = MessageFromPayloadData(packetData) {
            switch message.opcode {
                
            case .ServerUpdate:
                let updateMessage = message as! ServerUpdateNetMessage
                
                // TODO: loop through NetPlayerUpdates
                // for one matching our ID, perform reconciliation
                // for others, find their characters and update accordingly
                
                
                // WARN: there is probably a functional operation for this
                var myUpdate: NetPlayerUpdate?
                for u in updateMessage.playerUpdates {
                    if u.id == netClient!.peerID {
                        myUpdate = u
                        break
                    }
                }
                
                if let u = myUpdate {
                    //NSLog("Recv update sq: %d, sent sq: %d, inputActive: %@", u.sequenceNumber, sequenceNumber, (inputActive ? "true" : "false"))
                    if (u.sequenceNumber >= sequenceNumber) && !inputActive {
                        serverOverrideUpdate = u // game loop will see and correct player state
                    }
                    sequenceNumber = u.sequenceNumber
                }
                else {
                    NSLog("*** I can haz update? ***")
                }
                break
                
            default:
                break
            }
        }
        else {
            let opcodeInt = NetMessageOpcodeRawValueFromPayloadData(packetData)
            NSLog("Unknown message opcode: %d", opcodeInt)
        }
    }
    
    /*****************************************************************************************************/
    // MARK:    SCNSceneRendererDelegate
    /*****************************************************************************************************/
    
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
    
    /*****************************************************************************************************/
    // MARK:   SCNPhysicsContactDelegate
    /*****************************************************************************************************/
    
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
    
    /*****************************************************************************************************/
    // MARK:   MKDNetClientDelegate
    /*****************************************************************************************************/
    
    public func client(client: MKDNetClient!, didConnectWithID clientID: UInt32) {
        NSLog("client(%@, didConnectWithID: %d)", client, clientID)
        
        let helloMessage = ClientHelloNetMessage(name: "gatsby")
        let packtData = helloMessage.encoded()
        client.sendPacket(packtData, channel: NetChannel.Control.rawValue , flags: .Reliable)
    }
    
    public func client(client: MKDNetClient!, didFailToConnect error: NSError!) {
        NSLog("client(%@, didFailToConnect: %@)", client, error)
    }
    
    public func clientDidDisconnect(client: MKDNetClient!) {
        NSLog("clientDidDisconnect(%@)")
    }
    
    public func client(client: MKDNetClient!, didRecievePacket packetData: NSData!, channel: UInt8) {
        //NSLog("client(%@, didRecievePacket: %@, channel: %d", self, packetData, channel)
        
        parseServerPacket(packetData)
    }

    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    required public init(inputManager: InputManager) {
        self.inputManager = inputManager
        super.init()
        setup()
        self.windowController = ClientWindowController(clientSimulationController: self)
    }
}
