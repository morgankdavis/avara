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
    private         var serverWindowController:     ServerWindowController? // temporary?
    private(set)    var scene =                     SCNScene()
    private(set)    var renderView:                 RenderView? // *** TEMPORARY ***
    private         var map:                        Map?
    private         var netPlayers =                [UInt32:NetPlayer]()
    private         var gameLoopTimer:              NSTimer? // temporary
    private         var networkTickTimer:           NSTimer?
    private         var netServer:                  MKDNetServer?
    private         var cameraNode:                 SCNNode?
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func start() {
        NSLog("ServerSimulationController.start()")
        
        serverWindowController?.showWindow(self)
        
        cameraNode = SCNNode()
        cameraNode?.name = "Server camera node"
        cameraNode?.position = SCNVector3(x: 0, y: 20, z: 0)
        cameraNode?.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -CGFloat(M_PI)/2.0)
        scene.rootNode.addChildNode(cameraNode!)
        switchToCameraNode(cameraNode!)
        
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
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/

    private func setup() {
        NSLog("ServerSimulationController.setup()")
        
        map = Map(scene: scene)

        scene.physicsWorld.timeStep = PHYSICS_TIMESTEP
        scene.physicsWorld.contactDelegate = self
        
//        // *** TEMPORARY ***
//        // setup an SCNView to do our server rendering in. This SHOULD DEFINITLY not actually need to be rendered.
//        
//        renderView = RenderView(frame: CGRect(origin: CGPointZero, size: SERVER_WINDOW_SIZE) as NSRect)
//        renderView?.scene = scene
//        renderView?.delegate = self
        
        netServer = MKDNetServer(port: NET_SERVER_PORT, maxClients: NET_MAX_CLIENTS, maxChannels: NET_MAX_CHANNELS, delegate: self)
    }
    
    private func gameLoop(dT: CGFloat) {
        //NSLog("dT: %.4f", dT)
        
        // work-around for blank screen until something changes
//        cameraNode?.rotation = SCNVector4(x: cameraNode!.rotation.x, y: cameraNode!.rotation.y, z: cameraNode!.rotation.z, w: cameraNode!.rotation.w+0.0001)
//        cameraNode?.position = SCNVector3(x: cameraNode!.position.x, y: cameraNode!.position.y+1, z: cameraNode!.position.z)
//        switchToCameraNode(cameraNode!)
//        serverWindowController?.renderView?.play(self)
        
//        let sphere = SCNSphere(radius: 1)
//        let sphereNode = SCNNode(geometry: sphere)
//        scene.rootNode.addChildNode(sphereNode)
//        
//        let sphereMaterial = SCNMaterial()
//        sphereMaterial.diffuse.contents = NSColor.whiteColor()
//        sphere.firstMaterial = sphereMaterial
        
        
        
        for (_,p) in netPlayers {
            let character = p.character
            // WARN: No mouse delta
            character.gameLoopWithActions(p.activeActions, mouseDelta: CGPointZero, dT: dT)
        }
        
        // check for input and move characters
        //localCharacter?.gameLoopWithKeysPressed(inputManager.keysPressed, mouseDelta: inputManager.readMouseDeltaAndClear(), dT: dT)
    }
    
    func switchToCameraNode(cameraNode: SCNNode) {
        NSLog("ServerSimulationController.switchToCameraNode() %@", cameraNode.name!)
        
        serverWindowController?.renderView?.pointOfView = cameraNode
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
        NSLog("ServerSimulationController.parseClientPacket(%@, clientID: %d", packetData, clientID)
        
        if let message = MessageFromPayloadData(packetData) {
            switch message.opcode {
                
            case .ClientHello:
                // well hello! lets create a new "NetPlayer" opject and populate it with what we go so far
                let helloMessage = message as! ClientHelloNetMessage
                let name = helloMessage.name!
                let sequenceNumber = helloMessage.sequenceNumber!
                NSLog("Client hello message! Name: %@, Sequence Number: %d", name, sequenceNumber)
                
                let character = Character(scene: scene) // adds itself to the scene
                netPlayers[clientID] = NetPlayer(id: clientID, name: name as String, character: character, lastSequenceNumber: sequenceNumber)
                break
                
            case .ClientUpdate:
                if let player = netPlayers[clientID] {
                    let updateMessage = message as! ClientUpdateNetMessage
                    let activeActions = updateMessage.activeActions
                    let sequenceNumber = updateMessage.sequenceNumber!
                    player.activeActions = activeActions
                    NSLog("Client update message! Active actions: %@, Sequence Number: %d", activeActions.description, sequenceNumber)
                }
                else {
                    NSLog("No player for that ID!")
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
    
    /******************************************************************************************************
    MARK:   SCNSceneRendererDelegate
    ******************************************************************************************************/
    
    public func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //NSLog("renderer(updateAtTime:)")
    }
    
    public func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //NSLog("renderer(didSimulatePhysicsAtTime:)")

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
        NSLog("server(%@, didConnectClient: %d)", server, client)
    }
    
    public func server(server: MKDNetServer!, didDisconnectClient client: UInt32) {
        NSLog("server(%@, didDisconnectClient: %d)", server, client)
    }
    
    public func server(server: MKDNetServer!, didRecievePacket packetData: NSData!, fromClient client: UInt32, channel: UInt8) {
        NSLog("server(%@, didRecievePacket: %@ fromClient: %d channel: %d)", server, packetData, client, channel)
        
        parseClientPacket(packetData, clientID: client)
    }

    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    override required public init() {
        super.init()
        setup()
        self.serverWindowController = ServerWindowController(serverSimulationController: self)
    }
}
