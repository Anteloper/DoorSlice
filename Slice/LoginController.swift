//
//  LoginController.swift
//  Slice
//
//  Created by Oliver Hill on 6/27/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.


import UIKit
import Alamofire
import SwiftyJSON

//When fields are non-empty, submits a request to /Login and parses out the response JSON into a User object.
//Then checks if the user has seen the tutorial or not and responds appropriately
class LoginController: NavBarless, UITextFieldDelegate{
    
    var phoneField = UITextField()
    var passwordField = UITextField()
    let phoneViewLeft = UIImageView()
    let passViewLeft = UIImageView()
    let goButton = UIButton()
    var rawNumber =  String()
    var autoFilledNumber: String?
    
    lazy fileprivate var activityIndicator : CustomActivityIndicatorView = {
        return CustomActivityIndicatorView(image: UIImage(imageLiteral: "loading-1"))
    }()
    
    //MARK: LifeCycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        actionForBackButton({self.present(WelcomeController(), animated: false, completion: nil)})
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setup()
        view.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: view.frame.midX, y: passwordField.frame.maxY + 10)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5, animations: {self.phoneField.alpha = 1.0; self.phoneViewLeft.alpha = 1.0})
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {self.passwordField.alpha = 1.0; self.passViewLeft.alpha = 1.0}, completion: nil)
        
    }
    
    func loginPressed(){
        if phoneField.text != ""{
            if passwordField.text != ""{
                activityIndicator.startAnimating()
                    loginRequest()
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
    
    func loginRequest(){
        let parameters = ["phone" : rawNumber, "password" : passwordField.text!]
        Alamofire.request(.POST, Constants.loginURLString, parameters: parameters).responseJSON{ response in
            self.activityIndicator.stopAnimating()
            switch response.result{
            case .Success:
                if let value = response.result.value{
                        if JSON(value)["success"].boolValue{
                        self.loginUser(self.parseUser(fromJSON: JSON(value)))
                    }
                    else{
                        Alerts.shakeView(self.phoneField, enterTrue: true)
                        Alerts.shakeView(self.phoneViewLeft, enterTrue: true)
                        Alerts.shakeView(self.passwordField, enterTrue: true)
                        Alerts.shakeView(self.passViewLeft, enterTrue: true)
                    }
                }
            case .Failure:
                Alerts.serverError()
            }
        }
    }
    
    func parseUser(fromJSON fromJson: JSON)->User{
        let jwt = fromJson["JWT"].stringValue
        let json = fromJson["User Profile"]
        let userID = json["_id"].stringValue
        let wantsReceipts = json["wantsReceipts"].boolValue
        let school = json["school"].stringValue
        let hasSeenTutorial = json["hasSeenTutorial"].boolValue
        let wantsOrderConfirmation = json["wantsConfirmation"].boolValue
        var email: String? = json["email"].stringValue
        if email == "noEmail"{email = nil}
        let hasCreatedFirstCard = json["hasStripeProfile"].boolValue
        let cardsJson = json["cards"].arrayValue
        let addressesJson = json["addresses"].arrayValue
        
        //Variable initialization to blank values
        var addressIDs = [String : String]()
        var addresses = [Address]()
        var cards = [String]()
        var cardIDs = [String : String]()
        var preferredAddress = 0
        var preferredCard = 0
        var orderHistory = [PastOrder]()
        
        //User Addresses
        for address in addressesJson{
            let add = Address(school: address["School"].stringValue, dorm: address["Dorm"].stringValue, room: address["Room"].stringValue)
            addresses.append(add)
            addressIDs[add.getName()] = address["_id"].stringValue
        }
        
        //User Cards
        for card in cardsJson{
            let lastFour = card["lastFour"].stringValue
            let cardID = card["cardID"].stringValue
            if(lastFour != "0"){
                cards.append(lastFour)
                cardIDs[lastFour] = cardID
            }
        }
        
        //Last Used Address and Card
        if let lastOrder = json["orders"].arrayValue.last{
            let lastAddID = lastOrder["address"].stringValue
            for possAdd in addresses{
                if addressIDs[possAdd.getName()] == lastAddID{
                    if let pa = addresses.index(of: possAdd){
                        preferredAddress = pa
                    }
                }
            }
            let lastCardID = lastOrder["cardUsed"].stringValue
        
            for lastFour in cards{
                if cardIDs[lastFour] == lastCardID{
                    if let pc = cards.index(of: lastFour){
                        preferredCard = pc
                    }
                }
            }
        }
        
        //Order History
        for order in json["orders"].arrayValue{
            var trueAddress = Address()
            if let jsonAddress = order["Address"].arrayValue.first {
                trueAddress = Address(school: jsonAddress["School"].stringValue, dorm: jsonAddress["Dorm"].stringValue, room: jsonAddress["Room"].stringValue)
            }
            
            var lastFour = ""
            for lFour in cards{
                if cardIDs[lFour] == order["cardUsed"].stringValue{
                    lastFour = lFour
                }
            }
            
            let cheese = order["cheese"].intValue
            let pepperoni = order["pepperoni"].intValue
            let price = order["price"].doubleValue
            let timeOrdered = stringToDate(order["orderDate"].stringValue)
            orderHistory.append(PastOrder(address: trueAddress, cheeseSlices: cheese, pepperoniSlices: pepperoni, price: price, timeOrdered: timeOrdered, paymentMethod: lastFour))
        }
        
        //Create User
        let user = User(userID: userID, addresses: addresses,
                        addressIDs: addressIDs,
                        preferredAddress: preferredAddress,
                        cards: cards,
                        cardIDs: cardIDs,
                        preferredCard: preferredCard,
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
    
    func stringToDate(_ date:String) -> Date {
        let formatter = DateFormatter()
        
        // Format 1
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let parsedDate = formatter.date(from: date) { return parsedDate }
        
        // Format 2
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:SSSZ"
        if let parsedDate = formatter.date(from: date) { return parsedDate }
        
        // Couldn't parsed with any format. Just get the date
        let splitedDate = date.components(separatedBy: "T")
        if splitedDate.count > 0 {
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsedDate = formatter.date(from: splitedDate[0]) {
                return parsedDate
            }
        }
        return Date()
    }
    
    func loginUser(_ user: User){
        view.endEditing(true)
        if user.hasSeenTutorial{
            let cc = ContainerController()
            cc.loggedInUser = user
            self.present(cc, animated: false, completion: nil)
        }
        else{
            let tc = TutorialController()
            tc.user = user
            self.present(tc, animated: false, completion: nil)
        }
    }
    
    
    //MARK: TextField Setup
    func setupTextField(_ frame: CGRect)->UITextField{
        let textField = UITextField(frame: frame)
        textField.delegate = self
        textField.backgroundColor = Constants.darkBlue
        textField.textAlignment = .center
        textField.textColor = UIColor.white
        textField.leftViewMode = UITextFieldViewMode.always
        textField.font = UIFont(name: "Myriad Pro", size: 18)
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 5
        view.addSubview(textField)
        return textField
    }
    
    //MARK: TextField Management
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneField{
            passwordField.becomeFirstResponder()
        }
        else{
            passwordField.resignFirstResponder()
            loginPressed()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        phoneField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneField{
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
                textFieldShouldReturn(phoneField)
            }
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if UIScreen.main.bounds.height <= 480.0 && textField == passwordField{
            UIView.animate(withDuration: 0.2, animations: {self.view.frame.origin.y -= 200})
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if UIScreen.main.bounds.height <= 480.0 && textField == passwordField{
            UIView.animate(withDuration: 0.2, animations: {self.view.frame.origin.y += 200})
        }
    }
    

    func setup(){
        let doorsliceLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.frame.width, height: 30))
        doorsliceLabel.attributedText = Constants.getTitleAttributedString(" DOORSLICE", size: 25, kern: 18.0)
        doorsliceLabel.textAlignment = .center
        view.addSubview(doorsliceLabel)
        
        let logoWidth = view.frame.width/4
        let logoView = UIImageView(frame: CGRect(x: view.frame.midX-logoWidth/2, y: 100, width: logoWidth, height: logoWidth))
        logoView.contentMode = .scaleAspectFit
        logoView.layer.minificationFilter = kCAFilterTrilinear
        logoView.image = UIImage(imageLiteral: "pepperoni")
        view.addSubview(logoView)
        
        let fieldSpacing:CGFloat = UIScreen.main.bounds.height <= 568.0 ? 15 : 25
        
        phoneField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/2 - (40 + fieldSpacing), width: view.frame.width/2, height: 40))
        phoneField.alpha = 0.0
        phoneField.text = rawNumber
        phoneField.keyboardType = .numberPad
        phoneField.text = autoFilledNumber != nil ? autoFilledNumber! : ""
        
        passwordField = setupTextField(CGRect(x: view.frame.width/4, y: view.frame.height/2 + fieldSpacing, width: view.frame.width/2, height: 40))
        passwordField.alpha = 0.0
        passwordField.isSecureTextEntry = true
        
        phoneViewLeft.image = UIImage(imageLiteral: "phone")
        phoneViewLeft.frame = CGRect(x:phoneField.frame.minX-35, y: phoneField.frame.minY+5,  width: 30, height: 30)
        phoneViewLeft.alpha = 0.0
        view.addSubview(phoneViewLeft)
        
        passViewLeft.image =  UIImage(imageLiteral: "padlock")
        passViewLeft.frame = CGRect(x:passwordField.frame.minX-35, y: passwordField.frame.minY+5, width: 30, height: 30)
        passViewLeft.alpha = 0.0
        view.addSubview(passViewLeft)
        
        let goButton = UIButton(frame: CGRect(x: view.frame.width/4, y: 4*view.frame.height/5-30, width: view.frame.width/2, height: 40))
        goButton.addTarget(self, action: #selector(loginPressed), for: .touchUpInside)
        let attributedString = NSMutableAttributedString(string: "LOGIN")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Constants.seaFoam, range: (attributedString.string as NSString).range(of: "LOGIN"))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(6.0), range: (attributedString.string as NSString).range(of: "LOGIN"))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 18)!, range: (attributedString.string as NSString).range(of: "LOGIN"))
        goButton.setAttributedTitle(attributedString, for: UIControlState())
        goButton.backgroundColor = UIColor.clear
        view.addSubview(goButton)
        
        let forgotPassword = UIButton(frame: CGRect(x: view.frame.width/4, y: goButton.frame.maxY+60, width: view.frame.width/2, height: 40))
        forgotPassword.addTarget(self, action: #selector(forgotPasswordPressed), for: .touchUpInside)
        
        let attributedString2 = NSMutableAttributedString(string: "FORGOT PASSWORD")
        attributedString2.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: (attributedString2.string as NSString).range(of: "FORGOT PASSWORD"))
        attributedString2.addAttribute(NSKernAttributeName, value: CGFloat(3.0), range: (attributedString2.string as NSString).range(of: "FORGOT PASSWORD"))
        attributedString2.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: 11)!, range: (attributedString2.string as NSString).range(of: "FORGOT PASSWORD"))
        forgotPassword.setAttributedTitle(attributedString2, for: UIControlState())
        forgotPassword.backgroundColor = UIColor.clear
        view.addSubview(forgotPassword)

    }
    
    
    func forgotPasswordPressed(){
        let fc = ForgotPasswordController()
        if rawNumber.characters.count >= 10{
            fc.placeHolder = phoneField.text
            fc.rawNumber = rawNumber
        }
        present(fc, animated: false, completion: nil)
    }
}
