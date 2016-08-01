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

class ForgotPasswordController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var rawNumber : String?
    let phoneViewLeft = UIImageView()
    var phoneField: UITextField!
    var sendButton = UIButton()
    
    var placeHolder: String?
    var isSending = false
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarHidden = true
        view.backgroundColor = Constants.darkBlue
        setup()
    }
    
    func setupTextField(frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.backgroundColor = Constants.darkBlue
        textField.textAlignment = .Center
        textField.textColor = UIColor.whiteColor()
        textField.leftViewMode = UITextFieldViewMode.Always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.keyboardType = .PhonePad
        textField.backgroundColor = UIColor.clearColor()
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.whiteColor().CGColor
        
        view.addSubview(textField)
        return textField
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
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
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
            UIView.animateWithDuration(1.0, animations: {textField.layer.borderColor = Constants.lightRed.CGColor})
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
            UIView.animateWithDuration(1.0, animations: {
                textField.layer.borderColor = Constants.seaFoam.CGColor
                self.sendButton.titleLabel?.textColor = Constants.seaFoam
            })
        }
        else if sendButton.titleLabel?.textColor == Constants.seaFoam{
            UIView.animateWithDuration(1.0, animations: {
                textField.layer.borderColor = Constants.lightRed.CGColor
                self.sendButton.titleLabel?.textColor = UIColor.whiteColor()
            })
        }
        return false
    }
    

    func sendPassCode(){
        if rawNumber != nil && rawNumber?.characters.count >= 10 && !isSending{
            isSending = true
            activityIndicator.startAnimating()
            let parameters = ["phone" : rawNumber!]
            Alamofire.request(.POST, Constants.sendPassodeURLString, parameters: parameters).responseJSON { response in
                debugPrint(response)
                self.activityIndicator.stopAnimating()
                switch response.result{
                case .Success:
                    if let value = response.result.value{
                        let json = JSON(value)
                        if json["success"].boolValue{
                            let code = json["code"].stringValue
                            let ec = EnterCodeController()
                            ec.code = code
                            ec.placeHolder = self.placeHolder
                            ec.shouldPromptPasswordChange = true
                            ec.phoneNumber = self.rawNumber!
                            self.presentViewController(ec, animated: false, completion: nil)
                        }
                        else{
                            SweetAlert().showAlert("NO ACCOUNT", subTitle: "No account with this phone number was found", style: .Error,  buttonTitle: "Okay", buttonColor: Constants.tiltColor)
                        }
                    }
                case .Failure:
                    self.isSending = false
                    SweetAlert().showAlert("SERVER ERROR", subTitle: "Please try again later", style: .Error,  buttonTitle: "Okay", buttonColor: Constants.tiltColor)
                }
            }
        }
        else{
            shakeTextField(phoneField, leftView: phoneViewLeft, enterTrue: true)
        }
    }
    
    func backPressed(){
        presentViewController(LoginController(), animated: false, completion: nil)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.text = ""
    }
    
    func setup(){
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/6, width: view.frame.width/2, height: 40))
        phoneField.text = placeHolder ?? ""
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        
        let backButton = Constants.getBackButton()
        backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .TouchUpInside)
        view.addSubview(backButton)
        
        phoneViewLeft.image = UIImage(imageLiteral: "phone")
        phoneViewLeft.frame = CGRect(x:phoneField.frame.minX-35, y: phoneField.frame.minY+5,  width: 30, height: 30)
        view.addSubview(phoneViewLeft)
        
        
        sendButton.frame = CGRect(x: view.frame.width/4, y: phoneField.frame.maxY+30, width: view.frame.width/2, height: 40)
        sendButton.addTarget(self, action: #selector(sendPassCode), forControlEvents: .TouchUpInside)
        let attributedString = NSMutableAttributedString(string: "SEND CODE")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString("SEND CODE"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString("SEND CODE"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 14)!, range: (attributedString.string as NSString).rangeOfString("SEND CODE"))
        sendButton.setAttributedTitle(attributedString, forState: .Normal)
        sendButton.backgroundColor = UIColor.clearColor()
        view.addSubview(sendButton)
        
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 75{
                presentViewController(LoginController(), animated: false, completion: nil)
            }
        }
    }
}
