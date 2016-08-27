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
//It is a delegate for menuController, sliceController, newCardController, paymentController, orderHistoryController and any alertController
//objects it contains and may present
class ContainerController: UIViewController, Slideable, Payable, Rateable, PKPaymentAuthorizationViewControllerDelegate {
    
    var navController: UINavigationController!
    var sliceController: SliceController!
    var menuController: MenuController?
    let networkController = NetworkingController()
    
    //Controllers that take the menu to fullscreen
    var newCardController: UINavigationController?
    var newAddressController: UINavigationController?
    var orderHistoryController: UINavigationController?
    var accountSettingsController: UINavigationController?

    var loggedInUser: User!
    var paymentPreferenceChanged = false
    
    var menuIsVisible = false{ didSet{ showShadow(menuIsVisible) } }
    let amountVisibleOfSliceController: CGFloat = 110
    
    private var amount = 0.00 //The amount in dollars (6.49 represents $6.49)
    func getAmountInt()->Int{ return Int(amount*100) }//The amount in cents. (649 represents $6.49)
    func getAmountString()->String {return String(amount)}// The double as a string (6.49 represents $6.49)
    
    //These two are to be mutated by the payForOrder function
    var cheeseSlices = 0
    var pepperoniSlices = 0
    
    var orderDescription = ""
    var activeAddresses: ActiveAddresses!
    
    var applePayCancelled = true
    var applePayFailed = false
    
