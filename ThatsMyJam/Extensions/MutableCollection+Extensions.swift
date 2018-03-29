//
//  MutableCollection+Extensions.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 2/2/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import Foundation

extension MutableCollection {
  /// Shuffles the contents of this collection.
  public mutating func shuffle() {
    let c = count
    guard c > 1 else { return }

    for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
      // let d: IndexDistance
      let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
      let i = index(firstUnshuffled, offsetBy: d)
      swapAt(firstUnshuffled, i)
    }
  }
}



