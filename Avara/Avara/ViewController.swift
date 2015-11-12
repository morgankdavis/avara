//
//  ViewController.swift
//  Avara
//
//  Created by Morgan Davis on 11/7/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import UIKit
import SceneKit


public class ViewController: UIViewController {
    
    /*****************************************************************************************************/
    // MARK:   Properties
    /*****************************************************************************************************/
    
    public          var serverSimulationController:     ServerSimulationController? { didSet { serverScene = serverSimulationController?.scene } }
    public          var clientSimulationController:     ClientSimulationController? { didSet { clientScene = clientSimulationController?.scene } }
    private         var inputManager:                   InputManager?
    private(set)    var serverRenderView:               RenderView?
    private(set)    var clientRenderView:               SCNView?
    private         var serverScene:                    SCNScene?
    private         var clientScene:                    SCNScene?
    
    /*****************************************************************************************************/
     // MARK:   Public
     /*****************************************************************************************************/
    
    public func setup() {
        NSLog("ViewController.setup")
        
        // server stuff
        
//        serverRenderView = RenderView()
//        serverRenderView!.scene = serverScene
//        serverRenderView!.allowsCameraControl = false
//        serverRenderView!.showsStatistics = true
//        serverRenderView!.debugOptions = SCN_DEBUG_OPTIONS
//        serverRenderView!.antialiasingMode = .None
//        serverRenderView!.backgroundColor = MKDColor.blackColor()
//        serverRenderView!.delegate = serverSimulationController
//        view?.addSubview(serverRenderView!)
        
        // client stuff
        
        //clientRenderView = RenderView()
        //clientRenderView = SCNView(frame: UIScreen.mainScreen().nativeBounds)
        clientRenderView = SCNView(frame: UIScreen.mainScreen().bounds)
        clientRenderView!.scene = clientScene
        clientRenderView!.allowsCameraControl = false
        clientRenderView!.showsStatistics = true
        clientRenderView!.debugOptions = SCN_DEBUG_OPTIONS
        // WARNING: Temporary
        if (NSProcessInfo.processInfo().hostName == "goosebox.local") {
            clientRenderView!.antialiasingMode = .Multisampling4X
        } else {
            clientRenderView!.antialiasingMode = .None
        }
        clientRenderView!.backgroundColor = MKDColor.blackColor()
        clientRenderView!.delegate = clientSimulationController
        view?.addSubview(clientRenderView!)
    }

    /******************************************************************************************************
        MARK:   UIViewController
     ******************************************************************************************************/
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*****************************************************************************************************/
    // MARK:   Object
    /*****************************************************************************************************/
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.view = UIView(frame: CGRectZero)
    }
}

