//
//  Utilities.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 7/17/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

func +(lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func -(lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

