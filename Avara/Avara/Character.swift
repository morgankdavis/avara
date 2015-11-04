//
//  Character.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


func allChildNodesRecursive(node: SCNNode) -> [SCNNode] {
    var result = [node]
    if node.childNodes.count > 0 {
        for child in node.childNodes {
            result.appendContentsOf(allChildNodesRecursive(child))
        }
    }
    return result
}


public class Character {
    
    /******************************************************************************************************
        MARK:   Constants
     ******************************************************************************************************/
    
    private         let WALK_VELOCITY =             Double(5.0)                 // meters/sec
    private         let TURN_ANG_VELOCITY =         Double(M_PI*(2.0/3.0))      // radians/sec
    private         let HULL_VERT_ANG_CLAMP =       Double(M_PI/4.0)
    private         let HULL_HORIZ_ANG_CLAMP =      Double(M_PI*(2.0/3.0))
    private         let MAX_JUMP_HEIGHT =           Double(2.01)                // units -- arbitrary for now
    private         let MAX_ALTITUDE_RISE =         Double(0.2)                 // units -- the distance above character.y to ray test for altitude
    private         let HULL_LOOK_ROLL_FACTOR =     Double(M_PI/24.0)
    private         let CROSSHAIR_HEIGHT =          CGFloat(0.25)
    private         let CROSSHAIR_FAR =             Double(15.0)                // units
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          let cameraNode =                SCNNode()
    public          var serverInstance =            false
    private(set)    var bodyNode =                  SCNNode()
    private(set)    var hullOuterNode:              SCNNode? // contains hullInnerNode. pitch+yaw
    private(set)    var hullInnerNode:              SCNNode? // contains geometry. roll
    private(set)    var legsNode:                   SCNNode?
    private         var scene:                      SCNScene
    private         var accelerationY =             Double(0)
    private         var largestWallPenetration =    Double(0)
    private         var replacementPosition:        SCNVector3?
    
    private         var orientFinderTopNode:        SCNNode?
    private         var orientFinderBottomNode:     SCNNode?
    
    private         var crosshairRNode:             SCNNode?
    private         var crosshairLNode:             SCNNode?

    /******************************************************************************************************
         MARK:   Public
     ******************************************************************************************************/
    
    public func updateForInputs(buttonInputs: Set<ButtonInput>, mouseDelta: CGPoint, dT: Double) {
        // called for local simulation where dT for all push imports is uniform
        
        var inputs = [ButtonInput: Double]()
        for i in buttonInputs {
            inputs[i] = dT
        }
        
        updateForInputs(inputs, mouseDelta: mouseDelta)
    }
    
