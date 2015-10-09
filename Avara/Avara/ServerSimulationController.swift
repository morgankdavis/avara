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
    
    private         var serverTickTimer:            NSTimer?
    
    
    private         var lastLoopDate:               Double?
    
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
            selector: "gameLoopTimer:",
            userInfo: nil,
            repeats: true)
    }
    
    /*****************************************************************************************************/
    // MARK:   Internal
    /*****************************************************************************************************/
    
    internal func gameLoopTimer(timer: NSTimer) {
        gameLoop()
    }
    
    internal func serverTickTimer(timer: NSTimer) {
        NSLog("serverTickTimer()")
        
        // broadcast state to all clients
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
    
    private func gameLoop() {
        let nowDate = NSDate.timeIntervalSinceReferenceDate()
        
        if let lastDate = lastLoopDate {
            
            let dT = CGFloat(nowDate - lastDate)
            //NSLog("computed dT: %f", dT)
            //dT = 1.0/60.0
            
            for (_, player) in netPlayers {
                let character = player.character
                
                
                let inputs = player.readAndClearAccums() //(pushInputs: [UserInput: Double], mouseDelta: CGPoint, largestDuration: Double)
                
                //            if inputs.pushInputs.count > 0 {
                //                NSLog("pushInputs: %@", inputs.pushInputs.description)
                //
                //            }
                
                if inputs.pushInputs.count > 0 {
                    NSLog("pushInputs: %@", inputs.pushInputs.description)
                }
                if inputs.mouseDelta.x > 0 || inputs.mouseDelta.y > 0 {
                    NSLog("mouseDelta: {%.2f, %.2f}", inputs.mouseDelta.x, inputs.mouseDelta.y)
                }
                if inputs.largestDuration > 0 {
                    NSLog("largestDuration: %f", inputs.largestDuration)
                }
                
                character.updateForInputs(inputs.pushInputs, mouseDelta: inputs.mouseDelta)
                character.updateForLoopDelta(dT)
                
                
                
                //            let playerTotals = p.calculateTotalsAndClear() // (userInputs: [UserInput: Float32], mouseDelta: CGPoint, deltaTime: Float)
                //if totalDeltaTime <= <time-since-last>
                
                // else {
                
                
                
                //            // first update head orientation
                //            character.gameLoopWithInputs(nil, mouseDelta: playerTotals.mouseDelta, dT: 0)
                //
                //            // now loop through and update position
                //            // WARN: can be optimizaed by pre-computing here before calling gameLoopWithInputs(mouseDelta:dT:) to avoid duplicate trig
                //            for (activeInput, dT) in playerTotals.userInputs {
                //                character.gameLoopWithInputs(activeInput, mouseDelta: nil, dT: dT)
                //            }
                
                //character.gameLoopWithInputs(p.activeInputs, mouseDelta: p.readMouseDeltaAndClear(), dT: dT)
                
                
                
                // make camera follow player
                cameraNode.position = SCNVector3(x: character.bodyNode.position.x, y: cameraNode.position.y, z: character.bodyNode.position.z)
            }
        }
        
        lastLoopDate = nowDate
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
                    let userInputs = updateMessage.userInputs
                    let mouseDelta = updateMessage.mouseDelta
                    let sequenceNumber = updateMessage.sequenceNumber!
                    
                    NSLog("Client update message. inputs: %@, mouse delta: (%.2f, %.2f), sq: %d",
                        userInputs.description, mouseDelta.x, mouseDelta.y, sequenceNumber)
                    
                    player.lastReceivedSequenceNumber = sequenceNumber
                    
                    player.addInputs(userInputs)
                    player.addMouseDelta(mouseDelta)
                    
//                    // WARN: if sending updates as 30Hz we will need to set inputs until they are seen/cleared from main loop
//                    player.activeInputs = activeInputs
//                    player.addMouseDelta(mouseDelta)
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
