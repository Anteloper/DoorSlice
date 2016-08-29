//
//  Alerts.swift
//  Slice
//
//  Created by Oliver Hill on 8/20/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import UIKit

//Class to hold all alerts
class Alerts{
    
    static func iPhone4(){
        SweetAlert().showAlert("NOT SUPPORTED", subTitle: "Sorry, our app isn't compatible with your device", style: .None, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, action: nil)
    }
    
    static func successfulOrder(loggedInUser: User, cc: ContainerController, total: Int){
        loggedInUser.hasPromptedRating = false
        let plural = total == 1 ? "slice" : "slices"
        SweetAlert().showAlert("ORDER PLACED", subTitle: "\(total) \(plural) on the way! You can check the details of your order in your order history", style: AlertStyle.Success, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, otherButtonTitle: "SHOW ME",
                               otherButtonColor: Constants.darkBlue) {
                                if !($0) {
                                    cc.toggleMenu(){
                                        cc.bringMenuToOrderHistory()
                                    }
                                }
        }
    }
    
    static func confirmOrder(cheese: Double, pepperoni: Double, cc: ContainerController, confirmedHandler: ()->Void){
        //String creation
        let value = cheese*CurrentPrices.sharedInstance.getCheeseDollars() + pepperoni*CurrentPrices.sharedInstance.getPepperoniDollars()
        var total = String(value)
        if value%1.00 == 0{
            total += "0"
        }
        let chs = Int(cheese)
        let pepp = Int(pepperoni)
        let first = "Confirm your order of"
        var second = ""
        if pepp != 0{
            let plural = pepp == 1 ? "slice" : "slices"
            second = "\(pepp) \(plural) of pepperoni "
            if chs != 0{
                let plural = chs == 1 ? "slice" : "slices"
                second += "and \(chs) \(plural) of cheese "
            }
            second += "for a total of $\(total)"
        }
        else{
            let plural = chs == 1 ? "slice" : "slices"
            second = "\(chs) \(plural) of cheese for a total of $\(total)"
        }
        
        SweetAlert().showAlert("CONFIRM ORDER", subTitle: "\(first) \(second)", style: .None, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, otherButtonTitle: "CANCEL", otherButtonColor: Constants.darkBlue){
            if ($0){
                confirmedHandler()
            }
            else{
                cc.sliceController.orderCancelled()
            }
        }
    }
    
