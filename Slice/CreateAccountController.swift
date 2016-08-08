//
//  CreateAccountController.swift
//  Slice
//
//  Created by Oliver Hill on 6/27/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class CreateAccountController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate{
    var webtoken: String?
    var userID: String?
    
    let fieldHeight: CGFloat = 40
    var fieldWidth: CGFloat!
    var rawNumber = ""
    
    var phoneField = UITextField()
    var passwordField = UITextField()
    var confirmPasswordField = UITextField()

    let phoneViewLeft = UIImageView()
    let passViewLeft = UIImageView()
    let confirmViewLeft = UIImageView()
    
    let goButton = UIButton()

    var viewIsRaised = false
    var keyboardHeight: CGFloat?
    var keyboardShouldMoveScreen = false //True for iphone 5 and smaller
    var hasSetUp = false
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIApplication.sharedApplication().statusBarHidden = true
        keyboardShouldMoveScreen = UIScreen.mainScreen().bounds.height <= 568.0 //Check Screen size
        view.backgroundColor = Constants.darkBlue
        addObservers()
        if !hasSetUp{
            setup()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.5, animations: {self.phoneField.alpha = 1.0; self.phoneViewLeft.alpha = 1.0})
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {self.passwordField.alpha = 1.0; self.passViewLeft.alpha = 1.0}, completion: nil)
        UIView.animateWithDuration(0.5, delay: 0.4, options: [], animations: {self.confirmPasswordField.alpha = 1.0; self.confirmViewLeft.alpha = 1.0} , completion: nil)
    }
    
    //MARK: Account Creation and Setup
    func createAccountPressed(){
        if rawNumber.characters.count >= 10{
            if passwordField.text?.characters.count >= 5{
                if confirmPasswordField.text == passwordField.text{
                    createAccount()
                }
                else{
                    shakeTextField(confirmPasswordField,leftView: confirmViewLeft, enterTrue: true)
                }
            }
            else{
                shakeTextField(passwordField,leftView: passViewLeft, enterTrue: true)
            }
        }
        else{
            shakeTextField(phoneField, leftView: phoneViewLeft, enterTrue: true)
        }
    }
    
    //Runs twice per call when enterTrue is true
    func shakeTextField(textField: UITextField, leftView: UIImageView, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            textField.frame.origin.x += 10
            leftView.frame.origin.x += 10
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                textField.frame.origin.x -= 10
                leftView.frame.origin.x -= 10
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        textField.frame.origin.x += 10
                        leftView.frame.origin.x += 10
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                textField.frame.origin.x -= 10
                                leftView.frame.origin.x -= 10
                                }, completion: { _ in
                                    if enterTrue{
                                        self.shakeTextField(textField, leftView: leftView, enterTrue: false)
                                    }
                                })
                            }
                        )
                    }
                )
            }
        )
    }
    
    func createAccount(){
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()

        Alamofire.request(.POST, Constants.sendCodeURLString, parameters: ["phone" : rawNumber]).responseJSON{ response in
            self.activityIndicator.stopAnimating()
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["success"].boolValue{
                        let ec = EnterCodeController()
                        ec.code = JSON(value)["message"].stringValue
                        print(ec.code)
                        ec.phoneNumber = self.rawNumber
                        ec.password = self.confirmPasswordField.text!
                        ec.shouldPromptPasswordChange = false
                        self.presentViewController(ec, animated: false, completion: nil)
                    }
                    else{
                        self.accountExists()
                    }
                }
            case .Failure:
                self.failure()
            }
        }
    }
    
    func accountCreated(){
        let ec = EnterCodeController()
        ec.shouldPromptPasswordChange = false
        ec.phoneNumber = rawNumber
        ec.password = confirmPasswordField.text!
        presentViewController(ec, animated: false, completion: nil)
    }
    
    func accountExists(){
        SweetAlert().showAlert("ACCOUNT EXISTS", subTitle: "This phone number is already registered with an account. Did you mean to login?", style: .Error, buttonTitle: "Dismiss", buttonColor: Constants.tiltColor, otherButtonTitle: "Login", otherButtonColor: Constants.tiltColor){
            if !($0){
                self.login()
            }
        }
    }
    
    func login(){
        self.activityIndicator.stopAnimating()
        let lc = LoginController()
        lc.shouldShowBackButton = true
        lc.rawNumber = rawNumber
        presentViewController(lc, animated: false, completion: nil)
    }
    
    func failure(){
        activityIndicator.stopAnimating()
        SweetAlert().showAlert("SERVER ERROR", subTitle: "Please try again later", style: .Error,  buttonTitle: "Okay", buttonColor: Constants.tiltColor)
    }
    
    
    //MARK: Navigation Bar Setup
    func navBarSetup(){
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont(name: "GillSans-Light", size: 25)
        titleLabel.textColor = Constants.tiltColor
        titleLabel.alpha = 0.8
        titleLabel.textAlignment = .Center
        titleLabel.text = "Slice"
        navigationItem.titleView = titleLabel
    }
    

    //MARK: TextField Setup
    func setupTextField(frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.backgroundColor = Constants.darkBlue
        textField.textAlignment = .Center
        textField.textColor = UIColor.whiteColor()
        textField.leftViewMode = UITextFieldViewMode.Always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        textField.backgroundColor = UIColor.clearColor()
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.whiteColor().CGColor
        
        view.addSubview(textField)
        return textField
    }
    

    func addObservers(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    //MARK: TextField Management
    func textFieldDidChange(textField: UITextField){
        if textField == passwordField{
            if textField.text?.characters.count == 5{
                UIView.animateWithDuration(1.0, animations: {self.passwordField.layer.borderColor = Constants.seaFoam.CGColor})
            }
                
            else if (textField.text?.characters.count)! < 5 && UIColor(CGColor: passwordField.layer.borderColor!) != Constants.lightRed{
                UIView.animateWithDuration(1.0, animations: {
                    self.passwordField.layer.borderColor = Constants.lightRed.CGColor
                    self.goButton.titleLabel?.textColor = UIColor.whiteColor()
                })
                
            }
            
            if UIColor(CGColor: confirmPasswordField.layer.borderColor!) == Constants.seaFoam{
                if passwordField.text != confirmPasswordField.text{
                    UIView.animateWithDuration(1.0, animations: {
                        self.confirmPasswordField.layer.borderColor = Constants.lightRed.CGColor
                        self.goButton.titleLabel?.textColor = UIColor.whiteColor()
                    })
                }
            }
        }
        else{
            if textField.text == passwordField.text && textField.text?.characters.count >= 5{
                UIView.animateWithDuration(1.0, animations: {self.confirmPasswordField.layer.borderColor = Constants.seaFoam.CGColor})
            }
            else if textField.text != passwordField.text && UIColor(CGColor: confirmPasswordField.layer.borderColor!) != Constants.lightRed{
                UIView.animateWithDuration(1.0, animations: {
                    self.confirmPasswordField.layer.borderColor = Constants.lightRed.CGColor
                    self.goButton.titleLabel?.textColor = UIColor.whiteColor()
                })
            }
        }
        if UIColor(CGColor: phoneField.layer.borderColor!) == Constants.seaFoam{
            if UIColor(CGColor: passwordField.layer.borderColor!) == Constants.seaFoam{
                if UIColor(CGColor: confirmPasswordField.layer.borderColor!) == Constants.seaFoam{
                    UIView.animateWithDuration(1.0, animations: {self.goButton.titleLabel?.textColor = Constants.seaFoam})
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
        if textField != phoneField{
            textField.secureTextEntry = true
        }
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        if keyboardShouldMoveScreen && confirmPasswordField.isFirstResponder() && !viewIsRaised {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                keyboardHeight = keyboardSize.height
                self.view.frame.origin.y -= keyboardSize.height
                viewIsRaised = true
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        if viewIsRaised{
            if let keyboardSize = (notification?.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                self.view.frame.origin.y += keyboardSize.height
                viewIsRaised = false
            }
            else{
                self.view.frame.origin.y += keyboardHeight!
                viewIsRaised = false
            }
        }
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if keyboardShouldMoveScreen && (textField == phoneField || textField == passwordField) && viewIsRaised{
            keyboardWillHide(nil)
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == phoneField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            confirmPasswordField.becomeFirstResponder()
        }
        else{
            confirmPasswordField.resignFirstResponder()
            createAccountPressed()
        }
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        phoneField.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneField{
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.hasPrefix("1")
            rawNumber = String(decimalString)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11{
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                return (newLength > 10) ? false : true
            }
            if length == 1{
                UIView.animateWithDuration(1.0, animations: {self.phoneField.layer.borderColor = Constants.lightRed.CGColor})
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne{
                formattedString.appendString("1 ")
                index += 1
            }
            
            if (length - index) > 3{
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            
            if length - index > 3{
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            
            if (length == 10 && !hasLeadingOne) || (length == 11 && hasLeadingOne){
                UIView.animateWithDuration(1.0, animations: {self.phoneField.layer.borderColor = Constants.seaFoam.CGColor})
                textFieldShouldReturn(phoneField)
            }
            return false
        }
        return true
    }
    
    
    //MARK: Setup
    func setup(){
        let logoWidth = view.frame.width/3
        let logoView = UIImageView(frame: CGRect(x: view.frame.midX-logoWidth/2, y: 50, width: logoWidth, height: logoWidth))
        logoView.contentMode = .ScaleAspectFit
        logoView.image = UIImage(imageLiteral: "logo")
        view.addSubview(logoView)
        
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: logoView.frame.maxY+60, width: view.frame.width/2, height: 40))
        phoneField.alpha = 0.0
        phoneField.keyboardType = .NumberPad
        
        passwordField = setupTextField(CGRect(x: view.frame.width/4, y: phoneField.frame.maxY+40, width: view.frame.width/2, height: 40))
        passwordField.alpha = 0.0
        passwordField.secureTextEntry = true
        
        confirmPasswordField = setupTextField(CGRect(x: view.frame.width/4, y: passwordField.frame.maxY+40, width: view.frame.width/2, height: 40))
        confirmPasswordField.alpha = 0.0
        confirmPasswordField.secureTextEntry = true
        
        phoneViewLeft.image = UIImage(imageLiteral: "phone")
        phoneViewLeft.alpha = 0.0
        phoneViewLeft.frame = CGRect(x:phoneField.frame.minX-40, y: phoneField.frame.minY+5,  width: 30, height: 30)
        view.addSubview(phoneViewLeft)
        
        passViewLeft.image =  UIImage(imageLiteral: "padlock")
        passViewLeft.alpha = 0.0
        passViewLeft.frame = CGRect(x:passwordField.frame.minX-40, y: passwordField.frame.minY+5, width: 30, height: 30)
        view.addSubview(passViewLeft)
        
        confirmViewLeft.image = UIImage(imageLiteral: "padlock")
        confirmViewLeft.alpha = 0.0
        confirmViewLeft.frame = CGRect(x: confirmPasswordField.frame.minX-40, y: confirmPasswordField.frame.minY+5, width: 30, height: 30)
        view.addSubview(confirmViewLeft)
  
        goButton.frame = CGRect(x: view.frame.width/4, y: 4*view.frame.height/5, width: view.frame.width/2, height: 40)
        goButton.addTarget(self, action: #selector(createAccountPressed), forControlEvents: .TouchUpInside)
        let attributedString = NSMutableAttributedString(string: "REGISTER")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 16)!, range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        goButton.setAttributedTitle(attributedString, forState: .Normal)
        goButton.backgroundColor = UIColor.clearColor()
        view.addSubview(goButton)
        
        let backButton = Constants.getBackButton()
        backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .TouchUpInside)
        view.addSubview(backButton)
        hasSetUp = true
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)

    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 0{
                presentViewController(WelcomeController(), animated: false, completion: nil)
            }
        }
    }
    
    func backPressed(){
        presentViewController(WelcomeController(), animated: false, completion: nil)
    }
}
