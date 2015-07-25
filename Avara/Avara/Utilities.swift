//
//  Utilities.swift
//  Avara
//
//  Created by Morgan Davis on 5/20/15.
//  Copyright (c) 2015 goosesensor. All rights reserved.
//

import Foundation
import SceneKit


func ConfigureCamera(camera: SCNCamera, fov: Double) {
    // set FOV according to view aspect ratio
    let viewSize: CGSize = WINDOW_SIZE
    let ratio: CGFloat  = CGFloat(viewSize.height / viewSize.width)
    camera.xFov = fov
    let yFov = camera.xFov * Double(ratio)
    camera.yFov = yFov
}
