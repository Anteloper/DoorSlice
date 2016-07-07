//
//  ContainerController.swift
//  Slice
//
//  Created by Oliver Hill on 6/9/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//


import UIKit
import Stripe


//The overseeing ViewController for the entire project. Nothing in this controller is directly visible
//Even the navigation bar belongs to the SliceController object it keeps track of. 
//It is a delegate for the menuController, sliceController, newCardController, and paymentController objects it contains
class ContainerController: UIViewController, Slideable, Payable, PKPaymentAuthorizationViewControllerDelegate {
    
    var sliceController: SliceController!
    var navController: UINavigationController!
    var menuController: MenuController?
    var newCardController: NewCardController?
    let paymentController = PaymentController()
    
    var loggedInUser: User!
    var paymentPreferenceChanged = false{didSet{print(paymentPreferenceChanged)}}
    
    var menuIsVisible = false{ didSet{ showShadow(menuIsVisible) } }
    let amountVisibleOfSliceController: CGFloat = 110
    
    var amount = 0//Should only be touched by the amountPaid function which is called by paymentController
    var orderDescription = ""
    
    var applePayCancelled = true
    var applePayFailed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(loggedInUser.cardIDs)
        print(loggedInUser.userID)
        sliceController = SliceController()
        sliceController.delegate = self
        paymentController.delegate = self
        
