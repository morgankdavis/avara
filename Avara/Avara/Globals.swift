//
//  SharedConstants.swift
//  Avara
//
//  Created by Morgan Davis on 5/20/15.
//  Copyright (c) 2015 Morgan K Davis. All rights reserved.
//

import Foundation


/*****************************************************************************************************/
// MARK:   Types
/*****************************************************************************************************/

enum CollisionCategory: Int {
    case Character =    0b00000001
    case Wall =         0b00000010
    case Floor =        0b00000100
    case Movable =      0b00001000
}
