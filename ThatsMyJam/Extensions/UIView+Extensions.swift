//
//  UIView+Extensions.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 2/2/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
  
  func createRoundedCorners() {
    layer.cornerRadius = 7
    clipsToBounds = true
  }
  
}
