//
//  NSObject+Extensions.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 9/26/19.
//  Copyright © 2019 Matthew Howes Singleton. All rights reserved.
//

import Foundation
import UIKit

extension NSObject {
  func delay(seconds delay: Double, closure: @escaping ()->()) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
  }
}
