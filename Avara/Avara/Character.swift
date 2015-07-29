//
//  Character.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class Character {
    
    /******************************************************************************************************
    MARK:   Constants
    ******************************************************************************************************/
    
    private         let WALK_VELOCITY =             CGFloat(5.0)                // meters/sec
    private         let TURN_ANG_VELOCITY =         CGFloat(M_PI*(2.0/3.0))     // radians/sec
    private         let HEAD_VERT_ANG_CLAMP =       CGFloat(M_PI/4.0)
    private         let HEAD_HORIZ_ANG_CLAMP =      CGFloat(M_PI*(2.0/3.0))
    private         let MAX_JUMP_HEIGHT =           CGFloat(2.01)               // units -- arbitrary for now
    private         let MAX_ALTITUDE_RISE =         CGFloat(0.07)               // units -- the distance above character.y to ray test for altitude
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    public          let cameraNode =                SCNNode()
    private         var scene:                      SCNScene
    private         let bodyNode =                  SCNNode()
    private         var headNode:                   SCNNode?
    private         var legsNode:                   SCNNode?
    private         var accelerationY =             CGFloat(0)
    private         var maxPenetrationDistance =    CGFloat(0)
    private         var replacementPosition:        SCNVector3?
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    public func gameLoopWithKeysPressed(keys: Set<Key>, mouseDelta: CGPoint, dT: CGFloat) {
        
        let initialPosition = bodyNode.position
        
        // body
        if keys.contains(.W) { // move forward
            let positionDelta = WALK_VELOCITY * dT
            
            let transform = bodyNode.transform
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = positionDelta * sinYRot
            let dz = positionDelta * cosYRot
            
            bodyNode.position = SCNVector3(
                x: bodyNode.position.x + dx,
                y: bodyNode.position.y,
                z: bodyNode.position.z - dz)
        }
        else if keys.contains(.S) { // move backward
            let positionDelta = WALK_VELOCITY * dT
            
            let transform = bodyNode.transform
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = positionDelta * sinYRot
            let dz = positionDelta * cosYRot
            
            bodyNode.position = SCNVector3(
                x: bodyNode.position.x - dx,
                y: bodyNode.position.y,
                z: bodyNode.position.z + dz)
        }
        
        if keys.contains(.A) { // turn left
            let rotationDelta = TURN_ANG_VELOCITY * dT
            bodyNode.rotation = SCNVector4(
                x: 0,
                y: 1,
                z: 0,
                w: bodyNode.rotation.w + CGFloat(rotationDelta))
        }
        else if keys.contains(.D) { // turn right
            let rotationDelta = TURN_ANG_VELOCITY * dT
            bodyNode.rotation = SCNVector4(
                x: 0,
                y: 1,
                z: 0,
                w: bodyNode.rotation.w - CGFloat(rotationDelta))
        }
        
        // head
        let viewDistanceFactor = MOUSE_SENSITIVITY
        
        let hAngle = acos(CGFloat(mouseDelta.x) / viewDistanceFactor) - CGFloat(M_PI_2)
        let vAngle = acos(CGFloat(mouseDelta.y) / viewDistanceFactor) - CGFloat(M_PI_2)
        
        var nAngles = SCNVector3(
            x: headNode!.eulerAngles.x + vAngle,
            y: headNode!.eulerAngles.y - hAngle,
            z: headNode!.eulerAngles.z)
        
        nAngles.x = max(-HEAD_VERT_ANG_CLAMP, min(HEAD_VERT_ANG_CLAMP, nAngles.x)) // clamp vertical angle
        nAngles.y = max(-HEAD_HORIZ_ANG_CLAMP, min(HEAD_HORIZ_ANG_CLAMP, nAngles.y)) // clamp horizontal angle
        
        headNode?.eulerAngles = nAngles
        
        // altitude
        
        var groundY: CGFloat = 0
        
        var position = bodyNode.position
        var rayOrigin = position
        rayOrigin.y += MAX_ALTITUDE_RISE
        var rayEnd = position
        rayEnd.y -= MAX_JUMP_HEIGHT
        
        let rayResults = scene.physicsWorld.rayTestWithSegmentFromPoint(
            rayOrigin,
            toPoint: rayEnd,
            options: [SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest])
        
        if (rayResults.count > 0) {
            let resultHit = rayResults[0] as SCNHitTestResult
                groundY = resultHit.worldCoordinates.y;
                bodyNode.position.y = groundY
     
            let THRESHOLD: CGFloat = 1e-5 // 0.1
            let GRAVITY_ACCEL = scene.physicsWorld.gravity.y/10.0
            if (groundY < position.y - THRESHOLD) {
                accelerationY -= dT * GRAVITY_ACCEL // approximation of acceleration for a delta time.
            }
            else {
                accelerationY = 0
            }
            
            position.y -= accelerationY
            
            // reset acceleration if we touch the ground
            if (groundY > position.y) {
                accelerationY = 0
                position.y = groundY
            }
            
            bodyNode.position = position
        }
        else {
            NSLog("***** NO ALTITUDE TEST RESULTS. RESETTING POSITION *****")
            // probably outside map bounds -- reset to initial position
            bodyNode.position = initialPosition
        }
        
        // collisions
        
        maxPenetrationDistance = 0
        replacementPosition = nil
    }
    
    public func didSimulatePhysicsAtTime(time: NSTimeInterval) {
        if let position = replacementPosition {
            bodyNode.position = position
        }
    }
    
    public func bodyPart(bodyPartNode: SCNNode, mayHaveHitWall wallNode: SCNNode, withContact contact: SCNPhysicsContact) {
//        NSLog("bodyPart(%@, mayHaveHitWall: %@, withContact: %@", bodyPartNode, wallNode, contact)
        
        //NSLog("contact.penetrationDistance: %.2f", contact.penetrationDistance)
    
        let LEG_BOTTOM_THRESHOLD: CGFloat = 0.05
        if let legContactPoint = legsNode?.convertPosition(contact.contactPoint, fromNode: scene.rootNode) {
            guard bodyPartNode == headNode || (bodyPartNode == legsNode && legContactPoint.y > LEG_BOTTOM_THRESHOLD) else {
                //NSLog("Contact at very bottom of legs.")
                return
            }
        }
        
//        guard contact.nodeA.parentNode != contact.nodeB.parentNode else {
//            NSLog("Contact between two body parts")
//            return
//        }
        
        guard bodyPartNode == headNode || bodyPartNode == legsNode else {
            NSLog("Doesn't look like a character body part...")
            return
        }
        
        guard contact.penetrationDistance > maxPenetrationDistance else {
            //NSLog("Low penetration")
            return
        }
        
        //NSLog("*** WALL CONTACT ***")
        
        maxPenetrationDistance = contact.penetrationDistance;
        
        let scaledNormal = SCNVector3(
            x: contact.contactNormal.x * contact.penetrationDistance,
            y: 0,
            z: contact.contactNormal.z * contact.penetrationDistance)
        
        replacementPosition = SCNVector3(
            x: bodyNode.position.x - scaledNormal.x,
            y: bodyNode.position.y,
            z: bodyNode.position.z - scaledNormal.z)
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func load() {
        NSLog("Character.load()")
        
        // body
        bodyNode.name = "Body node"
        bodyNode.position = SCNVector3Make(0, 0.5, 0)
        scene.rootNode.addChildNode(bodyNode)

        // legs
        if let meshScene = SCNScene(named: "Models.scnassets/hector_legs.dae") {
            legsNode = meshScene.rootNode.childNodeWithName("legs", recursively: true)
            legsNode?.name = "Legs node"
            legsNode?.position = SCNVector3(x: 0, y: 0, z: 0)
            legsNode?.physicsBody = SCNPhysicsBody.kinematicBody()
            legsNode?.physicsBody?.categoryBitMask = CollisionCategory.Character.rawValue
            legsNode?.physicsBody?.collisionBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            legsNode?.physicsBody?.contactTestBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            bodyNode.addChildNode(legsNode!)
        }
        
        // head
        if let meshScene = SCNScene(named: "Models.scnassets/hector_head.dae") {
            headNode = meshScene.rootNode.childNodeWithName("head", recursively: true)
            headNode?.name = "Head node"
            headNode?.position = SCNVector3(x: 0, y: 1.6, z: 0)
            headNode?.physicsBody = SCNPhysicsBody.kinematicBody()
            headNode?.physicsBody?.categoryBitMask = CollisionCategory.Character.rawValue
            headNode?.physicsBody?.collisionBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            headNode?.physicsBody?.contactTestBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            legsNode?.addChildNode(headNode!)
        }
        
        // camera
        let camera = SCNCamera()
        ConfigureCamera(camera, fov: 80.0)
        camera.zNear = 0.01
        camera.zFar = 1000.0
        cameraNode.camera = camera
        cameraNode.name = "Head node"
        cameraNode.position = SCNVector3(x: 0, y: 0.25, z: -0.25) // move the camera slightly forward in the character's head
        headNode?.addChildNode(cameraNode)
    }
    
    /******************************************************************************************************
    MARK:   Object
    ******************************************************************************************************/
    
    init(scene: SCNScene) {
        self.scene = scene
        self.load()
    }
}