//
//  PhotoProvider.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/20/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

protocol PhotoProvider {
    func nextImage() -> NSImage
}
