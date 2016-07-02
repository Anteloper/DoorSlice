//
//  Slideable.swift
//  Slice
//
//  Created by Oliver Hill on 6/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import UIKit
import Stripe

//MARK: Slideable Protocol
//A menu can be slid out on top of items that conform to this protocol
protocol Slideable{
    
    func toggleMenu()
    func userTap()
    func menuCurrentlyShowing()->Bool
    func bringMenuToFullscreen()
    func returnFromFullscreen(withCard card: STPCardParams?)
    func payForOrder(cheese cheese: Double, pepperoni: Double)
    func getPaymentAndAddress() -> (String, String)
}


protocol Timeable{
    func timerEnded(didComplete: Bool)
}


internal struct Constants{
    
    //The amount of the main view that is still showing when the side menu slides out. Should match amountVisibleOfSliceController
    static let sliceControllerShowing: CGFloat = 110
    static let tiltColor = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 1.0)
    static let eucalyptus = UIColor(red: 38/255.0, green: 166/255.0, blue: 91/255.0, alpha: 1.0)
    static let sliceColor = UIColor(red: 238/255.0, green: 93/255.0, blue: 27/255.0, alpha: 1.0)
    static let stripePublishableKey = "pk_test_Lp3E4ypwmrizs2jfEenXdwpr"
    
    static let backendChargeURLString = "https://doorslice.herokuapp.com/api/newchargeuser/"
    static let accountCreationURLString = "https://doorslice.herokuapp.com/api/users"
    static let newCardURLString = "https://doorslice.herokuapp.com/api/newcard/"
    static let firstCardURLString = "https://doorslice.herokuapp.com/api/newstripeuser/"
    static let updateCardURLString = "https://doorslice.herokuapp.com/api/updatecard/"
    //https://stormy-mesa-19767.herokuapp.com/api/newchargeuser/574cdcfae222261100d91c85
    
    static let appleMerchantId = "merchant.com.dormslice"
    
    
    
    static let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    
    static let userKey = "user"
    static let cardsKey = "cards"
    static let cardPrefKey = "cardPref"
    static let addressesKey = "addresses"
    static let addressPrefKey = "addressPref"
    
    
    
}

struct Order{
    
    var cheeseSlices: Double = 0
    var pepperoniSlices: Double = 0
    
    mutating func add(sliceType: Slice){
        switch sliceType{
        case .Cheese:
            cheeseSlices += 1
        case .Pepperoni:
            pepperoniSlices += 1
        }
    }
    mutating func clear(){
        cheeseSlices = 0
        pepperoniSlices = 0
    }
    
    func totalSlices() -> Int{
        return Int(cheeseSlices+pepperoniSlices)
    }
}


//MARK: User Class

class User: NSObject, NSCoding{
    
    var phoneNumber: String
    var password:String
    var userID: String
    var addresses: [String]? {didSet{saveToDefaults()}}
    var preferredAddress: Int? {didSet{saveToDefaults()}}
    var cards: [String]? {didSet{saveToDefaults()}}
    var cardIDs: [String : String] {didSet{saveToDefaults()}}
    var paymentMethod: PaymentPreference? {didSet{saveToDefaults()}}
    
    
    init(phoneNumber: String, password: String, userID: String, addresses: [String]? = [String](), preferredAddress: Int? = 0,
         cards: [String] = ["Pay"], cardIDs: [String : String] = [String : String](), paymentMethod: PaymentPreference? = .ApplePay){
        self.phoneNumber = phoneNumber
        self.password = password
        self.userID = userID
        self.addresses = addresses
        self.preferredAddress = preferredAddress
        self.cards = cards
        self.cardIDs = cardIDs
        self.paymentMethod = paymentMethod
    }

    
    required convenience init?(coder decoder: NSCoder){
        guard let addresses = decoder.decodeObjectForKey("addresses") as? [String],
            let cards = decoder.decodeObjectForKey("cards") as? [String],
            let cardIDs = decoder.decodeObjectForKey("cardIDs") as? [String : String],
            let phoneNumber = decoder.decodeObjectForKey("phoneNumber") as? String,
            let password = decoder.decodeObjectForKey("password") as? String,
            let userID = decoder.decodeObjectForKey("userID") as? String else{
                return nil
        }
        let pref = decoder.decodeIntegerForKey("paymentMethod")
        let prefEnum = pref == -1 ? PaymentPreference.ApplePay : PaymentPreference.CardIndex(pref)
        
        self.init(phoneNumber: phoneNumber,
                  password: password,
                  userID:  userID,
                  addresses: addresses,
                  preferredAddress: decoder.decodeIntegerForKey("preferredAddress"),
                  cards: cards,
                  cardIDs: cardIDs,
                  paymentMethod: prefEnum
        )
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.phoneNumber, forKey: "phoneNumber")
        aCoder.encodeObject(self.password, forKey: "password")
        aCoder.encodeObject(self.userID, forKey:  "userID")
        aCoder.encodeObject(self.addresses, forKey: "addresses")
        aCoder.encodeInteger(self.preferredAddress ?? -1, forKey: "preferredAddress")
        aCoder.encodeObject(self.cards, forKey: "cards")
        aCoder.encodeObject(self.cardIDs, forKey: "cardIDs")
        aCoder.encodeInteger(preferenceToInt(self.paymentMethod), forKey: "paymentMethod")
    
    }
    
    private func preferenceToInt(pref: PaymentPreference?)-> Int{
        if pref != nil{
            switch(pref!){
            case .ApplePay:
                return -1
            case .CardIndex(let index):
                return index
            }
        }
        return -1
    }
    
    private func intToPreference(num: Int)->PaymentPreference{
        return num == -1 ? PaymentPreference.ApplePay : PaymentPreference.CardIndex(num)
    }
    
    func saveToDefaults(){
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: Constants.userKey)
    }
    
}


enum Slice{
    case Cheese
    case Pepperoni
}


//Menu Items
enum CellType{
    case HeaderCell
    case PreferenceCell
    case NewCell
}

enum CellCategory{
    case Address
    case Card
}

enum PaymentPreference{
    case CardIndex(Int)
    case ApplePay
}