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
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    private     let inputManager =                  InputManager()
    private     var serverSimulationController:     ServerSimulationController?
    private     var clientSimulationController:     ClientSimulationController?
    
    /*****************************************************************************************************/
    // MARK:   NSApplicationDelegate
    /*****************************************************************************************************/
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        serverSimulationController = ServerSimulationController()
        serverSimulationController?.start()
        
        clientSimulationController = ClientSimulationController(inputManager: inputManager)
        clientSimulationController?.play()
        
    }
}
