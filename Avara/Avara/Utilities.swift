//
//  Utilities.swift
//  Avara
//
//  Created by Morgan Davis on 5/20/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation
import SceneKit


func ConfigureCamera(camera: SCNCamera, screenSize: CGSize, fov: Double) {
    // set FOV according to view aspect ratio
    let viewSize: CGSize = screenSize
    let ratio: CGFloat  = CGFloat(viewSize.height / viewSize.width)
    camera.xFov = fov
    let yFov = camera.xFov * Double(ratio)
    camera.yFov = yFov
}
