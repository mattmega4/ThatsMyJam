//
//  AlbumArtistConcatenation.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 9/25/19.
//  Copyright © 2019 Matthew Howes Singleton. All rights reserved.
//

import Foundation
import UIKit

struct AlbumArtistConcatenation {

  func convertSongInfoFromStringToNSAttributedString(text: String, textColor: UIColor) -> NSAttributedString {

    let attributes = [ NSAttributedString.Key.foregroundColor: textColor]
    let attributedString = NSAttributedString(string: text, attributes: attributes)

    return attributedString
  }
  

}
