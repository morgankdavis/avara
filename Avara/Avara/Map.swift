//
//  Map.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class Map : NSObject, SCNProgramDelegate {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private     var scene:          SCNScene
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func load() {
        NSLog("Map.load()")
        
        // world physics
        scene.physicsWorld.gravity = SCNVector3(x: 0, y: -9.8, z: 0)
        
        // atmosphere
        scene.fogStartDistance = 0.0
        scene.fogEndDistance = 200.0
        scene.fogDensityExponent = 2.0
        scene.fogColor = NSColor.lightGrayColor()
        
        // background
        //scene.background.contents = NSColor(red:102.0/255.0, green:204.0/255.0, blue:255.0/255.0, alpha:1)
//        scene.background.contents = [
//            NSImage(named: "sky_interstellar_0.png")!,
//            NSImage(named: "sky_interstellar_1.png")!,
//            NSImage(named: "sky_interstellar_2.png")!,
//            NSImage(named: "sky_interstellar_3.png")!,
//            NSImage(named: "sky_interstellar_4.png")!,
//            NSImage(named: "sky_interstellar_5.png")!]
        scene.background.contents = [
            NSImage(named: "sky_miramar_0.png")!,
            NSImage(named: "sky_miramar_1.png")!,
            NSImage(named: "sky_miramar_2.png")!,
            NSImage(named: "sky_miramar_3.png")!,
            NSImage(named: "sky_miramar_4.png")!,
            NSImage(named: "sky_miramar_5.png")!]
        // WARNING: Temporary
        if (NSProcessInfo.processInfo().hostName == "goosebox.local") {
            scene.background.maxAnisotropy = 16.0
        } else {
            scene.background.maxAnisotropy = 2.0
        }
        scene.background.mipFilter = .Linear
		
        
        
//		let skyBoxGeo = SCNBox(width: 50, height: 50, length: 50, chamferRadius: 0)
//        let skyBoxNode = SCNNode(geometry: skyBoxGeo)
//        scene.rootNode.addChildNode(skyBoxNode)
//        
//        
//		let skyProgram = SCNProgram()
//        
//        if let vshPath = NSBundle.mainBundle().pathForResource("sky", ofType: "vsh") {
//            do {
//                let vshString = try NSString(contentsOfFile: vshPath, encoding: NSUTF8StringEncoding)
//                skyProgram.vertexShader = vshString as String
//            }
//            catch {
//                NSLog("Exception loading vsh file.")
//            }
//        }
//        
//        if let fshPath = NSBundle.mainBundle().pathForResource("sky", ofType: "fsh") {
//            do {
//                let fshString = try NSString(contentsOfFile: fshPath, encoding: NSUTF8StringEncoding)
//                skyProgram.fragmentShader = fshString as String
//            }
//            catch {
//                NSLog("Exception loading fsh file.")
//            }
//        }
//        
//        skyProgram.setSemantic(SCNGeometrySourceSemanticVertex, forSymbol: "vtx_position", options: nil)
//        skyProgram.setSemantic(SCNModelViewProjectionTransform, forSymbol: "l_vector", options: nil)
//        
//        skyProgram.delegate = self
//        
//        skyBoxGeo.program = skyProgram
		

        
		
        
        // ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = NSColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        // omni light
        let omniLight = SCNLight()
        omniLight.type = SCNLightTypeOmni
        omniLight.color = NSColor(white: 0.75, alpha: 1.0)
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3Make(40, 25, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        // spot light
//        let spotLight = SCNLight()
//        spotLight.type = SCNLightTypeSpot
//        spotLight.color = NSColor(white: 0.75, alpha: 1.0)
//        let spotLightNode = SCNNode()
//        spotLightNode.light = spotLight
//        spotLightNode.position = SCNVector3Make(40, 25, 50)
//        //spotLightNode.eulerAngles = SCNVector3(x: -30, y: -30, z: 0)
//        spotLightNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-M_PI/2.0))
////        let centerCode = SCNNode()
////        centerCode.position = SCNVector3Zero
////        scene.rootNode.addChildNode(centerCode)
////        spotLightNode.constraints = [SCNLookAtConstraint(target: centerCode)]
//        scene.rootNode.addChildNode(spotLightNode)
//        spotLight.castsShadow = true
//        spotLight.shadowMode = .Modulated

        // floor node
        let floor = SCNFloor()
        floor.reflectivity = 0.25
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = NSColor.grayColor()
        floorMaterial.ambient.contents = NSColor.blackColor()
        floorMaterial.diffuse.contents = NSImage(named: "grid.png")
        let floorDiffScale: CGFloat = 12.0
        floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(floorDiffScale, floorDiffScale, floorDiffScale)//SCNMatrix4MakeScale(10.0, 10.0, 10.0)
        floorMaterial.diffuse.intensity = 1.0
        floorMaterial.diffuse.mipFilter = .Linear
        // WARNING: Temporary
        if (NSProcessInfo.processInfo().hostName == "goosebox.local") {
            floorMaterial.diffuse.maxAnisotropy = 16.0
        } else {
            floorMaterial.diffuse.maxAnisotropy = 2.0
        }
//        floorMaterial.normal.contents = NSImage(named: "floorBump.jpg")
//        floorMaterial.normal.contentsTransform = SCNMatrix4MakeScale(15.0, 15.0, 15.0)
//        floorMaterial.normal.intensity = 0.15

        floorMaterial.locksAmbientWithDiffuse = true

        floorMaterial.normal.wrapS = .Mirror
        floorMaterial.normal.wrapT = .Mirror
        floorMaterial.specular.wrapS = .Mirror
        floorMaterial.specular.wrapT = .Mirror
        floorMaterial.diffuse.wrapS  = .Repeat
        floorMaterial.diffuse.wrapT  = .Repeat
        
        floor.firstMaterial = floorMaterial
        
        // map physics
        floorNode.physicsBody = SCNPhysicsBody.staticBody()
        
        floorNode.physicsBody?.categoryBitMask = CollisionCategory.Floor.rawValue
        floorNode.physicsBody?.collisionBitMask = 0
        floorNode.physicsBody?.contactTestBitMask = 0
        //floorNode.physicsBody!.categoryBitMask = CollisionCategory.Map.rawValue
        scene.rootNode.addChildNode(floorNode)
        
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = NSColor.redColor()
//        boxMaterial.normal.contents = NSImage(named: "needlepointSteel_normal.png")
//        boxMaterial.normal.intensity = 1.0
        
        
        // boxes
        let BOX_SIZE: CGFloat = 2.0
        let BOX_Y: CGFloat = BOX_SIZE / 2.0
        
        let boxGeometry = SCNBox(width: BOX_SIZE, height: BOX_SIZE, length: BOX_SIZE, chamferRadius: 0)
        boxGeometry.materials = [boxMaterial]
        
        let box1Node = SCNNode(geometry: SCNBox(width: BOX_SIZE, height: BOX_SIZE, length: BOX_SIZE, chamferRadius: 0))
        box1Node.geometry?.materials = [boxMaterial]
        box1Node.position = SCNVector3Make(-10, BOX_Y, 10)
        box1Node.name = "Box node 1"
        scene.rootNode.addChildNode(box1Node)
        
        let box2Node = SCNNode(geometry: SCNBox(width: BOX_SIZE, height: BOX_SIZE, length: BOX_SIZE, chamferRadius: 0))
        box2Node.geometry?.materials = [boxMaterial]
        box2Node.position = SCNVector3Make(10, BOX_Y, 10)
        box2Node.name = "Box node 2"
        scene.rootNode.addChildNode(box2Node)

        // box physics
        box1Node.physicsBody = SCNPhysicsBody.dynamicBody()
        box1Node.physicsBody?.friction = 1 // default is .5
        box1Node.physicsBody?.rollingFriction = 1
        box1Node.physicsBody?.categoryBitMask = CollisionCategory.Movable.rawValue
        box1Node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
        box1Node.physicsBody?.contactTestBitMask = CollisionCategory.Character.rawValue

        box2Node.physicsBody = SCNPhysicsBody.dynamicBody()
        box2Node.physicsBody?.friction = 1 // default is .5
        box2Node.physicsBody?.rollingFriction = 1
        box2Node.physicsBody?.categoryBitMask = CollisionCategory.Movable.rawValue
        box2Node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
        box2Node.physicsBody?.contactTestBitMask = CollisionCategory.Character.rawValue
        
        // platform
        
        let platformMaterial = SCNMaterial()
        platformMaterial.diffuse.contents = NSColor.yellowColor()
        platformMaterial.doubleSided = true
        
        let rRampGeometry = SCNPlane(width: 2, height: 4)
        let rRampNode = SCNNode(geometry: rRampGeometry)
        rRampNode.name = "R Ramp"
        rRampNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-M_PI/3.0))
        rRampNode.position = SCNVector3(x: 10, y: 1, z: -9.125)
        rRampGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(rRampNode)
        
        let lRampGeometry = SCNPlane(width: 2, height: 4)
        let lRampNode = SCNNode(geometry: lRampGeometry)
        lRampNode.name = "L Ramp"
        lRampNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-M_PI/3.0))
        lRampNode.position = SCNVector3(x: -10, y: 1, z: -9.125)
        lRampGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(lRampNode)
        
        let rPlatformGeometry = SCNPlane(width: 2, height: 5)
        let rPlatformNode = SCNNode(geometry: rPlatformGeometry)
        rPlatformNode.name = "R Platform"
        rPlatformNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-M_PI/2.0))
        rPlatformNode.position = SCNVector3(x: 10, y: 2.0, z: -10 - 3.36)
        rPlatformGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(rPlatformNode)
        
        let lPlatformGeometry = SCNPlane(width: 2, height: 5)
        let lPlatformNode = SCNNode(geometry: lPlatformGeometry)
        lPlatformNode.name = "L Platform"
        lPlatformNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: CGFloat(-M_PI/2.0))
        lPlatformNode.position = SCNVector3(x: -10, y: 2.0, z: -10 - 3.36)
        lPlatformGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(lPlatformNode)
        
        let cPlatformGeometry = SCNPlane(width: 2, height: 18)
        let cPlatformNode = SCNNode(geometry: cPlatformGeometry)
        cPlatformNode.name = "C Platform"
        let rotFlatMat = SCNMatrix4MakeRotation(CGFloat(-M_PI/2.0), 1, 0, 0)
        let rotSideMat = SCNMatrix4MakeRotation(CGFloat(-M_PI/2.0), 0, 1, 0)
        var cTransform = cPlatformNode.transform
        cTransform = SCNMatrix4Mult(cTransform, rotFlatMat)
        cTransform = SCNMatrix4Mult(cTransform, rotSideMat)
        cPlatformNode.transform = cTransform
        cPlatformNode.position = SCNVector3(x: 0, y: 2.0, z: -10 - 3.36 - 1.5)
        cPlatformGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(cPlatformNode)
        
        // ramp&platform physics
        setupCollisionNode(rRampNode)
        setupCollisionNode(lRampNode)
        setupCollisionNode(rPlatformNode)
        setupCollisionNode(lPlatformNode)
        setupCollisionNode(cPlatformNode)
        
        // wall
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = NSColor.yellowColor()
        wallMaterial.doubleSided = true
        
        
        // wall -- plane