    public func updateForInputs(pushInputs: [ButtonInput: Double], mouseDelta: CGPoint?) {
        // called every loop iteration or net update
        // when local mouseDelta is set. when network hull node angles are set externally
    
        // body
        if pushInputs.keys.contains(.MoveForward) {
            let dT = pushInputs[.MoveForward]!
            let positionDelta = WALK_VELOCITY * dT
            
            let transform = bodyNode.transform
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = CGFloat(positionDelta) * sinYRot
            let dz = CGFloat(positionDelta) * cosYRot
            
            bodyNode.position = SCNVector3(
                x: bodyNode.position.x + dx,
                y: bodyNode.position.y,
                z: bodyNode.position.z - dz)
        }
        if pushInputs.keys.contains(.MoveBackward) {
            let dT = pushInputs[.MoveBackward]!
            let positionDelta = WALK_VELOCITY * dT
            
            let transform = bodyNode.transform
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = CGFloat(positionDelta) * sinYRot
            let dz = CGFloat(positionDelta) * cosYRot
            
            bodyNode.position = SCNVector3(
                x: bodyNode.position.x - dx,
                y: bodyNode.position.y,
                z: bodyNode.position.z + dz)
        }
        
        if pushInputs.keys.contains(.TurnLeft) {
            let dT = pushInputs[.TurnLeft]!
            let rotationDelta = TURN_ANG_VELOCITY * dT
            bodyNode.rotation = SCNVector4(
                x: 0,
                y: 1,
                z: 0,
                w: bodyNode.rotation.w + CGFloat(rotationDelta))
        }
        if pushInputs.keys.contains(.TurnRight) {
            let dT = pushInputs[.TurnRight]!
            let rotationDelta = TURN_ANG_VELOCITY * dT
            bodyNode.rotation = SCNVector4(
                x: 0,
                y: 1,
                z: 0,
                w: bodyNode.rotation.w - CGFloat(rotationDelta))
        }
        
        // hull
        
        if let mD = mouseDelta {
            let viewDistanceFactor = 1.0/(MOUSE_SENSITIVITY*MOUSE_SENSITIVITY_MULTIPLIER)
            
            let dP = acos(CGFloat(mD.x) / viewDistanceFactor) - CGFloat(M_PI_2)
            let dY = acos(CGFloat(mD.y) / viewDistanceFactor) - CGFloat(M_PI_2)
            
            var nAngles = SCNVector3(
                x: hullOuterNode!.eulerAngles.x + dY,
                y: hullOuterNode!.eulerAngles.y - dP,
                z: hullOuterNode!.eulerAngles.z)
            
            nAngles.x = max(-CGFloat(HULL_VERT_ANG_CLAMP), min(CGFloat(HULL_VERT_ANG_CLAMP), nAngles.x)) // clamp vertical angle
            nAngles.y = max(-CGFloat(HULL_HORIZ_ANG_CLAMP), min(CGFloat(HULL_HORIZ_ANG_CLAMP), nAngles.y)) // clamp horizontal angle
            
            hullOuterNode?.eulerAngles = nAngles
            
            updateHullRoll()
        }
        
        // crosshair
        
    }
    
