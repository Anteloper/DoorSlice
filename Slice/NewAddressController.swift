//
//  NewAddressController.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//View Controller for inputting a new address. If the user is sucessful in creating an address, it is passed to the delegate for processing
class NewAddressController: NavBarred, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
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
        actionForBackButton({self.exitWithoutAddress(false)})
        keyboardShouldMoveScreen = UIScreen.main.bounds.height <= 568.0
        dormPicker.delegate = self
        dormPicker.dataSource = self
        textFieldSetup()
        dormPicker.frame = CGRect(x: 0, y: dormField.frame.maxY, width: view.frame.width, height : 130)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        checkData()
        addSave()
    }
    
    func checkData(){
        if dorms == nil{
            Alerts.noAddresses(self)
        }
    }

    func addSave(){
        saveButton = UIButton(frame: CGRect(x: 0, y: roomField.frame.maxY+200, width: view.frame.width, height: 50))
        saveButton.setAttributedTitle(getAttributedTitle("SAVE ADDRESS", size: 16, kern: 6.0, isGreen: false), for: UIControlState())
        saveButton.addTarget(self, action: #selector(self.exitWithAddress), for: .touchUpInside)
        view.addSubview(saveButton)
    }
    
    func getAttributedTitle(_ text: String, size: CGFloat, kern: Double, isGreen: Bool)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        let color = isGreen ? Constants.seaFoam : UIColor.white
        attributedString.addAttribute(NSForegroundColorAttributeName, value: color, range: (attributedString.string as NSString).range(of: text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).range(of: text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: size)!, range: (attributedString.string as NSString).range(of: text))
        return attributedString
    }
    
    func textFieldSetup(){
        dormField = makeTextFieldWithText("  DORM", yPos: 100, isGreen: false)
        roomField = makeTextFieldWithText("  ROOM NUMBER", yPos: 200, isGreen: false)
        roomField.allowsEditingTextAttributes = true
        roomField.autocapitalizationType = .none
        roomField.autocorrectionType = .no

        view.addSubview(dormField)
        view.addSubview(roomField)
    }
    
    func makeTextFieldWithText(_ text: String, yPos: CGFloat, isGreen: Bool)->PickerField{
        let textField = PickerField(frame: CGRect(x: 10, y: yPos, width: view.frame.width-20, height: 40))
        textField.attributedText = getAttributedTitle(text, size: 15, kern: textFieldKern, isGreen: isGreen)
        textField.delegate = self
        textField.backgroundColor = UIColor.clear

        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.bottomBorder = border
        return textField
        
    }
    
    func keyboardWillShow(_ notification: Notification) {
        if keyboardShouldMoveScreen && roomField.isFirstResponder && !viewIsRaised {
            if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                self.view.frame.origin.y -= keyboardSize.height/2
                viewIsRaised = true
            }
        }
    }
    
    func keyboardWillHide(_ notification: Notification?) {
        if roomField.text != "" && roomField.text != "  ROOM"{
            UIView.animate(withDuration: 1.0, animations: {
                self.roomField.bottomBorder?.borderColor = Constants.seaFoam.cgColor
                if self.dormField.text != "  DORM" && self.dormField.text != ""{
                    self.saveButton.titleLabel?.textColor = Constants.seaFoam
                }
            })
        }
        if viewIsRaised{
            if let keyboardSize = ((notification as NSNotification?)?.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                self.view.frame.origin.y += keyboardSize.height
                viewIsRaised = false
            }
        }
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = CharacterSet(charactersIn: acceptableCharacters).inverted
        let filteredString = string.components(separatedBy: cs).joined(separator: "")
        if string != filteredString{
            roomField.bottomBorder?.borderColor = Constants.lightRed.cgColor
            Alerts.shakeView(roomField, enterTrue: false)
        }
        return string == filteredString
    }
    
    
    
    //MARK: TextField Delegate Functions
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if dormField.text != "  DORM" && dormField.text != ""{
            if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                exitWithAddress()
            }
        }
        return true
    }
    
    //Will only be reached when it's roomField
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if roomField.isFirstResponder{
            roomField.resignFirstResponder()
        }
    }

    
    //MARK: TextField Selection Response Functions
    func dormFieldSelected(){
        dormField.attributedText = getAttributedTitle(dorms[selectedDorm], size: 15, kern: textFieldKern, isGreen: false)
        roomField.resignFirstResponder()
        UIView.animate(withDuration: 1.0, animations: {self.dormField.bottomBorder?.borderColor = Constants.seaFoam.cgColor})
        dormField.frame.origin.y = 100
        UIView.animate(withDuration: 0.3, animations: {self.roomField.frame.origin.y = 270}, completion: {if $0 {self.view.addSubview(self.dormPicker)}})
        dormPicker.becomeFirstResponder()
    }
    
    func roomFieldSelected(){
        dormPicker.removeFromSuperview()
        dormField.frame.origin.y = 100
        UIView.animate(withDuration: 0.3, animations: {self.roomField.frame.origin.y = 200})
    }
    
    
    //MARK: PickerView Delegate Functions
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dorms.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let plainString = dorms[row]
        return getAttributedTitle(plainString, size: 14, kern: 3.0, isGreen: false)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDorm = row
    }

    func dormSelected(){
        dormField.attributedText = getAttributedTitle(dorms[selectedDorm], size: 15, kern: textFieldKern, isGreen: false)
    }

    
    //MARK: Return Functions
    func exitWithoutAddress(_ networkError: Bool){
        if networkError && delegate != nil{
            delegate?.retrieveAddresses()
        }
        if delegate != nil{
            delegate!.returnFromNewAddress(withAddress: nil)
        }
        else{
            let tc = TutorialController()
            tc.user = user!
            present(tc, animated: false, completion: nil)
        }

    }
    
    func exitWithAddress(){
        if dormField.text != "  DORM" && dormField.text != ""{
            if roomField.text != "  ROOM NUMBER" && roomField.text != ""{
                let address = Address(school: schoolFullName!, dorm: dormField.text!, room: roomField.text!)
                if delegate != nil{
                    delegate!.returnFromNewAddress(withAddress: address)
                }
                else{
                    let tc = TutorialController()
                    tc.user = user!
                    tc.pendingAddress = address
                    present(tc, animated: false, completion: nil)
                }
            }
            else{
                Alerts.shakeView(roomField, enterTrue: true)
            }
        }
        else{
            Alerts.shakeView(dormField, enterTrue: true)
        }
    }
    
}

class PickerField: UITextField{
    var bottomBorder: CALayer?
}
