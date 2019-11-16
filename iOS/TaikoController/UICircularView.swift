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
class UICircularView : UIAnimatedView {
    
    @IBInspectable var flip : Bool = false
    @IBInspectable var name : String = "CircularView"
    @IBInspectable var strokeColor : UIColor = UIColor.black
    
    var shapeLayer = CAShapeLayer()
//    var path = UIBezierPath()
    
    var path: UIBezierPath {
        let rect = self.bounds
        let startAngle: CGFloat = 0.0
        let endAngle: CGFloat = CGFloat(M_PI * 4)

        if flip {
            return UIBezierPath(
                arcCenter: CGPoint(x: rect.maxX, y:rect.maxY/2),
                radius: rect.maxX - rect.minX,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
        } else {
            return UIBezierPath(
                arcCenter: CGPoint(x: rect.minX, y:rect.maxY/2),
                radius: rect.maxX - rect.minX,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
        }
    }
    
    public func setupLayer() {
        shapeLayer = CAShapeLayer()
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
    
    
//    override func draw(_ rect: CGRect) {
//        print(rect)
//        let startAngle: CGFloat = 0.0
//        let endAngle: CGFloat = CGFloat(M_PI * 4)
//        
//        if flip {
//            self.path = UIBezierPath(
//                arcCenter: CGPoint(x: rect.maxX, y:rect.maxY/2),
//                radius: rect.maxX - rect.minX,
//                startAngle: startAngle,
//                endAngle: endAngle,
//                clockwise: true
//            )
//        } else {
//            self.path = UIBezierPath(
//                arcCenter: CGPoint(x: rect.minX, y:rect.maxY/2),
//                radius: rect.maxX - rect.minX,
//                startAngle: startAngle,
//                endAngle: endAngle,
//                clockwise: true
//            )
//        }
//        
//    
//        shapeLayer = CAShapeLayer()
//        shapeLayer.frame = self.bounds
//        shapeLayer.path = self.path.cgPath
//        
//        self.layer.mask = shapeLayer
//        
//        strokeColor.set()
//        path.stroke()
//        
//        super.draw(rect)
//    }
    
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let outcome = path.contains(point) && self.layer.contains(point)
//        print("\(name) point inside: \(outcome)")
        return outcome
    }
    
}
