//
//  SettingsViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
  
  @IBOutlet weak var rightNavBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var logoImgView: UIImageView!
  @IBOutlet weak var buttonStackView: UIStackView!
  @IBOutlet weak var acknowledgementsButton: UIButton!
  @IBOutlet weak var legalButton: UIButton!
  @IBOutlet weak var feedbackButton: UIButton!
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    

  
    // MARK: - IB Actions
  
  @IBAction func rightBarButtonItemTapped(_ sender: UIBarButtonItem) {
  }
  
  @IBAction func acknowledgementsButtonTapped(_ sender: UIButton) {
    if let ackVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.acknowledgementsVCViewControllerStoryboardID) as? AcknowledgementsViewController {
      self.navigationController?.pushViewController(ackVC, animated: true)
    }
  }
  
  @IBAction func legalButtontapped(_ sender: UIButton) {
    if let legalVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.legalVCViewControllerStoryboardID) as? LegalViewController {
      self.navigationController?.pushViewController(legalVC, animated: true)
    }
  }
  
  @IBAction func feedbackButtonTapped(_ sender: UIButton) {
    if let feedVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.feedbackVCViewControllerStoryboardID) as? FeedbackViewController {
      self.navigationController?.pushViewController(feedVC, animated: true)
    }
  }
  

}
