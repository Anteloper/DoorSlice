//
//  ForgotPasswordController.swift
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


//Simply a controller with a phone number text field. When the user fills it out and hits send it sends a request to /sendCode
//It then prepares an EnterCodeController to respond appropriately
class ForgotPasswordController: NavBarless, UITextFieldDelegate{
    
    var rawNumber : String?
    let phoneViewLeft = UIImageView()
    var phoneField: UITextField!
    var sendButton = UIButton()
    
    var placeHolder: String?
    var isSending = false
    
    lazy fileprivate var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteralResourceName: "loading"))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        actionForBackButton({self.present(LoginController(), animated: false, completion: nil)})
        setup()
    }
    
    func setupTextField(_ frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.backgroundColor = Constants.darkBlue
        textField.textAlignment = .center
        textField.textColor = UIColor.white
        textField.leftViewMode = UITextFieldViewMode.always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.keyboardType = .phonePad
        textField.backgroundColor = UIColor.clear
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.white.cgColor
        
        view.addSubview(textField)
        return textField
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let decimalString = components.joined(separator: "") as NSString
        let length = decimalString.length
        let hasLeadingOne = length > 0 && decimalString.hasPrefix("1")
        rawNumber = String(decimalString)
            
        if length == 0 || (length > 10 && !hasLeadingOne) || length > 11{
            let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
            return (newLength > 10) ? false : true
        }
        if length == 1{
            UIView.animate(withDuration: 1.0, animations: {textField.layer.borderColor = Constants.lightRed.cgColor})
        }
        
        var index = 0 as Int
        let formattedString = NSMutableString()
        
        if hasLeadingOne{
            formattedString.append("1 ")
            index += 1
        }
        
        if (length - index) > 3{
            let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
            formattedString.appendFormat("(%@) ", areaCode)
            index += 3
        }
            
        if length - index > 3{
            let prefix = decimalString.substring(with: NSMakeRange(index, 3))
            formattedString.appendFormat("%@-", prefix)
            index += 3
        }
            
        let remainder = decimalString.substring(from: index)
        formattedString.append(remainder)
        textField.text = formattedString as String
            
        if (length == 10 && !hasLeadingOne) || (length == 11 && hasLeadingOne){
            UIView.animate(withDuration: 1.0, animations: {
                textField.layer.borderColor = Constants.seaFoam.cgColor
                self.sendButton.titleLabel?.textColor = Constants.seaFoam
            })
        }
        else if sendButton.titleLabel?.textColor == Constants.seaFoam{
            UIView.animate(withDuration: 1.0, animations: {
                textField.layer.borderColor = Constants.lightRed.cgColor
                self.sendButton.titleLabel?.textColor = UIColor.white
            })
        }
        return false
    }
    

    func sendPassCode(){
        view.endEditing(true)
        if rawNumber != nil && rawNumber?.characters.count >= 10 && !isSending{
            isSending = true
            activityIndicator.startAnimating()
            let parameters = ["phone" : rawNumber!]
            
            Alamofire.request(Constants.sendPassodeURLString, method: .post, parameters: parameters).responseJSON { response in
                self.activityIndicator.stopAnimating()
                self.isSending = false
                switch response.result{
                case .success:
                    if let value = response.result.value{
                        let json = JSON(value)
                        if json["success"].boolValue{
                            let code = json["code"].stringValue
                            let ec = EnterCodeController()
                            ec.code = code
                            ec.placeHolder = self.placeHolder
                            ec.shouldPromptPasswordChange = true
                            ec.phoneNumber = self.rawNumber!
                            self.present(ec, animated: false, completion: nil)
                        }
                        else{
                            Alerts.noAccount()
                        }
                    }
                case .failure:
                    Alerts.serverError()
                }
            }
        }
        else{
            Alerts.shakeView(phoneField, enterTrue: true)
            Alerts.shakeView(phoneViewLeft, enterTrue: true)
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func setup(){
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/6, width: view.frame.width/2, height: 40))
        phoneField.text = placeHolder ?? ""
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        
        phoneViewLeft.image = UIImage(imageLiteralResourceName: "phone")
        phoneViewLeft.frame = CGRect(x:phoneField.frame.minX-35, y: phoneField.frame.minY+5,  width: 30, height: 30)
        view.addSubview(phoneViewLeft)
        
        sendButton.frame = CGRect(x: view.frame.width/4, y: phoneField.frame.maxY+30, width: view.frame.width/2, height: 40)
        sendButton.addTarget(self, action: #selector(sendPassCode), for: .touchUpInside)
        let attributedString = NSMutableAttributedString(string: "SEND CODE")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: (attributedString.string as NSString).range(of: "SEND CODE"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).range(of: "SEND CODE"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 14)!, range: (attributedString.string as NSString).range(of: "SEND CODE"))
        sendButton.setAttributedTitle(attributedString, for: UIControlState())
        sendButton.backgroundColor = UIColor.clear
        view.addSubview(sendButton)
    }
    
}
