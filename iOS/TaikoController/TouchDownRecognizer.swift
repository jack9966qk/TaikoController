//
//  TouchDownRecognizer.swift
//  TaikoController
//
//  Created by Jack on 20/11/2016.
//  Copyright © 2016 Jack. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

class TouchDownRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible
        {
            self.state = .recognized
        }
    }
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
//        self.state = .failed
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
//        self.state = .failed
//    }
}
