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
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private         var renderer:                       SCNRenderer?
    private         var renderTimer:                    NSTimer?
    
    #if os(OSX)
    public          var windowController:               ServerWindowController?
    #else
    public          var viewController:                 ViewController?
    #endif
    private(set)    var scene =                         SCNScene()
    private         var map:                            Map?
    private         var netPlayers =                    [UInt32:NetPlayer]()            // id:player
    private         var netServer:                      MKDNetServer?
    private         var cameraNode =                    SCNNode()
    
    private         var serverTickTimer:                NSTimer?
    private         var serverSentNoChangePacket =      [UInt32:Bool]()                 // id:sent
    
    private         var magicSphereOfPower:             SCNNode?
    private         var lastRenderTime:                 Double?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func start() {
        NSLog("ServerSimulationController.start()")
        
        //windowController?.showWindow(self)
        
        switchToCameraNode(cameraNode)
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func serverTickTimer(timer: NSTimer) {
        //NSLog("serverTickTimer()")
        
        // broadcast state to all clients
        
        var snapshotsToSend = [NetPlayerSnapshot]()
        for (id, player) in netPlayers {
            //NSLog("-- PLAYER ID %d --", id)
            
            // make a snapshot for each player
            // if that snapshot is different from player.lastSentPlayerSnapshot, add it to the list to send
            
            // pack up inner&outer hull angles
            let hullAngles = SCNVector3Make(
                player.character.hullOuterNode!.eulerAngles.x,
                player.character.hullOuterNode!.eulerAngles.y,
                player.character.hullInnerNode!.eulerAngles.z)
            let snapshot = NetPlayerSnapshot(
                sequenceNumber: player.lastReceivedSequenceNumber+1,
                id: id,
                position: player.character.bodyNode.position,
                bodyRotation: player.character.bodyNode.rotation,
                hullEulerAngles: hullAngles) // WARN: change to "hull" + add roll
            
            if snapshot != player.lastSentNetPlayerSnapshot {
                //NSLog("-- SERVER SENDING --")
                snapshotsToSend.append(snapshot)
                player.lastSentNetPlayerSnapshot = snapshot
                player.lastReceivedSequenceNumber++
                
                serverSentNoChangePacket[id] = false
            }
            else {
                if serverSentNoChangePacket[id] == nil || serverSentNoChangePacket[id] == false {
                    // send a single packet indicating there is no new input
                    
                    //NSLog("-- SERVER SENDING DUPLICATE --")
                    
                    snapshotsToSend.append(snapshot)
                    player.lastSentNetPlayerSnapshot = snapshot
                    player.lastReceivedSequenceNumber++
                    
                    serverSentNoChangePacket[id] = true
                }
                else {
                    //NSLog("-- SERVER SKIPPING --")
                }
            }
            
            if snapshotsToSend.count > 0 {
                let updateMessage = ServerUpdateNetMessage(playerSnapshots: snapshotsToSend)
                let packtData = updateMessage.encoded()
                if let server = netServer {
                    server.broadcastPacket(packtData, channel: NetChannel.Signaling.rawValue, flags: .Unsequenced, duplicate: NET_SERVER_PACKET_DUP)
                }
            }
        }
        
//        if let server = netServer {
//            server.pump()
//        }
    }
    
    internal func renderTimer(timer: NSTimer) {
        //NSLog("renderTimer()")
        
        scene.paused = false
        
        let time: CFTimeInterval = CACurrentMediaTime()
        renderer?.renderAtTime(time)
        renderer(renderer!, updateAtTime: time)
        //scene.physicsWorld.updateCollisionPairs()
    }

    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("ServerSimulationController.setup()")
        
        if !SERVER_VIEW_ENABLED {
            renderer?.scene = scene
            renderTimer = NSTimer.scheduledTimerWithTimeInterval(
                1.0/NSTimeInterval(60.0),
                target: self,
                selector: "renderTimer:",
                userInfo: nil,
                repeats: true)
        }
        
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
        
        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
        let camera = SCNCamera()
        ConfigureCamera(camera, screenSize: SERVER_WINDOW_SIZE, fov: 95.0)
        camera.zNear = 0.01
        camera.zFar = 1000.0
        cameraNode.camera = camera
        cameraNode.name = "Server camera node"
        cameraNode.position = SCNVector3(x: 0, y: 15, z: 0)
        cameraNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -MKDFloat(M_PI)/2.0)
        scene.rootNode.addChildNode(cameraNode)
        
        netServer = MKDNetServer(port: NET_SERVER_PORT, maxClients: NET_MAX_CLIENTS, maxChannels: NET_MAX_CHANNELS, delegate: self)
        startServerTickTimer()
    }
    
    private func gameLoop(dT: MKDFloat) {
        //NSLog("gameLoop: %f", dT)
        
        // hack to keep loop running. see setup()
        magicSphereOfPower!.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: 0), impulse: true)
        
        for (_, player) in netPlayers {
            let character = player.character
            let (buttonEntries, _) = player.readAndClearButtonEntries() // ([([(ButtonInput, CGFloat)], CGFloat)], CGFloat)
            let hullEulerAngles = player.lastReceivedHullEulerAngles
            
            // WARN: SANITY CHECK CLIENT INPUT TIME DELTAS
            
            // IMPORTANT! initialPosition has to be set BEFORE translation in each loop invocation
            let initialPosition = character.bodyNode.position
            character.updateForInputs(buttonEntries, mouseDelta: nil)
//            character.updateForInputs(inputs.buttonInputs, mouseDelta: nil)
            character.hullOuterNode?.eulerAngles = SCNVector3Make(hullEulerAngles.x, hullEulerAngles.y, 0)
            character.hullInnerNode?.eulerAngles = SCNVector3Make(0, 0, hullEulerAngles.z)
            character.updateForLoopDelta(dT, initialPosition:initialPosition)
            
            
            // make camera follow player
            cameraNode.position = SCNVector3(x: character.bodyNode.position.x, y: cameraNode.position.y, z: character.bodyNode.position.z)
        }
        
        
        
