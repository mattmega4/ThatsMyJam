//
//  UIViewController+Extensions.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
  
  func setNavBar() {
    self.navigationController?.isNavigationBarHidden = false
    navigationController?.navigationBar.barTintColor = UIColor(red: 38.0/255.0,
                                                               green: 38.0/255.0,
                                                               blue: 38.0/255.0,
                                                               alpha: 1.0)
    
    UINavigationBar.appearance().tintColor = .white
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white,
                                                               NSAttributedStringKey.font: UIFont(name: "GillSans-Bold",
                                                                                                  size: 18)!]
  }
  
  
}
