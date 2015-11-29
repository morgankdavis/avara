//
//  Map.swift
//  Avara
//
//  Created by Morgan Davis on 5/12/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit

import AVFoundation


public class Map : NSObject, SCNProgramDelegate {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private     var scene:                  SCNScene
    
    
    
    private     let VIDEO_TEX_ENABLED =     true
    private     var previewLayer:           AVCaptureVideoPreviewLayer?
    
    
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
        scene.fogColor = MKDColor.lightGrayColor()
        
        // sky
//        scene.background.contents = [
//            MKDImage(named: "sky_miramar_0.png")!,
//            MKDImage(named: "sky_miramar_1.png")!,
//            MKDImage(named: "sky_miramar_2.png")!,
//            MKDImage(named: "sky_miramar_3.png")!,
//            MKDImage(named: "sky_miramar_4.png")!,
//            MKDImage(named: "sky_miramar_5.png")!]
        
        let sky = MDLSkyCubeTexture(name: nil,
            channelEncoding: MDLTextureChannelEncoding.UInt8,
            textureDimensions: [Int32(320), Int32(320)],
            turbidity: 0.25,
            sunElevation: 0.85,
            upperAtmosphereScattering: 0.55,
            groundAlbedo: 0.85)
        scene.background.contents = sky.imageFromTexture()?.takeUnretainedValue()

        
        // WARNING: Temporary
        if (NSProcessInfo.processInfo().hostName == "goosebox.local") {
            scene.background.maxAnisotropy = 16.0
        }
        else {
            scene.background.maxAnisotropy = 2.0
        }
        scene.background.mipFilter = .Linear
		
        
        // ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = MKDColor(white: 0.25, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
//        // omni light
//        let omniLight = SCNLight()
//        omniLight.type = SCNLightTypeOmni
//        omniLight.color = MKDColor(white: 0.75, alpha: 1.0)
//        let omniLightNode = SCNNode()
//        omniLightNode.light = omniLight
//        omniLightNode.position = SCNVector3Make(40, 25, 50)
//        scene.rootNode.addChildNode(omniLightNode)
        
        // spot light
        let spotLight = SCNLight()
        spotLight.type = SCNLightTypeSpot
        spotLight.color = MKDColor(white: 1.0, alpha: 1.0)
        let spotLightNode = SCNNode()
        spotLightNode.light = spotLight
        let spotlightPosition = SCNVector3Make(130, 300, -150)
        //let spotlightPosition = SCNVector3Make(30, 40, -30)
        spotLightNode.position = spotlightPosition

        spotLight.castsShadow = true
        spotLightNode.castsShadow = true
        spotLight.shadowColor = MKDColor.blackColor()
        spotLight.spotOuterAngle = 35.0
        //spotLight.shadowRadius = 1.0
        spotLight.shadowMapSize = CGSizeMake(1*1024, 1*1024)
        spotLight.shadowSampleCount = 4
        spotLight.shadowMode = .Forward
//        spotLight.shadowBias = 0.1
        spotLight.zFar = 1000
        spotLight.zNear = 0.1
        
        let centerCode = SCNNode()
        centerCode.position = SCNVector3Zero
        scene.rootNode.addChildNode(centerCode)
        
        spotLightNode.constraints = [SCNLookAtConstraint(target: centerCode)]
        scene.rootNode.addChildNode(spotLightNode)

        // floor node
        let floor = SCNPlane(width: 40, height: 40)
        floor.name = "Floor"
        let floorNode = SCNNode(geometry: floor)
        floorNode.rotation = SCNVector4Make(1, 0, 0, -MKDFloat(M_PI)/2.0)
        scene.rootNode.addChildNode(floorNode)

        let floorMaterial = SCNMaterial()
        //floorMaterial.diffuse.contents = MKDColor.grayColor()
        floorMaterial.ambient.contents = MKDColor.blackColor()
        floorMaterial.specular.contents = MKDColor(white: 0.15, alpha: 1.0)
        floorMaterial.diffuse.contents = MKDImage(named: "grid_diffuse.png")
        
        let floorScale = floor.width/1.0
        floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(floorScale, floorScale, floorScale)
        floorMaterial.diffuse.intensity = 1.0
        floorMaterial.diffuse.mipFilter = .Linear
        floorMaterial.diffuse.maxAnisotropy = 16.0
        floorMaterial.diffuse.wrapS  = .Repeat
        floorMaterial.diffuse.wrapT  = .Repeat
        
        floorMaterial.locksAmbientWithDiffuse = true
        
        floor.firstMaterial = floorMaterial
        
        // map physics
        floorNode.physicsBody = SCNPhysicsBody.staticBody()
        