    let buttonColor = Constants.darkBlue
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarHidden = false
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        if !NetworkingController.checkHours(loggedInUser.userID){
            sliceController = SliceController()
            sliceController.delegate = self
            navController = UINavigationController(rootViewController: sliceController)
        }
        else{
            let cc = ClosedController()
            cc.delegate = self
            navController = UINavigationController(rootViewController: cc)
        }
        activeAddresses = ActiveAddresses(user: loggedInUser)
        networkController.containerDelegate = self
        networkController.headers = ["authorization" : loggedInUser.jwt]
        view.addSubview(navController.view)
        addChildViewController(navController)
        navController.didMoveToParentViewController(self)
        
    }
    override func viewDidLayoutSubviews() {
        promptUserFeedBack()
    }
    
    func promptUserFeedBack() {
        if loggedInUser.hasPromptedRating != nil && loggedInUser.hasPromptedRating! == false{
            if let lastOrder = loggedInUser.orderHistory.last?.timeOrdered{
                if NSDate().timeIntervalSinceDate(lastOrder) > 600{
                    loggedInUser.hasPromptedRating = true
                    let rc = RatingController()
                    rc.delegate = self
                    rc.showAlert()
                }
            }
        }
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
            Alerts.catchall() { _ in self.logOutUser() }
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
    
    func logoutConfirmation() {
        Alerts.logoutConfirmation(self)
    }
    
    func userTap(){
        if menuIsVisible{
            toggleMenu(nil)
        }
    }
    func menuCurrentlyShowing()->Bool{
        return menuIsVisible
    }
    
    //1 for NewCard, 2 for NewAddress, 3 for OrderHistory, 4 for Account Settings
    func bringMenuToFullscreen(toScreen screen: Int) {
        let completion: (Bool)->Void = { if ($0) { self.menuController?.removeFromParentViewController() }}
        if newCardController == nil && screen == 1{
            let nc = NewCardController()
            nc.delegate = self
            newCardController = UINavigationController(rootViewController: nc)
            prepareControllerForFullsreen(newCardController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false){
                if($0){
                    self.menuController?.removeFromParentViewController()
                    nc.paymentTextField.becomeFirstResponder()
                }
            }
        }
        else if newAddressController == nil && screen == 2{
            let na = NewAddressController()
            na.delegate = self
            na.dorms = activeAddresses.getDorms()
            na.schoolFullName = "\(loggedInUser.school) UNIVERSITY"
            newAddressController = UINavigationController(rootViewController: na)
            prepareControllerForFullsreen(newAddressController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false, completion: completion)
        }
            
        else if orderHistoryController == nil && screen == 3{
            let oc = OrderHistoryController()
            oc.delegate = self
            oc.orderHistory = loggedInUser.orderHistory
            orderHistoryController = UINavigationController(rootViewController: oc)
            prepareControllerForFullsreen(orderHistoryController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false, completion: completion)
        }
        else if accountSettingsController == nil && screen == 4{
            let asc = AccountSettingsController()
            asc.user = loggedInUser
            asc.delegate = self
            accountSettingsController = UINavigationController(rootViewController: asc)
            prepareControllerForFullsreen(accountSettingsController!)
            animateCenterPanelXPosition(view.frame.width, fromFullScreen: false, completion: completion)
        }
    }
    
    func prepareControllerForFullsreen(controller: UIViewController){
        view.insertSubview(controller.view, atIndex: 1)
        addChildViewController(controller)
        controller.didMoveToParentViewController(self)
    }

    
    func returnFromFullscreen(withCard card: STPCardParams?, orAddress address: Address?, fromSettings: Bool = false) {
        
        if card != nil{
            let lastFour = card!.last4()!
            if !loggedInUser.cards!.contains(lastFour){
                menuController?.cardBeingProcessed = lastFour
                let url = (loggedInUser.cardIDs.count == 0 && !loggedInUser.hasCreatedFirstCard) ? Constants.firstCardURLString : Constants.newCardURLString
                networkController.saveNewCard(card!, url: url+loggedInUser.userID, lastFour: lastFour)
                
            }
            else{
                Alerts.duplicate(isCard: true)
            }
        }
        if address != nil {
            if loggedInUser.addresses != nil{
                if !loggedInUser.addressIDs.keys.contains(address!.getName()){
                    menuController?.addressBeingProcessed = address!
                    networkController.saveAddress(address!, userID: loggedInUser.userID)
                }
                else{
                    Alerts.duplicate(isCard: false)
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
                self.accountSettingsController?.view.removeFromSuperview()
                self.accountSettingsController = nil
            }
        }
        
        if fromSettings{
            networkController.booleanChange(Constants.wantsReceipts, userID: loggedInUser.userID, boolean: loggedInUser.wantsReceipts)
            networkController.booleanChange(Constants.wantsConfirmation, userID: loggedInUser.userID, boolean: loggedInUser.wantsOrderConfirmation)
            if loggedInUser.email != nil{
                networkController.addEmail(loggedInUser.userID, email: loggedInUser.email!)
            }
        }
    }
    
    //Called after a user tries to select an address with no internet
    func retrieveAddresses(){
        activeAddresses = ActiveAddresses(user: loggedInUser)
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
                Alerts.failedDeleteAlert(true)
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
                Alerts.failedDeleteAlert(false)
            }
        }
    }
    
    
    func logOutUser(){
        loggedInUser.isLoggedIn = false
        let lc = LoginController()
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

    func timerEnded(cheese cheese: Double, pepperoni: Double){
        if loggedInUser.email == nil && loggedInUser.orderHistory.count == 0{
            let receiptController = ReceiptController()
            receiptController.delegate = self
            receiptController.showAlert() { [unowned self] in
                self.payForOrder(cheese, pepperoni: pepperoni)
            }
        }
        else{
            self.payForOrder(cheese, pepperoni: pepperoni)
        }
    }
    
    //MARK: Payment Functions
    //The beginning point for any payment process when the sliceController timer runs out. This function decides which
    //payment method is appropriate and the calls the corresponding function
    func payForOrder(cheese: Double, pepperoni: Double) {
        if Alerts.checkValidity(loggedInUser, cc: self){
            amount = (cheese*CurrentPrices.sharedInstance.getCheeseDollars()  + pepperoni*CurrentPrices.sharedInstance.getPepperoniDollars())
            cheeseSlices = Int(cheese) //So that apple pay delegate functions can see these values
            pepperoniSlices = Int(pepperoni)
            orderDescription = getOrderDescription(cheeseSlices, pepperoni: pepperoniSlices)
            applePayCancelled = true //It will be set to false when payment is properly authorized but must be reset every order in this way
            
            if case .ApplePay = loggedInUser.paymentMethod!{
                if NetworkingController.canApplePay(){
                    let paymentRequest = networkController.createPaymentRequest(cheese: cheese, pepperoni: pepperoni)
                    //Send it to an apple-made viewcontroller. This will take my PKPaymentRequest and turn it into a PKPayment which is passed to function below. This function will save order and charge user on the backend
                    let paymentAuthVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
                    paymentAuthVC.delegate = self
                    sliceController.presentViewController(paymentAuthVC, animated: true, completion: nil)
                }
            }
            else{
                let cardPayment: ()->Void = {
                    let lastFour = self.loggedInUser.cards![self.loggedInUser.paymentMethod!.value()]
                    let id = self.loggedInUser.cardIDs[lastFour]!
                    if let currentAddressID = self.loggedInUser.addressIDs[self.loggedInUser.addresses![self.loggedInUser.preferredAddress!].getName()]{
                        self.sliceController.orderProcessing()
                        if self.paymentPreferenceChanged{
                            self.networkController.changeCard(id, userID: self.loggedInUser.userID){
                                self.paymentPreferenceChanged = false
                                self.saveOrderThenCharge(Int(cheese), pepperoni: Int(pepperoni), addressID: currentAddressID, cardID: id)
                            }
                        }
                        else{
                            self.saveOrderThenCharge(Int(cheese), pepperoni: Int(pepperoni), addressID: currentAddressID, cardID: id)
                        }
                    }
                        
                    //If the cardID couldnt be found in the dictionary. Should never reach this point
                    else{
                        Alerts.catchall({_ in self.logOutUser()})
                    }
                }
                
                //Actual Card Payment
                loggedInUser.wantsOrderConfirmation ? Alerts.confirmOrder(cheese, pepperoni: pepperoni, cc: self, confirmedHandler: cardPayment) : cardPayment()
            }
        }
    }
    
    //Saves the order to the backend then submits a charge token to the backend. 
    //Credit Card exclusive
    func saveOrderThenCharge(cheese: Int, pepperoni: Int, addressID: String, cardID: String){
        networkController.saveOrder(cheese, pepperoni: pepperoni, url: Constants.saveOrderURLString+loggedInUser.userID + "/" + addressID, cardID: cardID, price: self.getAmountString()){
            self.networkController.chargeUser(Constants.chargeUserURLString+self.loggedInUser.userID, amount: String(self.getAmountInt()), description: self.orderDescription)
        }
    }
    
    
    //MARK: PKPaymentAuthorizationViewControllerDelegate Functions
    //Apple Pay Exclusive
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {
        let name = loggedInUser.addresses![loggedInUser.preferredAddress!].getName()
        let addID = loggedInUser.addressIDs[name]
        networkController.saveOrder(cheeseSlices, pepperoni: pepperoniSlices, url: Constants.saveOrderURLString+loggedInUser.userID + "/" + addID!, cardID: Constants.applePayCardID, price: getAmountString()){
            self.networkController.applePayAuthorized(payment, userID: self.loggedInUser.userID, amount: self.getAmountInt(), description: self.orderDescription, completion: completion)
            self.applePayCancelled = false
        }
    }
    
    //Apple Pay Exclusive
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        dismissViewControllerAnimated(true, completion: nil)
        if(applePayCancelled || applePayFailed){
            sliceController.orderCancelled()
        }
        else{
            let order = PastOrder(address: loggedInUser.addresses![loggedInUser.preferredAddress!], cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, price: amount, timeOrdered: NSDate(), paymentMethod: Constants.applePayCardID)
            loggedInUser.orderHistory.append(order)
            sliceController.orderCompleted()
            Alerts.successfulOrder(loggedInUser, cc: self, total: pepperoniSlices + cheeseSlices)
        }
    }
    
    func getOrderDescription(cheese: Int, pepperoni: Int)->String{
        var string = ""
        if pepperoni != 0{
            let plural = pepperoni == 1 ? "Slice" : "Slices"
            string = "\(pepperoni) Pepperoni \(plural)"
            if cheese != 0{
                let plural = cheese == 1 ? "Slice" : "Slices"
                string += ", \(cheese) Cheese \(plural)"
            }
        }
        else{
            let plural = cheese == 1 ? "Slice" : "Slices"
            string = "\(cheese) Cheese \(plural)"
        }

        return string
    }
    
    
    
    
    
    //MARK: Payable Delegate Methods
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
    
    
    func cardStoreageFailed(cardDeclined declined: Bool){
        menuController?.cardBeingProcessed = nil
        declined ? Alerts.cardDeclined() : Alerts.saveNotSuccesful(isCard: true, internetError: false)
    }
    
    func cardPaymentSuccesful(){
        if let val = loggedInUser.paymentMethod?.value(){
            if let payString = loggedInUser?.cards?[val]{
                let order = PastOrder(address: loggedInUser.addresses![loggedInUser.preferredAddress!], cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, price: amount, timeOrdered: NSDate(), paymentMethod: payString)
                loggedInUser.orderHistory.append(order)
            }
        }
        sliceController.orderCompleted()
        Alerts.successfulOrder(loggedInUser, cc: self, total: pepperoniSlices + cheeseSlices)
    }
    
    func cardPaymentFailed(cardDeclined declined: Bool){
        sliceController.orderCancelled()
        declined ? Alerts.cardDeclined() : Alerts.failedPayment()
    }
    
    func addressSaveSucceeded(add: Address, orderID: String) {
        loggedInUser.addresses!.append(add)
        loggedInUser.preferredAddress = loggedInUser.addresses!.count-1
        menuController?.preferredAddress = loggedInUser.preferredAddress
        menuController?.addresses = loggedInUser.addresses
        menuController?.addressBeingProcessed = nil
        loggedInUser.addressIDs[add.getName()] = orderID
    }
    
    func addressSaveFailed() {
        menuController?.addressBeingProcessed = nil
        Alerts.saveNotSuccesful(isCard: false, internetError: true)
    }
    

    func emailSaveFailed() {
        Alerts.emailSaveFailed()
    }
    
    func unauthenticated() {
        Alerts.unauthenticated(){ _ in self.logOutUser() }
    }

    
    //MARK: Rateable Delegate Functions
    func dismissed(withRating rating: Int, comment: String?) {
        loggedInUser.hasPromptedRating = true
        networkController.rateLastOrder(loggedInUser.userID, stars: rating, comment: comment)
    }
    
    func addEmail(email: String) {
        loggedInUser.email = email
        networkController.addEmail(loggedInUser.userID, email: email)
        networkController.booleanChange(Constants.wantsReceipts, userID: loggedInUser.userID, boolean: true)
    }
}
