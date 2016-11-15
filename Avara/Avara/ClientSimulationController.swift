//
//  ClientSimulationController.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


func sync_obj(lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}


public class ClientSimulationController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, MKDNetClientDelegate {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    #if os(OSX)
    public          var windowController:                   ClientWindowController?
    #else
    public          var viewController:                     ViewController?
    #endif
    private(set)    var inputManager:                       InputManager
    private(set)    var scene =                             SCNScene()
    private         var map:                                Map?
    private         var character:                          Character?
    private         let flyoverCamera =                     FlyoverCamera()
    private         var isFlyoverMode =                     false
    
    private         var netClient:                          MKDNetClient?
    private         var sequenceNumber =                    UInt32(0)
    
    private         var netServerOverrideSnapshot:          NetPlayerSnapshot?
    
    private         var clientAccumButtonEntries =          [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
    private         let clientAccumButtonEntriesLockQueue = dispatch_queue_create("com.morgankdavis.clientAccumButtonEntriesLockQueue", nil)
    private         var clientLastSentHullEulerAngles =     SCNVector3Zero
    private         var clientTickTimer:                    NSTimer?
    //private         var sentNoInputPacket =                 false

    private         var magicSphereOfPower:                 SCNNode?
    private         var lastRenderTime:                     Double?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func play() {
        NSLog("play()")
        
        //windowController?.showWindow(self)
        switchToCameraNode(character!.cameraNode)
        
        netClient?.connect()
        startClientTickTimer()
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func inputManagerDidStartPressingButtonNotification(note: NSNotification) {
        //NSLog("inputManagerDidStartPressingButtonNotification(%@)", note)
        
        if let buttonRawValue = note.userInfo?[InputManager.Notifications.DidStartPressingButton.UserInfoKeys.buttonRawValue] as? Int {
            if let button = ButtonInput(rawValue: UInt8(buttonRawValue)) {
                NSLog("Button down: %@", button.description)
                
                switch button {
                case .ToggleFocus:
                    #if os(OSX)
                        windowController?.toggleIsCursorCaptured()
                    #else
                        break
                    #endif
                case .ToggleFlyover:    toggleFlyoverMode()
                case .HeadCamera:       switchToCameraNode(character!.cameraNode)
                case .FlyoverCamera:    switchToCameraNode(flyoverCamera.node)
                case .Fire:             character?.shoot()
                default: break
                }
            }
        }
    }
    
    internal func clientTickTimer(timer: NSTimer) {
        //NSLog("clientTickTimer()")
        
        if let client = netClient {
            if client.isConnected {
                
                let hullEulerAngles = SCNVector3Make(
                    character!.hullOuterNode!.eulerAngles.x,
                    character!.hullOuterNode!.eulerAngles.y,
                    character!.hullInnerNode!.eulerAngles.z)
                
                dispatch_sync(clientAccumButtonEntriesLockQueue) {
                    let newInput = (self.clientAccumButtonEntries.count > 0)
                        || (hullEulerAngles.x != self.clientLastSentHullEulerAngles.x)
                        || (hullEulerAngles.y != self.clientLastSentHullEulerAngles.y)
                        || (hullEulerAngles.z != self.clientLastSentHullEulerAngles.z)
                    if newInput {
                        //NSLog("-- CLIENT SENDING HIGH --")
                        
                        ++self.sequenceNumber
                        let updateMessage = ClientUpdateNetMessage(
                            buttonEntries: self.clientAccumButtonEntries,
                            hullEulerAngles: hullEulerAngles,
                            sequenceNumber: self.sequenceNumber)
                        
                        let packtData = updateMessage.encoded()
                        client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue , flags: .Unsequenced, duplicate: NET_CLIENT_PACKET_DUP)
                        
                        // reset accumulator/last sent hull angles
                        self.clientAccumButtonEntries = [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
                        self.clientLastSentHullEulerAngles = hullEulerAngles
                        
                        //sentNoInputPacket = false
                    }
                    else { // no input
//                        if !sentNoInputPacket {
//                            // send a single packet indicating there is no new input
//                            
//                            //NSLog("-- CLIENT SENDING LOW --")
//                            
//                            ++sequenceNumber
//                            let updateMessage = ClientUpdateNetMessage(
//                                buttonEntries: clientAccumButtonEntries,
//                                hullEulerAngles: hullEulerAngles,
//                                sequenceNumber: sequenceNumber)
//                            
//                            let packtData = updateMessage.encoded()
//                            client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue , flags: .Unsequenced, duplicate: NET_CLIENT_PACKET_DUP)
//                            
//                            sentNoInputPacket = true
//                        }
//                        else {
//                            //NSLog("-- CLIENT SKIPPING --")
//                        }
                    }
                } // lock
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
        
        // this is a hack to keep the render loop running
        // unless the render loop "changes" something in the physics sim each iteration, the loop will eventually stop
        magicSphereOfPower = SCNNode(geometry: SCNSphere(radius: 1e-5))
        magicSphereOfPower?.position = SCNVector3Make(0, -100, 0)
        magicSphereOfPower?.name = "MAGIC SPHERE OF POWER"
        scene.rootNode.addChildNode(magicSphereOfPower!)
        magicSphereOfPower?.physicsBody = SCNPhysicsBody.dynamicBody()
        magicSphereOfPower?.physicsBody?.velocityFactor = SCNVector3Zero
        magicSphereOfPower?.physicsBody?.affectedByGravity = false
        
        character = Character(scene: scene)
        
        scene.physicsWorld.timeStep = NSTimeInterval(MKDFloat(1.0)/PHYSICS_TIMESTEP)
        scene.physicsWorld.contactDelegate = self
        
        flyoverCamera.node.position = SCNVector3(x: 0, y: 0.5, z: 10)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "inputManagerDidStartPressingButtonNotification:",
            name: InputManager.Notifications.DidStartPressingButton.name,
            object: nil)
        
        netClient = MKDNetClient(destinationAddress: "127.0.0.1", port: NET_SERVER_PORT, maxChannels: NET_MAX_CHANNELS, delegate: self)
    }
    
    private func gameLoop(dT: MKDFloat) {
        //NSLog("gameLoop: %f", dT)
        
        // hack to keep loop running. see setup()
        magicSphereOfPower!.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: 0), impulse: true)
        
        // pump direct input handler
        #if os(OSX)
            if windowController!.isCursorCaptured {
                if let directMouseHelper = inputManager.directMouseHelper {
                    dispatch_async(dispatch_get_main_queue(),{
                        directMouseHelper.pump()
                    })
                }
            }
        #endif
        
        // put the buttons into a format Character/Flyovercamera like
        let pressedButtons = inputManager.pressedButtons
        var buttonEntries = [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)]()
        var buttons = [(button: ButtonInput, force: MKDFloat)]()
        var buttonDown = false
        for (button, force) in pressedButtons {
            buttons.append((button, force))
            buttonDown = true
        }
        buttonEntries.append((buttons, MKDFloat(dT)))
        
        // get look delta
        var lookDelta = CGPointZero
        #if os(OSX)
            lookDelta = inputManager.readMouseDeltaAndClear()
        #endif
        if let fY = pressedButtons[.LookUp] {
            if THUMBLOOK_INVERSION_ENABLED {
                lookDelta.y = CGFloat(fY)
            }
            else {
                lookDelta.y = -CGFloat(fY)
            }
        }
        if let fY = pressedButtons[.LookDown] {
            if THUMBLOOK_INVERSION_ENABLED {
                lookDelta.y = -CGFloat(fY)
            }
            else {
                lookDelta.y = CGFloat(fY)
            }
        }
        if let fX = pressedButtons[.LookLeft] {
            lookDelta.x = CGFloat(fX)
        }
        if let fX = pressedButtons[.LookRight] {
            lookDelta.x = -CGFloat(fX)
        }
        
        // handle flyover or player movement
        if isFlyoverMode {
            flyoverCamera.updateForInputs(pressedButtons, dT: dT, lookDelta: lookDelta)
            windowController?.renderView?.play(self) // why the fuck must we do this?? (force re-render)
        }
        else {
            if NET_CLIENT_RECONCILIATION_ENABLED {
                // check for server override before applying local input
                if let override = netServerOverrideSnapshot {
                    NSLog("* SERVER OVERRIDE *")
                    
                    character?.applyServerOverrideSnapshot(override)
                    netServerOverrideSnapshot = nil
                }
            }
            
            // add to net client output accumulator
            if buttonDown {
                dispatch_sync(clientAccumButtonEntriesLockQueue) {
                    self.clientAccumButtonEntries.append((buttons, MKDFloat(dT)))
                }
            }
            
            // IMPORTANT! initialPosition has to be set BEFORE any translation in each loop invocation
            let initialPosition = character?.bodyNode.position
            character?.updateForInputs(buttonEntries, lookDelta: lookDelta)
            character?.updateForLoopDelta(dT, initialPosition: initialPosition!)
        }
        
        
//        if inputManager.pressedButtons.keys.contains(.Fire) {
//            character?.shoot()
//        }
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("switchToCameraNode() %@", cameraNode.name!)
        
        #if os(OSX)
            windowController?.renderView?.pointOfView = cameraNode
        #else
            viewController?.clientRenderView?.pointOfView = cameraNode
        #endif
        
        if cameraNode != flyoverCamera.node {
            isFlyoverMode = false
        }
    }
    
