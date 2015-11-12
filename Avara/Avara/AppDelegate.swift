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
        clientSimulationController = ClientSimulationController(inputManager: inputManager)
        
        if SERVER_VIEW_ENABLED {
            let serverWindowController = ServerWindowController(serverSimulationController: serverSimulationController!)
            serverSimulationController!.windowController = serverWindowController
            serverWindowController.showWindow(self)
        }
        
        let clientWindowController = ClientWindowController(clientSimulationController: clientSimulationController!)
        clientSimulationController!.windowController = clientWindowController
        clientWindowController.showWindow(self)
        
        serverSimulationController?.start()
        clientSimulationController?.play()
    }
}
