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
    func retrieveAddresses()
    func cardRemoved(index: Int)
    func addressRemoved(index: Int)
    func logOutUser()
    func orderHistory()

}

//Objects that conform to this protocol can call networkController functions
protocol Payable {
    var applePayFailed: Bool{ get set }
    func storeCardID(cardID: String, lastFour: String)
    func cardStoreageFailed(trueFailure trueFailure: Bool)
    func cardPaymentSuccesful()
    func cardPaymentFailed()
    func addressSaveSucceeded(add: Address, orderID: String)
    func addressSaveFailed()
    func addLoyalty(slices: Int)
    func removeLoyalty(slices: Int)
}

protocol Timeable{
   func timerEnded(didComplete: Bool)
}

protocol Rateable{
    func dismissed(withRating rating: Int, comment: String?)
}
