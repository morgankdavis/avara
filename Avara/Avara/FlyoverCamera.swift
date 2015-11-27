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
    
    private         let MOVE_RATE =                 MKDFloat(10.0)                // units/sec
    private         let VERT_CLAMP =                MKDFloat(M_PI/2.0)
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          let node =                      SCNNode()
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func updateForInputs(pressedButtons: [ButtonInput : MKDFloat], dT: MKDFloat, lookDelta: CGPoint) {
        
        let transform = node.transform
        
        if pressedButtons.keys.contains(.MoveForward) {
            let force = pressedButtons[.MoveForward]!
            let positionDelta = MOVE_RATE * dT * force
            
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
        if pressedButtons.keys.contains(.MoveBackward) {
            let force = pressedButtons[.MoveBackward]!
            let positionDelta = MOVE_RATE * dT * force
            
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
        if pressedButtons.keys.contains(.TurnLeft) {
            let force = pressedButtons[.TurnLeft]!
            let positionDelta = MOVE_RATE * dT * force
            
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
        if pressedButtons.keys.contains(.TurnRight) {
            let force = pressedButtons[.TurnRight]!
            let positionDelta = MOVE_RATE * dT * force
            
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
        if pressedButtons.keys.contains(.Jump) {
            let force = pressedButtons[.Jump]!
            let positionDelta = MOVE_RATE * dT * force
            
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
        
        // look
        
        #if os(OSX)
            let viewDistanceFactor = 1.0/(MOUSELOOK_SENSITIVITY*MOUSELOOK_SENSITIVITY_MULTIPLIER)
        #else
            let viewDistanceFactor = 1.0/(THUMBLOOK_SENSITIVITY*THUMBLOOK_SENSITIVITY_MULTIPLIER)
        #endif
        
        let dP = acos(CGFloat(lookDelta.x) / viewDistanceFactor) - CGFloat(M_PI_2)
        let dY = acos(CGFloat(lookDelta.y) / viewDistanceFactor) - CGFloat(M_PI_2)
        
        var nAngles = SCNVector3(
            x: node.eulerAngles.x + MKDFloat(dY),
            y: node.eulerAngles.y - MKDFloat(dP),
            z: node.eulerAngles.z)

        nAngles.x = max(-MKDFloat(VERT_CLAMP), min(MKDFloat(VERT_CLAMP), nAngles.x)) // clamp vertical angle
        
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
