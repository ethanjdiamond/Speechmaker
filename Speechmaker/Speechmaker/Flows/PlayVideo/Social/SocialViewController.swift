//
//  SocialViewController.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/16/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import UIKit
import AVFoundation
import Social
import Accounts
import Crashlytics

let ANIMATION_DURATION = 0.5

class SocialViewController: UIViewController {

    @IBOutlet var socialView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var accountsButton: UIButton!
    @IBOutlet var socialViewBottomConstraint: NSLayoutConstraint!
    
    var video: AVURLAsset!
    var socialAccount: SocialAccount!
    var accounts: [ACAccount]!
    var account: ACAccount! {
        didSet {
            accountsButton.setTitle(socialAccount.usernameForAccount(account), for: UIControlState())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SocialViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        view.alpha = 0
        socialView.layer.cornerRadius = 8.0
        socialView.layer.masksToBounds = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func presentWithSocialAccount(_ socialAccount: SocialAccount, video: AVURLAsset, complete: () -> ()) {
        if (CMTimeCompare(video.duration, CMTimeMakeWithSeconds(1, 1)) == -1) {
            UIAlertController.alert("Videos shorter than one second cannot be shared.")
            return
        }
        
        self.socialAccount = socialAccount
        self.video = video
        self.textView.text = ""
        
        titleLabel.text = socialAccount.name
        imageView.image = thumbnailFromAsset(video)
        
        socialAccount.getAccounts({ (accounts) in
            self.accounts = accounts
            
            if (self.accounts.count == 1) {
                self.accountsButton.isEnabled = false
                self.accountsButton.setTitleColor(UIColor.lightGray, for: UIControlState())
            } else {
                self.accountsButton.isEnabled = true
                self.accountsButton.setTitleColor(UIColor.blue, for: UIControlState())
            }
            
            self.account = self.accounts.first!
            self.present()
        }, failure: { (error) in
            UIAlertController.alert(error.localizedDescription)
        })
    }
    
    func present() {
        textView.becomeFirstResponder()
        self.view.isHidden = false
        UIView.animate(withDuration: ANIMATION_DURATION, animations: {
            self.view.alpha = 1
        })
    }
    
    func dismiss() {
        textView.resignFirstResponder()
        UIView.animate(withDuration: ANIMATION_DURATION, animations: { 
            self.view.alpha = 0
        }, completion: { (_) in
            self.view.isHidden = true
        }) 
    }
    
    @IBAction func cancelWasTapped() {
        dismiss()
    }
    
    @IBAction func postWasTapped() {
        if (!Reachability.instance.isReachable) {
            UIAlertController.alert("Unable to connect to the internet. Please connect and try again.")
            return
        }
        
        self.dismiss()
        self.socialAccount.postVideo(try! Data(contentsOf: video.url), account: account, text: textView.text, success: {
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] \(self.socialAccount.name) Share", customAttributes: ["account" : self.socialAccount.usernameForAccount(self.account), "message" : self.textView.text])
            log("FINISHED POSTING FOR " + self.socialAccount.name)
        }) { (error) in
            Answers.logCustomEvent(withName: "[\(ANALYTICS_NAME)] \(self.socialAccount.name) Share Failure", customAttributes: ["error" : error.localizedDescription])
            UIAlertController.alert(error.localizedDescription)
        }
    }
    
    @IBAction func changeAccountWasTapper() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for account in accounts {
            alertController.addAction(UIAlertAction(title: socialAccount.usernameForAccount(account), style: .default, handler: { (action) in
                self.account = self.accounts[alertController.actions.index(of: action)!]
                alertController.dismiss(animated: true, completion: nil)
            }))
        }
        self.present(alertController, animated: true, completion: nil)
    }

    // MARK: Convenience
    
    func thumbnailFromAsset(_ asset: AVAsset) -> UIImage? {
        do {
            let imageGenerator = AVAssetImageGenerator(asset: asset);
            let time = CMTimeMakeWithSeconds(1.0, 1)
            var actualTime : CMTime = CMTimeMake(0, 0)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    
    @objc fileprivate func keyboardDidShow(_ notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        socialViewBottomConstraint.constant = keyboardHeight + 20
    }
}
