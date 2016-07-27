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
    func returnFromFullscreen(withCard card: STPCardParams?, orAddress address: Address?)
    func payForOrder(cheese cheese: Double, pepperoni: Double)
    func getPaymentAndAddress() -> (String, String)
    func cardRemoved(index: Int)
    func addressRemoved(index: Int)
    func logOutUser()
    func orderHistory()

}

//Objects that conform to this protocol can call paymentController functions
protocol Payable {
    var applePayFailed: Bool{ get set }
    func amountPaid(amount: Double)
    func storeCardID(cardID: String, lastFour: String)
    func cardStoreageFailed(trueFailure trueFailure: Bool)
    func cardPaymentSuccesful()
    func cardPaymentFailed()
    func addressSaveSucceeded(add: Address, orderID: String)
    func addressSaveFailed()
}

protocol Timeable{
    func timerEnded(didComplete: Bool)
}