        floorNode.physicsBody?.categoryBitMask = CollisionCategory.Floor.rawValue
        floorNode.physicsBody?.collisionBitMask = 0
        floorNode.physicsBody?.contactTestBitMask = 0
        //floorNode.physicsBody!.categoryBitMask = CollisionCategory.Map.rawValue
        scene.rootNode.addChildNode(floorNode)
        
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = MKDColor.redColor()
//        boxMaterial.normal.contents = MKDImage(named: "needlepointSteel_normal.png")
//        boxMaterial.normal.intensity = 1.0
        
        
        // boxes
        let BOX_SIZE = 2.0
        let BOX_Y = BOX_SIZE / 2.0
        
        let boxGeometry = SCNBox(width: CGFloat(BOX_SIZE), height: CGFloat(BOX_SIZE), length: CGFloat(BOX_SIZE), chamferRadius: 0)
        boxGeometry.materials = [boxMaterial]
        
        let box1Node = SCNNode(geometry: SCNBox(width: CGFloat(BOX_SIZE), height: CGFloat(BOX_SIZE), length: CGFloat(BOX_SIZE), chamferRadius: 0))
        box1Node.geometry?.materials = [boxMaterial]
        box1Node.position = SCNVector3Make(-10, MKDFloat(BOX_Y), 10)
        box1Node.name = "Box node 1"
        scene.rootNode.addChildNode(box1Node)
        
        let box2Node = SCNNode(geometry: SCNBox(width: CGFloat(BOX_SIZE), height: CGFloat(BOX_SIZE), length: CGFloat(BOX_SIZE), chamferRadius: 0))
        box2Node.geometry?.materials = [boxMaterial]
        box2Node.position = SCNVector3Make(10, MKDFloat(BOX_Y), 10)
        box2Node.name = "Box node 2"
        scene.rootNode.addChildNode(box2Node)

        // box physics
        box1Node.physicsBody = SCNPhysicsBody.dynamicBody()
        box1Node.physicsBody?.friction = 0.25 // default is .5
        box1Node.physicsBody?.rollingFriction = 0.25
        //box1Node.physicsBody?.angularVelocityFactor = SCNVector3(x: 0, y: 0, z: 0)
        box1Node.physicsBody?.categoryBitMask = CollisionCategory.Movable.rawValue
        box1Node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
        //box1Node.physicsBody?.contactTestBitMask = CollisionCategory.Character.rawValue

        box2Node.physicsBody = SCNPhysicsBody.dynamicBody()
        box2Node.physicsBody?.friction = 0.25 // default is .5
        box2Node.physicsBody?.rollingFriction = 0.25
        //box1Node.physicsBody?.angularVelocityFactor = SCNVector3(x: 0, y: 0, z: 0)
        box2Node.physicsBody?.categoryBitMask = CollisionCategory.Movable.rawValue
        box2Node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
        //box2Node.physicsBody?.contactTestBitMask = CollisionCategory.Character.rawValue
        
        // platform
        
        let platformMaterial = SCNMaterial()
        platformMaterial.diffuse.contents = MKDColor.yellowColor()
        platformMaterial.doubleSided = true
        
