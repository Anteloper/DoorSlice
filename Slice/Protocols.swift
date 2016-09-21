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
    func toggleMenu(_ completion: (()->Void)?)
    func userTap()
    func menuCurrentlyShowing()->Bool
    func bringMenuToNewCard()
    func bringMenuToNewAddress()
    func bringMenuToSettings()
    func bringMenuToOrderHistory()
    func returnFromNewCard(withCard card: STPCardParams?)
    func returnFromNewAddress(withAddress address: Address?)
    func returnFromSettings()
    func returnFromOrderHistory()
    func timerEnded(cheese: Double, pepperoni: Double)
    func retrieveAddresses()
    func cardRemoved(_ index: Int)
    func addressRemoved(_ index: Int)
    func logoutConfirmation()
}

//Objects that conform to this protocol can name themselves as a networkController delegate functions
protocol Payable {
    func open()
    func closed(_ closedMessage: String)
    func storeCardID(_ cardID: String, lastFour: String)
    func cardStoreageFailed(cardDeclined declined: Bool)
    func cardPaymentSuccesful(_ cheeseSlices: Int, pepperoniSlices: Int)
    func cardPaymentFailed(cardDeclined declined: Bool)
    func addressSaveSucceeded(_ add: Address, orderID: String)
    func addressSaveFailed()
    func emailSaveFailed()
    func unauthenticated()
}

//Only responsible for responding to functions related to cards and addresses. Used by the tutorial screen when configuring a user
protocol Configurable{
    func storeCardID(_ cardID: String, lastFour: String)
    func cardStoreageFailed(cardDeclined declined: Bool)
    func addressSaveSucceeded(_ add: Address, orderID: String)
    func addressSaveFailed()
    func unauthenticated()
}

//Objects that conform to this protocol can implement a timer bar and be notified when it reaches completion
protocol Timeable{
   func timerEnded(_ didComplete: Bool)
}

//Objects that conform to this protocol can present a RatingController or ReceiptController object
protocol Rateable{
    func dismissed(withRating rating: Int, comment: String?)
    func addEmail(_ email: String)
}
