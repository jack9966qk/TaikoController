//
//  UIAnimatedView.swift
//  TaikoController
//
//  Created by Jack on 8/1/2017.
//  Copyright © 2017 Jack. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class AnimatedView : UIView {
    @IBInspectable var idleColor: UIColor = UIColor.clear
    @IBInspectable var activeColor: UIColor = UIColor.blue
    @IBInspectable var totalDurationInSeconds: Double = 0.15
    @IBInspectable var fillRelativeDuration: Double = 0.2
    @IBInspectable var fadeRalativeDuration: Double = 0.8
    
    public func animateToTap() {
        self.layer.removeAllAnimations()
        UIView.animateKeyframes(withDuration: totalDurationInSeconds,
                                delay: 0,
                                options: .allowUserInteraction,
                                animations: {
            UIView.addKeyframe(withRelativeStartTime: 0,
                               relativeDuration: self.fillRelativeDuration) {
                self.setColor(self.activeColor)
            }
            UIView.addKeyframe(withRelativeStartTime: self.fillRelativeDuration,
                               relativeDuration: self.fadeRalativeDuration) {
                self.setColor(self.idleColor)
            }
        }, completion: nil)
    }
    
    public func setColor(_ color: UIColor) {
        self.backgroundColor = color
    }
}
