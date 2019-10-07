//
//  UIViewController+Extensions.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import Foundation
import UIKit
import ChameleonFramework

extension UIViewController {
  
  func setNavBar() {
    self.navigationController?.isNavigationBarHidden = false
    UINavigationBar.appearance().barTintColor = .flatBlackDark()
    navigationController?.navigationBar.barTintColor = FlatBlackDark() /* UIColor(red: 38.0/255.0,
                                                               green: 38.0/255.0,
                                                               blue: 38.0/255.0,
                                                               alpha: 1.0) */
    
//    UINavigationBar.appearance().tintColor = .white
    view.backgroundColor = FlatBlack()
    UINavigationBar.appearance().tintColor = FlatBlackDark()

    UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.flatWhite()]
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.flatWhite(),
                                                               NSAttributedString.Key.font: UIFont(name: "GillSans-Bold",
                                                                                                  size: 18)!]
  }
  
  
}
