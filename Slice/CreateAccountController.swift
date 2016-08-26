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

//When all fields are entered correctly, this Viewcontroller submits a request to /sendCode, waits for a response, 
//then passes the necessary information to EnterCodeController with shoudlPromptPasswordChange set to false
class CreateAccountController: NavBarless, UITextFieldDelegate{
    var webtoken: String?
    var userID: String?

    var rawNumber = ""
    
    let georgetownButton = UIButton()
    let columbiaButton = UIButton()
    
    var phoneField = UITextField()
    var passwordField = UITextField()
    var confirmPasswordField = UITextField()

    let schoolViewLeft = UIImageView()
    let phoneViewLeft = UIImageView()
    let passViewLeft = UIImageView()
    let confirmViewLeft = UIImageView()
    
    let goButton = UIButton()

    var viewIsRaised = false
    var keyboardHeight: CGFloat?
    var keyboardShouldMoveScreen = false //True for iphone 5 and smaller
    var hasSetUp = false
    
    var isGeorgetown: Bool? = nil
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIApplication.sharedApplication().statusBarHidden = true
        keyboardShouldMoveScreen = UIScreen.mainScreen().bounds.height <= 568.0 //Check Screen size
        addObservers()
        if !hasSetUp{
            setup()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionForBackButton({self.presentViewController(WelcomeController(), animated: false, completion: nil)})
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let doorsliceLabel = UILabel(frame: CGRect(x: 0, y: 18, width: view.frame.width, height: 30))
        doorsliceLabel.attributedText = Constants.getTitleAttributedString(" DOORSLICE", size: 20, kern: 18.0)
        doorsliceLabel.textAlignment = .Center
        view.addSubview(doorsliceLabel)
        
        let logoWidth = view.frame.width/4
        let logoView = UIImageView(frame: CGRect(x: view.frame.midX-logoWidth/2, y: 50, width: logoWidth, height: logoWidth))
        logoView.contentMode = .ScaleAspectFit
        logoView.layer.minificationFilter = kCAFilterTrilinear
        logoView.image = UIImage(imageLiteral: "pepperoni")
        view.addSubview(logoView)
       
        UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {self.phoneField.alpha = 1.0; self.phoneViewLeft.alpha = 1.0}, completion: nil)
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {self.passwordField.alpha = 1.0; self.passViewLeft.alpha = 1.0}, completion: nil)
        UIView.animateWithDuration(0.5, delay: 0.4, options: [], animations: {self.confirmPasswordField.alpha = 1.0; self.confirmViewLeft.alpha = 1.0} , completion: nil)
         UIView.animateWithDuration(0.5, delay: 0.6, options: [], animations: {self.georgetownButton.alpha = 1.0; self.columbiaButton.alpha = 1.0; self.schoolViewLeft.alpha = 1.0}, completion: nil)
    }
    
    //MARK: Account Creation and Setup
    func createAccountPressed(){
        if rawNumber.characters.count >= 10{
            if passwordField.text?.characters.count >= 5{
                if confirmPasswordField.text == passwordField.text{
                    if isGeorgetown != nil{
                        createAccount()
                    }
                    else{
                        Alerts.shakeView(georgetownButton, enterTrue: true)
                        Alerts.shakeView(columbiaButton, enterTrue: true)
                    }
                }
                else{
                    Alerts.shakeView(confirmPasswordField, enterTrue: true)
                    Alerts.shakeView(confirmViewLeft, enterTrue: true)
                }
            }
            else{
                Alerts.shakeView(passwordField, enterTrue: true)
                Alerts.shakeView(passViewLeft, enterTrue: true)
            }
        }
        else{
            Alerts.shakeView(phoneField, enterTrue: true)
            Alerts.shakeView(phoneViewLeft, enterTrue: true)
        }
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
                        ec.school = self.isGeorgetown! ? "GEORGETOWN" : "COLUMBIA"
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
        Alerts.accountExists(){ if ($0){ self.login() } }
    }
    
    func login(){
        self.activityIndicator.stopAnimating()
        let lc = LoginController()
        lc.rawNumber = rawNumber
        presentViewController(lc, animated: false, completion: nil)
    }
    
    func failure(){
        activityIndicator.stopAnimating()
        Alerts.serverError()
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
        let spacer: CGFloat = !keyboardShouldMoveScreen ? 40 : 0
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: 150 + spacer, width: view.frame.width/2, height: 40))
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
        passViewLeft.layer.minificationFilter = kCAFilterTrilinear
        passViewLeft.frame = CGRect(x:passwordField.frame.minX-40, y: passwordField.frame.minY+5, width: 30, height: 30)
        view.addSubview(passViewLeft)
        
        confirmViewLeft.image = UIImage(imageLiteral: "padlock")
        confirmViewLeft.alpha = 0.0
        confirmViewLeft.layer.minificationFilter = kCAFilterTrilinear
        confirmViewLeft.frame = CGRect(x: confirmPasswordField.frame.minX-40, y: confirmPasswordField.frame.minY+5, width: 30, height: 30)
        view.addSubview(confirmViewLeft)
    
        let buttonYVal = (view.frame.height*6/7 - ((view.frame.height*6/7 - confirmPasswordField.frame.maxY)/2 + 20))
        georgetownButton.frame = CGRect(x: 20, y: buttonYVal, width: view.frame.width/2-23, height: 40)
        georgetownButton.setAttributedTitle(Constants.getTitleAttributedString("GEORGETOWN", size: 10, kern: 4.0), forState: .Normal)
        georgetownButton.layer.cornerRadius = 5
        georgetownButton.clipsToBounds = true
        georgetownButton.layer.borderColor = UIColor.whiteColor().CGColor
        georgetownButton.layer.borderWidth = 1.0
        georgetownButton.addTarget(self, action: #selector(georgetownPressed), forControlEvents: .TouchUpInside)
        georgetownButton.alpha = 0.0
        view.addSubview(georgetownButton)
        
        columbiaButton.frame = CGRect(x: view.frame.width/2+3, y: buttonYVal, width: view.frame.width/2-23, height: 40)
        columbiaButton.addTarget(self, action: #selector(columbiaPressed), forControlEvents: .TouchUpInside)
        columbiaButton.setAttributedTitle(Constants.getTitleAttributedString("COLUMBIA", size: 10, kern: 4.0), forState: .Normal)
        columbiaButton.layer.cornerRadius = 5
        columbiaButton.clipsToBounds = true
        columbiaButton.layer.borderWidth = 1.0
        columbiaButton.layer.borderColor = UIColor.whiteColor().CGColor
        columbiaButton.alpha = 0.0
        view.addSubview(columbiaButton)
  
        
        goButton.frame = CGRect(x: view.frame.width/4, y: 6*view.frame.height/7, width: view.frame.width/2, height: 40)
        goButton.addTarget(self, action: #selector(createAccountPressed), forControlEvents: .TouchUpInside)
        let attributedString = NSMutableAttributedString(string: "REGISTER")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 16)!, range: (attributedString.string as NSString).rangeOfString("REGISTER"))
        goButton.setAttributedTitle(attributedString, forState: .Normal)
        goButton.backgroundColor = UIColor.clearColor()
        view.addSubview(goButton)
     
        hasSetUp = true

    }
    
    func georgetownPressed(){
        let at = Constants.getTitleAttributedString("GEORGETOWN", size: 10, kern: 4.0)
        at.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (at.string as NSString).rangeOfString("GEORGETOWN"))
        georgetownButton.setAttributedTitle(at, forState: .Normal)
        georgetownButton.layer.borderColor = Constants.seaFoam.CGColor
        isGeorgetown = true
        
        columbiaButton.setAttributedTitle(Constants.getTitleAttributedString("COLUMBIA", size: 10, kern: 4.0), forState: .Normal)
        columbiaButton.layer.borderColor = UIColor.whiteColor().CGColor
        
    }
    
    func columbiaPressed(){
        let at = Constants.getTitleAttributedString("COLUMBIA", size: 10, kern: 4.0)
        at.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (at.string as NSString).rangeOfString("COLUMBIA"))
        columbiaButton.setAttributedTitle(at, forState: .Normal)
        columbiaButton.layer.borderColor = Constants.seaFoam.CGColor
        isGeorgetown = false
        
        georgetownButton.setAttributedTitle(Constants.getTitleAttributedString("GEORGETOWN", size: 10, kern: 4.0), forState: .Normal)
        georgetownButton.layer.borderColor = UIColor.whiteColor().CGColor
    }

}
