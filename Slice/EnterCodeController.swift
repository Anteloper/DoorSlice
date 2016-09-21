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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}



//View Controller for authenticating phone numbers or changing password.
//Any controller instantiating this one MUST SET the shouldPromptPasswordChange, code, and phoneNumber variables

//When creating a user it sends a request to /Users waits for a response, then /Authenticate. It then creates the user locally
//And passes the user to an instance of TutorialController
class EnterCodeController: NavBarless, UITextFieldDelegate{
    
    var code: String!
    var shouldPromptPasswordChange: Bool!
    var phoneNumber: String!
    
    var school: String! //Must be set if creating user
    var password: String? //Must be set if creating user
    
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
    
    lazy fileprivate var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteralResourceName: "loading"))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        let previousVc = shouldPromptPasswordChange! ? ForgotPasswordController() : CreateAccountController()
        actionForBackButton(){
            if !self.requestIsProcessing{
                self.present(previousVc, animated: false, completion: nil)
            }
        }
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let label = UILabel(frame: CGRect(x: 5, y: codeFields[0].frame.maxY+15, width: view.frame.width-10, height: 50))
        label.numberOfLines = 0
        label.textAlignment = .center
        let message = "ENTER THE SIX DIGIT CODE TEXTED TO YOU"
        let attributedString = NSMutableAttributedString(string: message)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (attributedString.string as NSString).range(of: message))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(5.0), range: (attributedString.string as NSString).range(of: message))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 14)!, range: (attributedString.string as NSString).range(of: message))
        label.attributedText = attributedString
        label.alpha = 0.0
        view.addSubview(label)
        
        UIView.animate(withDuration: 1.5, animations: {label.alpha = 1.0}, completion: nil)
    }


    
    //MARK: Networking Functions
    func changePassword(_ newPass: String){
        let parameters = ["phone" : phoneNumber, "code" : code, "password" : newPass]
        requestIsProcessing = true
        Alamofire.request(Constants.resetPasswordURLString, method: .post, parameters: parameters).responseJSON{ response in
            switch response.result{
            case .success:
                if let value = response.result.value{
                    if JSON(value)["success"].boolValue{
                        let lc = LoginController()
                        if self.placeHolder != nil{
                            lc.autoFilledNumber = self.placeHolder
                            lc.rawNumber = self.phoneNumber
                        }
                        self.present(lc, animated: false, completion: {_ in Alerts.passwordReset()})
                    }
                }
                
            case .failure:
                Alerts.serverError()
            }
        }
    }
    
    func createAccount(){
        let parameters1 = ["phone" : phoneNumber, "password" : password, "school" : school]
        let parameters2 = ["phone" : phoneNumber, "password" : password]
        //Request to /Users
        Alamofire.request(Constants.accountCreationURLString, method: .post, parameters: parameters1).responseJSON { response in
            switch response.result{
                
            case .success:
                if let value = response.result.value{
                    let json = JSON(value)
                    if json["success"].boolValue{
                        let userID = JSON(value)["userID"].stringValue
                        //Request to /Authenticate
                        Alamofire.request(Constants.authenticateURLString, method: .post, parameters: parameters2).responseJSON{ response in
                            self.activityIndicator.stopAnimating()
                            switch response.result{
                            case .success:
                                if let value = response.result.value{
                                    let jwt = JSON(value)["token"].stringValue
                                    let newUser = User(userID: userID, jwt: jwt, school: self.school)
                                    let tc = TutorialController()
                                    tc.user = newUser
                                    self.view.endEditing(true)
                                    let navController = tc
                                    self.present(navController, animated: false, completion: nil)
                                }
                            case .failure:
                                self.failure()
                            }
                        }
                    }
                    else{
                        self.activityIndicator.stopAnimating()
                        self.failure()
                    }
                }
            case .failure:
                self.failure()
            }
        }
    }
    
    func failure(){
        Alerts.serverError()
    }
    
    //MARK: TextField Management
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if UIScreen.main.bounds.height <= 480.0 && textField == confirmPassField{
            UIView.animate(withDuration: 0.2, animations: {self.view.frame.origin.y -= 200})
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if UIScreen.main.bounds.height <= 480.0 && textField == confirmPassField{
            UIView.animate(withDuration: 0.2, animations: {self.view.frame.origin.y += 200})
        }
    }
    

    func textFieldDidChange(_ textField: UITextField){
        if textField == newPassField{
            if textField.text?.characters.count == 5{
                UIView.animate(withDuration: 1.0, animations: {self.newPassField.layer.borderColor = Constants.seaFoam.cgColor})
            }
                
            else if (textField.text?.characters.count)! < 5 && UIColor(cgColor: newPassField.layer.borderColor!) != Constants.lightRed{
                UIView.animate(withDuration: 1.0, animations: {
                    self.newPassField.layer.borderColor = Constants.lightRed.cgColor
                    self.resetPasswordButton.titleLabel?.textColor = UIColor.white
                })
            }
            
            if UIColor(cgColor: confirmPassField.layer.borderColor!) == Constants.seaFoam{
                if newPassField.text != confirmPassField.text{
                    UIView.animate(withDuration: 1.0, animations: {
                        self.confirmPassField.layer.borderColor = Constants.lightRed.cgColor
                        self.resetPasswordButton.titleLabel?.textColor = UIColor.white
                    })
                }
            }
        }

        else{
            if textField.text == newPassField.text && textField.text?.characters.count >= 5{
                UIView.animate(withDuration: 1.0, animations: {self.confirmPassField.layer.borderColor = Constants.seaFoam.cgColor})
            }
            else if textField.text != newPassField.text && UIColor(cgColor: confirmPassField.layer.borderColor!) != Constants.lightRed{
                UIView.animate(withDuration: 1.0, animations: {
                    self.confirmPassField.layer.borderColor = Constants.lightRed.cgColor
                    self.resetPasswordButton.titleLabel?.textColor = UIColor.white
                })
            }
        }
        
        if UIColor(cgColor: resetPasswordButton.layer.borderColor!) == Constants.seaFoam{
            if UIColor(cgColor: newPassField.layer.borderColor!) == Constants.seaFoam{
                if UIColor(cgColor: confirmPassField.layer.borderColor!) == Constants.seaFoam{
                    UIView.animate(withDuration: 1.0, animations: {self.resetPasswordButton.titleLabel?.textColor = Constants.seaFoam})
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField is CodeField{
            if !bordersAreRed{
                for border in borders{
                    UIView.animate(withDuration: 1.0, animations: {border.borderColor = Constants.lightRed.cgColor})
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
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPassField{
            confirmPassField.becomeFirstResponder()
        }
        else if textField == confirmPassField{
            confirmPassField.resignFirstResponder()
            resetPasswordPressed()
        }
        return true
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
                UIView.animate(withDuration: 1.0, animations: {border.borderColor = Constants.seaFoam.cgColor})
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
                Alerts.shakeView(field, enterTrue: true)
            }
        }
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func resetPasswordPressed(){
        if newPassField.text?.characters.count >= 5{
            if confirmPassField.text == newPassField.text{
                changePassword(confirmPassField.text!)
            }
            else{
                Alerts.shakeView(confirmPassField, enterTrue: true)
                Alerts.shakeView(confirmViewLeft, enterTrue: true)
            }
        }
        else{
            Alerts.shakeView(newPassField, enterTrue: true)
            Alerts.shakeView(newPassViewLeft, enterTrue: true)
        }
    }
    
    //MARK: Setup Functions
    func setupCodeField(withTag tag: Int, xPos: CGFloat)->CodeField{
        let textField = CodeField(frame: CGRect(x: xPos, y: view.frame.height/6, width: view.frame.width*3/48, height: 40))
        textField.delegate = self
        textField.tag = tag
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.textColor = UIColor.white
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        borders.append(border)
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
        
        view.addSubview(textField)
        return textField
    }
    
    
    func setupTextField(_ frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.textAlignment = .center
        textField.textColor = UIColor.white
        textField.leftViewMode = UITextFieldViewMode.always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.white.cgColor
        textField.clipsToBounds = true
        view.addSubview(textField)
        return textField
    }
    
    
    //Returns a padlock UIImageView to the left of the text field entered
    func leftViewForField(_ field: UITextField)-> UIImageView{
        let iview = UIImageView()
        iview.image = UIImage(imageLiteralResourceName: "padlock")
        iview.alpha = 0.0
        iview.frame = CGRect(x: field.frame.minX-40, y: field.frame.minY+5, width: 30, height: 30)
        view.addSubview(iview)
        return iview
    }

    
    func addPasswordTextFields(){
        newPassField = setupTextField(CGRect(x: view.frame.width/4, y: codeFields[1].frame.maxY+70, width: view.frame.width/2, height: 40))
        newPassField.alpha = 0.0
        newPassField.isSecureTextEntry = true
        
        confirmPassField = setupTextField(CGRect(x: view.frame.width/4, y: newPassField.frame.maxY+40, width: view.frame.width/2, height: 40))
        confirmPassField.alpha = 0.0
        confirmPassField.isSecureTextEntry = true
        
        confirmViewLeft = leftViewForField(confirmPassField)
        newPassViewLeft = leftViewForField(newPassField)
        
        resetPasswordButton.frame = CGRect(x: view.frame.width/6, y: confirmPassField.frame.maxY+45, width: view.frame.width*2/3, height: 40)
        resetPasswordButton.addTarget(self, action: #selector(resetPasswordPressed), for: .touchUpInside)
        let attributedString = NSMutableAttributedString(string: "RESET PASSWORD")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: (attributedString.string as NSString).range(of: "RESET PASSWORD"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).range(of: "RESET PASSWORD"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 17)!, range: (attributedString.string as NSString).range(of: "RESET PASSWORD"))
        resetPasswordButton.setAttributedTitle(attributedString, for: UIControlState())
        resetPasswordButton.backgroundColor = UIColor.clear
        
        view.addSubview(resetPasswordButton)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.newPassField.alpha = 1.0
            self.newPassViewLeft.alpha = 1.0
            }, completion:{ _ in self.newPassField.becomeFirstResponder()})
        
        UIView.animate(withDuration: 0.5, delay: 0.2 , options: [], animations: {
            self.confirmPassField.alpha = 1.0
            self.confirmViewLeft.alpha = 1.0
            }, completion: nil)
        
        UIView.animate(withDuration: 0.5, delay: 0.4 , options: [], animations: {self.resetPasswordButton.alpha = 1.0}, completion: nil)
    }
    
    
    func setup(){
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        for i in 2...7{
            codeFields.append(setupCodeField(withTag: i, xPos: view.frame.width/6 + CGFloat(i-1)*view.frame.width/12))
        }
        _ = codeFields[0].becomeFirstResponder()
    }
}

class CodeField: UITextField {
    
    override func deleteBackward() {
        super.deleteBackward()
        _ = delegate?.textField!(self, shouldChangeCharactersIn: NSRange(), replacementString: "")
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        text = ""
        return true
    }
}
