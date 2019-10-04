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
  
   public func roundedCorners() {
    layer.cornerRadius = 7
    clipsToBounds = true
  }

  public func roundedButton() {
    layer.cornerRadius = 15
    clipsToBounds = true
    backgroundColor = UIColor.white.withAlphaComponent(0.7)
  }
  
}
