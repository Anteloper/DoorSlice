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
    var delegate: Rateable!
    
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
        contentView.frame = CGRect(x: view.frame.width/2-150, y: view.frame.height/2-150, width: 300, height: 200)
        contentView.backgroundColor = Constants.tiltColor
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
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
        line.frame = CGRect(x: 15, y: 150, width: 270, height: 1)
        line.backgroundColor = Constants.darkBlue.CGColor
        line.opacity = 0.6
        contentView.layer.addSublayer(line)
        
        okayButton.frame = CGRect(x: 165, y: 160, width: 120, height: 35)
        let at = Constants.getTitleAttributedString("YES", size: 18, kern: 6.0)
        at.addAttribute(NSForegroundColorAttributeName, value: Constants.darkBlue.CGColor, range:  ("YES" as NSString).rangeOfString("YES"))
        okayButton.setAttributedTitle(at, forState: .Normal)
        okayButton.addTarget(self, action: #selector(dismissWithAddress) , forControlEvents: .TouchUpInside)
        okayButton.clipsToBounds = true
        contentView.addSubview(okayButton)
        
        let div = CALayer()
        div.frame = CGRect(x: 150, y: 160, width: 1, height: 30)
        div.backgroundColor = Constants.darkBlue.CGColor
        div.opacity = 0.6
        contentView.layer.addSublayer(div)
        
        
        noButton.frame = CGRect(x: 15, y: 160, width: 120, height: 35)
        let at2 = Constants.getTitleAttributedString("NO", size: 18, kern: 6.0)
        at2.addAttribute(NSForegroundColorAttributeName, value: Constants.darkBlue.CGColor, range:  ("NO" as NSString).rangeOfString("NO"))
        noButton.setAttributedTitle(at2, forState: .Normal)
        noButton.addTarget(self, action: #selector(dismissWithoutAddress) , forControlEvents: .TouchUpInside)
        contentView.addSubview(noButton)
        
    }
    
    func dismissWithAddress(){
        delegate.addEmail(emailField.text!)
        removeAlertFromView()
    }
    
    func dismissWithoutAddress(){
        removeAlertFromView()
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
        emailField.frame = CGRect(x: 15, y: yRef+30, width: 270, height: 30)
        emailField.font = UIFont(name: "Myriad Pro", size: 18)
        emailField.textColor = Constants.darkBlue
        emailField.backgroundColor = UIColor.whiteColor()
        emailField.textAlignment = .Center
        emailField.layer.cornerRadius = 5
        emailField.clipsToBounds = true
        emailField.layer.borderColor = UIColor(white: 0.8, alpha: 0.0).CGColor
        emailField.layer.borderWidth = 1.0
        emailField.delegate = self
        contentView.addSubview(emailField)
        
        let lineLeft = CALayer()
        lineLeft.frame = CGRect(x: 15, y: yRef+15, width: 55, height: 1)
        lineLeft.opacity = 0.5
        lineLeft.backgroundColor = Constants.darkBlue.CGColor
        contentView.layer.addSublayer(lineLeft)
        
        let label = UILabel(frame: CGRect(x: 75, y: yRef, width: 150, height: 30))
        label.attributedText = Constants.getTitleAttributedString("EMAIL ADDRESS", size: 10, kern: 6.0)
        label.textAlignment = .Center
        contentView.addSubview(label)
        
        let lineRight = CALayer()
        lineRight.frame = CGRect(x: label.frame.maxX, y: yRef+15, width: 55, height: 1)
        lineRight.opacity = 0.5
        lineRight.backgroundColor = Constants.darkBlue.CGColor
        contentView.layer.addSublayer(lineRight)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(){ UIView.animateWithDuration(0.5, animations: { self.contentView.frame.origin.y -= 100 }) }
    
    func keyboardWillHide(){UIView.animateWithDuration(0.5, animations: {self.contentView.frame.origin.y += 100})}
    
    func showAlert(){
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
        return true
    }
}

