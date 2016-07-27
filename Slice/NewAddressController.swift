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
    var data: [String : [String]]!
    
    var schoolField = PickerField()
    var dormField = PickerField()
    var roomField = PickerField()
    
    var schoolPicker = UIPickerView()
    var dormPicker = UIPickerView()
    var saveButton = UIButton()
    
    var selectedDorm = 0{didSet{dormSelected()}}
    var selectedSchool = 0{didSet{schoolSelected()}}
    
    var keyboardShouldMoveScreen = false
    var viewIsRaised = false
    
    let textFieldKern = 4.0
    let acceptableCharacters = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    
    
    //MARK: Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        keyboardShouldMoveScreen = UIScreen.mainScreen().bounds.height <= 568.0
        schoolPicker.dataSource = self
        schoolPicker.delegate = self
        dormPicker.delegate = self
        dormPicker.dataSource = self
        textFieldSetup()
        schoolPicker.frame = CGRect(x: 0, y: schoolField.frame.maxY, width: view.frame.width, height: 130)
        dormPicker.frame = CGRect(x: 0, y: dormField.frame.maxY, width: view.frame.width, height : 130)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        addCancel()
        addSave()
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
       
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                exitWithoutAddress()
            }
        }
    }

    
    func addCancel(){
        let cancelButton = Constants.getBackButton()
        cancelButton.addTarget(self, action: #selector(self.exitWithoutAddress), forControlEvents: .  TouchUpInside)
        view.addSubview(cancelButton)

    }
    func addSave(){
        saveButton = UIButton(frame: CGRect(x: 0, y: roomField.frame.maxY+100, width: view.frame.width, height: 50))
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
        schoolField = makeTextFieldWithText("  SCHOOL", yPos: 100, isGreen: false)
        dormField = makeTextFieldWithText("  DORM", yPos: 200, isGreen: false)
        roomField = makeTextFieldWithText("  ROOM NUMBER", yPos: 300, isGreen: false)
        roomField.allowsEditingTextAttributes = true
        
        view.addSubview(schoolField)
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
                self.view.frame.origin.y -= keyboardSize.height
                viewIsRaised = true
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        if roomField.text != "" && roomField.text != "  ROOM"{
            UIView.animateWithDuration(1.0, animations: {
                self.roomField.bottomBorder?.borderColor = Constants.seaFoam.CGColor
                if self.schoolField.text != "  SCHOOL" && self.schoolField.text != "" && self.dormField.text != "  DORM" && self.dormField.text != ""{
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
        if textField == schoolField{
            schoolFieldSelected()
            return false
        }
        else if textField == dormField{
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
        
        if schoolField.text != "  SCHOOL" && schoolField.text != "" {
            if dormField.text != "  DORM" && dormField.text != ""{
                if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                    exitWithAddress()
                }
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
    func schoolFieldSelected(){
        schoolField.attributedText = getAttributedTitle(Array(data.keys)[schoolPicker.selectedRowInComponent(0)], size: 15, kern: textFieldKern, isGreen: false)
        roomField.resignFirstResponder()
        dormPicker.removeFromSuperview()
        UIView.animateWithDuration(1.0, animations: {self.schoolField.bottomBorder?.borderColor = Constants.seaFoam.CGColor})
        UIView.animateWithDuration(0.3, animations: {self.dormField.frame.origin.y = CGFloat(270)}, completion: {if $0 {self.view.addSubview(self.schoolPicker) }})
        schoolPicker.becomeFirstResponder()
    }
    
    func dormFieldSelected(){
        dormField.attributedText = getAttributedTitle(data[Array(data.keys)[selectedSchool]]![dormPicker.selectedRowInComponent(0)], size: 15, kern: textFieldKern, isGreen: false)
        roomField.resignFirstResponder()
        schoolPicker.removeFromSuperview()
        UIView.animateWithDuration(1.0, animations: {self.dormField.bottomBorder?.borderColor = Constants.seaFoam.CGColor})
        dormField.frame.origin.y = 150
        UIView.animateWithDuration(0.3, animations: {self.roomField.frame.origin.y = 370}, completion: {if $0 {self.view.addSubview(self.dormPicker)}})
        dormPicker.becomeFirstResponder()
    }
    
    func roomFieldSelected(){
        dormPicker.removeFromSuperview()
        schoolPicker.removeFromSuperview()
        dormField.frame.origin.y = 200
        UIView.animateWithDuration(0.3, animations: {self.roomField.frame.origin.y = 300})
    }
    
    
    //MARK: PickerView Delegate Functions
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pickerView == schoolPicker ? data.count : data[Array(data.keys)[selectedSchool]]!.count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let plainString = pickerView == schoolPicker ? Array(data.keys)[row] : data[Array(data.keys)[selectedSchool]]![row]
        return getAttributedTitle(plainString, size: 14, kern: 3.0, isGreen: false)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == schoolPicker{
            selectedSchool = row
        }
        else{
            selectedDorm = row
        }
    }

    func dormSelected(){
        dormField.attributedText = getAttributedTitle(data[Array(data.keys)[selectedSchool]]![selectedDorm], size: 15, kern: textFieldKern, isGreen: false)
    }
    
    func schoolSelected(){
        dormPicker.reloadComponent(0)
        schoolField.attributedText = getAttributedTitle(Array(data.keys)[selectedSchool], size: 15, kern: textFieldKern, isGreen: false)
    }
    
    func invalidCharacters(){
        shakeTextField(roomField, enterTrue: true)
        let alert = UIAlertController(title: "Invalid Character Used", message: "Please use only letters and numbers when entering your room number", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        presentViewController(alert, animated: false, completion: nil)
    }
    
    //MARK: Return Functions
    func exitWithoutAddress(){
        delegate?.returnFromFullscreen(withCard: nil, orAddress: nil)
    }
    
    func exitWithAddress(){
        if schoolField.text != "  SCHOOL" && schoolField.text != "" {
            if dormField.text != "  DORM" && dormField.text != ""{
                if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                    delegate?.returnFromFullscreen(withCard: nil, orAddress: Address(school: schoolField.text!, dorm: dormField.text!, room: roomField.text!))
                }
                else{
                    shakeTextField(roomField, enterTrue: true)
                }
            }
            else{
                shakeTextField(dormField, enterTrue: true)
            }
        }
        else{
            shakeTextField(schoolField, enterTrue: true)
        }
    }
}

class PickerField: UITextField{
    var bottomBorder: CALayer?
}
