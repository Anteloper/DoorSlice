//
//  TutorialController.swift
//  Slice
//
//  Created by Oliver Hill on 8/11/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit

class TutorialController: UIViewController {
    
    var user: User!
    var addressButton = UIButton()
    var paymentButton = UIButton()
    var addresses = ActiveAddresses()
    
    //MARK: Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.darkBlue
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = .Default
        
    }
    
    override func viewDidAppear(animated: Bool){
        let isIphone5 = UIScreen.mainScreen().bounds.height <= 568.0
        let fullView = UIImageView(frame: view.frame)
        fullView.image = UIImage(imageLiteral: isIphone5 ? "" : "darkblue")
        fullView.layer.minificationFilter = kCAFilterTrilinear
        view.addSubview(fullView)
        fullView.alpha = 0.0
        UIView.animateWithDuration(1.0, animations: {fullView.alpha = 1.0}){
            if $0{
                self.addAddressButton()
                self.addLabel()
                self.addPaymentButton()
                self.addSliceLabel()
                self.addGoButton()
                if self.user.addresses?.count != 0{
                    if let addName = self.user.addresses!.first?.getName(){
                        self.addressCompleted(addName)
                    }
                }
                
                if NetworkingController.canApplePay() || self.user.cards?.count != 0{
                    
                }
            }
        }
    }
    
    //MARK: Address Views
    
    func addAddressButton(){
        let label = UILabel(frame: CGRect(x: 0, y: 130, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("ADD YOUR ROOM NUMBER", size: 14, kern: 4.0)
        label.textAlignment = .Center
        view.addSubview(label)
        
        addressButton.frame = CGRect(x: 0, y: 120, width: view.frame.width, height: 115)
        addressButton.addTarget(self, action: #selector(addressPressed), forControlEvents: .TouchUpInside)
        view.addSubview(addressButton)
    }
    
    
    func addressPressed(){
        //TODO: Transition horizontally
        let na = NewAddressController()
        na.data = addresses.getData()
        presentViewController(NewAddressController(), animated: false, completion: nil)
        
        
    }
    
    func addressCompleted(address: String){
        
    }
    
    //MARK: Payment Views
    func addPaymentButton(){
        let label = UILabel(frame: CGRect(x: 0, y: 245, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("ADD A PAYMENT METHOD", size: 14, kern: 4.0)
        label.textAlignment = .Center
        view.addSubview(label)
        
        paymentButton.frame = CGRect(x: 0, y: 235, width: view.frame.width, height: 115)
        paymentButton.addTarget(self, action: #selector(paymentPressed), forControlEvents: .TouchUpInside)
        view.addSubview(paymentButton)
    }
    
    
    func paymentPressed(){
        
    }
    
    func paymentCompleted(payment: PaymentPreference){
        
    }
    
    //MARK: Slice Views
    func addSliceLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: 360, width: view.frame.width, height: 30))
        label.attributedText = Constants.getTitleAttributedString("TAP A SLICE TO ORDER", size: 14, kern: 4.0)
        label.textAlignment = .Center
        view.addSubview(label)
    }
    
    //MARK: Bottom Views
    func addLabel(){
        let label = UILabel(frame: CGRect(x: 0, y: view.frame.height*4/5-20, width: view.frame.width, height: 40))
        label.attributedText = Constants.getTitleAttributedString("WE'LL BE THERE IN FIVE", size: 20, kern: 6.0)
        label.textAlignment = .Center
        view.addSubview(label)
    }
    
    func addGoButton(){
        let goButton = UIButton(frame: CGRect(x: view.frame.midX-40, y: view.frame.height*7/8-20, width: 80, height: 80))
        goButton.addTarget(self, action: #selector(goPressed), forControlEvents: .TouchUpInside)
        view.addSubview(goButton)
    }
    
    func goPressed(){
        let cc = ContainerController()
        cc.loggedInUser = user
        presentViewController(cc, animated: false, completion: nil)
    }
}
