//
//  AppDelegate.swift
//  Avara
//
//  Created by Morgan Davis on 7/25/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Cocoa
import SceneKit


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
        
        
//        let pos = SCNVector3(x: 0, y: 0, z: 0)
//        let bRot = SCNVector4(x: 0, y: 0, z: 0, w: -0.139626)
//        let hAng = SCNVector3(x: 0, y: 0, z: 0)
//
//        
//        let u = NetPlayerUpdate(sequenceNumber: 0, id: 0, position: pos, bodyRotation: bRot, headEulerAngles: hAng)
//        var us = [NetPlayerUpdate]()
//        us.append(u)
//        let mOut = ServerUpdateNetMessage(playerUpdates: us)
//        let pOut = mOut.encoded()
//        
//        
//        if let message = MessageFromPayloadData(pOut!) {
//            switch message.opcode {
//                
//            case .ServerUpdate:
//                let updateMessage = message as! ServerUpdateNetMessage
//                let uIn = updateMessage.playerUpdates[0]
//                NSLog("uIn: %@", uIn.description)
//                
//            default:
//                break
//            }
//        }
        
        
    }
}
