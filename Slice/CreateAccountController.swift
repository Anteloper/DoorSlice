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

class CreateAccountController: UIViewController, UITextFieldDelegate{
    
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
        view.backgroundColor = UIColor.whiteColor()
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
        Alamofire.request(.POST, Constants.accountCreationURLString, parameters: parameters).responseJSON { response in
            switch response.result{
            case .Success:
                self.activityIndicator.stopAnimating()
                if let value = response.result.value{
                    let json = JSON(value)
                    print(json)
                    let id = json["data"]["_id"].stringValue
                    if id == "" { self.failure() }
                    else{
                        let add = ["56 Montgomery Place", "40 Cedar Street", "333 E 53rd Street"]
                        let newUser = User(phoneNumber: self.phoneField.text!, password: self.confirmPasswordField.text!, userID: id, addresses: add)
                        let cc = ContainerController()
                        cc.loggedInUser = newUser
                        self.presentViewController(cc, animated: false, completion: nil)
                    }
                }
            case .Failure(let error):
                self.activityIndicator.stopAnimating()
                print(error)
            }
        }
    }

    func failure(){
    
    }
    
    
    
    //MARK: TextField Setups
    func addPhoneField(){
        phoneField = textFieldSetup(CGRect(x: 10, y: 100, width: fieldWidth, height: fieldHeight))
        phoneField.keyboardType = .PhonePad
        phoneField.placeholder = "Phone Number"
        view.addSubview(phoneField)
    }
    
    func addPasswordField(){
        passwordField = textFieldSetup(CGRect(x: 10, y: 110 + fieldHeight, width: fieldWidth, height: fieldHeight))
        passwordField.secureTextEntry = true
        passwordField.placeholder = "Password"
        view.addSubview(passwordField)
    }
    
    func addConfirmPasswordField(){
        confirmPasswordField = textFieldSetup(CGRect(x: 10, y: 120 + fieldHeight*2, width: fieldWidth, height: fieldHeight))
        confirmPasswordField.secureTextEntry = true
        confirmPasswordField.placeholder = "Confirm Password"
        view.addSubview(confirmPasswordField)
    }
    

    func textFieldSetup(frame: CGRect) -> UITextField{
        let textField = UITextField(frame: frame)
        textField.backgroundColor = Constants.tiltColor
        textField.layer.cornerRadius = fieldHeight/8
        textField.contentVerticalAlignment = .Center
        textField.clipsToBounds = true
        textField.delegate = self
        textField.textColor = UIColor.whiteColor()
        textField.font = UIFont(name: "GillSans-Light", size: 17)
        return textField
    }
    
    //MARK: ImageView Setups
    
    func imageViewSetup(){
        phoneImage.frame = CGRect(x:view.frame.width-phoneField.frame.height, y:phoneField.frame.origin.y, width:phoneField.frame.height, height: phoneField.frame.height)
        view.addSubview(phoneImage)
        
        passwordImage.frame = CGRect(x:view.frame.width-passwordField.frame.height, y:passwordImage.frame.origin.y, width:passwordField.frame.height, height: passwordField.frame.height)
        view.addSubview(passwordImage)
        
        confirmPasswordImage.frame = CGRect(x:view.frame.width-confirmPasswordField.frame.height, y:confirmPasswordField.frame.origin.y, width:confirmPasswordField.frame.height, height: confirmPasswordField.frame.height)
        view.addSubview(confirmPasswordImage)
    }
    
    
    //MARK: Button Setup
    func addCreateAccountButton(){
        createAccountButton.frame = CGRect(x: 0, y: confirmPasswordField.frame.maxY+100, width: view.frame.width, height: fieldHeight)
        createAccountButton.backgroundColor = Constants.sliceColor
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == passwordField{
            
        }
        else if textField == confirmPasswordField{
            
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
                phoneImage.image = UIImage(imageLiteral: "check")
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
    
    
    
    
}
