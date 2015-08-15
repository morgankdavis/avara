
//  ClientWindowController.swift
//  Avara
//
//  Created by Morgan Davis on 2/27/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import AppKit
import SceneKit


public class ClientWindowController: NSWindowController, NSWindowDelegate {

    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private         var clientSimulationController:     ClientSimulationController
    private         let inputManager:                   InputManager
    private(set)    var renderView:                     RenderView?
    private(set)    var isCursorCaptured =              false
    private         var scene:                          SCNScene
    private         var stashedCursorPoint =            CGPointZero
    private         var lastCursorPoint =               CGPointZero
    
    /*****************************************************************************************************/
    // MARK:   Public
    /*****************************************************************************************************/
    
    public func captureCursor() {
        NSLog("captureCursor()")
        
        if isCursorCaptured == false {
            isCursorCaptured = true
            stashCursor()
            self.window?.acceptsMouseMovedEvents = true
            if DIRECT_MOUSE_ENABLED {
                inputManager.startDirectMouseCapture()
            }
        }
    }
    
    public func uncaptureCursor() {
        NSLog("uncaptureCursor()")
        
        if isCursorCaptured {
            isCursorCaptured = false
            self.window?.acceptsMouseMovedEvents = false
            restoreCursor()
            if DIRECT_MOUSE_ENABLED {
                inputManager.stopDirectMouseCapture()
            }
        }
    }
    
    public func toggleIsCursorCaptured() {
        if isCursorCaptured == true {
            uncaptureCursor()
        } else {
            captureCursor()
        }
    }
    
    /*****************************************************************************************************/
    // MARK:   Private
    /*****************************************************************************************************/
    
    private func stashCursor() {
        NSLog("stashCursor()")
        
        // remember the cursor point so we can restore it on exit
        let currentEvent = CGEventCreate(nil)!
        let point = CGEventGetLocation(currentEvent)
        stashedCursorPoint = point
        
        var err: CGError = CGDisplayHideCursor(0) // NSCursor.hide()
        if (err != .Success) {
            NSLog("Error hiding cursor: %d", err.rawValue)
        }
        
        let screenSize: CGSize = CGSize(width: CGDisplayPixelsWide(0), height: CGDisplayPixelsHigh(0))
        let screenMid: CGPoint  = CGPointMake(screenSize.width/2.0, screenSize.height/2.0)
        err = CGDisplayMoveCursorToPoint(0, screenMid) // CGWarpMouseCursorPosition(screenMid)
        if (err != .Success) {
            NSLog("Error warping cursor: %d", err.rawValue)
        }
        
        lastCursorPoint = CGPointZero
    }
    
    private func restoreCursor() {
        NSLog("restoreCursor()")
        
        var err: CGError = CGDisplayMoveCursorToPoint(0, stashedCursorPoint) // CGWarpMouseCursorPosition(screenMid)
        if (err != .Success) {
            NSLog("Error warping cursor: %d", err.rawValue)
        }
        
        err = CGDisplayShowCursor(0)
        if (err != .Success) {
            NSLog("Error showing cursor: %d", err.rawValue)
        }
    }
    
    private func setup() {
        NSLog("GameViewController.setup()")
        
        renderView = RenderView(frame: CGRect(origin: CGPointZero, size: CLIENT_WINDOW_SIZE) as NSRect)
        renderView?.scene = scene
        renderView?.allowsCameraControl = false
        renderView?.showsStatistics = true
        renderView?.debugOptions = SCN_DEBUG_OPTIONS
        // WARNING: Temporary
        if (NSProcessInfo.processInfo().hostName == "goosebox.local") {
            renderView?.antialiasingMode = .Multisampling16X
        } else {
            renderView?.antialiasingMode = .None
        }
        renderView?.backgroundColor = NSColor.blackColor()
        renderView?.delegate = clientSimulationController
        window?.contentView.addSubview(renderView!)
        window?.title = "Avara"
        window?.delegate = self
        window?.center()
    }
    
    /*****************************************************************************************************/
    // MARK:   NSWindowDelegate
    /*****************************************************************************************************/
    
    // !! These are not being called for some reason...
    
    public func windowDidBecomeKey(notification: NSNotification) {
        NSLog("windowDidBecomeKey()")
        captureCursor()
    }
    
    public func windowWillClose(notification: NSNotification) {
        NSLog("windowWillClose()")
        uncaptureCursor()
    }

    /*****************************************************************************************************/
    // MARK:   NSResponder
    /*****************************************************************************************************/
    
    override public func mouseMoved(theEvent: NSEvent) {
        // this method originally existed for mouse input. then we switched to ManyMouse for input.
        // but this method is still here to keep the captured cursor "under" the game window to is doesnt interfere with other things.
        
        let loc: NSPoint = NSEvent.mouseLocation()
        
        let screenSize: CGSize = CGSizeMake(CGFloat(CGDisplayPixelsWide(0)), CGFloat(CGDisplayPixelsHigh(0)))
        let screenMid: CGPoint = CGPointMake(screenSize.width/2.0, screenSize.height/2.0)
        let locRelOrigin: CGPoint = CGPointMake(loc.x-screenMid.x, loc.y-screenMid.y)
        let delta: CGPoint = CGPointMake(lastCursorPoint.x-locRelOrigin.x, lastCursorPoint.y-locRelOrigin.y)
        
        if !DIRECT_MOUSE_ENABLED {
            inputManager.addMouseDelta(delta)
        }
        
        // if the distance from the origin (center of window) gets too big, reset the cursor to the middle
        let distanceThr: CGFloat = 32.0
        let distance = sqrt(CGFloat(pow(locRelOrigin.x, 2)) + CGFloat(pow(locRelOrigin.y, 2)))
        
        if (distance > distanceThr) {
            let err: CGError = CGDisplayMoveCursorToPoint(0, screenMid) // CGWarpMouseCursorPosition(screenMid)
            if (err != .Success) {
                NSLog("Error warping cursor: %d", err.rawValue)
            }
            CGAssociateMouseAndMouseCursorPosition(1) // if this isn't called new mouse events are ignored for about 200ms
            lastCursorPoint = CGPointZero
        }
        else {
            lastCursorPoint = locRelOrigin
        }
    }
    
    override public func keyDown(theEvent: NSEvent) {
        inputManager.updateKeyCode(theEvent.keyCode, pressed: true)
    }
    
    override public func keyUp(theEvent: NSEvent) {
        inputManager.updateKeyCode(theEvent.keyCode, pressed: false)
    }
    
    /*****************************************************************************************************/
    // MARK:   NSWindowController
    /*****************************************************************************************************/
    
    required public init(clientSimulationController: ClientSimulationController) {
        let newWindow = NSWindow(
            contentRect: CGRect(origin: CGPointZero, size: CLIENT_WINDOW_SIZE) as NSRect,
            styleMask: (NSTitledWindowMask | NSMiniaturizableWindowMask),
            backing: .Buffered,
            `defer`: false)
        self.clientSimulationController = clientSimulationController
        self.inputManager = clientSimulationController.inputManager
        self.scene = clientSimulationController.scene
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

