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
import JWT

class CreateAccountController: UIViewController, UITextFieldDelegate{
    var webtoken: String?
    var userID: String?
    
    var phoneField = UITextField()
    var passwordField = UITextField()
    var confirmPasswordField = UITextField()
    let createAccountButton = UIButton()
    let fieldHeight: CGFloat = 40
    var fieldWidth: CGFloat!
    var rawNumber = ""
    
    let phoneImage = UIImageView()
    let passwordImage = UIImageView()
    let confirmPasswordImage = UIImageView()
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()
    
    
    override func viewDidLoad() {
        fieldWidth = view.frame.width*4/5
        view.backgroundColor = UIColor.blackColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        addPhoneField()
        addPasswordField()
        addConfirmPasswordField()
        addCreateAccountButton()
        imageViewSetup()
        phoneField.becomeFirstResponder()
        navBarSetup()
    }
    
    func accountPressed(){
        
        createAccount()
    }
    
    func createAccount(){
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        
        let parameters = ["phone" : rawNumber, "password" : confirmPasswordField.text!]
        //Request to /Users
        Alamofire.request(.POST, Constants.accountCreationURLString, parameters: parameters).responseJSON { response in
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    self.userID = JSON(value)["userID"].stringValue
                    
                    //Request to /Authenticate
                    Alamofire.request(.POST, Constants.authenticateURLString, parameters: parameters).responseJSON { response in
                        switch response.result{
                        case .Success:
                            self.webtoken = (JSON(response.result.value!))["token"].stringValue
                            self.activityIndicator.stopAnimating()
                            self.accountCreated()
                        
                        case .Failure:
                            self.activityIndicator.stopAnimating()
                            self.failure()
                    }
                }
            }
            case .Failure:
                self.activityIndicator.stopAnimating()
                self.failure()
            }
        }
    }
    
    func accountCreated(){
        let add = ["56 Montgomery Place", "40 Cedar Street", "333 E 53rd Street"]
        print(userID)
        let newUser = User(phoneNumber: self.phoneField.text!, password: self.confirmPasswordField.text!, userID: userID!, addresses: add)
        let cc = ContainerController()
        cc.loggedInUser = newUser
        self.presentViewController(cc, animated: false, completion: nil)
    }
    

    func failure(){
        activityIndicator.stopAnimating()
    }
    

    //MARK: TextField Setups
    func addPhoneField(){
        phoneField = textFieldSetup(CGRect(x: 10, y: 100, width: fieldWidth, height: fieldHeight))
        phoneField.keyboardType = .PhonePad
        phoneField.text = " Phone Number"
        view.addSubview(phoneField)
    }
    
    func addPasswordField(){
        passwordField = textFieldSetup(CGRect(x: 10, y: 140 + fieldHeight, width: fieldWidth, height: fieldHeight))
        passwordField.text = " Password"
        view.addSubview(passwordField)
    }
    
    func addConfirmPasswordField(){
        confirmPasswordField = textFieldSetup(CGRect(x: 10, y: 180 + fieldHeight*2, width: fieldWidth, height: fieldHeight))
        confirmPasswordField.text = " Confirm Password"
        view.addSubview(confirmPasswordField)
    }

    
    func textFieldSetup(frame: CGRect) -> UITextField{
        let textField = UITextField(frame: frame)
        textField.backgroundColor = UIColor.whiteColor()
        textField.layer.cornerRadius = fieldHeight/8
        textField.contentVerticalAlignment = .Center
        textField.clipsToBounds = true
        textField.delegate = self
        textField.textColor = UIColor.lightGrayColor()
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        textField.font = UIFont(name: "GillSans-Light", size: 17)
        return textField
    }
    
    //MARK: ImageView Setups
    
    func imageViewSetup(){
        phoneImage.frame = CGRect(x:view.frame.width-phoneField.frame.height, y:phoneField.frame.origin.y+phoneField.frame.height/4, width:phoneField.frame.height/2, height: phoneField.frame.height/2)
        view.addSubview(phoneImage)
        
        passwordImage.frame = CGRect(x:view.frame.width-passwordField.frame.height, y:passwordField.frame.origin.y+passwordField.frame.height/4, width:passwordField.frame.height/2, height: passwordField.frame.height/2)
        view.addSubview(passwordImage)
        
        confirmPasswordImage.frame = CGRect(x:view.frame.width-confirmPasswordField.frame.height, y:confirmPasswordField.frame.origin.y+phoneField.frame.height/4, width:confirmPasswordField.frame.height/2, height: confirmPasswordField.frame.height/2)
        view.addSubview(confirmPasswordImage)
    }
    
    
    //MARK: Button Setup
    func addCreateAccountButton(){
        createAccountButton.frame = CGRect(x: 0, y: confirmPasswordField.frame.maxY+100, width: view.frame.width, height: fieldHeight)
        createAccountButton.backgroundColor = Constants.tiltColor
        createAccountButton.setTitle("Create Account", forState: .Normal)
        createAccountButton.titleLabel?.font = UIFont(name: "GillSans-Light", size: 17)
        createAccountButton.addTarget(self, action:#selector(accountPressed) , forControlEvents: .TouchUpInside)
        view.addSubview(createAccountButton)
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
    

    //MARK: TextField Delegate Functions
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.textColor = UIColor.grayColor()
        if textField == passwordField || textField == confirmPasswordField{
            textField.secureTextEntry = true
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == phoneField{
            self.passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            self.confirmPasswordField.becomeFirstResponder()
        }
        else{
            self.view.endEditing(true)
            accountPressed()
        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField){
        if textField == passwordField{
            if passwordField.text!.characters.count < 8 {
                passwordImage.image = UIImage(imageLiteral: "circleRed")
            }
            else{
                passwordImage.image = UIImage(imageLiteral: "circleGreen")
            }
        }
        else if textField == confirmPasswordField{
            if confirmPasswordField.text!.characters.count < 8{
                confirmPasswordImage.image = UIImage(imageLiteral: "circleRed")
            }
            else{
                confirmPasswordImage.image = UIImage(imageLiteral: "circleGreen")
            }
        }
    }
    
    

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneField{
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string) as NSString
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            rawNumber = String(decimalString)
            let length = decimalString.length

            let hasLeadingOne = length > 0 && String(decimalString)[String(decimalString).startIndex] == "1"
            
            if (length == 10 && !hasLeadingOne) || (length == 11 && hasLeadingOne){
                textFieldShouldReturn(phoneField)
                phoneImage.image = UIImage(imageLiteral: "circleGreen")
            }
            else{
                phoneImage.image = UIImage(imageLiteral: "circleRed")
            }
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11{
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                return (newLength > 10) ? false : true
                
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
                formattedString.appendFormat("%@ ", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
                textField.text! = formattedString as String
            return false
        }
            
        else{
            return true
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

}
