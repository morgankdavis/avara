//
//  Character.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


func AllChildNodesRecursive(node: SCNNode) -> [SCNNode] {
    var result = [node]
    if node.childNodes.count > 0 {
        for child in node.childNodes {
            result.appendContentsOf(AllChildNodesRecursive(child))
        }
    }
    return result
}


public class Character {
    
    /******************************************************************************************************
        MARK:   Constants
     ******************************************************************************************************/
    
    private         let WALK_VELOCITY =             MKDFloat(5.0)                 // meters/sec
    private         let TURN_ANG_VELOCITY =         MKDFloat(M_PI*(2.0/3.0))      // radians/sec
    private         let HULL_VERT_ANG_CLAMP =       MKDFloat(M_PI/4.0)
    private         let HULL_HORIZ_ANG_CLAMP =      MKDFloat(M_PI*(2.0/3.0))
    private         let MAX_JUMP_HEIGHT =           MKDFloat(2.01)                // units -- arbitrary for now
    private         let MAX_ALTITUDE_RISE =         MKDFloat(0.2)                 // units -- the distance above character.y to ray test for altitude
    private         let HULL_LOOK_ROLL_FACTOR =     MKDFloat(M_PI/24.0)
    private         let CROSSHAIR_HEIGHT =          MKDFloat(0.5)
    private         let CROSSHAIR_FAR =             MKDFloat(15.0)                // units
    
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
    private         var accelerationY =             MKDFloat(0)
    private         var largestWallPenetration =    MKDFloat(0)
    private         var replacementPosition:        SCNVector3?
    
    private         var orientFinderTopNode:        SCNNode?
    private         var orientFinderBottomNode:     SCNNode?
    
    private         var crosshairRNode:             SCNNode?
    private         var crosshairLNode:             SCNNode?
    
    private         var allBodyNodes =             [SCNNode]()

    /******************************************************************************************************
         MARK:   Public
     ******************************************************************************************************/
    
//    public func updateForInputs(buttonInputs: Set<ButtonInput>, mouseDelta: CGPoint, dT: Double) {
//        // called for local simulation where dT for all push imports is uniform
//        
//        var inputs = [ButtonInput: Double]()
//        for i in buttonInputs {
//            inputs[i] = dT
//        }
//        
//        updateForInputs(inputs, mouseDelta: mouseDelta)
//    }
    
    public func updateForInputs(buttonEntries: [(buttons: [(button: ButtonInput, force: MKDFloat)], dT: MKDFloat)], lookDelta: CGPoint?) {
        for (buttonForce, dT) in buttonEntries {
            for (button, force) in buttonForce {
                // body
                if button == .MoveForward {
                    let positionDelta = WALK_VELOCITY * dT * force
                    
                    let transform = bodyNode.transform
                    let sinYRot = transform.m13
                    let cosYRot = transform.m33
                    
                    let dx = MKDFloat(positionDelta) * sinYRot
                    let dz = MKDFloat(positionDelta) * cosYRot
                    
                    bodyNode.position = SCNVector3(
                        x: bodyNode.position.x + dx,
                        y: bodyNode.position.y,
                        z: bodyNode.position.z - dz)
                }
                else if button == .MoveBackward {
                    let positionDelta = WALK_VELOCITY * dT * force
                    
                    let transform = bodyNode.transform
                    let sinYRot = transform.m13
                    let cosYRot = transform.m33
                    
                    let dx = MKDFloat(positionDelta) * sinYRot
                    let dz = MKDFloat(positionDelta) * cosYRot
                    
                    bodyNode.position = SCNVector3(
                        x: bodyNode.position.x - dx,
                        y: bodyNode.position.y,
                        z: bodyNode.position.z + dz)
                }
                else if button == .TurnLeft {
                    let rotationDelta = TURN_ANG_VELOCITY * dT * force
                    bodyNode.rotation = SCNVector4(
                        x: 0,
                        y: 1,
                        z: 0,
                        w: bodyNode.rotation.w + MKDFloat(rotationDelta))
                }
                else if button == .TurnRight {
                    let rotationDelta = TURN_ANG_VELOCITY * dT * force
                    bodyNode.rotation = SCNVector4(
                        x: 0,
                        y: 1,
                        z: 0,
                        w: bodyNode.rotation.w - MKDFloat(rotationDelta))
                }
            }
        }
        
        // hull
        
        if let dL = lookDelta {
            #if os(OSX)
                let viewDistanceFactor = 1.0/(MOUSELOOK_SENSITIVITY*MOUSELOOK_SENSITIVITY_MULTIPLIER)
            #else
                let viewDistanceFactor = 1.0/(THUMBLOOK_SENSITIVITY*THUMBLOOK_SENSITIVITY_MULTIPLIER)
            #endif
            
            let dP = acos(CGFloat(dL.x) / viewDistanceFactor) - CGFloat(M_PI_2)
            let dY = acos(CGFloat(dL.y) / viewDistanceFactor) - CGFloat(M_PI_2)
            
            var nAngles = SCNVector3(
                x: hullOuterNode!.eulerAngles.x + MKDFloat(dY),
                y: hullOuterNode!.eulerAngles.y - MKDFloat(dP),
                z: hullOuterNode!.eulerAngles.z)
            
            nAngles.x = max(-MKDFloat(HULL_VERT_ANG_CLAMP), min(MKDFloat(HULL_VERT_ANG_CLAMP), nAngles.x)) // clamp vertical angle
            nAngles.y = max(-MKDFloat(HULL_HORIZ_ANG_CLAMP), min(MKDFloat(HULL_HORIZ_ANG_CLAMP), nAngles.y)) // clamp horizontal angle
            nAngles.z = MKDFloat(HULL_LOOK_ROLL_FACTOR) * nAngles.y // roll
            
            hullOuterNode?.eulerAngles = nAngles
        }
        
        // crosshair
        
    }
    
