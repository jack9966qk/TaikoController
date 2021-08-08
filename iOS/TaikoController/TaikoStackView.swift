//
//  TaikoStackView.swift
//  TaikoController
//
//  Created by Jack on 2021/8/7.
//  Copyright © 2021 Jack. All rights reserved.
//

import UIKit

class TaikoStackView: UIStackView {
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		// Accept the point only if one of its subviews does.
		for subview in self.subviews {
			let pointInSubView = self.convert(point, to: subview)
			if subview.point(inside: pointInSubView, with: event) {
				return true
			}
		}
		return false
	}
}
