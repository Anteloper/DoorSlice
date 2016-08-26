//
//  LoginController.swift
//  Slice
//
//  Created by Oliver Hill on 6/27/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.


import UIKit
import Alamofire
import SwiftyJSON

class LoginController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var phoneField = UITextField()
    var passwordField = UITextField()
    let phoneViewLeft = UIImageView()
    let passViewLeft = UIImageView()
    let goButton = UIButton()
    var rawNumber =  String()
    var autoFilledNumber: String?
    
    lazy private var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()

    var shouldShowBackButton: Bool?
    
    //MARK: LifeCycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarHidden = true
        view.backgroundColor = Constants.darkBlue
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setup()
        view.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: view.frame.midX, y: passwordField.frame.maxY + 10)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.5, animations: {self.phoneField.alpha = 1.0; self.phoneViewLeft.alpha = 1.0})
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {self.passwordField.alpha = 1.0; self.passViewLeft.alpha = 1.0}, completion: nil)
        
    }
    
    func loginPressed(){
        if phoneField.text != ""{
            if passwordField.text != ""{
                activityIndicator.startAnimating()
                    loginRequest()
            }
            else{
                shakeTextField(passwordField, leftView: passViewLeft, enterTrue: true)
            }
        }
        else{
            shakeTextField(phoneField, leftView: phoneViewLeft, enterTrue: true)
        }
    }
    
    func loginRequest(){
        let parameters = ["phone" : rawNumber, "password" : passwordField.text!]
        Alamofire.request(.POST, Constants.loginURLString, parameters: parameters).responseJSON{ response in
            debugPrint(response)
            self.activityIndicator.stopAnimating()
            switch response.result{
            case .Success:
                if let value = response.result.value{
                        if JSON(value)["success"].boolValue{
                        self.loginUser(self.parseUser(fromJSON: JSON(value)))
                    }
                    else{
                        self.shakeTextField(self.phoneField, leftView: self.phoneViewLeft, enterTrue: true)
                        self.shakeTextField(self.passwordField, leftView: self.passViewLeft, enterTrue: true)
                    }
                }
            case .Failure:
                Alerts.serverError()
            }
        }
    }
    
    func parseUser(fromJSON fromJson: JSON)->User{
        print(fromJson)
        let jwt = fromJson["JWT"].stringValue
        let json = fromJson["User Profile"]
        let userID = json["_id"].stringValue
        let wantsReceipts = json["wantsReceipts"].boolValue
        let school = json["school"].stringValue
        let hasSeenTutorial = json["hasSeenTutorial"].boolValue
        let wantsOrderConfirmation = json["wantsConfirmation"].boolValue
        var email: String? = json["email"].stringValue
        if email == "noEmail"{
            email = nil
        }
        let hasCreatedFirstCard = json["hasStripeProfile"].boolValue
        let cardsJson = json["cards"].arrayValue
        let addressesJson = json["addresses"].arrayValue
        
        var addressIDs = [String : String]()
        var addresses = [Address]()
        var cards = ["Pay"]
        var cardIDs = [String : String]()
        var preferredAddress: Int? = nil
        var preferredPayment: PaymentPreference = PaymentPreference.ApplePay
        var orderHistory = [PastOrder]()
        
        for address in addressesJson{
            let add = Address(school: address["School"].stringValue, dorm: address["Dorm"].stringValue, room: address["Room"].stringValue)
            addresses.append(add)
            addressIDs[add.getName()] = address["_id"].stringValue
        }
        
        for card in cardsJson{
            let lastFour = card["lastFour"].stringValue
            let cardID = card["cardID"].stringValue
            if(lastFour != "0"){
                cards.append(lastFour)
                cardIDs[lastFour] = cardID
            }
        }
        
        if let lastOrder = json["orders"].arrayValue.last{
            let lastAddID = lastOrder["address"].stringValue
            for possAdd in addresses{
                if addressIDs[possAdd.getName()] == lastAddID{
                    preferredAddress = addresses.indexOf(possAdd)
                }
            }
            let lastCardID = lastOrder["cardUsed"].stringValue
        
            if lastCardID != Constants.applePayCardID{
                for lastFour in cards{
                    if cardIDs[lastFour] == lastCardID{
                        preferredPayment = PaymentPreference.CardIndex(cards.indexOf(lastFour)!)
                    }
                }
            }
        }
        
        for order in json["orders"].arrayValue{
            let jsonAddress = order["address"].arrayValue.first!
            let trueAddress = Address(school: jsonAddress["School"].stringValue, dorm: jsonAddress["Dorm"].stringValue, room: jsonAddress["Room"].stringValue)
            
            var lastFour = "applePay"
            if !(order["cardUsed"].stringValue == Constants.applePayCardID){
                for lFour in cards{
                    if cardIDs[lFour] == order["cardUsed"].stringValue{
                        lastFour = lFour
                    }
                }
            }
            let cheese = order["cheese"].intValue
            let pepperoni = order["pepperoni"].intValue
            let price = order["price"].doubleValue
            let timeOrdered = stringToDate(order["orderDate"].stringValue)
            orderHistory.append(PastOrder(address: trueAddress, cheeseSlices: cheese, pepperoniSlices: pepperoni, price: price, timeOrdered: timeOrdered, paymentMethod: lastFour))
        }
        
        
        let user = User(userID: userID, addresses: addresses,
                        addressIDs: addressIDs,
                        preferredAddress: preferredAddress,
                        cards: cards,
                        cardIDs: cardIDs,
                        paymentMethod: preferredPayment,
                        hasCreatedFirstCard: hasCreatedFirstCard,
                        isLoggedIn: true,
                        jwt: jwt,
                        orderHistory: orderHistory,
                        hasPromptedRating: nil,
                        loyaltySlices: 0,
                        hasSeenTutorial: hasSeenTutorial,
                        email: email,
                        wantsReceipts: wantsReceipts,
                        wantsOrderConfirmation: wantsOrderConfirmation,
                        school: school)
        return user
            
    }
    
    func stringToDate(date:String) -> NSDate {
        let formatter = NSDateFormatter()
        
        // Format 1
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let parsedDate = formatter.dateFromString(date) { return parsedDate }
        
        // Format 2
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:SSSZ"
        if let parsedDate = formatter.dateFromString(date) { return parsedDate }
        
        // Couldn't parsed with any format. Just get the date
        let splitedDate = date.componentsSeparatedByString("T")
        if splitedDate.count > 0 {
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsedDate = formatter.dateFromString(splitedDate[0]) {
                return parsedDate
            }
        }
        return NSDate()
    }
    
    func loginUser(user: User){
        view.endEditing(true)
        if user.hasSeenTutorial{
            let cc = ContainerController()
            cc.loggedInUser = user
            self.presentViewController(cc, animated: false, completion: nil)
        }
        else{
            let tc = TutorialController()
            tc.user = user
            self.presentViewController(tc, animated: false, completion: nil)
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
    
    
    //MARK: TextField Setup
    func setupTextField(frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.backgroundColor = Constants.darkBlue
        textField.textAlignment = .Center
        textField.textColor = UIColor.whiteColor()
        textField.leftViewMode = UITextFieldViewMode.Always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.layer.borderColor = UIColor.whiteColor().CGColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 5
        view.addSubview(textField)
        return textField
    }
    
    //MARK: TextField Management
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == phoneField{
            passwordField.becomeFirstResponder()
        }
        else{
            passwordField.resignFirstResponder()
            loginPressed()
        }
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        phoneField.resignFirstResponder()
        passwordField.resignFirstResponder()
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
                textFieldShouldReturn(phoneField)
            }
            return false
        }
        return true
    }
    

    func setup(){
        let doorsliceLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.frame.width, height: 30))
        doorsliceLabel.attributedText = Constants.getTitleAttributedString(" DOORSLICE", size: 25, kern: 18.0)
        doorsliceLabel.textAlignment = .Center
        view.addSubview(doorsliceLabel)
        
        let logoWidth = view.frame.width/4
        let logoView = UIImageView(frame: CGRect(x: view.frame.midX-logoWidth/2, y: 100, width: logoWidth, height: logoWidth))
        logoView.contentMode = .ScaleAspectFit
        logoView.layer.minificationFilter = kCAFilterTrilinear
        logoView.image = UIImage(imageLiteral: "pepperoni")
        view.addSubview(logoView)
        
        let fieldSpacing:CGFloat = UIScreen.mainScreen().bounds.height <= 568.0 ? 15 : 25
        
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/2 - (40 + fieldSpacing), width: view.frame.width/2, height: 40))
        phoneField.alpha = 0.0
        phoneField.text = rawNumber
        phoneField.keyboardType = .NumberPad
        phoneField.text = autoFilledNumber != nil ? autoFilledNumber! : ""
        
        passwordField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/2 + fieldSpacing, width: view.frame.width/2, height: 40))
        passwordField.alpha = 0.0
        passwordField.secureTextEntry = true
        
        phoneViewLeft.image = UIImage(imageLiteral: "phone")
        phoneViewLeft.frame = CGRect(x:phoneField.frame.minX-35, y: phoneField.frame.minY+5,  width: 30, height: 30)
        phoneViewLeft.alpha = 0.0
        view.addSubview(phoneViewLeft)
        
        passViewLeft.image =  UIImage(imageLiteral: "padlock")
        passViewLeft.frame = CGRect(x:passwordField.frame.minX-35, y: passwordField.frame.minY+5, width: 30, height: 30)
        passViewLeft.alpha = 0.0
        view.addSubview(passViewLeft)
        
        let goButton = UIButton(frame: CGRect(x: view.frame.width/4, y: 4*view.frame.height/5-30, width: view.frame.width/2, height: 40))
        goButton.addTarget(self, action: #selector(loginPressed), forControlEvents: .TouchUpInside)
        let attributedString = NSMutableAttributedString(string: "LOGIN")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (attributedString.string as NSString).rangeOfString("LOGIN"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).rangeOfString("LOGIN"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 18)!, range: (attributedString.string as NSString).rangeOfString("LOGIN"))
        goButton.setAttributedTitle(attributedString, forState: .Normal)
        goButton.backgroundColor = UIColor.clearColor()
        view.addSubview(goButton)
        
        if shouldShowBackButton == nil || shouldShowBackButton! == true{
            let backButton = Constants.getBackButton()
            backButton.addTarget(self, action: #selector(backPressed), forControlEvents: .  TouchUpInside)
            view.addSubview(backButton)
        }
        
        let forgotPassword = UIButton(frame: CGRect(x: view.frame.width/4, y: goButton.frame.maxY+60, width: view.frame.width/2, height: 40))
        forgotPassword.addTarget(self, action: #selector(forgotPasswordPressed), forControlEvents: .TouchUpInside)
        
        let attributedString2 = NSMutableAttributedString(string: "FORGOT PASSWORD")
        attributedString2.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString2.string as NSString).rangeOfString("FORGOT PASSWORD"))
        attributedString2.addAttribute(NSKernAttributeName, value: CGFloat(3.0), range: (attributedString2.string as NSString).rangeOfString("FORGOT PASSWORD"))
        attributedString2.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 11)!, range: (attributedString2.string as NSString).rangeOfString("FORGOT PASSWORD"))
        forgotPassword.setAttributedTitle(attributedString2, forState: .Normal)
        forgotPassword.backgroundColor = UIColor.clearColor()
        view.addSubview(forgotPassword)
        
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                presentViewController(WelcomeController(), animated: false, completion: nil)
            }
        }
    }
    
    func forgotPasswordPressed(){
        let fc = ForgotPasswordController()
        if rawNumber.characters.count >= 10{
            fc.placeHolder = phoneField.text
            fc.rawNumber = rawNumber
        }
        presentViewController(fc, animated: false, completion: nil)
    }
    
    func backPressed(){
        presentViewController(WelcomeController(), animated: false, completion: nil)
    }

}
