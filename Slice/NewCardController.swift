//
//  PaymentViewController.swift
//  Slice
//
//  Created by Oliver Hill on 6/16/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import Stripe

//View Controller for adding a credit card. When the user does so the information is passed to the delegate for processing
class NewCardController: NavBarred, STPPaymentCardTextFieldDelegate{
    
    let paymentTextField = STPPaymentCardTextField()
    var delegate: Slideable?
    var validated = false
    
    var user: User!//Only needed when presented by an instance of TutorialController
    var shouldDismissWithApplePayAlert: Bool?//Will be true when presented by an instance of TutorialController and the user has Apple Pay
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionForBackButton({self.exit()})
        paymentTextField.textColor = UIColor.whiteColor()
        paymentTextField.frame = CGRect(x: 15, y: 100, width: view.frame.width-30, height: 44)
        paymentTextField.delegate = self
        view.addSubview(paymentTextField)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldDismissWithApplePayAlert != nil{
            if shouldDismissWithApplePayAlert!{
                Alerts.applePayFound(self)
            }
        }
    }
    
    func exit(){
        if delegate != nil{
            self.delegate!.returnFromNewCard(withCard: nil)
        }
        else{
            let tc = TutorialController()
            tc.user = self.user
            presentViewController(tc, animated: false, completion: nil)
        }
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
            UIView.animateWithDuration(0.75, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15, options: .CurveLinear, animations: {
                checkView.transform = CGAffineTransformIdentity
            }){
                if($0){
                    UIView.animateWithDuration(0.3, animations: {
                        checkView.alpha = 0.0
                        }, completion:{
                            if($0){
                                if self.delegate != nil{
                                    self.delegate!.returnFromNewCard(withCard: textField.cardParams)
                                }
                                else{
                                    let tc = TutorialController()
                                    tc.user = self.user
                                    tc.pendingCard = textField.cardParams
                                    self.presentViewController(tc, animated: false, completion: nil)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}