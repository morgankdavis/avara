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
    
    private         var windowController:           ServerWindowController?
    private(set)    var scene =                     SCNScene()
    private         var map:                        Map?
    private         var netPlayers =                [UInt32:NetPlayer]()            // id:player
    private         var netServer:                  MKDNetServer?
    private         var cameraNode =                SCNNode()
    
    private         var serverTickTimer:            NSTimer?
    private         var sentNoChangePacket =        [UInt32:Bool]()                 // id:sent
    
    private         var magicSphereOfPower:         SCNNode?
    private         var lastLoopTime:               Double?
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func start() {
        NSLog("ServerSimulationController.start()")
        
        windowController?.showWindow(self)
        
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
            
            // TODO: add convenience method to NetPlayer to make its own snapshot?
            let snapshot = NetPlayerSnapshot(
                sequenceNumber: player.lastReceivedSequenceNumber+1,
                id: id,
                position: player.character.bodyNode.position,
                bodyRotation: player.character.bodyNode.rotation,
                headEulerAngles: player.character.hullNode!.eulerAngles)
            
            if snapshot != player.lastSentNetPlayerSnapshot {
                //NSLog("-- SERVER SENDING --")
                snapshotsToSend.append(snapshot)
                player.lastSentNetPlayerSnapshot = snapshot
                player.lastReceivedSequenceNumber++
                
                sentNoChangePacket[id] = false
            }
            else {
                if sentNoChangePacket[id] == nil || sentNoChangePacket[id] == false {
                    // send a single packet indicating there is no new input
                    
                    //NSLog("-- SERVER SENDING DUPLICATE --")
                    
                    snapshotsToSend.append(snapshot)
                    player.lastSentNetPlayerSnapshot = snapshot
                    player.lastReceivedSequenceNumber++
                    
                    sentNoChangePacket[id] = true
                }
                else {
                    //NSLog("-- SERVER SKIPPING --")
                }
            }
            
            if snapshotsToSend.count > 0 {
                let updateMessage = ServerUpdateNetMessage(playerSnapshots: snapshotsToSend)
                let packtData = updateMessage.encoded()
                if let server = netServer {
                    server.broadcastPacket(packtData, channel: NetChannel.Signaling.rawValue, flags: .Unsequenced)
                }
            }
        }
        
//        if let server = netServer {
//            server.pump()
//        }
    }

    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("ServerSimulationController.setup()")
        
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
        cameraNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -CGFloat(M_PI)/2.0)
        scene.rootNode.addChildNode(cameraNode)
        
        netServer = MKDNetServer(port: NET_SERVER_PORT, maxClients: NET_MAX_CLIENTS, maxChannels: NET_MAX_CHANNELS, delegate: self)
        startServerTickTimer()
    }
    
    private func gameLoop(dT: Double) {
        //NSLog("gameLoop: %f", dT)
        
        // hack to keep loop running. see setup()
        magicSphereOfPower!.physicsBody?.applyForce(SCNVector3(x: 0, y: 0, z: 0), impulse: true)
        
        for (_, player) in netPlayers {
            let character = player.character
            let inputs = player.readAndClearAccums() //(buttonInputs: [ButtonInput: Double], mouseDelta: CGPoint, largestDuration: Double)
            
            //                if inputs.buttonInputs.count > 0 {
            //                    NSLog("pushInputs: %@", inputs.buttonInputs.description)
            //                }
            //                if abs(inputs.mouseDelta.x) > 0 || abs(inputs.mouseDelta.y) > 0 {
            //                    NSLog("mouseDelta: {%.2f, %.2f}", inputs.mouseDelta.x, inputs.mouseDelta.y)
            //                }
            //                if inputs.largestDuration > 0 {
            //                    NSLog("largestDuration: %f", inputs.largestDuration)
            //                }
            
            // WARN: SANITY CHECK CLIENT INPUT TIME DELTAS
            
            // IMPORTANT! initialPosition has to be set BEFORE translation in each loop invocation
            let initialPosition = character.bodyNode.position
            character.updateForInputs(inputs.buttonInputs, mouseDelta: inputs.mouseDelta)
            character.updateForLoopDelta(dT, initialPosition:initialPosition)
            
            
            // make camera follow player
            cameraNode.position = SCNVector3(x: character.bodyNode.position.x, y: cameraNode.position.y, z: character.bodyNode.position.z)
        }
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("ServerSimulationController.switchToCameraNode() %@", cameraNode.name!)
        
        windowController?.renderView?.pointOfView = cameraNode
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
                bodyNodes.append(player.character.hullNode!)
                
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
                    let buttonInputs = updateMessage.buttonInputs
                    let mouseDelta = updateMessage.mouseDelta
                    let sequenceNumber = updateMessage.sequenceNumber!
                    
                    //                    NSLog("Client update message. inputs: %@, mouse delta: (%.2f, %.2f), sq: %d",
                    //                        userInputs.description, mouseDelta.x, mouseDelta.y, sequenceNumber)
                    
                    if sequenceNumber > player.lastReceivedSequenceNumber {
                        player.lastReceivedSequenceNumber = sequenceNumber
                        
                        player.addInputs(buttonInputs)
                        player.addMouseDelta(mouseDelta)
                    }
                    else {
                        NSLog("*** SQ \(sequenceNumber) not greater than \(player.lastReceivedSequenceNumber)! **")
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
        //NSLog("renderer(%@, updateAtTime: %f)", renderer.description, time)
        
        if let lastTime = lastLoopTime {
            let dT = time - lastTime
            
            dispatch_async(dispatch_get_main_queue(),{
                self.gameLoop(dT)
            })
        }
        
        lastLoopTime = time
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //NSLog("renderer(didSimulatePhysicsAtTime:)")

        dispatch_async(dispatch_get_main_queue(),{
            for (_,player) in self.netPlayers {
                player.character.didSimulatePhysicsAtTime(time)
            }
        })
    }
    
    /*****************************************************************************************************/
    // MARK:   SCNPhysicsContactDelegate
    /*****************************************************************************************************/
    
    public func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didUpdateContact: %@)", contact)
        
        dispatch_async(dispatch_get_main_queue(),{
            self.physicsWorld(world, didBeginOrUpdateContact: contact)
        })
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginContact: %@)", contact)
        
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
        self.windowController = ServerWindowController(serverSimulationController: self)
    }
}
