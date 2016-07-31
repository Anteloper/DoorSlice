//
//  PaymentViewController.swift
//  Slice
//
//  Created by Oliver Hill on 6/16/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import Stripe


class NewCardController: UIViewController, STPPaymentCardTextFieldDelegate, UIGestureRecognizerDelegate{
    
    let paymentTextField = STPPaymentCardTextField()
    var delegate: Slideable?
    var validated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBarSetup()
        view.backgroundColor = Constants.darkBlue
        paymentTextField.textColor = UIColor.whiteColor()
        paymentTextField.frame = CGRect(x: 15, y: 100, width: view.frame.width-30, height: 44)
        paymentTextField.delegate = self
        view.addSubview(paymentTextField)
        addCancel()
        let swipe = UIPanGestureRecognizer(target: self, action: #selector(self.didSwipe(_:)))
        swipe.delegate = self
        view.addGestureRecognizer(swipe)
        
    }
    
    func navBarSetup(){
        navigationController?.navigationBar.barTintColor = Constants.darkBlue
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        titleLabel.attributedText = Constants.getTitleAttributedString("SLICE", size: 16, kern: 6.0)
        titleLabel.textAlignment = .Center
        navigationItem.titleView = titleLabel
        
        let backButton = UIButton(type: .Custom)
        backButton.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        backButton.addTarget(self, action: #selector(exit), forControlEvents: .TouchUpInside)
        backButton.frame = CGRect(x: -40, y: -4, width: 20, height: 20)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    func didSwipe(recognizer: UIPanGestureRecognizer){
        if recognizer.state == .Ended{
            let point = recognizer.translationInView(view)
            if(abs(point.x) >= abs(point.y)) && point.x > 40{
                exit()
            }
        }
    }

    func addCancel(){
        let cancelButton = Constants.getBackButton()
        cancelButton.addTarget(self, action: #selector(self.exit), forControlEvents: .  TouchUpInside)
        view.addSubview(cancelButton)
    }
    
    func exit(){
        self.delegate!.returnFromFullscreen(withCard: nil, orAddress: nil)
    }
    
    func paymentCardTextFieldDidChange(textField: STPPaymentCardTextField) {
        
        if(textField.isValid && !validated){
            
            validated = true //Because it was running this code twice for some reason
            textField.resignFirstResponder()
            
            let sideLength: CGFloat = 2/3*view.frame.size.width
            let origin = CGPoint(x:view.frame.size.width/2-sideLength/2, y:view.frame.height/2-sideLength/2)
            let checkView = UIImageView(frame: CGRect(origin: origin, size: CGSize(width: sideLength, height: sideLength)))
            checkView.image = UIImage(imageLiteral: "check")
            checkView.contentMode = .ScaleToFill
            view.addSubview(checkView)
            checkView.alpha = 0.6
            
            //Animate
            checkView.transform = CGAffineTransformMakeScale(0,0)
            UIView.animateWithDuration(0.75,
                                       delay: 0.0,
                                       usingSpringWithDamping: 0.5,
                                       initialSpringVelocity: 15,
                                       options: .CurveLinear,
                                       animations: {
                                        checkView.transform = CGAffineTransformIdentity
                                       },
                                       completion: {
                                        if($0){
                                            UIView.animateWithDuration(0.3, animations: {
                                                checkView.alpha = 0.0
                                                }, completion:{
                                                    if($0){
                                                        self.delegate!.returnFromFullscreen(withCard: textField.cardParams, orAddress: nil)
                                                    }
                                                }
                                            )
                                        }
                                    }
            )
        }
    }
}



