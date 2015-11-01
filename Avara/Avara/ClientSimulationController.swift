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
    private         var gameLoopTimer:              NSTimer? // temporary
    private         let flyoverCamera =             FlyoverCamera()
    private         var isFlyoverMode =             false
    
    private         var netClient:                  MKDNetClient?
    private         var sequenceNumber =            UInt32(0)
    
    private         var lastActiveInput:            Set<ButtonInput>?
    private         var lastMouseDelta:             CGPoint?
    
    private         var serverOverrideSnapshot:     NetPlayerSnapshot?
    
    private         var clientAccumButtonInputs =   [ButtonInput: Double]()
    private         var clientAccumMouseDelta =     CGPointZero
    private         var clientTickTimer:            NSTimer?
    private         var sentNoInputPacket =         false
    
    private         var lastLoopDate:               Double?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        windowController?.showWindow(self)
        switchToCameraNode(localCharacter!.cameraNode)
        
        //lastLoopDate = NSDate.timeIntervalSinceReferenceDate()
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoopTimer:",
            userInfo: nil,
            repeats: true)
        
        netClient?.connect()
        startClientTickTimer()
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func gameLoopTimer(timer: NSTimer) {
        gameLoop()
    }
    
    internal func inputManagerDidBeginUserInputNotification(note: NSNotification) {
        //NSLog("inputManagerDidBeginUserInputNotification()")
        
        if let inputRawValue = note.userInfo?[InputManager.Notifications.DidBeginButtonInput.UserInfoKeys.inputRawValue] as? Int {
            if let input = ButtonInput(rawValue: UInt8(inputRawValue)) {
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
    
    internal func clientTickTimer(timer: NSTimer) {
        //NSLog("clientTickTimer()")
        
        if let client = netClient {
            if client.isConnected {
                
                let newInput = clientAccumButtonInputs.count > 0 || abs(clientAccumMouseDelta.x) > 0 || abs(clientAccumMouseDelta.y) > 0
                if newInput {
                    //NSLog("-- CLIENT SENDING HIGH --")
                    
                    ++sequenceNumber
                    let updateMessage = ClientUpdateNetMessage(
                        buttonInputs: clientAccumButtonInputs,
                        mouseDelta: clientAccumMouseDelta,
                        sequenceNumber: sequenceNumber)
   
                    let packtData = updateMessage.encoded()
                    client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue , flags: .Reliable) // WARN: change to unreliable
                    
                    // reset accumulators
                    clientAccumButtonInputs = [ButtonInput: Double]()
                    clientAccumMouseDelta = CGPointZero
                    
                    sentNoInputPacket = false
                }
                else { // no input
                    if !sentNoInputPacket {
                        // send a single packet indicating there is no new input
                        
                        //NSLog("-- CLIENT SENDING LOW --")
                        
                        ++sequenceNumber
                        let updateMessage = ClientUpdateNetMessage(
                            buttonInputs: clientAccumButtonInputs,
                            mouseDelta: clientAccumMouseDelta,
                            sequenceNumber: sequenceNumber)
                        
                        let packtData = updateMessage.encoded()
                        client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue , flags: .Reliable) // WARN: change to unreliable
                        
                        sentNoInputPacket = true
                    }
                    else {
                        //NSLog("-- CLIENT SKIPPING --")
                    }
                }
            }
            
            //client.pump()
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("ClientSimulationController.setup()")
        
        map = Map(scene: scene)
        localCharacter = Character(scene: scene)
        //localCharacter!.isRemote = true
        
        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
        flyoverCamera.node.position = SCNVector3(x: 0, y: 0.5, z: 10)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "inputManagerDidBeginUserInputNotification:",
            name: InputManager.Notifications.DidBeginButtonInput.name,
            object: nil)
        
        netClient = MKDNetClient(destinationAddress: "127.0.0.1", port: NET_SERVER_PORT, maxChannels: NET_MAX_CHANNELS, delegate: self)
    }
    
    private func gameLoop() {
        let nowDate = NSDate.timeIntervalSinceReferenceDate()
        
        if let lastDate = lastLoopDate {
            
            let dT = CGFloat(nowDate - lastDate)
            //NSLog("computed dT: %f", dT)
            //dT = 1.0/60.0
            
            // pump direct input handler
            if windowController!.isCursorCaptured {
                if let directMouseHelper = inputManager.directMouseHelper {
                    directMouseHelper.pump()
                }
            }
            
//            // pump net socket client
//            if let client = netClient {
//                client.pump()
//            }
            
            // handle flyover or player movement
            if isFlyoverMode {
                flyoverCamera.gameLoopWithInputs(inputManager.activeButtonInputs, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
                windowController?.renderView?.play(self) // why the fuck must we do this?? (force re-render)
            }
            else {
                let activeButtonInput = inputManager.activeButtonInputs
                let mouseDelta = inputManager.readMouseDeltaAndClear()
                
                // add input to the net client input accumulator
                for input in activeButtonInput {
                    if let total = clientAccumButtonInputs[input] {
                        clientAccumButtonInputs[input] = total + Double(dT)
                    }
                    else {
                        clientAccumButtonInputs[input] = Double(dT)
                    }
                }
                clientAccumMouseDelta = CGPoint(x: clientAccumMouseDelta.x + mouseDelta.x, y: clientAccumMouseDelta.y + mouseDelta.y)
                
                if NET_CLIENT_RECONCILIATION_ENABLED {
                    // check for server override before applying local input
                    if let override = serverOverrideSnapshot {
                        NSLog("** SERVER OVERRIDE **")
                        
                        localCharacter?.applyServerOverrideSnapshot(override)
                        serverOverrideSnapshot = nil
                    }
                }

                // IMPORTANT! initialPosition has to be set BEFORE any translation in each loop invocation
                let initialPosition = localCharacter?.bodyNode.position
                localCharacter?.updateForInputs(activeButtonInput, mouseDelta: mouseDelta, dT: dT)
                localCharacter?.updateForLoopDelta(dT, initialPosition: initialPosition!)
            }
        }
        
        lastLoopDate = nowDate
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
        
        if (COLLISION_DETECTION_ENABLED) {
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
    }
    
    private func serverPacketReceived(packetData: NSData) {
        //NSLog("ClientSimulationController.serverPacketReceived(%@)", packetData)
        
        if let message = MessageFromPayloadData(packetData) {
            switch message.opcode {
                
            case .ServerUpdate:
                let updateMessage = message as! ServerUpdateNetMessage
                
                // TODO: loop through NetPlayerSnapshots
                // for one matching our ID, perform reconciliation
                // for others, find their characters and update accordingly
                
                
                // WARN: there is probably a functional operation for this
                var mySnapshot: NetPlayerSnapshot?
                for u in updateMessage.playerSnapshots {
                    if u.id == netClient!.peerID {
                        mySnapshot = u
                        break
                    }
                }
                
                if let u = mySnapshot {
                    //NSLog("Server update message with sq: %d, prev sent sq: %d", u.sequenceNumber, sequenceNumber)s
                    if (u.sequenceNumber > sequenceNumber) && sentNoInputPacket {
                        serverOverrideSnapshot = u // game loop will see and correct player state
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
    
    private func startClientTickTimer() {
        NSLog("startClientTickTimer()")
        
        clientTickTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/NSTimeInterval(NET_CLIENT_TICK_RATE),
            target: self,
            selector: "clientTickTimer:",
            userInfo: nil,
            repeats: true)
    }
    
    /*****************************************************************************************************/
    // MARK:    SCNSceneRendererDelegate
    /*****************************************************************************************************/
    
    public func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //NSLog("renderer(%@, updateAtTime: %f)", renderer, time)
    }
    
    public func renderer(renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //NSLog("renderer(didRenderScene: %@, atTime: %f)", scene, time)
    }
    
    public func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //        NSLog("renderer(%@, didSimulatePhysicsAtTime: %f)", renderer, time)
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
        //NSLog("physicsWorld(%@, didUpdateContact: %@)", world, contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(%@, didBeginContact: %@)", world, contact)
        
        physicsWorld(world, didBeginOrUpdateContact: contact)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(%@, didEndContact: %@)", world, contact)
    }
    
    /*****************************************************************************************************/
    // MARK:   MKDNetClientDelegate
    /*****************************************************************************************************/
    
    public func client(client: MKDNetClient!, didConnectWithID clientID: UInt32) {
        NSLog("client(%@, didConnectWithID: %d)", client, clientID)
        
        let helloMessage = ClientHelloNetMessage(name: "gatsby")
        let packtData = helloMessage.encoded()
        client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue , flags: .Reliable)
        
        // WARN: Wait for game start message in future (or whatever)
        //startClientTickTimer()
    }
    
    public func client(client: MKDNetClient!, didFailToConnect error: NSError!) {
        NSLog("client(%@, didFailToConnect: %@)", client, error)
    }
    
    public func clientDidDisconnect(client: MKDNetClient!) {
        NSLog("clientDidDisconnect(%@)")
    }
    
    public func client(client: MKDNetClient!, didRecievePacket packetData: NSData!, channel: UInt8) {
        //NSLog("client(%@, didRecievePacket: %@, channel: %d", self, packetData, channel)
        
        serverPacketReceived(packetData)
    }
    
    public func client(client: MKDNetClient!, didUpdateUploadRate bytesUpPerSec: UInt, downloadRate bytesDownPerSec: UInt) {
        //NSLog("NET RATE: %.2fKB/sec up, %.2fKB/sec down", Double(bytesUpPerSec)/1024.0, Double(bytesDownPerSec)/1024.0)
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