    static func failedPayment(){
        SweetAlert().showAlert("ORDER FAILED", subTitle: "Check your internet connection and try again", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func cardDeclined(){
         SweetAlert().showAlert("DECLINED", subTitle: "Something went wrong processing your payment", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func emailSaveFailed(){
        SweetAlert().showAlert("SAVE FAILED", subTitle: "Check your internet connection and try again", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func saveNotSuccesful(isCard isCard: Bool, internetError: Bool){
        let string = isCard ? "Card" : "Address"
        SweetAlert().showAlert("SAVE FAILED", subTitle: "\(string) could not be saved. Check your internet connection and try again.", style: AlertStyle.Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func duplicate(isCard isCard: Bool){
        let string = isCard ? "card" : "address"
        SweetAlert().showAlert("DUPLICATE", subTitle: "You already have this \(string) on file", style: .Warning, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func failedDeleteAlert(isCard: Bool){
        let string = isCard ? "Card" : "Address"
        SweetAlert().showAlert("DELETE FAILED", subTitle: "\(string) could not be deleted. Check your internet and try again later", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func logoutConfirmation(cc: ContainerController){
        SweetAlert().showAlert("LOGOUT?", subTitle: "Are you sure you want to logout?", style: AlertStyle.None, buttonTitle: "YES", buttonColor: Constants.darkBlue, otherButtonTitle: "NO", otherButtonColor: Constants.darkBlue){
            if ($0){
                cc.logOutUser()
            }
        }
    }
    
    //Logs the user out and forces them to Re-login. Hopefully will fix any bug
    static func catchall(action: (Bool) -> Void){
        SweetAlert().showAlert("ERROR", subTitle: "Something went wrong on our end. Please log in again.", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, action: action)
    }
    
    static func unauthenticated(action: (Bool) -> Void){
        SweetAlert().showAlert("SESSION EXPIRED", subTitle: "Your session has expired. Please log in again.", style: .Warning, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, action: action)
    }
    
    //Returns true if the user has a valid address and payment method, false otherwise. Means force unwrapping options is ok in payForOrder
    static func checkValidity(loggedInUser: User, cc: ContainerController)->Bool{
        if case .ApplePay = loggedInUser.paymentMethod!{
            if !NetworkingController.canApplePay(){
                let messageString = loggedInUser.cards?.count == 1 ? "Please add a credit card in the menu" : "Please change your payment method in the menu"
                let toggleCompleted: (()->Void)? = loggedInUser.cards?.count == 1 ? {cc.bringMenuToNewCard()} : nil
                SweetAlert().showAlert("NO PAY", subTitle: messageString, style: .Warning, buttonTitle: "SHOW ME", buttonColor: Constants.darkBlue, otherButtonTitle: "DISMISS", otherButtonColor: Constants.darkBlue){
                    if ($0){
                        cc.toggleMenu(toggleCompleted)
                    }
                }
                cc.sliceController?.orderCancelled()
                return false
            }
        }
        if loggedInUser.addresses == nil || loggedInUser.addresses?.count == 0{
            SweetAlert().showAlert("NO ADDRESS", subTitle: "Enter a delivery address in the menu and then place your order.", style: .Warning, buttonTitle: "SHOW ME", buttonColor: Constants.darkBlue, otherButtonTitle: "DISMISS", otherButtonColor: Constants.darkBlue){
                if ($0){
                    cc.toggleMenu({cc.bringMenuToNewAddress()})
                }
            }
            cc.sliceController?.orderCancelled()
            return false
        }
        return true
    }
    
    static func accountExists(completion: (Bool)->Void){
        SweetAlert().showAlert("ACCOUNT EXISTS", subTitle: "This phone number is already registered with an account. Did you mean to login?", style: .None, buttonTitle: "LOGIN", buttonColor: Constants.darkBlue, otherButtonTitle: "DISMISS", otherButtonColor: Constants.darkBlue, action: completion)
    }
    
    static func serverError(){
        SweetAlert().showAlert("SERVER ERROR", subTitle: "Please try again later", style: .Error,  buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    
    static func noAccount(){
        SweetAlert().showAlert("NO ACCOUNT", subTitle: "No account with this phone number was found", style: .Error,  buttonTitle: "OKAY", buttonColor: Constants.darkBlue)
    }
    static func holdUp(string: String){
        SweetAlert().showAlert("HOLD UP", subTitle: "We're still processing your \(string), give us one second", style: .None, buttonTitle: "OKAY", buttonColor: Constants.darkBlue, action: nil)
    }
    
    static func overload(sc: SliceController){
        SweetAlert().showAlert("OVERLOAD", subTitle: "We have an 8 slice maximum for now, sorry!", style: .Warning, buttonTitle: "OKAY", buttonColor: Constants.darkBlue){
            _ in sc.orderProgressBar?.timer.resume()
        }
    }
    
    static func noAddresses(na: NewAddressController){
        SweetAlert().showAlert("NETWORK ERROR", subTitle: "Failed to fetch list of active dorms. Please check your network connection", style: .Error, buttonTitle: "OKAY", buttonColor: Constants.darkBlue){ _ in
            na.exitWithoutAddress(true)
        }
    }
    
    static func applePayFound(nc: NewCardController){
        SweetAlert().showAlert("YOU'RE ALL SET", subTitle: "We've set up Apple Pay for you. Your payment is good to go!", style: .None, buttonTitle: "OKAY", buttonColor: Constants.darkBlue){ _ in
            let tc = TutorialController()
            tc.user = nc.user
            nc.presentViewController(tc, animated: false, completion: nil)
        }
    }
    
    //Runs twice per call when enterTrue is true
    static func shakeView(view: UIView, enterTrue: Bool){
        UIView.animateWithDuration(0.1, animations: {
            view.frame.origin.x += 10
            }, completion:{ _ in UIView.animateWithDuration(0.1, animations: {
                view.frame.origin.x -= 10
                }, completion: { _ in
                    UIView.animateWithDuration(0.1, animations: {
                        view.frame.origin.x += 10
                        }, completion: { _ in
                            UIView.animateWithDuration(0.1, animations: {
                                view.frame.origin.x -= 10
                                }, completion: { _ in
                                    if enterTrue{
                                        self.shakeView(view, enterTrue: false)
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