        let rRampGeometry = SCNPlane(width: 2, height: 4)
        let rRampNode = SCNNode(geometry: rRampGeometry)
        rRampNode.name = "R Ramp"
        rRampNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: MKDFloat(-M_PI/3.0))
        rRampNode.position = SCNVector3(x: 10, y: 1, z: -9.125)
        rRampGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(rRampNode)
        
        let lRampGeometry = SCNPlane(width: 2, height: 4)
        let lRampNode = SCNNode(geometry: lRampGeometry)
        lRampNode.name = "L Ramp"
        lRampNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: MKDFloat(-M_PI/3.0))
        lRampNode.position = SCNVector3(x: -10, y: 1, z: -9.125)
        lRampGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(lRampNode)
        
        let rPlatformGeometry = SCNPlane(width: 2, height: 5)
        let rPlatformNode = SCNNode(geometry: rPlatformGeometry)
        rPlatformNode.name = "R Platform"
        rPlatformNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: MKDFloat(-M_PI/2.0))
        rPlatformNode.position = SCNVector3(x: 10, y: 2.0, z: -10 - 3.36)
        rPlatformGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(rPlatformNode)
        
        let lPlatformGeometry = SCNPlane(width: 2, height: 5)
        let lPlatformNode = SCNNode(geometry: lPlatformGeometry)
        lPlatformNode.name = "L Platform"
        lPlatformNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: MKDFloat(-M_PI/2.0))
        lPlatformNode.position = SCNVector3(x: -10, y: 2.0, z: -10 - 3.36)
        lPlatformGeometry.materials = [platformMaterial]
        scene.rootNode.addChildNode(lPlatformNode)
        
        let cPlatformGeometry = SCNPlane(width: 2, height: 18)
        let cPlatformNode = SCNNode(geometry: cPlatformGeometry)
        cPlatformNode.name = "C Platform"
        let rotFlatMat = SCNMatrix4MakeRotation(MKDFloat(-M_PI/2.0), 1, 0, 0)
        let rotSideMat = SCNMatrix4MakeRotation(MKDFloat(-M_PI/2.0), 0, 1, 0)
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
        let wallGeometry = SCNPlane(width: 5, height: 5)
        wallGeometry.materials = [platformMaterial]
        let wallNode = SCNNode(geometry: wallGeometry)
        wallNode.name = "Wall node"
        wallNode.position = SCNVector3(x: 0, y: 2.5, z: 5)
        scene.rootNode.addChildNode(wallNode)
        
        setupCollisionNode(wallNode)
        
        
        if VIDEO_TEX_ENABLED {
            let captureSession = AVCaptureSession()
            if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
                do {
                    let videoIn = try AVCaptureDeviceInput(device: videoDevice)
                    if (captureSession.canAddInput(videoIn as AVCaptureInput)){
                        captureSession.addInput(videoIn as AVCaptureDeviceInput)
                    }
                }
                catch {
                    NSLog("Exception")
                }
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = CGRectMake(0, 0, 320, 320);
            previewLayer?.videoGravity = AVLayerVideoGravityResize
            previewLayer?.contentsGravity = kCAGravityResizeAspectFill
            
            let videoMaterial = SCNMaterial()
            videoMaterial.doubleSided = true
            videoMaterial.diffuse.contents = previewLayer!
            
            wallGeometry.materials = [videoMaterial]
            
            box1Node.geometry?.materials = [videoMaterial]
            box2Node.geometry?.materials = [videoMaterial]
            
            captureSession.startRunning()
        }
        
        
        // LINE
        
//        let verticies: [SCNVector3] = [
//            SCNVector3Make(0, 0, -2),
//            SCNVector3Make(0, 0, 2)]
//
//        let indices: [CInt] = [0, 1]
//        
//        let vertexSource = SCNGeometrySource(vertices: verticies, count: 2)
//        let indexData = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
//        
//        let element = SCNGeometryElement(data: indexData, primitiveType: .Line, primitiveCount: 1, bytesPerIndex: sizeof(CInt))
//        let line = SCNGeometry(sources: [vertexSource], elements: [element])
//        
//        let material = SCNMaterial()
//        material.diffuse.contents = MKDColor.redColor()
//        material.lightingModelName = SCNLightingModelConstant
//        line.materials = [material]
//
//        let lineNode = SCNNode(geometry: line)
//        scene.rootNode.addChildNode(lineNode)
        
        
        
        
//        let positions: [Float32] = [
//            Float32(0), Float32(0), Float32(0),
//            Float32(0), Float32(5), Float32(-5)]
//        let positionData = NSData(bytes: positions, length: sizeof(Float32)*positions.count)
//        let indices: [Int32] = [0, 1]
//        let indexData = NSData(bytes: indices, length: sizeof(Int32) * indices.count)
//        
//        let source = SCNGeometrySource(
//            data: positionData,
//            semantic: SCNGeometrySourceSemanticVertex,
//            vectorCount: indices.count,
//            floatComponents: true,
//            componentsPerVector: 3,
//            bytesPerComponent: sizeof(Float32),
//            dataOffset: 0,
//            dataStride: sizeof(Float32) * 3)
//        
//        let element = SCNGeometryElement(
//            data: indexData,
//            primitiveType: .Line,
//            primitiveCount: indices.count,
//            bytesPerIndex: sizeof(Int32))
//        
//        let line = SCNGeometry(sources: [source], elements: [element])
//        
////        let material = SCNMaterial()
////        material.diffuse.contents = MKDColor.redColor()
////        material.lightingModelName = SCNLightingModelConstant
////        line.materials = [material]
//        
//        let lineNode = SCNNode(geometry: line)
//        scene.rootNode.addChildNode(lineNode)
    }
    
    func setupCollisionNode(node: SCNNode) {
        node.physicsBody = SCNPhysicsBody.staticBody()
        //node.physicsBody?.physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
        
        node.physicsBody?.categoryBitMask = CollisionCategory.Wall.rawValue
        //node.physicsBody?.collisionBitMask = CollisionCategory.Character.rawValue
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
        
        
//        for n in scene.rootNode.childNodes {
//            NSLog("NODE: %@", n)
//            if let name = n.name {
//                NSLog("NAME: %@", name)
//            }
//            if let g = n.geometry {
//                NSLog("GEO: %@", g)
//            }
//            NSLog("----")
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
