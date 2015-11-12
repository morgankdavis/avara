//
//  ServerWindowController.swift
//  Avara
//
//  Created by Morgan Davis on 7/29/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import AppKit
import SceneKit


public class ServerWindowController: NSWindowController {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private         var serverSimulationController:     ServerSimulationController
    private         var scene:                          SCNScene
    private(set)    var renderView:                     RenderView?
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func setup() {
        NSLog("GameViewController.setup()")
        
        renderView = RenderView(frame: CGRect(origin: CGPointZero, size: SERVER_WINDOW_SIZE) as NSRect)
        NSLog("scene: %@", scene)
        renderView?.scene = scene
        renderView?.allowsCameraControl = true
        renderView?.showsStatistics = true
        renderView?.debugOptions = SCN_DEBUG_OPTIONS
        renderView?.antialiasingMode = .None
        renderView?.backgroundColor = NSColor.blackColor()
        renderView?.delegate = serverSimulationController
        window?.contentView?.addSubview(renderView!)
        window?.title = "Avara Server"
        
        if let screen = NSScreen.mainScreen() {
            let screenSize = screen.visibleFrame
            let originPoint = CGPoint(x: 0, y: screenSize.height - SERVER_WINDOW_SIZE.height/CGFloat(2.0))
            window?.setFrameOrigin(originPoint)
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   NSWindowController
    /*****************************************************************************************************/
    
    required public init(serverSimulationController: ServerSimulationController) {
        let newWindow = NSWindow(
            contentRect: CGRect(origin: CGPointZero, size: SERVER_WINDOW_SIZE) as NSRect,
            styleMask: (NSTitledWindowMask | NSMiniaturizableWindowMask),
            backing: .Buffered,
            `defer`: false)
        self.serverSimulationController = serverSimulationController
        self.scene = serverSimulationController.scene
        super.init(window: newWindow)
        setup()
    }
    
    /*****************************************************************************************************/
    // MARK:   NSCoder
    /*****************************************************************************************************/
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}