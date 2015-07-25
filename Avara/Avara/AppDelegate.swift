//
//  AppDelegate.swift
//  Avara
//
//  Created by Morgan Davis on 7/25/15.
//  Copyright © 2015 goosesensor. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private     let inputManager =                  InputManager()
    private     var clientSimulationController:     ClientSimulationController?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        clientSimulationController = ClientSimulationController(inputManager: inputManager)
        clientSimulationController?.play()
    }
}
