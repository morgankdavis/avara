//
//  Types.swift
//  Avara
//
//  Created by Morgan Davis on 11/26/15.
//  Copyright © 2015 Morgan K Davis. All rights reserved.
//

import Foundation
#if os(OSX)
    import AppKit
#else
    import UIKit
#endif


#if os(OSX)
    public typealias MKDFloat = CGFloat
    public typealias MKDColor = NSColor
    public typealias MKDImage = NSImage
#else
    public typealias MKDFloat = Float
    public typealias MKDColor = UIColor
    public typealias MKDImage = UIImage
#endif

