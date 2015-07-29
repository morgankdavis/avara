//
//  AppDelegate.swift
//  Avara
//
//  Created by Morgan Davis on 7/25/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private     let inputManager =                  InputManager()
    private     var serverSimulationController:     ServerSimulationController?
    private     var clientSimulationController:     ClientSimulationController?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        serverSimulationController = ServerSimulationController()
        
//        clientSimulationController = ClientSimulationController(inputManager: inputManager)
//        clientSimulationController?.play()
    }
}
