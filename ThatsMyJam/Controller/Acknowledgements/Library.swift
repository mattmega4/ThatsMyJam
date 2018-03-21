//
//  Library.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit

class Library: NSObject {
  
  var name: String?
  var legalDescription: String?
  
  init(object: [String : String]) {
    name = object["Title"]
    legalDescription = object["FooterText"]
  }
}