//        // put the buttons into a format Character likes
//        var buttonEntries = [(buttons: [(button: ButtonInput, magnitude: CGFloat)], dT: CGFloat)]()
//        var buttons = [(button: ButtonInput, magnitude: CGFloat)]()
//        for (button, magnitude) in pressedButtons {
//            buttons.append((button, magnitude))
//        }
//        buttonEntries.append((buttons, CGFloat(dT)))
//        
//        // add to net client output array
//        netClientAccumButtonEntries.append((buttons, CGFloat(dT)))
//        
//        // IMPORTANT! initialPosition has to be set BEFORE any translation in each loop invocation
//        let initialPosition = character?.bodyNode.position
//        character?.updateForInputs(buttonEntries, mouseDelta: mouseDelta)
//        //character?.updateForInputs(activeButtonInput, mouseDelta: mouseDelta, dT: dT)
//        character?.updateForLoopDelta(dT, initialPosition: initialPosition!)
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("ServerSimulationController.switchToCameraNode() %@", cameraNode.name!)
        
        #if os(OSX)
            windowController?.renderView?.pointOfView = cameraNode
        #else
            
        #endif
    }
    
    private func startServerTickTimer() {
        NSLog("startServerTickTimer()")
        
        serverTickTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/NSTimeInterval(NET_SERVER_TICK_RATE),
            target: self,
            selector: "serverTickTimer:",
            userInfo: nil,
            repeats: true)
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginOrUpdateContact contact: SCNPhysicsContact) {
        //NSLog("ServerSimulationController.physicsWorld(didBeginOrUpdateContact: %@)", contact)
        
        if COLLISION_DETECTION_ENABLED {
            // WARN: this is stupid. should be taken are of automatically with floor's collisionBitmask
            guard contact.nodeA.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue
                && contact.nodeB.physicsBody?.categoryBitMask != CollisionCategory.Floor.rawValue else {
                    return
            }
            
            // match node to a client character and update accordingly
            
            for (_,player) in netPlayers {
                let character = player.character
                //let childNodes = player.character.bodyNode.childNodes
                // would be nice to do this recursively from bodyNode down
                var bodyNodes = [SCNNode]()
                bodyNodes.append(player.character.bodyNode)
                bodyNodes.append(player.character.legsNode!)
                bodyNodes.append(player.character.hullInnerNode!)
                
                if bodyNodes.contains(contact.nodeA) { // nodeA belongs to 'player'
                    character.bodyPart(contact.nodeA, mayHaveHitWall:contact.nodeB, withContact:contact)
                }
                else if bodyNodes.contains(contact.nodeB) { // nodeB belongs to 'player'
                    character.bodyPart(contact.nodeB, mayHaveHitWall:contact.nodeA, withContact:contact)
                }
            }
        }
    }

    private func clientPacketReceived(packetData: NSData, clientID: UInt32) {
        //NSLog("ServerSimulationController.clientPacketReceived(%@, clientID: %d)", packetData, clientID)
        
        if let message = MessageFromPayloadData(packetData) {
            switch message.opcode {
                
            case .ClientHello:
                // well hello! lets create a new "NetPlayer" opject and populate it with what we go so far
                let helloMessage = message as! ClientHelloNetMessage
                let name = helloMessage.name!
                //let sequenceNumber = helloMessage.sequenceNumber!
                NSLog("Client hello message! name: %@, id: %d", name, clientID)
                
                let character = Character(scene: scene) // adds itself to the scene
                character.serverInstance = true
                netPlayers[clientID] = NetPlayer(id: clientID, name: name as String, character: character)
                break
                
            case .ClientUpdate:
                //dNSLog("Update from player id: %d", clientID)
                
                if let player = netPlayers[clientID] {
                    let updateMessage = message as! ClientUpdateNetMessage
                    let sequenceNumber = updateMessage.sequenceNumber!
                    
                    //NSLog("Client update message. sq: %d", sequenceNumber)
                    
                    if sequenceNumber > player.lastReceivedSequenceNumber {
                        player.lastReceivedSequenceNumber = sequenceNumber
                        
                        let buttonEntries = updateMessage.buttonEntries!
                        let hullEulerAngles = updateMessage.hullEulerAngles
                        
                        player.addButtonEntries(buttonEntries)
                        player.lastReceivedHullEulerAngles = hullEulerAngles
                    }
                    else {
                        //NSLog("*** SQ \(sequenceNumber) not greater than \(player.lastReceivedSequenceNumber)! ***")
                    }
                }
                else {
                    NSLog("No player for ID:  %d", clientID)
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
    // MARK:   SCNSceneRendererDelegate
    /*****************************************************************************************************/
    
    public func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //NSLog("renderer(%@, updateAtTime: %f)", aRenderer.description, time)
        
        if let lastTime = lastRenderTime {
            lastRenderTime = time
            
            let dT = MKDFloat(time - lastTime)
            
            dispatch_async(dispatch_get_main_queue(),{
                self.gameLoop(dT)
            })
        }
        else {
            lastRenderTime = time
        }
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didApplyAnimationsAtTime time: NSTimeInterval) {
        //NSLog("renderer(%@, didApplyAnimationsAtTime: %f)", aRenderer.description, time)
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //NSLog("renderer(didSimulatePhysicsAtTime:)")

        dispatch_async(dispatch_get_main_queue(),{
            for (_,player) in self.netPlayers {
                player.character.didSimulatePhysicsAtTime(time)
            }
        })
    }
    
    public func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //NSLog("renderer(%@, willRenderScene: %@, scene: %@, atTime: %f)", renderer.description, scene, time)
    }
    
    public func renderer(renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //NSLog("renderer(%@, didRenderScene: %@, atTime: %f)", renderer.description, scene, time)
    }
    
    /*****************************************************************************************************/
    // MARK:   SCNPhysicsContactDelegate
    /*****************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        if !SERVER_VIEW_ENABLED {
            NSLog("physicsWorld(didUpdateContact: %@)", contact)
        }
        
        dispatch_async(dispatch_get_main_queue(),{
            self.physicsWorld(world, didBeginOrUpdateContact: contact)
        })
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        if !SERVER_VIEW_ENABLED {
            NSLog("physicsWorld(didBeginContact: %@)", contact)
        }
        
        dispatch_async(dispatch_get_main_queue(),{
            self.physicsWorld(world, didBeginOrUpdateContact: contact)
        })
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didEndContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didEndContact: %@)", contact)
    }
    
    /*****************************************************************************************************/
    // MARK:   MKDNetServerDelegate
    /*****************************************************************************************************/
    
    public func server(server: MKDNetServer!, didConnectClient client: UInt32) {
        NSLog("server(%@, didConnectClient: %d)", server, client)
    }
    
    public func server(server: MKDNetServer!, didDisconnectClient client: UInt32) {
        NSLog("server(%@, didDisconnectClient: %d)", server, client)
    }
    
    public func server(server: MKDNetServer!, didRecievePacket packetData: NSData!, fromClient client: UInt32, channel: UInt8) {
        //NSLog("server(%@, didRecievePacket: %@ fromClient: %d channel: %d)", server, packetData, client, channel)
        
        clientPacketReceived(packetData, clientID: client)
    }

    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    override required public init() {
        super.init()
        setup()
        if SERVER_VIEW_ENABLED {
            //self.windowController = ServerWindowController(serverSimulationController: self)
        }
        else {
            #if os(OSX)
                self.renderer = SCNRenderer(context: nil, options: nil)
            #endif
        }
    }
}
