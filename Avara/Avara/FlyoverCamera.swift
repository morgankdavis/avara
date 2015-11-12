//
//  FlyoverCamera.swift
//  Avara
//
//  Created by Morgan Davis on 5/21/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


public class FlyoverCamera {
    
    /*****************************************************************************************************/
    // MARK:   Types
    /*****************************************************************************************************/
    
    private         let MOVE_RATE =                 Double(10.0)                // units/sec
    private         let VERT_CLAMP =                Double(M_PI/2.0)
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          let node =                      SCNNode()
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func gameLoopWithInputs(inputs: Set<ButtonInput>, mouseDelta: CGPoint, dT: Double) {
        // keys
        let positionDelta = MOVE_RATE * dT
        let transform = node.transform
        
        if inputs.contains(.MoveForward) {
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            let sinXRot = transform.m32
            
            let dx = MKDFloat(positionDelta) * sinYRot
            let dy = MKDFloat(positionDelta) * sinXRot
            let dz = MKDFloat(positionDelta) * cosYRot
            
            node.position = SCNVector3(
                x: node.position.x + dx,
                y: node.position.y - dy,
                z: node.position.z - dz)
        }
        if inputs.contains(.MoveBackward) {
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            let sinXRot = transform.m32
            
            let dx = MKDFloat(positionDelta) * sinYRot
            let dy = MKDFloat(positionDelta) * sinXRot
            let dz = MKDFloat(positionDelta) * cosYRot
            
            node.position = SCNVector3(
                x: node.position.x - dx,
                y: node.position.y + dy,
                z: node.position.z + dz)
        }
        
        if inputs.contains(.TurnLeft) { // move left
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = MKDFloat(positionDelta) * sinYRot
            let dz = MKDFloat(positionDelta) * cosYRot
            
            // take the cross product with a unit Y vector, should point out an orthogonal vector (right or left?)
            // scale the orthogonal vector to our distance and move!
            
            let orientationVector = SCNVector3(x: dx, y: 0, z: dz)
            let unitY = SCNVector3(x: 0, y: -1, z: 0)
            
            let crossVector: GLKVector3 = GLKVector3CrossProduct(SCNVector3ToGLKVector3(orientationVector), SCNVector3ToGLKVector3(unitY))
            let normCrossVector: GLKVector3 = GLKVector3Normalize(crossVector)
            let scaledVector: GLKVector3 = GLKVector3MultiplyScalar(normCrossVector, Float(positionDelta))
            
            node.position = SCNVector3(
                x: node.position.x - MKDFloat(scaledVector.x),
                y: node.position.y,
                z: node.position.z + MKDFloat(scaledVector.z))
        }
        if inputs.contains(.TurnRight) { // move right
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            
            let dx = MKDFloat(positionDelta) * sinYRot
            let dz = MKDFloat(positionDelta) * cosYRot
            
            // take the cross product with a unit Y vector, should point out an orthogonal vector (right or left?)
            // scale the orthogonal vector to our distance and move!
            
            let orientationVector = SCNVector3(x: dx, y: 0, z: dz)
            let unitY = SCNVector3(x: 0, y: 1, z: 0)
            
            let crossVector: GLKVector3 = GLKVector3CrossProduct(SCNVector3ToGLKVector3(orientationVector), SCNVector3ToGLKVector3(unitY))
            let normCrossVector: GLKVector3 = GLKVector3Normalize(crossVector)
            let scaledVector: GLKVector3 = GLKVector3MultiplyScalar(normCrossVector, Float(positionDelta))
            
            node.position = SCNVector3(
                x: node.position.x - MKDFloat(scaledVector.x),
                y: node.position.y,
                z: node.position.z + MKDFloat(scaledVector.z))
        }
        
        if inputs.contains(.Jump) { // move up
            let sinYRot = transform.m13
            let cosYRot = transform.m33
            let sinXRot = transform.m32
            
            let dx = MKDFloat(positionDelta) * sinYRot
            let dy = MKDFloat(positionDelta) * sinXRot
            let dz = MKDFloat(positionDelta) * cosYRot
            
            // take the cross product with a unit x vector, should point out an orthogonal vector (up or down?)
            // scale the orthogonal vector to our distance and move!
            
            let orientationVector = SCNVector3(x: dx, y: dy, z: dz)
            let unitX = SCNVector3(x: 1, y: 0, z: 0)
            
            let crossVector: GLKVector3 = GLKVector3CrossProduct(SCNVector3ToGLKVector3(orientationVector), SCNVector3ToGLKVector3(unitX))
            let normCrossVector: GLKVector3 = GLKVector3Normalize(crossVector)
            let scaledVector: GLKVector3 = GLKVector3MultiplyScalar(normCrossVector, Float(positionDelta))
            
            node.position = SCNVector3(
                x: node.position.x - MKDFloat(scaledVector.x),
                y: node.position.y + MKDFloat(abs(scaledVector.y)),
                z: node.position.z + MKDFloat(scaledVector.z))
        }
        
        // mouse
        let viewDistanceFactor = 1.0/(MOUSELOOK_SENSITIVITY*MOUSELOOK_SENSITIVITY_MULTIPLIER)
        
        let hAngle = acos(CGFloat(mouseDelta.x) / viewDistanceFactor) - CGFloat(M_PI_2)
        let vAngle = acos(CGFloat(mouseDelta.y) / viewDistanceFactor) - CGFloat(M_PI_2)
        
        var nAngles = SCNVector3(
            x: node.eulerAngles.x + MKDFloat(vAngle),
            y: node.eulerAngles.y - MKDFloat(hAngle),
            z: node.eulerAngles.z)
        
        nAngles.x = max(-MKDFloat(VERT_CLAMP), min(MKDFloat(VERT_CLAMP), nAngles.x)) // clamp angle to PI/4 < a < PI/4
        
        node.eulerAngles = nAngles
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    func setup() {
        let camera = SCNCamera()
        ConfigureCamera(camera, screenSize: CLIENT_WINDOW_SIZE, fov:90.0)
        camera.zNear = 0.1
        camera.zFar = 1000.0
        node.name = "Fly camera node"
        node.camera = camera
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    init() {
        setup()
    }
}