//        let wallGeometry = SCNPlane(width: 5, height: 5)
//        wallGeometry.materials = [platformMaterial]
//        let wallNode = SCNNode(geometry: wallGeometry)
//        wallNode.name = "Wall node"
//        wallNode.position = SCNVector3(x: 5, y: 2.5, z: 5)
//        scene.rootNode.addChildNode(wallNode)
        
        // wall -- box
        let wallGeometry = SCNBox(width: 5, height: 5, length: 1, chamferRadius: 0)
        wallGeometry.materials = [wallMaterial]
        let wallNode = SCNNode(geometry: wallGeometry)
        wallNode.name = "Wall node"
        wallNode.position = SCNVector3(x: 0, y: 2.5, z: 5)
        scene.rootNode.addChildNode(wallNode)
        
        setupCollisionNode(wallNode)
    }
    
    func setupCollisionNode(node: SCNNode) {
        node.physicsBody = SCNPhysicsBody.staticBody()
        //node.physicsBody?.physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
        
        node.physicsBody?.categoryBitMask = CollisionCategory.Wall.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
        node.physicsBody?.contactTestBitMask = CollisionCategory.Character.rawValue
        
        // From Apple's "Fox" example (WWDC 2015) AAPLGameViewController.m:~188
        // "Temporary workaround because concave shape created from geometry instead of node fails"
        
//        let child = SCNNode()
//        node.addChildNode(child)
//        child.hidden = true
//        child.geometry = node.geometry
//        node.geometry = nil
//        node.hidden = false
//        
//        for(SCNNode *child in node.childNodes) {
//            if (child.hidden == NO) {
//                [self setupCollisionNodes:child];
//            }
//        }
    }
    
    /*****************************************************************************************************/
    // MARK:   SCNProgramDelegate
    /*****************************************************************************************************/
    
    @objc public func program(program: SCNProgram, handleError error: NSError) {
        NSLog("program(%@, handleError: %@", program, error)
    }
    
//    func program(program: SCNProgram, bindValueForSymbol symbol: String, atLocation location: UInt32, programID: UInt32, renderer: SCNRenderer) -> Bool {
//        NSLog("program(program: %@, bindValueForSymbol: %@, atLocation: %d, programID: %d, renderer: %@", program, symbol, location, programID ,renderer)
//    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    init(scene: SCNScene) {
        self.scene = scene
        super.init()
        self.load()
    }
}
