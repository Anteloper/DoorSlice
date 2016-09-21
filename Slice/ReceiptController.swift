//
//  ReceiptController.swift
//  Slice
//
//  Created by Oliver Hill on 8/8/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

//Alert specifically for prompting the user for their receipt preference and email if applicable
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
        let window: UIWindow = UIApplication.shared.keyWindow!
        window.addSubview(view)
        window.bringSubview(toFront: view)
        
        view.frame = window.bounds
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
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
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.layer.borderWidth = 1.0
        view.addSubview(contentView)
    }
    
    func addLabel(){
        titleLabel.frame = CGRect(x: 15, y: 15, width: 270, height: 30)
        titleLabel.attributedText = Constants.getTitleAttributedString("TURN ON RECEIPTS?", size: 18, kern: 4.0)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }
    
    func addButtons(){
        let line = CALayer()
        line.frame = CGRect(x: 0, y: 150, width: 300, height: 1)
        line.backgroundColor = UIColor.white.cgColor
        line.opacity = 0.6
        contentView.layer.addSublayer(line)
        
        okayButton.frame = CGRect(x: 151, y: 160, width: 148, height: 35)
        okayButton.setAttributedTitle(Constants.getTitleAttributedString("YES", size: 18, kern: 6.0), for: UIControlState())
        okayButton.addTarget(self, action: #selector(dismissWithAddress) , for: .touchUpInside)
        okayButton.clipsToBounds = true
        contentView.addSubview(okayButton)
        
        let div = CALayer()
        div.frame = CGRect(x: 150, y: 160, width: 1, height: 30)
        div.backgroundColor = UIColor.white.cgColor

        contentView.layer.addSublayer(div)
        
        noButton.frame = CGRect(x: 0, y: 160, width: 150, height: 35)
        noButton.setAttributedTitle(Constants.getTitleAttributedString("NO", size: 18, kern: 6.0), for: UIControlState())
        noButton.addTarget(self, action: #selector(dismissWithoutAddress) , for: .touchUpInside)
        contentView.addSubview(noButton)
    }
    
    func dismissWithAddress(){
        if isValidEmail(emailField.text!){
            delegate.addEmail(emailField.text!)
            removeAlertFromView()
            if completion != nil { completion!() }
        }
        else{
            Alerts.shakeView(emailField, enterTrue: true)
        }
    }
    
    func dismissWithoutAddress(){
        removeAlertFromView()
        if completion != nil { completion!() }
    }
    
    func removeAlertFromView(){
       
        if emailField.isFirstResponder { emailField.resignFirstResponder() }
    
        UIView.animate(withDuration: 0.3,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseOut,
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
        emailField.backgroundColor = UIColor.white
        emailField.textAlignment = .center
        emailField.layer.cornerRadius = 5
        emailField.clipsToBounds = true
        emailField.layer.borderColor = UIColor(white: 0.8, alpha: 0.0).cgColor
        emailField.layer.borderWidth = 1.0
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none
        emailField.delegate = self
        contentView.addSubview(emailField)
        
        let lineLeft = CALayer()
        lineLeft.frame = CGRect(x: 0, y: yRef+15, width: 70, height: 1)
        lineLeft.opacity = 0.5
        lineLeft.backgroundColor = UIColor.white.cgColor
        contentView.layer.addSublayer(lineLeft)
        
        let label = UILabel(frame: CGRect(x: 75, y: yRef, width: 150, height: 30))
        label.attributedText = Constants.getTitleAttributedString("EMAIL ADDRESS", size: 10, kern: 6.0)
        label.textAlignment = .center
        contentView.addSubview(label)
        
        let lineRight = CALayer()
        lineRight.frame = CGRect(x: label.frame.maxX, y: yRef+15, width: 70, height: 1)
        lineRight.opacity = 0.5
        lineRight.backgroundColor = UIColor.white.cgColor
        contentView.layer.addSublayer(lineRight)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(){
        if !keyBoardIsRaised{
            UIView.animate(withDuration: 0.5, animations: { self.contentView.frame.origin.y -= 100 })
            keyBoardIsRaised = true
        }
    }
    
    func keyboardWillHide(){
        if keyBoardIsRaised{
            UIView.animate(withDuration: 0.5, animations: {self.contentView.frame.origin.y += 100})
            keyBoardIsRaised = false
        }
    }
    
    //Completion will be called after the alert is dismissed, not presented
    func showAlert(_ completion: (()->Void)?){
        self.completion = completion
        view.alpha = 0;
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.alpha = 1.0;
        })
        let previousTransform = self.contentView.transform
        self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.contentView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 0.0)
        }, completion: { (Bool) -> Void in
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 0.0)
            }, completion: { (Bool) -> Void in
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.contentView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0)
                }, completion: { (Bool) -> Void in
                    self.contentView.transform = previousTransform
                }) 
            }) 
        }) 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if isValidEmail(emailField.text!){
            emailField.layer.borderColor = Constants.seaFoam.cgColor
        }
        else{
            emailField.layer.borderColor = Constants.lightRed.cgColor
            
        }
        return true
    }
    
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
}
