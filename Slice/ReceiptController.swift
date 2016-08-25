//
//  ReceiptController.swift
//  Slice
//
//  Created by Oliver Hill on 8/8/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class ReceiptController: UIViewController, UITextFieldDelegate{
    var contentView = UIView()
    var strongSelf: ReceiptController?
    var titleLabel = UILabel()
    var okayButton = UIButton()
    var noButton = UIButton()
    var emailField = UITextField()
    var completion: (()->Void)?
    var delegate: Rateable!
    var keyBoardIsRaised = false
    
    init(){
        super.init(nibName: nil, bundle: nil)
        let window: UIWindow = UIApplication.sharedApplication().keyWindow!
        window.addSubview(view)
        window.bringSubviewToFront(view)
        
        view.frame = window.bounds
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.3)
        
        strongSelf = self
        addContentView()
        addLabel()
        addEmailField()
        addButtons()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func addContentView(){
        contentView.frame = CGRect(x: view.frame.width/2-150, y: view.frame.height/2-100, width: 300, height: 200)
        contentView.backgroundColor = Constants.darkBlue
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        contentView.layer.borderColor = UIColor.whiteColor().CGColor
        contentView.layer.borderWidth = 1.0
        view.addSubview(contentView)
    }
    
    func addLabel(){
        titleLabel.frame = CGRect(x: 15, y: 15, width: 270, height: 30)
        titleLabel.attributedText = Constants.getTitleAttributedString("TURN ON RECEIPTS?", size: 18, kern: 4.0)
        titleLabel.textAlignment = .Center
        contentView.addSubview(titleLabel)
    }
    
    func addButtons(){
        let line = CALayer()
        line.frame = CGRect(x: 0, y: 150, width: 300, height: 1)
        line.backgroundColor = UIColor.whiteColor().CGColor
        line.opacity = 0.6
        contentView.layer.addSublayer(line)
        
        okayButton.frame = CGRect(x: 151, y: 160, width: 148, height: 35)
        okayButton.setAttributedTitle(Constants.getTitleAttributedString("YES", size: 18, kern: 6.0), forState: .Normal)
        okayButton.addTarget(self, action: #selector(dismissWithAddress) , forControlEvents: .TouchUpInside)
        okayButton.clipsToBounds = true
        contentView.addSubview(okayButton)
        
        let div = CALayer()
        div.frame = CGRect(x: 150, y: 160, width: 1, height: 30)
        div.backgroundColor = UIColor.whiteColor().CGColor

        contentView.layer.addSublayer(div)
        
        noButton.frame = CGRect(x: 0, y: 160, width: 150, height: 35)
        noButton.setAttributedTitle(Constants.getTitleAttributedString("NO", size: 18, kern: 6.0), forState: .Normal)
        noButton.addTarget(self, action: #selector(dismissWithoutAddress) , forControlEvents: .TouchUpInside)
        contentView.addSubview(noButton)
    }
    
    func dismissWithAddress(){
        if isValidEmail(emailField.text!){
            delegate.addEmail(emailField.text!)
            removeAlertFromView()
            if completion != nil { completion!() }
        }
        else{
            shakeTextField(emailField, enterTrue: true)
        }
    }
    
    func dismissWithoutAddress(){
        removeAlertFromView()
        if completion != nil { completion!() }
    }
    
    func removeAlertFromView(){
       
        if emailField.isFirstResponder() { emailField.resignFirstResponder() }
    
        UIView.animateWithDuration(0.3,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: { self.view.alpha = 0.0}, completion: { _ in
                                    self.view.removeFromSuperview()
                                    self.contentView.removeFromSuperview()
                                    self.contentView = UIView()
            }
        )
        self.strongSelf = nil //Releasing strong refrence of itself.
    }

    func addEmailField(){
        let yRef: CGFloat = 65
        emailField.frame = CGRect(x: 15, y: yRef+35, width: 270, height: 30)
        emailField.font = UIFont(name: "Myriad Pro", size: 18)
        emailField.textColor = Constants.darkBlue
        emailField.backgroundColor = UIColor.whiteColor()
        emailField.textAlignment = .Center
        emailField.layer.cornerRadius = 5
        emailField.clipsToBounds = true
        emailField.layer.borderColor = UIColor(white: 0.8, alpha: 0.0).CGColor
        emailField.layer.borderWidth = 1.0
        emailField.autocorrectionType = .No
        emailField.autocapitalizationType = .None
        emailField.delegate = self
        contentView.addSubview(emailField)
        
        let lineLeft = CALayer()
        lineLeft.frame = CGRect(x: 0, y: yRef+15, width: 70, height: 1)
        lineLeft.opacity = 0.5
        lineLeft.backgroundColor = UIColor.whiteColor().CGColor
        contentView.layer.addSublayer(lineLeft)
        
        let label = UILabel(frame: CGRect(x: 75, y: yRef, width: 150, height: 30))
        label.attributedText = Constants.getTitleAttributedString("EMAIL ADDRESS", size: 10, kern: 6.0)
        label.textAlignment = .Center
        contentView.addSubview(label)
        
        let lineRight = CALayer()
        lineRight.frame = CGRect(x: label.frame.maxX, y: yRef+15, width: 70, height: 1)
        lineRight.opacity = 0.5
        lineRight.backgroundColor = UIColor.whiteColor().CGColor
        contentView.layer.addSublayer(lineRight)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(){
        if !keyBoardIsRaised{
            UIView.animateWithDuration(0.5, animations: { self.contentView.frame.origin.y -= 100 })
            keyBoardIsRaised = true
        }
    }
    
    func keyboardWillHide(){
        if keyBoardIsRaised{
            UIView.animateWithDuration(0.5, animations: {self.contentView.frame.origin.y += 100})
            keyBoardIsRaised = false
        }
    }
    
    //Completion will be called after the alert is dismissed, not presented
    func showAlert(completion: (()->Void)?){
        self.completion = completion
        view.alpha = 0;
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.view.alpha = 1.0;
        })
        let previousTransform = self.contentView.transform
        self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.contentView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 0.0)
        }) { (Bool) -> Void in
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
            }) { (Bool) -> Void in
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    self.contentView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0)
                }) { (Bool) -> Void in
                    self.contentView.transform = previousTransform
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        emailField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if isValidEmail(emailField.text!){
            emailField.layer.borderColor = Constants.seaFoam.CGColor
        }
        else{
            emailField.layer.borderColor = Constants.lightRed.CGColor
            
        }
        return true
    }
    
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    func shakeTextField(textField: UITextField, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            textField.frame.origin.x += 3
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                textField.frame.origin.x -= 3
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        textField.frame.origin.x += 3
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                textField.frame.origin.x -= 3
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
}


