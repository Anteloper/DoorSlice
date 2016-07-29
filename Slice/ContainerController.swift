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
    var newAddressController: NewAddressController?
    let networkController = NetworkingController()
    var orderHistoryController: OrderHistoryController?
    
    var loggedInUser: User!
    var paymentPreferenceChanged = false
    
    var menuIsVisible = false{ didSet{ showShadow(menuIsVisible) } }
    let amountVisibleOfSliceController: CGFloat = 110
    
    var amount = 0//Should only be touched by the amountPaid function which is called by paymentController
    
    //These two are to be set by the payForOrder function
    var cheeseSlices = 0
    var pepperoniSlices = 0
    
    var orderDescription = ""
    var activeAddresses: ActiveAddresses!
    
    var applePayCancelled = true
    var applePayFailed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarHidden = false
        activeAddresses = ActiveAddresses()
        sliceController = SliceController()
        sliceController.delegate = self
        networkController.delegate = self
        networkController.headers = ["authorization" : loggedInUser.jwt]
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
        if let add = loggedInUser.addresses?[loggedInUser.preferredAddress!].getName(){
             return(digits, add)
        }
        else{
            catchall()
        }
       return(digits, String())
    }
    
    
    func toggleMenu(completion: (()->Void)?) {
        //Display menu when no menu is visible
        if !menuIsVisible && menuController == nil{
            menuController = MenuController()
            menuController?.addresses = loggedInUser.addresses ?? [Address]()
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
            animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController, fromFullScreen: false){
                if ($0){
                    if completion != nil{
                        completion!()
                    }
                }
            }
        }
            
        //Hide menu when one is visible and completion is nil
        else if completion == nil{
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
        //When completion isn't nil, this function was called by an alert handler and completion will bring up a screen called by menuController
        //For this reason, we don't want to dismiss the menu before showing the animation to that screen. When control reaches this point,
        //completion() should awlays call bringMenuToFullScreen(withScreen:_)
        else{
            completion!()
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, fromFullScreen: Bool, completion: ((Bool) ->Void)! = nil){
        
        UIView.animateWithDuration(0.3,
                                   delay: 0.0,
                                   options: [.CurveEaseInOut],
                                   animations: {
                                    if(fromFullScreen){
                                        self.newAddressController?.view.alpha = 0.0
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
            toggleMenu(nil)
        }
    }
    func menuCurrentlyShowing()->Bool{
        return menuIsVisible
    }
    
    //1 for NewCard, 2 for NewAddress, 3 for OrderHistory
    func bringMenuToFullscreen(toScreen screen: Int) {
        if newCardController == nil && screen == 1{
            newCardController = NewCardController()
            newCardController!.delegate = self
            prepareControllerForFullsreen(newCardController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false){
                if($0){
                    self.menuController?.removeFromParentViewController()
                    self.newCardController?.paymentTextField.becomeFirstResponder()
                }
            }
        }
        else if newAddressController == nil && screen == 2{
            newAddressController = NewAddressController()
            newAddressController!.delegate = self
            newAddressController?.data = activeAddresses.getData()
            prepareControllerForFullsreen(newAddressController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false){
                if($0){
                    self.menuController?.removeFromParentViewController()
                }
            }
        }
        else if orderHistoryController == nil && screen == 3{
            orderHistoryController = OrderHistoryController()
            orderHistoryController!.delegate = self
            orderHistoryController!.orderHistory = loggedInUser.orderHistory
            prepareControllerForFullsreen(orderHistoryController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false){
                if ($0){
                    self.menuController?.removeFromParentViewController()
                }
            }
        }
    }
    
    func prepareControllerForFullsreen(controller: UIViewController){
        view.insertSubview(controller.view, atIndex: 1)
        addChildViewController(controller)
        controller.didMoveToParentViewController(self)
    }

    
    func returnFromFullscreen(withCard card: STPCardParams?, orAddress address: Address?) {
        
        
        if card != nil{
            let lastFour = card!.last4()!
            if !loggedInUser.cards!.contains(lastFour){
                menuController?.cardBeingProcessed = lastFour
                let url = (loggedInUser.cardIDs.count == 0 && !loggedInUser.hasCreatedFirstCard) ? Constants.firstCardURLString : Constants.newCardURLString
                networkController.saveNewCard(card!, url: url+loggedInUser.userID, lastFour: lastFour)
                
            }
            else{
                duplicate(isCard: true)
            }
        }
        if address != nil {
            if loggedInUser.addresses != nil{
                if !loggedInUser.addressIDs.keys.contains(address!.getName()){
                    menuController?.addressBeingProcessed = address!
                    networkController.saveAddress(address!, userID: loggedInUser.userID)
                }
                else{
                    duplicate(isCard: false)
                }
            }
        }
        animateCenterPanelXPosition(navController.view.frame.width - amountVisibleOfSliceController, fromFullScreen: true){ didComplete in
            if didComplete{
                self.newCardController?.view.removeFromSuperview()
                self.newCardController = nil
                self.newAddressController?.view.removeFromSuperview()
                self.newAddressController = nil
                self.menuController?.tableView.reloadData()
                self.orderHistoryController?.view.removeFromSuperview()
                self.orderHistoryController = nil
            }
        }
    }
    

    func cardRemoved(index: Int) {
        let lastFour = loggedInUser.cards![index]
        let url = Constants.deleteCardURLString + loggedInUser.userID
        networkController.deleteCard(url, card: loggedInUser.cardIDs[lastFour]!){
            if ($0){
                self.loggedInUser.cards?.removeAtIndex(index)
                self.loggedInUser.cardIDs.removeValueForKey(lastFour)
                let val = self.loggedInUser.paymentMethod!.value()
                if val != -1 && val != 1 {
                    self.loggedInUser.paymentMethod = PaymentPreference.CardIndex(val-1)
                }
                else if val == 1{
                    self.loggedInUser.paymentMethod = .ApplePay
                }
                self.menuController?.preferredCard = self.loggedInUser.paymentMethod!
            }
            else{
                self.failedDeleteAlert(true)
            }
        }
        
    }
    
    func addressRemoved(index: Int) {
        let name = loggedInUser.addresses![index].getName()
        let url = Constants.deleteAddressURLString + loggedInUser.userID + "/" + loggedInUser.addressIDs[name]!
        networkController.deleteAddress(url){ [unowned self] in
            if ($0){
                self.loggedInUser.addresses?.removeAtIndex(index)
                self.loggedInUser.addressIDs.removeValueForKey(name)
                if index == self.loggedInUser.preferredAddress{
                    self.loggedInUser.preferredAddress = 0
                }
                else if self.loggedInUser.preferredAddress != 0{
                    self.loggedInUser.preferredAddress! -= 1
                }
                self.menuController?.preferredAddress = self.loggedInUser.preferredAddress
            }
            else{
                self.failedDeleteAlert(false)
            }
        }
    }
    
    func logOutUser(){
        loggedInUser.isLoggedIn = false
        let lc = LoginController()
        lc.shouldShowBackButton = true
        presentViewController(lc, animated: false, completion: nil)
    }
    
    func orderHistory(){
        if !menuIsVisible{
            toggleMenu(){
                self.bringMenuToFullscreen(toScreen: 3)
            }
        }
        else{
            bringMenuToFullscreen(toScreen: 3)
        }
    }

    
    //MARK: Payment Functions
    //The beginning point for any payment process when the sliceController timer runs out. This function decides which
    //payment method is appropriate and the calls the corresponding function
    func payForOrder(cheese cheese: Double, pepperoni: Double) {
        if checkValidity(){
            cheeseSlices = Int(cheese) //So that apple pay delegate functions can see these values
            pepperoniSlices = Int(pepperoni)
            orderDescription = String(Int(cheese)) + "cheese, " + String(Int(pepperoni)) + "pepperoni"
            
            if case .ApplePay = loggedInUser.paymentMethod!{
                if NetworkingController.canApplePay(){
                    let paymentRequest = networkController.createPaymentRequest(cheese: cheese, pepperoni: pepperoni)
                    //Send it to an apple-made viewcontroller. This will take my PKPaymentRequest and turn it into a PKPayment which is passed to function bleow
                    let paymentAuthVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                    paymentAuthVC.delegate = self
                    sliceController.presentViewController(paymentAuthVC, animated: true, completion: nil)
                }
            }
            else{
                let lastFour = loggedInUser.cards![loggedInUser.paymentMethod!.value()]
                let id = loggedInUser.cardIDs[lastFour]!
                let amount = String(Int(((cheese*4 + pepperoni*4)*100)))
                if let currentAddressID = loggedInUser.addressIDs[loggedInUser.addresses![loggedInUser.preferredAddress!].getName()]{
                    sliceController.orderProcessing()
                    if paymentPreferenceChanged{
                        networkController.changeCard(id, userID: loggedInUser.userID){
                            self.paymentPreferenceChanged = false
                            self.saveOrderThenCharge(Int(cheese), pepperoni: Int(pepperoni), amount: amount, addressID: currentAddressID, cardID: id)
                        }
                    }
                    else{
                        self.saveOrderThenCharge(Int(cheese), pepperoni: Int(pepperoni), amount: amount, addressID: currentAddressID, cardID: id)
                    }
                }
                //If the cardID couldnt be found in the dictionary. Should never reach this point
                else{
                    catchall()
                }
            }
        }
    }
    
    //Saves the order to the backend then submits a charge token to the backend
    func saveOrderThenCharge(cheese: Int, pepperoni: Int, amount: String, addressID: String, cardID: String){
        networkController.saveOrder(String(cheese), pepperoni: String(pepperoni), url: Constants.saveOrderURLString+loggedInUser.userID + "/" + addressID, cardID: cardID){
            self.networkController.chargeUser(Constants.chargeUserURLString+self.loggedInUser.userID, amount: amount, description: self.orderDescription)
        }
    }
    
    
    //MARK: PKPaymentAuthorizationViewControllerDelegate Functions
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {
        let name = loggedInUser.addresses![loggedInUser.preferredAddress!].getName()
        let addID = loggedInUser.addressIDs[name]
        networkController.saveOrder(String(cheeseSlices), pepperoni: String(pepperoniSlices), url: Constants.saveOrderURLString+loggedInUser.userID + "/" + addID!, cardID: Constants.applePayCardID){
            self.networkController.applePayAuthorized(payment, userID: self.loggedInUser.userID, amount: self.amount, description: self.orderDescription, completion: completion)
            self.applePayCancelled = false
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        dismissViewControllerAnimated(true, completion: nil)
        if(applePayCancelled || applePayFailed){
            sliceController.orderCancelled()
        }
        else{
            let payString = loggedInUser.paymentMethod?.value() == -1 ? "applePay" : loggedInUser!.cards![(loggedInUser.paymentMethod?.value())!]
            let order = PastOrder(address: loggedInUser.addresses![loggedInUser.preferredAddress!], cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, timeOrdered: NSDate(), paymentMethod: payString)
            loggedInUser.orderHistory.append(order)
            sliceController.orderCompleted()
            successfulOrder()
        }
    }
    
    
    //MARK: Payable Delegate Methods
    func amountPaid(am: Double) {
        amount = Int(am*100)
    }

    func storeCardID(cardID: String, lastFour: String){
        loggedInUser.hasCreatedFirstCard = true
        loggedInUser.cards!.append(lastFour)
        loggedInUser.paymentMethod = .CardIndex(loggedInUser.cards!.count-1)
        menuController?.preferredCard = loggedInUser.paymentMethod!
        menuController?.cards = loggedInUser.cards
        menuController?.cardBeingProcessed = nil
        loggedInUser.cardIDs[lastFour] = cardID
        paymentPreferenceChanged = true
    }
    
    
    func cardStoreageFailed(trueFailure internetError: Bool){
        menuController?.cardBeingProcessed = nil
        saveNotSuccesful(isCard: true, internetError: internetError)
    }
    
    func cardPaymentSuccesful(){
        let payString = loggedInUser.paymentMethod?.value() == -1 ? "applePay" : loggedInUser!.cards![(loggedInUser.paymentMethod?.value())!]
        let order = PastOrder(address: loggedInUser.addresses![loggedInUser.preferredAddress!], cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, timeOrdered: NSDate(), paymentMethod: payString)
        loggedInUser.orderHistory.append(order)
        sliceController.orderCompleted()
        successfulOrder()
    }
    
    func cardPaymentFailed(){
        sliceController.orderCancelled()
        let alert = UIAlertController(title: "Order Not Placed", message: "Check your internet connection and try again", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        presentViewController(alert, animated: false, completion: nil)
    }
    
    func addressSaveFailed() {
        menuController?.addressBeingProcessed = nil
        saveNotSuccesful(isCard: false, internetError: true)
    }
    
    func addressSaveSucceeded(add: Address, orderID: String) {
        loggedInUser.addresses!.append(add)
        loggedInUser.preferredAddress = loggedInUser.addresses!.count-1
        menuController?.preferredAddress = loggedInUser.preferredAddress
        menuController?.addresses = loggedInUser.addresses
        menuController?.addressBeingProcessed = nil
        loggedInUser.addressIDs[add.getName()] = orderID
    }
    

    //MARK: Alerts
    func successfulOrder(){
        let alert = UIAlertController(title: "Pizza On The Way", message: "You can check the details of your order in your order history", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Take Me There", style: .Default, handler:{ _ in self.toggleMenu(){
            self.bringMenuToFullscreen(toScreen: 3)
            }}))
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        presentViewController(alert, animated: false, completion: nil)
    }
    
    func saveNotSuccesful(isCard isCard: Bool, internetError: Bool){
        let titleString = isCard ? "Card Save Not Succesful" : "Address Save Not Succesful"
        let message = internetError ? "Check your internet connection and try again" : "Check your card details and try again"
        let alert = UIAlertController(title: titleString, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func duplicate(isCard isCard: Bool){
        let string = isCard ? "card" : "address"
        let titleString = isCard ? "Duplicate Card" : "Duplicate Address"
        let alert = UIAlertController(title: titleString, message: "You already have this " + string + " on file", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func failedDeleteAlert(isCard: Bool){
        let titleString = isCard ? "Failed to Delete Card" : "Failed To Delete Address"
        let alert = UIAlertController(title: titleString, message: "Check your internet and try again later", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        self.presentViewController(alert, animated: false, completion: nil)
    }
    
    //Logs the user out and forces them to Re-login. Hopefully will fix any bug
    func catchall(){
        let alert = UIAlertController(title: "Something Went Wrong On Our End", message: "Please log in again, we apologize for the inconvenience", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: { _ in self.logOutUser()}))
        presentViewController(alert, animated: false, completion: nil)

    }
    
    //Returns true if the user has a valid address and payment method, false otherwise. Means force unwrapping options is ok in payForOrder
    func checkValidity()->Bool{
        if case .ApplePay = loggedInUser.paymentMethod!{
            if !NetworkingController.canApplePay(){
                let messageString = loggedInUser.cards?.count == 1 ? "Please add a credit card in the menu" : "Please change your payment method in the menu"
                let alert = UIAlertController(title: "Apple Pay Not Set Up", message: messageString, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                let toggleCompleted: (()->Void)? = loggedInUser.cards?.count == 1 ? {self.bringMenuToFullscreen(toScreen: 1)} : nil
                alert.addAction(UIAlertAction(title: "Take Me There", style: .Default , handler: {_ in self.toggleMenu(toggleCompleted)}))
                self.presentViewController(alert, animated: true, completion: {_ in self.sliceController?.orderCancelled()})
                return false
            }
        }
        
        if loggedInUser.addresses == nil || loggedInUser.addresses?.count == 0{
            let alert = UIAlertController(title: "No Adress Entered", message: "Enter a delivery address in the menu and then place your order.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: {_ in self.sliceController.orderCancelled()}))
            alert.addAction(UIAlertAction(title: "Take Me There", style: .Default, handler: {_ in self.toggleMenu(){
                self.bringMenuToFullscreen(toScreen:2)}}))
            self.presentViewController(alert, animated: true, completion: {_ in self.sliceController?.orderCancelled()})
            return false
        }
        return true
    }
    
}