    public func updateForLoopDelta(dT: MKDFloat, initialPosition: SCNVector3) {
        // called every iteration of the simulation loop for things like physics
        // IMPORTANT! initialPosition is the position BEFORE ANY TRANSLATIONS THIS LOOP ITERATION
        
        // altitude
        
        var groundY: MKDFloat = 0
        
        var position = bodyNode.position
        var rayOrigin = position
        rayOrigin.y += MKDFloat(MAX_ALTITUDE_RISE)
        var rayEnd = position
        rayEnd.y -= MKDFloat(MAX_JUMP_HEIGHT)
        
        let rayResults = scene.physicsWorld.rayTestWithSegmentFromPoint(
            rayOrigin,
            toPoint: rayEnd,
            options: [SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest])
        
        if rayResults.count > 0 {
            let resultHit = rayResults[0] as SCNHitTestResult
            //NSLog("HIT %@", resultHit.node)
            groundY = resultHit.worldCoordinates.y;
            bodyNode.position.y = groundY
            
            let THRESHOLD: MKDFloat = 1e-3 //1e-5 // 1e-5 == 0.00001
            let GRAVITY_ACCEL = MKDFloat(scene.physicsWorld.gravity.y/10.0)
            if (groundY < position.y - THRESHOLD) {
                accelerationY -= dT * GRAVITY_ACCEL // approximation of acceleration for a delta time.
            }
            else {
                accelerationY = 0
            }
            
            position.y -= MKDFloat(accelerationY)
            
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
    
    public func shootAFuckingBall() {
        NSLog("shootAFuckingBall")
        
        let ballGeo = SCNSphere(radius: 0.15)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = MKDColor.cyanColor()
        ballGeo.materials = [ballMaterial]
        let ballNode = SCNNode(geometry: ballGeo)
        ballNode.physicsBody = SCNPhysicsBody.dynamicBody()
        ballNode.physicsBody?.restitution = 1.0
        scene.rootNode.addChildNode(ballNode)
        let posInFrotOfHull = SCNVector3Make(0, 0, -100)
        let worldPosInFromOfHull = hullInnerNode!.convertPosition(posInFrotOfHull, toNode: scene.rootNode)
        ballNode.position = hullInnerNode!.convertPosition(SCNVector3Make(0, 0, -1.25), toNode: scene.rootNode)
        ballNode.physicsBody?.applyForce(worldPosInFromOfHull, impulse: true)
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
    
        let LEG_BOTTOM_THRESHOLD: MKDFloat = 0.05
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
        
        guard MKDFloat(contact.penetrationDistance) > MKDFloat(largestWallPenetration) else {
            //NSLog("Low penetration")
            return
        }
        
        if serverInstance {
            //NSLog("*** WALL CONTACT ***")
        }
        
        largestWallPenetration = MKDFloat(contact.penetrationDistance)
        
        let scaledNormal = SCNVector3(
            x: contact.contactNormal.x * MKDFloat(contact.penetrationDistance),
            y: 0,
            z: contact.contactNormal.z * MKDFloat(contact.penetrationDistance))
        
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
    
//    public func allBodyNodes() -> [SCNNode] {
//        // WARN: needs to be maintained as character composition changes
//        
//        // this is an optimization method. when other places need to check something against all character nodes
//        // this method should be consulted instead of doing a recuivive search each time (such as collision detection)
//        
//        return allBNodes
//    }
    
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
        #if os(OSX)
            ConfigureCamera(camera, screenSize: CLIENT_WINDOW_SIZE, fov: 80.0)
        #else
            ConfigureCamera(camera, screenSize: UIScreen.mainScreen().bounds.size, fov: 80.0)
        #endif
        camera.zNear = 0.01
        camera.zFar = 1000.0
        cameraNode.camera = camera
        cameraNode.name = "Camera node"
        cameraNode.position = SCNVector3(x: 0, y: 0.25, z: -0.25) // move the camera slightly forward in the character's head
        hullInnerNode?.addChildNode(cameraNode)
        
        // "orientation finders"
        
        let finderMaterial = SCNMaterial()
        let finderImage = MKDImage(named: "finder_blue.png")
        finderMaterial.diffuse.contents = finderImage
        finderMaterial.emission.contents = finderImage
        finderMaterial.doubleSided = true
        
        orientFinderTopNode = SCNNode(geometry: SCNPlane(width: 0.5, height: 0.5))
        orientFinderTopNode?.name = "Top orientation finder"
        orientFinderTopNode?.geometry?.materials = [finderMaterial]
        orientFinderTopNode?.position = SCNVector3(x: 0, y: 2.30, z: -1.15)
        orientFinderTopNode?.rotation = SCNVector4(x: 1.0, y: 0, z: 0, w: -MKDFloat(M_PI)/2.0*5.0)
        legsNode?.addChildNode(orientFinderTopNode!)
        
        orientFinderBottomNode = SCNNode(geometry: SCNPlane(width: 0.5, height: 0.5))
        orientFinderBottomNode?.name = "Bottom orientation finder"
        orientFinderBottomNode?.geometry?.materials = [finderMaterial]
        orientFinderBottomNode?.position = SCNVector3(x: 0, y: 1.25, z: -1.15)
        orientFinderBottomNode?.rotation = SCNVector4(x: 1.0, y: 0, z: 0, w: -MKDFloat(M_PI)/2.0)
        legsNode?.addChildNode(orientFinderBottomNode!)
        
        orientFinderTopNode?.castsShadow = false
        orientFinderBottomNode?.castsShadow = false
        
        // crosshairs
        
        let crosshairLMaterial = SCNMaterial()
        let crosshairLImage = MKDImage(named: "crosshairL.png") // WARN: check this
        crosshairLMaterial.diffuse.contents = crosshairLImage
        crosshairLMaterial.emission.contents = crosshairLImage
//        crosshairLMaterial.selfIllumination.contents = crosshairLImage
        crosshairLMaterial.doubleSided = true
        
        let crosshairRMaterial = SCNMaterial()
        let crosshairRImage = MKDImage(named: "crosshairR.png") // WARN: check this
        crosshairRMaterial.diffuse.contents = crosshairRImage
        crosshairRMaterial.emission.contents = crosshairRImage
//        crosshairRMaterial.selfIllumination.contents = crosshairsRImage
        crosshairRMaterial.doubleSided = true
        
        let crosshairCenterSphereMaterial = SCNMaterial()
        crosshairCenterSphereMaterial.diffuse.contents = MKDColor.cyanColor()
        crosshairCenterSphereMaterial.emission.contents = MKDColor.cyanColor()
        
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
        
        hullInnerNode!.addChildNode(crosshairRNode!)
        hullInnerNode!.addChildNode(crosshairLNode!)
        
        // update allBodyNodes
        
        var allBNodes = AllChildNodesRecursive(bodyNode)
        if let i = allBNodes.indexOf(crosshairRNode!) {
            allBNodes.removeAtIndex(i)
        }
        if let i = allBNodes.indexOf(crosshairLNode!) {
            allBNodes.removeAtIndex(i)
        }
        if let i = allBNodes.indexOf(orientFinderTopNode!) {
            allBNodes.removeAtIndex(i)
        }
        if let i = allBNodes.indexOf(orientFinderBottomNode!) {
            allBNodes.removeAtIndex(i)
        }
        allBodyNodes = allBNodes
    }
    
    private func updateCrosshairs() {
        
        let CROSSHAIR_SEPARATION_FACTOR = MKDFloat(1.5)

        // RIGHT
        
        do {
            let crosshairPlane = crosshairRNode!.geometry as! SCNPlane
            let crosshairWidth = MKDFloat(crosshairPlane.width)
            let crosshairHeight = MKDFloat(crosshairPlane.height)
            
            let baseOffset = SCNVector3Make(crosshairWidth * CROSSHAIR_SEPARATION_FACTOR, 0, 0)
            
            let offsetPoints = [
                SCNVector3Make( baseOffset.x + -crosshairWidth/2.0,     baseOffset.y + -crosshairHeight/2.0,    0 ),     // 0. top left
                SCNVector3Make( baseOffset.x + crosshairWidth/2.0,      baseOffset.y + -crosshairHeight/2.0,    0 ),     // 1. top right
                SCNVector3Make( baseOffset.x + crosshairWidth/2.0,      baseOffset.y + crosshairHeight/2.0,     0 ),     // 2. bottom right
                SCNVector3Make( baseOffset.x + -crosshairWidth/2.0,     baseOffset.y + crosshairHeight/2.0,     0 ),     // 3. bottom left
                SCNVector3Make( baseOffset.x + -crosshairWidth/4.0,     baseOffset.y + 0,                       0 ),     // 4. center inside
                SCNVector3Make( baseOffset.x + crosshairWidth/2.0,      baseOffset.y + 0,                       0 )]     // 5. center outside
            
            var closestHitResult: (result: SCNHitTestResult, distance: CGFloat)?
            
            for offsetPoint in offsetPoints {
                let worldSourcePoint = hullInnerNode!.convertPosition(offsetPoint, toNode:scene.rootNode)
                
                let worldDestinationPoint = hullInnerNode!.convertPosition(
                    SCNVector3Make(offsetPoint.x, offsetPoint.y, offsetPoint.z - CROSSHAIR_FAR),
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
                        let distance = CGFloat(GLKVector3Length(SCNVector3ToGLKVector3(difference)))
                        
                        if !allBodyNodes.contains(result.node) { // don't project onto parts of the hector's own body...
                            if let (_, cD) = closestHitResult {
                                if distance < cD {
                                    closestHitResult = (result, distance)
                                }
                            }
                            else {
                                closestHitResult = (result, distance)
                            }
                        }
                    }
                }
            }
            
            if let (_, distance) = closestHitResult {
                crosshairRNode!.position = SCNVector3Make(
                    baseOffset.x,
                    baseOffset.y,
                    -(MKDFloat(distance) - 0.005))
            }
            else { // so results. project out to CROSSHAIR_FAR
                crosshairRNode!.position = SCNVector3Make(
                    baseOffset.x,
                    baseOffset.y,
                    -CROSSHAIR_FAR)
            }
        }
        
        // LEFT
        
        do {
            let crosshairPlane = crosshairLNode!.geometry as! SCNPlane
            let crosshairWidth = MKDFloat(crosshairPlane.width)
            let crosshairHeight = MKDFloat(crosshairPlane.height)
            
            let baseOffset = SCNVector3Make(-crosshairWidth * CROSSHAIR_SEPARATION_FACTOR, 0, 0)
            
            let offsetPoints = [
                SCNVector3Make( baseOffset.x + -crosshairWidth/2.0,    baseOffset.y + -crosshairHeight/2.0,   0 ),     // 0. top left
                SCNVector3Make( baseOffset.x + crosshairWidth/2.0,     baseOffset.y + -crosshairHeight/2.0,   0 ),     // 1. top right
                SCNVector3Make( baseOffset.x + crosshairWidth/2.0,     baseOffset.y + crosshairHeight/2.0,    0 ),     // 2. bottom right
                SCNVector3Make( baseOffset.x + -crosshairWidth/2.0,    baseOffset.y + crosshairHeight/2.0,    0 ),     // 3. bottom left
                SCNVector3Make( baseOffset.x + crosshairWidth/4.0,     baseOffset.y + 0,                      0 ),     // 4. center outside
                SCNVector3Make( baseOffset.x + -crosshairWidth/2.0,    baseOffset.y + 0,                      0 )]     // 5. center inside
            
            var closestHitResult: (result: SCNHitTestResult, distance: CGFloat)?
            
            for offsetPoint in offsetPoints {
                let worldSourcePoint = hullInnerNode!.convertPosition(offsetPoint, toNode:scene.rootNode)
                
                let worldDestinationPoint = hullInnerNode!.convertPosition(
                    SCNVector3Make(offsetPoint.x, offsetPoint.y, offsetPoint.z - CROSSHAIR_FAR),
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
                        let distance = CGFloat(GLKVector3Length(SCNVector3ToGLKVector3(difference)))
                        
                        if !allBodyNodes.contains(result.node) { // don't project onto parts of the hector's own body...
                            if let (_, cD) = closestHitResult {
                                if distance < cD {
                                    closestHitResult = (result, distance)
                                }
                            }
                            else {
                                closestHitResult = (result, distance)
                            }
                        }
                    }
                }
            }
            
            if let (_, distance) = closestHitResult {
                crosshairLNode!.position = SCNVector3Make(
                    baseOffset.x,
                    baseOffset.y,
                    -(MKDFloat(distance) - 0.005))
            }
            else { // so results. project out to CROSSHAIR_FAR
                crosshairLNode!.position = SCNVector3Make(
                    baseOffset.x,
                    baseOffset.y,
                    -CROSSHAIR_FAR)
            }
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    init(scene: SCNScene) {
        self.scene = scene
        self.load()
    }
}
