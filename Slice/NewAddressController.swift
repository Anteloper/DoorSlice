//
//  NewAddressController.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class NewAddressController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate{
    var delegate: Slideable?
    var dorms: [String]!
    var schoolFullName: String!
    
    var dormField = PickerField()
    var roomField = PickerField()

    var dormPicker = UIPickerView()
    var saveButton = UIButton()
    
    var selectedDorm = 0{didSet{dormSelected()}}
    
    var keyboardShouldMoveScreen = false
    var viewIsRaised = false
    
    let textFieldKern = 4.0
    let acceptableCharacters = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    var user: User?
    
    
    //MARK: Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        navBarSetup()
        keyboardShouldMoveScreen = UIScreen.mainScreen().bounds.height <= 568.0
        dormPicker.delegate = self
        dormPicker.dataSource = self
        textFieldSetup()
        dormPicker.frame = CGRect(x: 0, y: dormField.frame.maxY, width: view.frame.width, height : 130)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        checkData()
        addCancel()
        addSave()
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
       
    }
    
    func checkData(){
        if dorms == nil{
            Alerts.noAddresses(self)
        }
    }
    
    func navBarSetup(){
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("DOORSLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        let backButton = UIButton(type: .Custom)
        backButton.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        backButton.addTarget(self, action: #selector(exitWithoutAddress), forControlEvents: .TouchUpInside)
        backButton.frame = CGRect(x: -40, y: -4, width: 20, height: 20)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                exitWithoutAddress(false)
            }
        }
    }

    func addCancel(){
        let cancelButton = Constants.getBackButton()
        cancelButton.addTarget(self, action: #selector(self.exitWithoutAddress), forControlEvents: .  TouchUpInside)
        view.addSubview(cancelButton)

    }
    func addSave(){
        saveButton = UIButton(frame: CGRect(x: 0, y: roomField.frame.maxY+200, width: view.frame.width, height: 50))
        saveButton.setAttributedTitle(getAttributedTitle("SAVE ADDRESS", size: 16, kern: 6.0, isGreen: false), forState: .Normal)
        saveButton.addTarget(self, action: #selector(self.exitWithAddress), forControlEvents: .TouchUpInside)
        view.addSubview(saveButton)
    }
    
    func getAttributedTitle(text: String, size: CGFloat, kern: Double, isGreen: Bool)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        let color = isGreen ? Constants.seaFoam : UIColor.whiteColor()
        attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: size)!, range: (attributedString.string as NSString).rangeOfString(text))
        return attributedString
    }
    
    func textFieldSetup(){
        dormField = makeTextFieldWithText("  DORM", yPos: 100, isGreen: false)
        roomField = makeTextFieldWithText("  ROOM NUMBER", yPos: 200, isGreen: false)
        roomField.allowsEditingTextAttributes = true

        view.addSubview(dormField)
        view.addSubview(roomField)
    }
    
    func makeTextFieldWithText(text: String, yPos: CGFloat, isGreen: Bool)->PickerField{
        let textField = PickerField(frame: CGRect(x: 10, y: yPos, width: view.frame.width-20, height: 40))
        textField.attributedText = getAttributedTitle(text, size: 15, kern: textFieldKern, isGreen: isGreen)
        textField.delegate = self
        textField.backgroundColor = UIColor.clearColor()

        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.whiteColor().CGColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.bottomBorder = border
        return textField
        
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if keyboardShouldMoveScreen && roomField.isFirstResponder() && !viewIsRaised {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                self.view.frame.origin.y -= keyboardSize.height/2
                viewIsRaised = true
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        if roomField.text != "" && roomField.text != "  ROOM"{
            UIView.animateWithDuration(1.0, animations: {
                self.roomField.bottomBorder?.borderColor = Constants.seaFoam.CGColor
                if self.dormField.text != "  DORM" && self.dormField.text != ""{
                    self.saveButton.titleLabel?.textColor = Constants.seaFoam
                }
            })
        }
        if viewIsRaised{
            if let keyboardSize = (notification?.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                self.view.frame.origin.y += keyboardSize.height
                viewIsRaised = false
            }
        }
    }
    
    func shakeTextField(textField: UITextField, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            textField.frame.origin.x += 10
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                textField.frame.origin.x -= 10
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        textField.frame.origin.x += 10
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                textField.frame.origin.x -= 10
                                }, completion: { _ in
                                    if enterTrue{
                                        self.shakeTextField(textField, enterTrue: false)
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
        let cs = NSCharacterSet(charactersInString: acceptableCharacters).invertedSet
        let filteredString = string.componentsSeparatedByCharactersInSet(cs).joinWithSeparator("")
        if string != filteredString{
            roomField.bottomBorder?.borderColor = Constants.lightRed.CGColor
            shakeTextField(roomField, enterTrue: false)
        }
        return string == filteredString
    }
    
    
    
    //MARK: TextField Delegate Functions
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {

        if textField == dormField{
            dormFieldSelected()
            return false
        }
        else{
            roomFieldSelected()
            return true
        }
    }
    
    //Will only be reached when it's roomField
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if dormField.text != "  DORM" && dormField.text != ""{
            if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                exitWithAddress()
            }
        }
        return true
    }
    
    //Will only be reached when it's roomField
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = ""
    }

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if roomField.isFirstResponder(){
            roomField.resignFirstResponder()
        }
    }

    
    //MARK: TextField Selection Response Functions
    func dormFieldSelected(){
        dormField.attributedText = getAttributedTitle(dorms[selectedDorm], size: 15, kern: textFieldKern, isGreen: false)
        roomField.resignFirstResponder()
        UIView.animateWithDuration(1.0, animations: {self.dormField.bottomBorder?.borderColor = Constants.seaFoam.CGColor})
        dormField.frame.origin.y = 100
        UIView.animateWithDuration(0.3, animations: {self.roomField.frame.origin.y = 270}, completion: {if $0 {self.view.addSubview(self.dormPicker)}})
        dormPicker.becomeFirstResponder()
    }
    
    func roomFieldSelected(){
        dormPicker.removeFromSuperview()
        dormField.frame.origin.y = 100
        UIView.animateWithDuration(0.3, animations: {self.roomField.frame.origin.y = 200})
    }
    
    
    //MARK: PickerView Delegate Functions
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dorms.count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let plainString = dorms[row]
        return getAttributedTitle(plainString, size: 14, kern: 3.0, isGreen: false)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDorm = row
    }

    func dormSelected(){
        dormField.attributedText = getAttributedTitle(dorms[selectedDorm], size: 15, kern: textFieldKern, isGreen: false)
    }

    
    //MARK: Return Functions
    func exitWithoutAddress(networkError: Bool){
        if networkError && delegate != nil{
            delegate?.retrieveAddresses()
        }
        if delegate != nil{
            delegate!.returnFromFullscreen(withCard: nil, orAddress: nil, fromSettings: false)
        }
        else{
            let tc = TutorialController()
            tc.user = user!
            presentViewController(tc, animated: false, completion: nil)
        }

    }
    
    func exitWithAddress(){
        
        if dormField.text != "  DORM" && dormField.text != ""{
            if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                let address = Address(school: schoolFullName!, dorm: dormField.text!, room: roomField.text!)
                if delegate != nil{
                    delegate!.returnFromFullscreen(withCard: nil, orAddress: address, fromSettings: false)
                }
                else{
                    let tc = TutorialController()
                    tc.user = user!
                    tc.pendingAddress = address
                    presentViewController(tc, animated: false, completion: nil)
                }
            }
            else{
                shakeTextField(roomField, enterTrue: true)
            }
        }
        else{
            shakeTextField(dormField, enterTrue: true)
        }
    }
    
}

class PickerField: UITextField{
    var bottomBorder: CALayer?
}
