//
//  FeedbackViewController.swift
//  ThatsMyJam
//
//  Created by Matthew Howes Singleton on 3/20/18.
//  Copyright © 2018 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import mailgun
import UITextView_Placeholder
import FirebaseAnalytics


class FeedbackViewController: UIViewController {
  
  @IBOutlet weak var rightNavBarButton: UIBarButtonItem!
  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var topicTextField: UITextField!
  @IBOutlet weak var bodyTextView: UITextView!
  
  var picker = UIPickerView()
  var topics: [String] = []
  
  var topicSatisfied: Bool?
  var bodySatisfied: Bool?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.topicTextField.delegate = self
    self.bodyTextView.delegate = self
    self.picker.delegate = self
    self.picker.dataSource = self
    
    setNavBar()
    title = "Feedback"
    
    addToTopicArray()
    bodyTextView.placeholder = "Write your feedback here..."
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    topicSatisfied = false
    bodySatisfied = false
    checkIfBothConditionsAreTrue()
  }
  
  
  // MARK: - Check Condition
  
  func checkIfBothConditionsAreTrue() {
    
    if topicSatisfied == true && bodySatisfied == true {
      rightNavBarButton.isEnabled = true
    } else {
      rightNavBarButton.isEnabled = false
    }
  }
  
  
  // Topic Array
  
  func addToTopicArray() {
    topics+=["Bug Report", "Feature Suggestion", "Other"]
  }
  
  
  // MARK: - Thank you Alert
  
  func thankYouAlert() {
    let alert = UIAlertController(title: "Thank you", message: "We will review feedback ASAP", preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel) { (action) in
      self.navigationController?.popViewController(animated: true)
      
    }
    alert.addAction(action)
    self.present(alert, animated: true, completion: nil)
  }
  
  // MARK: - IBActions
  
  @IBAction func rightNavBarButtonTapped(_ sender: UIBarButtonItem) {
    guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist") else {
      return
    }
    guard let dic = NSDictionary(contentsOfFile: path) as? [String : String] else {
      return
    }
    
    guard let mailKey = dic["ActiveApiKey"] else {
      return
    }
    
    guard let mGun = dic["mailGun"] else {
      return
    }
    
    let mailGun = Mailgun.client(withDomain: mGun, apiKey: mailKey)
    
    guard let theTopic = topicTextField.text else {
      return
    }
    
    guard let theBody = bodyTextView.text else {
      return
    }
    
    mailGun?.sendMessage(to: "singletondevelopment@gmail.com", from: "ThatsMyJam@ThatsMyJam.com", subject: theTopic, body: theBody, success: { (success) in
      Analytics.logEvent("feedbackSent", parameters: ["topic": theTopic])
      self.thankYouAlert()
      
    }, failure: { (error) in
      
      debugPrint(error.debugDescription)
      self.thankYouAlert()
    })
    
  }
  
  
  // MARK: - Keyboard Methods
  
  func keyboardWillShow(notification:NSNotification) {
    var userInfo = notification.userInfo!
    var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
    keyboardFrame = self.view.convert(keyboardFrame, from: nil)
    var contentInset: UIEdgeInsets = self.scrollView.contentInset
    contentInset.bottom = keyboardFrame.size.height
    self.scrollView.contentInset = contentInset
  }
  
  
  func keyboardWillHide(notification:NSNotification) {
//    let contentInset:UIEdgeInsets = UIEdgeInsets.zero
    let contentInset:UIEdgeInsets = UIEdgeInsets()
    self.scrollView.contentInset = contentInset
  }
}


// MARK: - UITextFieldDelegate

extension FeedbackViewController: UITextFieldDelegate {
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == topicTextField {
      textField.inputView = picker
    }
  }
}


// MARK: - UITextViewDelegate

extension FeedbackViewController: UITextViewDelegate {
  
  func textViewDidChange(_ textView: UITextView) {
    if textView == bodyTextView {
      if !textView.text.isEmpty {
        bodySatisfied = true
      } else {
        bodySatisfied = false
      }
    }
    checkIfBothConditionsAreTrue()
  }

}


// MARK: - UIPickerView Delegate & DataSource

extension FeedbackViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return topics.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return topics[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    topicTextField.text = topics[row]
    if !topics[row].isEmpty {
      topicSatisfied = true
    } else {
      topicSatisfied = false
    }
    checkIfBothConditionsAreTrue()
  }
  
  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let titleData = topics[row]

    let myTitle = NSAttributedString(string: titleData, attributes: [NSAttributedString.Key.font: UIFont(name: "GillSans", size: 15.0)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray])

//    let myTitle = NSAttributedString(string: titleData, NSAttributedString.KeyNSAttributedString.Key.font: UIFont(name: "GillSans", size: 15.0)!,NSAttributedString.Key.foregroundColor:UIColor.darkGray])
    return myTitle
  }
  
  
}
