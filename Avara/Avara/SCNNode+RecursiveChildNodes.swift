//
//  SCNNode+RecursiveChildNodes.swift
//  Avara
//
//  Created by Morgan Davis on 11/5/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//


// 15/11/05: Was causing weird crashing in unrelated areas

//import Foundation
//import SceneKit
//
//
//extension SCNNode {
//    public func childNodesRecursive() -> [SCNNode] {
//        var result = [self]
//        if self.childNodes.count > 0 {
//            for child in self.childNodes {
//                result.appendContentsOf(child.childNodesRecursive())
//            }
//        }
//        return result
//    }
//}
