//
//  Array+RemoveObject.swift
//  Avara
//
//  Created by Morgan Davis on 11/5/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation


//extension Array {
//    mutating func remove<T>(object:T) -> Bool {
//        if let index = find(self, object) {
//            self.removeAtIndex(index)
//            return true
//        }
//        return false
//    }
//}


//extension Array {
//    mutating func removeObject<U: Equatable>(object: U) {
//        var index: Int?
//        for (idx, objectToCompare) in enumerate(self) {
//            if let to = objectToCompare as? U {
//                if object == to {
//                    index = idx
//                }
//            }
//        }
//        
//        if(index) {
//            self.removeAtIndex(index!)
//        }
//    }
//}

//extension Array {
//    func contains<T:AnyObject>(item:T) -> Bool {
//        for element in self {
//            if item === element as? T {
//                return true
//            }
//        }
//        return false
//    }
//}
