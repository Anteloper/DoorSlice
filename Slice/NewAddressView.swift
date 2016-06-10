//
//  NewAddressView.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

//
//  NewAddressView.swift
//  DoorSlice
//
//  Created by Oliver Hill on 5/31/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class NewAddressView: UIView, UITextFieldDelegate {
    
    var delegate: Slideable!
    var nameField: UITextField!
    var streetField: UITextField!
    var roomField: UITextField!
    var zipField: UITextField!
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blackColor()
        
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 60, width: frame.width, height: 60))
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.text = "New Address"
        titleLabel.font = UIFont(name: "GillSans-Light", size: 25)
        titleLabel.textAlignment = .Center
        addSubview(titleLabel)
        
        nameField = makeTextFieldWithText("Name (Ex: home)", yPos: 150)
        streetField = makeTextFieldWithText("Bulding Number and Street Name", yPos: 210)
        roomField = makeTextFieldWithText("Room Number", yPos: 270)
        zipField = makeTextFieldWithText("Zip Code", yPos: 330)
        
        addSubview(nameField)
        addSubview(streetField)
        addSubview(roomField)
        addSubview(zipField)
        
        nameField.becomeFirstResponder()
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameField{
            streetField.becomeFirstResponder()
        }
        else if textField == streetField{
            roomField.becomeFirstResponder()
        }
        else if textField == roomField{
            zipField.becomeFirstResponder()
        }
        else{
            delegate.returnFromFullscreen()
        }
        return true
    }
    
    func makeTextFieldWithText(text: String, yPos: CGFloat)->UITextField{
        let textField = UITextField(frame: CGRect(x: 10, y: yPos, width: frame.width-20, height: 40))
        textField.backgroundColor = Properties.tiltColor
        textField.textColor = UIColor.blackColor()
        textField.placeholder = text
        textField.font = UIFont(name: "GillSans-Light", size: 15)
        textField.delegate = self
        return textField
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
