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
    private         var gameLoopTimer:              NSTimer?
    private         var netServer:                  MKDNetServer?
    private         var cameraNode =                SCNNode()
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func start() {
        NSLog("ServerSimulationController.start()")
        
        windowController?.showWindow(self)
        
        switchToCameraNode(cameraNode)
        
        gameLoopTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: "gameLoop",
            userInfo: nil,
            repeats: true)
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func gameLoop() {
        gameLoop(1.0/60.0)
    }

    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("ServerSimulationController.setup()")
        
        map = Map(scene: scene)
        
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
    }
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        for (_,p) in netPlayers {
            let character = p.character
            
            character.gameLoopWithInputs(p.activeInputs, mouseDelta: p.readMouseDeltaAndClear(), dT: dT)
            
            // make camera follow player
            cameraNode.position = SCNVector3(x: character.bodyNode.position.x, y: cameraNode.position.y, z: character.bodyNode.position.z)
        }
        
        if let server = netServer {
            // updates ("player states") for our players
            var updatesToSend = [NetPlayerUpdate]()
            for (_,player) in netPlayers {
                let update = player.netPlayerUpdate()
                
                var send = false
                
                let inputActive = (player.activeInputs.count > 0) || (player.accumulatedMouseDelta != CGPointZero)
                
                if let lastUpdate = player.lastSentNetPlayerUpdate {
                    // here's the last sent update for this player.
                    if update != lastUpdate {
                        // player update is different (e.g. they're moved)
                        send = true
                    }
                    else {
                        if let lastInputActive = player.lastSentInputActive {
                            if inputActive != lastInputActive {
                                NSLog("** INPUT CHANGED **")
                                send = true
                            }
                        }
                    }
                }
                else {
                    // no last sent update for this player. send one.
                    send = true
                }
                
                if send {
                    updatesToSend.append(update)
                    player.lastSentNetPlayerUpdate = update
                }
                
                player.lastSentInputActive = inputActive
            }
            
            if updatesToSend.count > 0 {
                //NSLog("Sending authorative state sq: %d", updatesToSend[0].sequenceNumber)
                
                let updateMessage = ServerUpdateNetMessage(playerUpdates: updatesToSend)
                let packtData = updateMessage.encoded()
                server.broadcastPacket(packtData, channel: NetChannel.Control.rawValue , flags: .Reliable) // WARN: change to unreliable
            }
            else {
                //NSLog("No server updates to send.")
            }
        }
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("ServerSimulationController.switchToCameraNode() %@", cameraNode.name!)
        
        windowController?.renderView?.pointOfView = cameraNode
    }
    
    public func physicsWorld(world: SCNPhysicsWorld, didBeginOrUpdateContact contact: SCNPhysicsContact) {
        //NSLog("physicsWorld(didBeginOrUpdateContact: %@)", contact)
        
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
            bodyNodes.append(player.character.headNode!)
            
            if bodyNodes.contains(contact.nodeA) { // nodeA belongs to 'player'
                character.bodyPart(contact.nodeA, mayHaveHitWall:contact.nodeB, withContact:contact)
            }
            else if bodyNodes.contains(contact.nodeB) { // nodeB belongs to 'player'
                character.bodyPart(contact.nodeB, mayHaveHitWall:contact.nodeA, withContact:contact)
            }
        }
    }
    
    private func parseClientPacket(packetData: NSData, clientID: UInt32) {
        //NSLog("ServerSimulationController.parseClientPacket(%@, clientID: %d)", packetData, clientID)
        
        if let message = MessageFromPayloadData(packetData) {
            switch message.opcode {
                
            case .ClientHello:
                // well hello! lets create a new "NetPlayer" opject and populate it with what we go so far
                let helloMessage = message as! ClientHelloNetMessage
                let name = helloMessage.name!
                //let sequenceNumber = helloMessage.sequenceNumber!
                NSLog("Client hello message! name: %@", name)
                
                let character = Character(scene: scene) // adds itself to the scene
                netPlayers[clientID] = NetPlayer(id: clientID, name: name as String, character: character)
                break
                
            case .ClientUpdate:
                if let player = netPlayers[clientID] {
                    let updateMessage = message as! ClientUpdateNetMessage
                    let activeInputs = updateMessage.activeInputs
                    let mouseDelta = updateMessage.mouseDelta
                    let sequenceNumber = updateMessage.sequenceNumber!
                    
                    NSLog("Client update message. active inputs: %@, mouse delta: (%.2f, %.2f), sq: %d",
                        activeInputs.description, mouseDelta.x, mouseDelta.y, sequenceNumber)
                    
                    player.lastReceivedSequenceNumber = sequenceNumber
                    
                    // WARN: if sending updates as 30Hz we will need to set inputs until they are seen/cleared from main loop
                    player.activeInputs = activeInputs
                    player.addMouseDelta(mouseDelta)
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
        //NSLog("renderer(updateAtTime:)")
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //NSLog("renderer(didSimulatePhysicsAtTime:)")

//        for character in characters {
//            character.didSimulatePhysicsAtTime(time)
//        }
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
        
        parseClientPacket(packetData, clientID: client)
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