        navController = UINavigationController(rootViewController: sliceController)
        view.addSubview(navController.view)
        addChildViewController(navController)
        navController.didMoveToParentViewController(self)
    }
    
    
    //MARK: Slideable Functions
    
    func getPaymentAndAddress() -> (String, String){
        var digits = "Pay"
        if loggedInUser.paymentMethod != nil{
            switch loggedInUser.paymentMethod!{
            case .CardIndex(let index):
                if(loggedInUser.cards != nil){
                    digits = loggedInUser.cards![index]
                }
            default:break
            }
        }
        //TODO: Is there a situation where this or the force unwrap above could crash?
        return(digits, loggedInUser.addresses![loggedInUser.preferredAddress!])
    }
    
    
    func toggleMenu() {
        
        if !menuIsVisible && menuController == nil{
            menuController = MenuController()
            menuController?.addresses = loggedInUser.addresses ?? [String]()
            menuController?.cards = loggedInUser.cards
            menuController?.preferredAddress = loggedInUser.preferredAddress
            menuController?.preferredCard = loggedInUser.paymentMethod ?? .ApplePay
            menuController?.delegate = self
            view.insertSubview(menuController!.view, atIndex: 0)
            addChildViewController(menuController!)
            menuController!.didMoveToParentViewController(self)
        }
        
        if !menuIsVisible{
            menuIsVisible = true
            animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController, fromFullScreen: false)
        }
            
            
        else{
            //Check if changed and update preferenceChanged property so we can update card on backend if needed when they try to buy
            if menuController!.preferredCard != (loggedInUser.paymentMethod == nil ? .CardIndex(23452) : loggedInUser.paymentMethod!) {
                paymentPreferenceChanged = true
            }
            loggedInUser.paymentMethod = menuController!.preferredCard
            loggedInUser.preferredAddress = menuController?.preferredAddress
            animateCenterPanelXPosition(0, fromFullScreen: false) { finished in
                self.menuIsVisible = false
                self.menuController?.view.removeFromSuperview()
                self.menuController = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, fromFullScreen: Bool, completion: ((Bool) ->Void)! = nil){
        
        UIView.animateWithDuration(0.3,
                                   delay: 0.0,
                                   options: [.CurveEaseInOut],
                                   animations: {
                                    if(fromFullScreen){
                                       self.newCardController?.view.alpha = 0.0
                                    }
                                    self.navController.view.frame.origin.x = targetPosition},
                                   completion:completion
        )
    }
    
    func showShadow(shouldShowShadow: Bool){
        if shouldShowShadow{
            navController.view.layer.shadowOpacity = 0.8
        }
        else{
            navController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func userTap(){
        if menuIsVisible{
            toggleMenu()
        }
    }
    func menuCurrentlyShowing()->Bool{
        return menuIsVisible
    }
    
    func bringMenuToFullscreen(isCardInput isCardInput: Bool) {
        if(newCardController == nil && isCardInput){
            newCardController = NewCardController()
            newCardController!.delegate = self
            view.insertSubview(newCardController!.view, atIndex: 1)
            addChildViewController(newCardController!)
            newCardController!.didMoveToParentViewController(self)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false){
                if($0){
                    self.menuController?.removeFromParentViewController()
                    self.newCardController?.paymentTextField.becomeFirstResponder()
                }
            }
        }
        else if !isCardInput{
            menuController?.addAddressView()
        }
    }

    
    func returnFromFullscreen(withCard card: STPCardParams?) {
        if card != nil{
            let lastFour = card!.last4()!
            if !loggedInUser.cards!.contains(lastFour){
        
                menuController?.cardBeingProcessed = lastFour
        
                let url = loggedInUser.cardIDs.count == 0 ? Constants.firstCardURLString : Constants.newCardURLString
                paymentController.saveNewCard(card!, url: url+loggedInUser.userID, lastFour: lastFour)
                
            }
            //TODO: Alert User Duplicates
            else{
                print("duplicate")
            }
           
        }
        animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController, fromFullScreen: true){ didComplete in
            if didComplete{
                self.newCardController?.view.removeFromSuperview()
                self.newCardController = nil
                self.menuController?.tableView.reloadData()
            }
        }
    }
    
    
    //MARK: Payment Functions
    
    //The beginning point for any payment process when the sliceController timer runs out. This function decides which
    //payment method is appropriate and the calls the correct function
    func payForOrder(cheese cheese: Double, pepperoni: Double) {
        if loggedInUser.paymentMethod != nil{
            orderDescription = String(Int(cheese)) + "cheese, " + String(Int(pepperoni)) + "pepperoni"
            if case .ApplePay = loggedInUser.paymentMethod!{
                if PaymentController.canApplePay(){
                    let paymentRequest = paymentController.createPaymentRequest(cheese: cheese, pepperoni: pepperoni)
                    
                    //Send it to an apple-made viewcontroller. This will take my PKPaymentRequest and turn it into a PKPayment which is passed to function bleow
                    let paymentAuthVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                    paymentAuthVC.delegate = self
                    sliceController.presentViewController(paymentAuthVC, animated: true, completion: nil)
                }
            }
            else{
                let amount = String(Int(((cheese*4 + pepperoni*4)*100)))
                sliceController.orderProcessing()
                if paymentPreferenceChanged{
                    let lastFour = loggedInUser.cards![loggedInUser.paymentMethod!.value()]
                    paymentController.changeCard(loggedInUser.cardIDs[lastFour]!, userID: loggedInUser.userID){
                        self.paymentController.chargeUser(Constants.chargeUserURLString+self.loggedInUser.userID, amount: amount, description: self.orderDescription)
                        self.paymentPreferenceChanged = false
                    }
                }
                else{
                    paymentController.chargeUser(Constants.chargeUserURLString+loggedInUser.userID, amount: amount, description: orderDescription)
                }
            }
        }
            
        else{
            
        }
    }
    
    //MARK: PKPaymentAuthorizationViewControllerDelegate Functions
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {
        paymentController.applePayAuthorized(payment, userID:loggedInUser.userID, amount: amount, description: orderDescription, completion: completion)
        applePayCancelled = false
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        dismissViewControllerAnimated(true, completion: nil)
        if(applePayCancelled || applePayFailed){
            sliceController.orderCancelled()
        }
        else{
            sliceController.orderCompleted()
        }
    }
    
    
    //MARK: Payable Delegate Methods
    func amountPaid(am: Double) {
        amount = Int(am*100)
    }

    func storeCardID(cardID: String, lastFour: String){
        loggedInUser.cards!.append(lastFour)
        loggedInUser.paymentMethod = .CardIndex(loggedInUser.cards!.count-1)
        menuController?.preferredCard = loggedInUser.paymentMethod!
        menuController?.cards = loggedInUser.cards
        menuController?.cardBeingProcessed = nil
        loggedInUser.cardIDs[lastFour] = cardID
        paymentPreferenceChanged = true
    }
    
    
    //TODO:
    func cardStoreageFailed(){
        menuController?.cardBeingProcessed = nil
    }
    
    func cardPaymentSuccesful(){
        sliceController.orderCompleted()
    }
    
    func cardPaymentFailed(){
        sliceController.orderCancelled()
    }
    
    
    
}

