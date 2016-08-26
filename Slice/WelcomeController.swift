//
//  WelcomeController.swift
//  Slice
//
//  Created by Oliver Hill on 7/13/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//The first screen the user will see. Contains the logo, a register button, and a login button
class WelcomeController: UIViewController {
    
    var loginButton = UIButton()
    var newAccountButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        UIApplication.sharedApplication().statusBarHidden = true
        let logoWidth = view.frame.width/3
        let logoView = UIImageView(frame: CGRect(x: view.frame.midX-logoWidth/2, y: 140, width: logoWidth, height: logoWidth))
        logoView.contentMode = .ScaleAspectFit
        logoView.layer.minificationFilter = kCAFilterTrilinear
        logoView.image = UIImage(imageLiteral: "pepperoni")
        view.addSubview(logoView)
        
        let doorsliceLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.frame.width, height: 30))
        doorsliceLabel.attributedText = Constants.getTitleAttributedString(" DOORSLICE", size: 25, kern: 18.0)
        doorsliceLabel.textAlignment = .Center
        view.addSubview(doorsliceLabel)
        
        //socialMediaButtons()
        
        loginButton =  setupButton(CGRect(x: view.frame.width/4, y: view.frame.height/2+20, width: view.frame.width/2, height: 40), text: "LOGIN")
        loginButton.addTarget(self, action: #selector(login), forControlEvents: .TouchUpInside)
        loginButton.alpha = 0.0
        view.addSubview(loginButton)
        
        newAccountButton = setupButton(CGRect(x: view.frame.width/4, y: loginButton.frame.maxY+30, width: view.frame.width/2, height: 40), text: "REGISTER")
        newAccountButton.addTarget(self, action: #selector(newAccount), forControlEvents: .TouchUpInside)
        newAccountButton.alpha = 0.0
        view.addSubview(newAccountButton)
      
    }
    
    func setupButton(frame: CGRect, text: String)-> UIButton{

        let button = UIButton(frame: frame)
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 16)!, range: (attributedString.string as NSString).rangeOfString(text))
        button.setAttributedTitle(attributedString, forState: .Normal)
        
        button.backgroundColor = UIColor.clearColor()
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1.0
        button.layer.borderColor = Constants.seaFoam.CGColor
        
        return button
    }
    
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.5, animations: {self.loginButton.alpha = 1.0}, completion: nil)
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {self.newAccountButton.alpha = 1.0}, completion: nil)
    }
    
    func newAccount(){
        presentViewController(CreateAccountController(), animated: false, completion: nil)
    }
    
    func login(){
        presentViewController(LoginController(), animated: false, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
