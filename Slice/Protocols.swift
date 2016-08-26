//
//  Protocols.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import Stripe


//A menu can be slid out on top of objects that conform to this protocol
protocol Slideable{
    
    func toggleMenu(completion: (()->Void)?)
    func userTap()
    func menuCurrentlyShowing()->Bool
    func bringMenuToFullscreen(toScreen screen: Int)
    func returnFromFullscreen(withCard card: STPCardParams?, orAddress address: Address?, fromSettings: Bool)
    func timerEnded(cheese cheese: Double, pepperoni: Double)
    func getPaymentAndAddress() -> (String, String)
    func retrieveAddresses()
    func cardRemoved(index: Int)
    func addressRemoved(index: Int)
    func logoutConfirmation()
    func orderHistory()

}

//Objects that conform to this protocol can name themselves as a networkController delegate functions
protocol Payable {
    var applePayFailed: Bool{ get set }
    func storeCardID(cardID: String, lastFour: String)
    func cardStoreageFailed(cardDeclined declined: Bool)
    func cardPaymentSuccesful()
    func cardPaymentFailed(cardDeclined declined: Bool)
    func addressSaveSucceeded(add: Address, orderID: String)
    func addressSaveFailed()
    func emailSaveFailed()
    func unauthenticated()
}

//Only responsible for responding to functions related to cards and addresses. Used by the tutorial screen when configuring a user
protocol Configurable{
    func storeCardID(cardID: String, lastFour: String)
    func cardStoreageFailed(cardDeclined declined: Bool)
    func addressSaveSucceeded(add: Address, orderID: String)
    func addressSaveFailed()
    func unauthenticated()
}

//Objects that conform to this protocol can implement a timer bar and be notified when it reaches completion
protocol Timeable{
   func timerEnded(didComplete: Bool)
}

//Objects that conform to this protocol can present a RatingController or ReceiptController object
protocol Rateable{
    func dismissed(withRating rating: Int, comment: String?)
    func addEmail(email: String)
}
