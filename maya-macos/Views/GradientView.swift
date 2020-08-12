//
//  GradientView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 8/11/20.
//  Copyright © 2020 KK. All rights reserved.
//

import Cocoa

@IBDesignable
class GradientView: NSView {
    @IBInspectable var topColor: NSColor = NSColor.clear
    @IBInspectable var bottomColor: NSColor = NSColor.black

    override func draw(_ dirtyRect: NSRect) {
        if (layer?.sublayers?.first as? CAGradientLayer) != nil {
            layer?.sublayers?.first?.removeFromSuperlayer()
        }
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(origin: CGPoint.zero, size: self.bounds.size)
        gradient.colors = [bottomColor.cgColor, topColor.cgColor]
//        gradient.startPoint = CGPoint(x: 1, y: 0)
//        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.zPosition = -1

        layer?.insertSublayer(gradient, at: 0)
    }
}
