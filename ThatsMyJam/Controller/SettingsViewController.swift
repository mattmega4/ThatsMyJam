//
//  SettingsViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import AcknowList
import ChameleonFramework

class SettingsViewController: UIViewController {
  
  @IBOutlet weak var rightNavBarButtonItem: UIBarButtonItem!
  @IBOutlet weak var logoImgView: UIImageView!
  @IBOutlet weak var appNameLabel: UILabel!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var buttonStackView: UIStackView!
  @IBOutlet weak var acknowledgementsButton: UIButton!
  @IBOutlet weak var legalButton: UIButton!
  @IBOutlet weak var feedbackButton: UIButton!

  let viewModel = AcknowledgementsViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setNavBar()
    
    title = "Settings"
    appNameLabel.text = "Thats My Jam"
    versionLabel.text = viewModel.getVersionInfo()
    acknowledgementsButton.roundedButton()
    legalButton.roundedButton()
    feedbackButton.roundedButton()
  }

  // MARK: - IB Actions
  
  @IBAction func rightBarButtonItemTapped(_ sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func acknowledgementsButtonTapped(_ sender: UIButton) {
    //    if let ackVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardKeys.acknowledgementsVCViewControllerStoryboardID) as? AcknowledgementsViewController {
    //      self.navigationController?.pushViewController(ackVC, animated: true)
    //    }
    let viewController = AcknowListViewController()
    navigationController?.pushViewController(viewController, animated: true)
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
