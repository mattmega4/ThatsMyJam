//
//  LegalViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit

class LegalViewController: UIViewController {

  @IBOutlet weak var leftNavBarButton: UIBarButtonItem!
  @IBOutlet weak var legalLabel: UILabel!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setNavBar()
    title = "Legal"
  }
  
  
  @IBAction func leftNavBarButtonTapped(_ sender: UIBarButtonItem) {
    navigationController?.popViewController(animated: true)
  }

}
