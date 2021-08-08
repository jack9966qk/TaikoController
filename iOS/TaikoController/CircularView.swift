//
//  UICircularView.swift
//  TaikoController
//
//  Created by Jack on 24/11/2016.
//  Copyright © 2016 Jack. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class CircularView : AnimatedView {
    
    @IBInspectable var flip : Bool = false
    @IBInspectable var name : String = "CircularView"
    @IBInspectable var strokeColor : UIColor = UIColor.black
    
    var path: UIBezierPath {
        let rect = self.bounds
        let startAngle: CGFloat = 0.0
        let endAngle: CGFloat = CGFloat(Double.pi * 4)

        let arcCenter = flip
            ? CGPoint(x: rect.maxX, y:rect.maxY/2)
            : CGPoint(x: rect.minX, y:rect.maxY/2)
        return UIBezierPath(
            arcCenter: arcCenter,
            radius: rect.maxX - rect.minX,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
    }
    
    public func setupLayer() {
        self.layer.sublayers = nil
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = self.bounds
        shapeLayer.path = self.path.cgPath

        self.layer.mask = shapeLayer
        
        let strokeLayer = CAShapeLayer()
        strokeLayer.path = self.path.cgPath
        strokeLayer.strokeColor = strokeColor.cgColor
        strokeLayer.lineWidth = 3.0
        strokeLayer.fillColor = UIColor.clear.cgColor
        
        self.layer.addSublayer(strokeLayer)
    }

    override func layoutSubviews() {
        self.setupLayer()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return path.contains(point) && self.layer.contains(point)
    }
}