    public func updateForLoopDelta(dT: Double, initialPosition: SCNVector3) {
        // called every iteration of the simulation loop for things like physics
        // IMPORTANT! initialPosition is the position BEFORE ANY TRANSLATIONS THIS LOOP ITERATION
        
        // altitude
        
        var groundY: CGFloat = 0
        
        var position = bodyNode.position
        var rayOrigin = position
        rayOrigin.y += CGFloat(MAX_ALTITUDE_RISE)
        var rayEnd = position
        rayEnd.y -= CGFloat(MAX_JUMP_HEIGHT)
        
        let rayResults = scene.physicsWorld.rayTestWithSegmentFromPoint(
            rayOrigin,
            toPoint: rayEnd,
            options: [SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest])
        
        if rayResults.count > 0 {
            let resultHit = rayResults[0] as SCNHitTestResult
            //NSLog("HIT %@", resultHit.node)
            groundY = resultHit.worldCoordinates.y;
            bodyNode.position.y = groundY
            
            let THRESHOLD: CGFloat = 1e-3 //1e-5 // 1e-5 == 0.00001
            let GRAVITY_ACCEL = Double(scene.physicsWorld.gravity.y/10.0)
            if (groundY < position.y - THRESHOLD) {
                accelerationY -= dT * GRAVITY_ACCEL // approximation of acceleration for a delta time.
            }
            else {
                accelerationY = 0
            }
            
            position.y -= CGFloat(accelerationY)
            
            // reset acceleration if we touch the ground
            if groundY > position.y {
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
        
        largestWallPenetration = 0
        replacementPosition = nil
        
        // crosshairs
        
        updateCrosshairs()
    }
    
    public func didSimulatePhysicsAtTime(time: NSTimeInterval) {
        if let position = replacementPosition {
//            NSLog("bodyNode.position: %@", NSStringFromSCNVector3(bodyNode.position))
//            NSLog("replacementPosition: %@", NSStringFromSCNVector3(position))
            
            bodyNode.position = position
        }
    }
    
    public func bodyPart(bodyPartNode: SCNNode, mayHaveHitWall wallNode: SCNNode, withContact contact: SCNPhysicsContact) {
        if serverInstance {
            //NSLog("bodyPart(%@, mayHaveHitWall: %@, withContact: %@", bodyPartNode.name!, wallNode.name!, contact)
        }
        
        //NSLog("contact.penetrationDistance: %.2f", contact.penetrationDistance)
    
        let LEG_BOTTOM_THRESHOLD: CGFloat = 0.05
        if let legContactPoint = legsNode?.convertPosition(contact.contactPoint, fromNode: scene.rootNode) {
            guard bodyPartNode == hullInnerNode || (bodyPartNode == legsNode && legContactPoint.y > LEG_BOTTOM_THRESHOLD) else {
                //NSLog("Contact at bottom of legs.")
                return
            }
        }
        
//        guard contact.nodeA.parentNode != contact.nodeB.parentNode else {
//            NSLog("Contact between two body parts")
//            return
//        }
        
        guard bodyPartNode == hullInnerNode || bodyPartNode == legsNode else {
            NSLog("Doesn't look like a character body part...")
            return
        }
        
        guard contact.penetrationDistance > CGFloat(largestWallPenetration) else {
            //NSLog("Low penetration")
            return
        }
        
        if serverInstance {
            //NSLog("*** WALL CONTACT ***")
        }
        
        largestWallPenetration = Double(contact.penetrationDistance)
        
        let scaledNormal = SCNVector3(
            x: contact.contactNormal.x * contact.penetrationDistance,
            y: 0,
            z: contact.contactNormal.z * contact.penetrationDistance)
        
        replacementPosition = SCNVector3(
            x: bodyNode.position.x - scaledNormal.x,
            y: bodyNode.position.y,
            z: bodyNode.position.z - scaledNormal.z)
    }
    
    public func applyServerOverrideSnapshot(override: NetPlayerSnapshot) {
        // apply the "authoritive" player state from the server
        // set it as our base and let any deltas be calculated from it on the next game loop (probably immediately after this)

        bodyNode.position = override.position
        bodyNode.rotation = override.bodyRotation
        let angles = override.hullEulerAngles
        hullOuterNode?.eulerAngles = SCNVector3Make(angles.x, angles.y, 0)
        hullInnerNode?.eulerAngles = SCNVector3Make(0, 0, angles.z)
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
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
            //legsNode?.physicsBody?.collisionBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            legsNode?.physicsBody?.contactTestBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            bodyNode.addChildNode(legsNode!)
        }
        
        // head
        if let meshScene = SCNScene(named: "Models.scnassets/hector_hull.dae") {
            hullInnerNode = meshScene.rootNode.childNodeWithName("head", recursively: true)
            hullInnerNode?.name = "Hull inner node"
            //hullInnerNode?.position = SCNVector3(x: 0, y: 1.6, z: 0)
            hullInnerNode?.physicsBody = SCNPhysicsBody.kinematicBody()
            hullInnerNode?.physicsBody?.categoryBitMask = CollisionCategory.Character.rawValue
            //hullNode?.physicsBody?.collisionBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            hullInnerNode?.physicsBody?.contactTestBitMask = CollisionCategory.Wall.rawValue | CollisionCategory.Movable.rawValue
            hullOuterNode = SCNNode()
            hullOuterNode?.name = "Hull outer node"
            hullOuterNode?.addChildNode(hullInnerNode!)
            hullOuterNode?.position = SCNVector3(x: 0, y: 1.6, z: 0)
            //hullOuterNode?.pivot = SCNMatrix4MakeTranslation(0, 1.0, 0)
            legsNode?.addChildNode(hullOuterNode!)
        }
        
        // camera
        let camera = SCNCamera()
        ConfigureCamera(camera, screenSize: CLIENT_WINDOW_SIZE, fov: 80.0)
        camera.zNear = 0.01
        camera.zFar = 1000.0
        cameraNode.camera = camera
        cameraNode.name = "Camera node"
        cameraNode.position = SCNVector3(x: 0, y: 0.25, z: -0.25) // move the camera slightly forward in the character's head
        hullInnerNode?.addChildNode(cameraNode)
        
        // "orientation finders"
        
        let finderMaterial = SCNMaterial()
        let finderImage = NSImage(named: "finder_blue.png")
        finderMaterial.diffuse.contents = finderImage
        finderMaterial.emission.contents = finderImage
        finderMaterial.doubleSided = true
        
        orientFinderTopNode = SCNNode(geometry: SCNPlane(width: 0.5, height: 0.5))
        orientFinderTopNode?.name = "Top orientation finder"
        orientFinderTopNode?.geometry?.materials = [finderMaterial]
        orientFinderTopNode?.position = SCNVector3(x: 0, y: 2.30, z: -1.15)
        orientFinderTopNode?.rotation = SCNVector4(x: 1.0, y: 0, z: 0, w: -CGFloat(M_PI)/2.0*5.0)
        legsNode?.addChildNode(orientFinderTopNode!)
        
        orientFinderBottomNode = SCNNode(geometry: SCNPlane(width: 0.5, height: 0.5))
        orientFinderBottomNode?.name = "Bottom orientation finder"
        orientFinderBottomNode?.geometry?.materials = [finderMaterial]
        orientFinderBottomNode?.position = SCNVector3(x: 0, y: 1.25, z: -1.15)
        orientFinderBottomNode?.rotation = SCNVector4(x: 1.0, y: 0, z: 0, w: -CGFloat(M_PI)/2.0)
        legsNode?.addChildNode(orientFinderBottomNode!)
        
        orientFinderTopNode?.castsShadow = false
        orientFinderBottomNode?.castsShadow = false
        
        // crosshairs
        
        let crosshairLMaterial = SCNMaterial()
        let crosshairLImage = NSImage(named: "crosshairL.png") // WARN: check this
        crosshairLMaterial.diffuse.contents = crosshairLImage
        crosshairLMaterial.emission.contents = crosshairLImage
        crosshairLMaterial.doubleSided = true
        
        let crosshairRMaterial = SCNMaterial()
        let crosshairRImage = NSImage(named: "crosshairR.png") // WARN: check this
        crosshairRMaterial.diffuse.contents = crosshairRImage
        crosshairRMaterial.emission.contents = crosshairRImage
        crosshairRMaterial.doubleSided = true
        
        let crosshairWRatio = crosshairLImage!.size.width / crosshairLImage!.size.height
        let crosshairWidth = CROSSHAIR_HEIGHT * crosshairWRatio
        
        crosshairRNode = SCNNode(geometry: SCNPlane(width: crosshairWidth, height: CROSSHAIR_HEIGHT))
        crosshairLNode = SCNNode(geometry: SCNPlane(width: crosshairWidth, height: CROSSHAIR_HEIGHT))
        
        crosshairRNode?.castsShadow = false
        crosshairLNode?.castsShadow = false
        
        crosshairRNode?.name = "Right crosshair node"
        crosshairLNode?.name = "Left crosshair node"
        
        crosshairRNode!.geometry!.materials = [crosshairRMaterial]
        crosshairLNode!.geometry!.materials = [crosshairLMaterial]
        
        crosshairRNode!.position = SCNVector3Make(CROSSHAIR_HEIGHT/2.0 - crosshairWidth/2.0, 1.6, -2)
        crosshairLNode!.rotation = SCNVector4Make(0, 1, 0, CGFloat(M_PI))
        crosshairLNode!.position = SCNVector3Make(-CROSSHAIR_HEIGHT/2.0 + crosshairWidth/2.0, 1.6, -2)
        
        let lookAtConstraint = SCNLookAtConstraint(target: hullOuterNode!)
        lookAtConstraint.gimbalLockEnabled = true
        crosshairRNode!.constraints = [lookAtConstraint]
        crosshairLNode!.constraints = [lookAtConstraint]
        
//        scene.rootNode.addChildNode(crosshairRNode!)
//        scene.rootNode.addChildNode(crosshairLNode!)
        
        hullOuterNode!.addChildNode(crosshairRNode!)
        //hullOuterNode!.addChildNode(crosshairLNode!)
        
        
        
        // for ray trace debugging
        
//        originSphereNode = SCNNode(geometry: SCNSphere(radius: 0.25))
//        destinationSphereNode = SCNNode(geometry: SCNSphere(radius: 0.25))
//        scene.rootNode.addChildNode(originSphereNode!)
//        scene.rootNode.addChildNode(destinationSphereNode!)
        
        
        let allBodyNodes = allChildNodesRecursive(bodyNode)
        NSLog("allBodyNodes: %@", allBodyNodes)
    }
    
    private func updateHullRoll() {
        // add roll effect
        let roll = CGFloat(HULL_LOOK_ROLL_FACTOR) * hullOuterNode!.eulerAngles.y
        hullInnerNode?.eulerAngles.z = roll
    }
    
    private func updateCrosshairs() {
        let crosshairPlane = crosshairRNode!.geometry as! SCNPlane
        let crosshairWidth = crosshairPlane.width
        let crosshairHight = crosshairPlane.height

        let offsetPoints = [
            SCNVector3Make( -crosshairWidth/2.0,    -crosshairHight/2.0,    0), // top left
            SCNVector3Make( crosshairWidth/2.0,     -crosshairHight/2.0,    0), // top right
            SCNVector3Make( crosshairWidth/2.0,     -crosshairHight/2.0,    0), // bottom right
            SCNVector3Make( -crosshairWidth/2.0,    -crosshairHight/2.0,    0), // bottom left
            SCNVector3Make( crosshairWidth/4.0,     0,                      0), // center inside
            SCNVector3Make( crosshairWidth/2.0,     0,                      0)] // center outside

        var closestResult: (result: SCNHitTestResult, distance: CGFloat)?
        
        let allBodyNodes = allChildNodesRecursive(bodyNode)
        
        for offsetPoint in offsetPoints {
            let worldSourcePoint = hullOuterNode!.convertPosition(offsetPoint, toNode:scene.rootNode)
            
            let worldDestinationPoint = hullOuterNode!.convertPosition(
                SCNVector3Make(offsetPoint.x, offsetPoint.y, offsetPoint.z - CGFloat(CROSSHAIR_FAR)),
                toNode:scene.rootNode)
            
            let rayResults = scene.physicsWorld.rayTestWithSegmentFromPoint(
                worldSourcePoint,
                toPoint: worldDestinationPoint,
                options: [SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeAll])
            
            if rayResults.count > 0 {
                for result in rayResults {
                    // find how long this ray is
                    let difference = SCNVector3Make(
                        result.worldCoordinates.x - worldSourcePoint.x,
                        result.worldCoordinates.y - worldSourcePoint.y,
                        result.worldCoordinates.z - worldSourcePoint.z)
                    let magnitude = CGFloat(GLKVector3Length(SCNVector3ToGLKVector3(difference)))
                    
                    //NSLog("HIT WITH MAG: %f", magnitude)
                    
                    if !allBodyNodes.contains(result.node) { // don't project onto parts of the hector's own body...
                        if let (_, cD) = closestResult {
                            if magnitude < cD {
                                closestResult = (result, magnitude)
                            }
                        }
                        else {
                            closestResult = (result, magnitude)
                        }
                    }
                }
            }
        }
        
        if let (_, distance) = closestResult {
            crosshairRNode!.position = SCNVector3Make(
                CROSSHAIR_HEIGHT/2.0 - crosshairWidth/2.0,
                crosshairWidth/2.0 + crosshairWidth/2.0,
                -(distance - 0.05))
            //crosshairRNode!.position = SCNVector3Make(0, 0, -(distance - 0.05))
        }
        else { // so results. project out to CROSSHAIR_FAR
            crosshairRNode!.position = SCNVector3Make(
                CROSSHAIR_HEIGHT/2.0 - crosshairWidth/2.0,
                crosshairWidth/2.0 + crosshairWidth/2.0,
                -CGFloat(CROSSHAIR_FAR))
        }
        
    
        
        //NSLog("results: %d", results.count)
        
        //crosshairRNode!.position = SCNVector3Make(CROSSHAIR_HEIGHT/2.0 - crosshairWidth/2.0, 1.6, -2)
        
//        if rayResults.count > 0 {
//            let resultHit = rayResults[0] as SCNHitTestResult
//            //NSLog("resultHit: %@", resultHit)
//            
//            crosshairRNode!.position = resultHit.worldCoordinates
//        }
//        else {
//            crosshairRNode!.position = destinationPoint
//        }
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    init(scene: SCNScene) {
        self.scene = scene
        self.load()
    }
}