    func toggleFlyoverMode() {
        if isFlyoverMode {
            isFlyoverMode = false
        }
        else {
            isFlyoverMode = true
            switchToCameraNode(flyoverCamera.node)
        }
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginOrUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginOrUpdateContact: %@)", contact)
        
        if COLLISION_DETECTION_ENABLED {
            // WARN: this is stupid. should be taken are of automatically with floor's collisionBitmask
            guard contact.nodeA.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue
                && contact.nodeB.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue else {
                    return
            }
            
            if let character = character {
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
                
                // WARN: there is probably a functional operation for this
                var mySnapshot: NetPlayerSnapshot?
                for u in updateMessage.playerSnapshots {
                    if u.id == netClient!.peerID {
                        mySnapshot = u
                        break
                    }
                }
                
                if let s = mySnapshot {
                    //NSLog("Server update message with sq: %d, prev sent sq: %d", s.sequenceNumber, sequenceNumber)
                    //if (s.sequenceNumber > sequenceNumber) && sentNoInputPacket {
                    if s.sequenceNumber > sequenceNumber+1 { // server incraments before return, so we look for one further
                        netServerOverrideSnapshot = s // game loop will see and correct player state
                    }
                    sequenceNumber = s.sequenceNumber
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
        //NSLog("renderer(%@, updateAtTime: %f)", renderer.description, time)
        
        if let lastTime = self.lastRenderTime {
            lastRenderTime = time
            
            let dT = MKDFloat(time - lastTime)
            
            //dispatch_async(dispatch_get_main_queue(),{
                self.gameLoop(dT)
            //})
        }
        else {
            lastRenderTime = time
        }
    }
    
    public func renderer(renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: NSTimeInterval) {
        //NSLog("renderer(%@, didApplyAnimationsAtTime: %f)", renderer.description, time)
    }
    
    public func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //NSLog("renderer(%@, didSimulatePhysicsAtTime: %f)", renderer.description, time)
        
//        if let lastTime = self.lastRenderTime {
//            lastRenderTime = time
//            
//            let dT = MKDFloat(time - lastTime)
//            
//            //dispatch_async(dispatch_get_main_queue(),{
//                self.gameLoop(dT)
//            //})
//        }
//        else {
//            lastRenderTime = time
//        }
        
        //dispatch_async(dispatch_get_main_queue(),{
            if let character = self.character {
                character.didSimulatePhysicsAtTime(time)
            }
        //})
    }
    
    public func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //NSLog("renderer(%@, willRenderScene: %@, scene: %@, atTime: %f)", renderer.description, scene, time)
        
        //character?.crosshairRNode?.rotation = SCNVector4Make(1, 1, 0, CGFloat(M_PI/3.0))
    }
    
    public func renderer(renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //NSLog("renderer(%@, didRenderScene: %@, atTime: %f)", renderer.description, scene, time)
    }
    
    /*****************************************************************************************************/
    // MARK:   SCNPhysicsContactDelegate
    /*****************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(%@, didUpdateContact: %@)", world, contact)
        
        //dispatch_async(dispatch_get_main_queue(),{
            self.physicsWorld(world, didBeginOrUpdateContact: contact)
        //})
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(%@, didBeginContact: %@)", world, contact)
        
        //dispatch_async(dispatch_get_main_queue(),{
            self.physicsWorld(world, didBeginOrUpdateContact: contact)
        //})
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
        client.sendPacket(packtData, channel: NetChannel.Signaling.rawValue, flags: .Reliable, duplicate: 0)
        
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
        //self.windowController = ClientWindowController(clientSimulationController: self)
    }
}
