//
//  EnterCodeController.swift
//  Slice
//
//  Created by Oliver Hill on 7/16/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


//View Controller for authenticating phone numbers or changing password.
//Any controller instantiating this one MUST SET the shouldPromptPasswordChange, code, and phoneNumber variables
class EnterCodeController: UIViewController,UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var code: String!
    var shouldPromptPasswordChange: Bool!
    var phoneNumber: String!
    
    var password: String? //Must be set if authenticating
    
    var placeHolder: String?
    
    var codeFields = [CodeField]()
    var borders = [CALayer]()
    var bordersAreRed = false
    var requestIsProcessing = false
    
    var newPassField = UITextField()
    var confirmPassField = UITextField()
    var confirmViewLeft = UIImageView()
    var newPassViewLeft = UIImageView()
    var resetPasswordButton = UIButton()
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        UIApplication.sharedApplication().statusBarHidden = true
        setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        let label = UILabel(frame: CGRect(x: 5, y: codeFields[0].frame.maxY+15, width: view.frame.width-10, height: 50))
        label.numberOfLines = 0
        label.textAlignment = .Center
        let message = "ENTER THE SIX DIGIT CODE TEXTED TO YOU"
        let attributedString = NSMutableAttributedString(string: message)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (attributedString.string as NSString).rangeOfString(message))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(5.0), range: (attributedString.string as NSString).rangeOfString(message))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 14)!, range: (attributedString.string as NSString).rangeOfString(message))
        label.attributedText = attributedString
        label.alpha = 0.0
        view.addSubview(label)
        
        UIView.animateWithDuration(1.5, animations: {label.alpha = 1.0}, completion: nil)
    }


    
    //MARK: Networking Functions
    func changePassword(newPass: String){
        let parameters = ["phone" : phoneNumber, "code" : code, "password" : newPass]
        requestIsProcessing = true
        Alamofire.request(.POST, Constants.resetPasswordURLString, parameters: parameters).responseJSON{ response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["success"].boolValue{
                        let lc = LoginController()
                        if self.placeHolder != nil{
                            lc.autoFilledNumber = self.placeHolder
                            lc.rawNumber = self.phoneNumber
                        }
                        self.presentViewController(lc, animated: false, completion: nil)
                    }
                }
                
            case .Failure:
                SweetAlert().showAlert("SERVER ERROR", subTitle: "Please try again later", style: .Error,  buttonTitle: "Okay", buttonColor: Constants.tiltColor)
            }
        }
    }
    
    func createAccount(){
        let parameters = ["phone" : phoneNumber, "password" : password]
        //Request to /Users
        Alamofire.request(.POST, Constants.accountCreationURLString, parameters: parameters).responseJSON { response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    let json = JSON(value)
                    if json["success"].boolValue{
                        let userID = JSON(value)["userID"].stringValue
                        //Request to /Authenticate
                        Alamofire.request(.POST, Constants.authenticateURLString, parameters: parameters).responseJSON{ response in
                            self.activityIndicator.stopAnimating()
                            switch response.result{
                            case .Success:
                                if let value = response.result.value{
                                    let jwt = JSON(value)["token"].stringValue
                                    let newUser = User(userID: userID, jwt: jwt)
                                    let cc = ContainerController()
                                    cc.loggedInUser = newUser
                                    self.view.endEditing(true)
                                    self.presentViewController(cc, animated: false, completion: nil)
                                }
                            case .Failure:
                                self.failure()
                            }
                        }
                    }
                }
            case .Failure:
                self.failure()
            }
        }
    }
    
    func failure(){
        SweetAlert().showAlert("SERVER ERROR", subTitle: "Please try again later", style: .Error,  buttonTitle: "Okay", buttonColor: Constants.tiltColor)
    }
    
    //MARK: TextField Management
    
    func textFieldDidChange(textField: UITextField){
  
        if textField == newPassField{
            if textField.text?.characters.count == 5{
                UIView.animateWithDuration(1.0, animations: {self.newPassField.layer.borderColor = Constants.seaFoam.CGColor})
            }
                
            else if (textField.text?.characters.count)! < 5 && UIColor(CGColor: newPassField.layer.borderColor!) != Constants.lightRed{
                UIView.animateWithDuration(1.0, animations: {
                    self.newPassField.layer.borderColor = Constants.lightRed.CGColor
                    self.resetPasswordButton.titleLabel?.textColor = UIColor.whiteColor()
                })
            }
            
            if UIColor(CGColor: confirmPassField.layer.borderColor!) == Constants.seaFoam{
                if newPassField.text != confirmPassField.text{
                    UIView.animateWithDuration(1.0, animations: {
                        self.confirmPassField.layer.borderColor = Constants.lightRed.CGColor
                        self.resetPasswordButton.titleLabel?.textColor = UIColor.whiteColor()
                    })
                }
            }
        }
        else{
            if textField.text == newPassField.text && textField.text?.characters.count >= 5{
                UIView.animateWithDuration(1.0, animations: {self.confirmPassField.layer.borderColor = Constants.seaFoam.CGColor})
            }
            else if textField.text != newPassField.text && UIColor(CGColor: confirmPassField.layer.borderColor!) != Constants.lightRed{
                UIView.animateWithDuration(1.0, animations: {
                    self.confirmPassField.layer.borderColor = Constants.lightRed.CGColor
                    self.resetPasswordButton.titleLabel?.textColor = UIColor.whiteColor()
                })
            }
        }
        if UIColor(CGColor: resetPasswordButton.layer.borderColor!) == Constants.seaFoam{
            if UIColor(CGColor: newPassField.layer.borderColor!) == Constants.seaFoam{
                if UIColor(CGColor: confirmPassField.layer.borderColor!) == Constants.seaFoam{
                    UIView.animateWithDuration(1.0, animations: {self.resetPasswordButton.titleLabel?.textColor = Constants.seaFoam})
                }
            }
        }
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField is CodeField{
            if !bordersAreRed{
                for border in borders{
                    UIView.animateWithDuration(1.0, animations: {border.borderColor = Constants.lightRed.CGColor})
                }
                bordersAreRed = true
            }
            if (textField.text?.characters.count < 1  && string.characters.count > 0){
                textField.text = string
                if textField.tag == 7 {fullField()}
                let nextResponder = textField.superview?.viewWithTag(textField.tag + 1)
                
                nextResponder?.becomeFirstResponder()
                return false
            }
                
            else if (string == ""){
                let previousResponder = textField.superview?.viewWithTag(textField.tag - 1) ?? textField.superview?.viewWithTag(2)
                previousResponder?.becomeFirstResponder()
                return false
            }
        }
        return true
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == newPassField{
            confirmPassField.becomeFirstResponder()
        }
        else if textField == confirmPassField{
            confirmPassField.resignFirstResponder()
            resetPasswordPressed()
        }
        return true
    }
    
    
    //Runs twice per call when enterTrue is true
    func shakeTextField(textField: UITextField, leftView: UIImageView? = nil, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            textField.frame.origin.x += 10
            leftView?.frame.origin.x += 10
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                textField.frame.origin.x -= 10
                leftView?.frame.origin.x -= 10
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        textField.frame.origin.x += 10
                        leftView?.frame.origin.x += 10
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                textField.frame.origin.x -= 10
                                leftView?.frame.origin.x -= 10
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
    
    //Called when all 6 digits are typed into the codeFields
    func fullField(){
        
        var totalString = ""
        for field in codeFields{
            
            totalString += field.text!
        }
        codeFields.last!.resignFirstResponder()
        
        if totalString == code{
            for border in borders{
                UIView.animateWithDuration(1.0, animations: {border.borderColor = Constants.seaFoam.CGColor})
            }
    
            if !self.shouldPromptPasswordChange{
                activityIndicator.startAnimating()
                createAccount()
            }
            else{
                addPasswordTextFields()
            }
        }
        else{
            for field in codeFields{
                shakeTextField(field, leftView: nil, enterTrue: true)
            }
        }
    }
    
    
    //MARK: Button Presses
    func backPressed(){
        let previousVc = shouldPromptPasswordChange! ? ForgotPasswordController() : CreateAccountController()
        if !requestIsProcessing{
            self.presentViewController(previousVc, animated: false, completion: nil)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func resetPasswordPressed(){
        if newPassField.text?.characters.count >= 5{
            if confirmPassField.text == newPassField.text{
                changePassword(confirmPassField.text!)
            }
            else{
                shakeTextField(confirmPassField, leftView: confirmViewLeft, enterTrue: true)
            }
        }
        else{
            shakeTextField(newPassField, leftView: newPassViewLeft, enterTrue: true)
        }
    }
    
    //MARK: Setup Functions
    func setupCodeField(withTag tag: Int, xPos: CGFloat)->CodeField{
        let textField = CodeField(frame: CGRect(x: xPos, y: view.frame.height/6, width: view.frame.width*3/48, height: 40))
        textField.delegate = self
        textField.tag = tag
        textField.keyboardType = .NumberPad
        textField.textAlignment = .Center
        textField.textColor = UIColor.whiteColor()
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.whiteColor().CGColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        borders.append(border)
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
        
        view.addSubview(textField)
        return textField
    }
    
    
    func setupTextField(frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.textAlignment = .Center
        textField.textColor = UIColor.whiteColor()
        textField.leftViewMode = UITextFieldViewMode.Always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        textField.backgroundColor = UIColor.clearColor()
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.whiteColor().CGColor
        textField.clipsToBounds = true
        view.addSubview(textField)
        return textField
    }
    
    
    //Returns a padlock UIImageView to the left of the text field entered
    func leftViewForField(field: UITextField)-> UIImageView{
        let iview = UIImageView()
        iview.image = UIImage(imageLiteral: "padlock")
        iview.alpha = 0.0
        iview.frame = CGRect(x: field.frame.minX-40, y: field.frame.minY+5, width: 30, height: 30)
        view.addSubview(iview)
        return iview
    }

    
    func addPasswordTextFields(){
        newPassField = setupTextField(CGRect(x: view.frame.width/4, y: codeFields[1].frame.maxY+70, width: view.frame.width/2, height: 40))
        newPassField.alpha = 0.0
        newPassField.secureTextEntry = true
        
        confirmPassField = setupTextField(CGRect(x: view.frame.width/4, y: newPassField.frame.maxY+40, width: view.frame.width/2, height: 40))
        confirmPassField.alpha = 0.0
        confirmPassField.secureTextEntry = true
        
        confirmViewLeft = leftViewForField(confirmPassField)
        newPassViewLeft = leftViewForField(newPassField)
        
        resetPasswordButton.frame = CGRect(x: view.frame.width/6, y: confirmPassField.frame.maxY+45, width: view.frame.width*2/3, height: 40)
        resetPasswordButton.addTarget(self, action: #selector(resetPasswordPressed), forControlEvents: .TouchUpInside)
        let attributedString = NSMutableAttributedString(string: "RESET PASSWORD")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString("RESET PASSWORD"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString("RESET PASSWORD"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 17)!, range: (attributedString.string as NSString).rangeOfString("RESET PASSWORD"))
        resetPasswordButton.setAttributedTitle(attributedString, forState: .Normal)
        resetPasswordButton.backgroundColor = UIColor.clearColor()
        
        view.addSubview(resetPasswordButton)
        
        UIView.animateWithDuration(0.5, animations: {
            self.newPassField.alpha = 1.0
            self.newPassViewLeft.alpha = 1.0
            }, completion:{ _ in self.newPassField.becomeFirstResponder()})
        
        UIView.animateWithDuration(0.5, delay: 0.2 , options: [], animations: {
            self.confirmPassField.alpha = 1.0
            self.confirmViewLeft.alpha = 1.0
            }, completion: nil)
        
        UIView.animateWithDuration(0.5, delay: 0.4 , options: [], animations: {self.resetPasswordButton.alpha = 1.0}, completion: nil)
    }
    
    
    func setup(){
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        for i in 2...7{
            codeFields.append(setupCodeField(withTag: i, xPos: view.frame.width/6 + CGFloat(i-1)*view.frame.width/12))
        }
        codeFields[0].becomeFirstResponder()
        
        let backButton = Constants.getBackButton()
        backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .  TouchUpInside)
        view.addSubview(backButton)
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
        
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 75{
                presentViewController(ForgotPasswordController(), animated: false, completion: nil)
            }
        }
    }
}

class CodeField: UITextField {
    
    override func deleteBackward() {
        super.deleteBackward()
        delegate?.textField!(self, shouldChangeCharactersInRange: NSRange(), replacementString: "")
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        text = ""
        return true
    }
}
