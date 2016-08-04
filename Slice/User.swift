//
//  User.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import UIKit

//Properties of this class must conform to NSObject, NSCoding, AND NSCopying
class User: NSObject, NSCoding{
    
    var userID: String
    var addresses: [Address]? {didSet{saveToDefaults()}}
    var addressIDs: [String: String] {didSet{saveToDefaults()}}
    var preferredAddress: Int? {didSet{saveToDefaults()}}
    var cards: [String]? {didSet{saveToDefaults()}}
    var cardIDs: [String : String] {didSet{saveToDefaults()}}
    var paymentMethod: PaymentPreference? {didSet{saveToDefaults()}}
    var hasCreatedFirstCard: Bool{didSet{saveToDefaults()}}
    var isLoggedIn: Bool{didSet{saveToDefaults()}}
    var orderHistory: [PastOrder]{didSet{saveToDefaults()}}
    var jwt: String {didSet{saveToDefaults()}}
    var hasPromptedRating: Bool? {didSet{saveToDefaults()}}//If nil or true, don't ask for slice rating
    var loyaltySlices: Int
    
    init(userID: String,
         addresses: [Address]? = [Address](), addressIDs: [String: String] = [String : String](),
         preferredAddress: Int? = 0, cards: [String] = ["Pay"],
         cardIDs: [String : String] = [String : String](), paymentMethod: PaymentPreference? = .ApplePay,
         hasCreatedFirstCard: Bool = false, isLoggedIn: Bool = true, jwt: String,  orderHistory: [PastOrder] = [PastOrder](), hasPromptedRating: Bool? = nil, loyaltySlices: Int = 0){
        
        self.userID = userID
        self.addresses = addresses
        self.addressIDs = addressIDs
        self.preferredAddress = preferredAddress ?? 0
        self.cards = cards
        self.cardIDs = cardIDs
        self.paymentMethod = paymentMethod ?? PaymentPreference.ApplePay
        self.hasCreatedFirstCard = hasCreatedFirstCard
        self.isLoggedIn = isLoggedIn
        self.jwt = jwt
        self.orderHistory = orderHistory
        self.hasPromptedRating = hasPromptedRating
        self.loyaltySlices = loyaltySlices
        super.init()
        self.saveToDefaults()
    }
    
    required convenience init?(coder decoder: NSCoder){
        guard let addresses = decoder.decodeObjectForKey("addresses") as? [Address],
            let addressIDs = decoder.decodeObjectForKey("addressIDs") as? [String : String],
            let cards = decoder.decodeObjectForKey("cards") as? [String],
            let cardIDs = decoder.decodeObjectForKey("cardIDs") as? [String : String],
            let userID = decoder.decodeObjectForKey("userID") as? String,
            let jwt = decoder.decodeObjectForKey("jwt") as? String,
            let orderHistory = decoder.decodeObjectForKey("orderHistory") as? [PastOrder],
            let hasPromptedRating = decoder.decodeObjectForKey("hasPrompted") as? Bool?,
            let loyaltySlices = decoder.decodeObjectForKey("loyaltySlices") as? Int else{
                return nil
        }
        let pref = decoder.decodeIntegerForKey("paymentMethod")
        let prefEnum = pref == -1 ? PaymentPreference.ApplePay : PaymentPreference.CardIndex(pref)
        
        self.init(userID:  userID,
                  addresses: addresses,
                  addressIDs:  addressIDs,
                  preferredAddress: decoder.decodeIntegerForKey("preferredAddress"),
                  cards: cards,
                  cardIDs: cardIDs,
                  paymentMethod: prefEnum,
                  hasCreatedFirstCard: decoder.decodeBoolForKey("hasCreated"),
                  isLoggedIn: decoder.decodeBoolForKey("isLoggedIn"),
                  jwt: jwt,
                  orderHistory: orderHistory,
                  hasPromptedRating: hasPromptedRating,
                  loyaltySlices: loyaltySlices
        )
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.userID, forKey:  "userID")
        aCoder.encodeObject(self.addresses, forKey: "addresses")
        aCoder.encodeObject(self.addressIDs, forKey: "addressIDs")
        aCoder.encodeInteger(self.preferredAddress ?? -1, forKey: "preferredAddress")
        aCoder.encodeObject(self.cards, forKey: "cards")
        aCoder.encodeObject(self.cardIDs, forKey: "cardIDs")
        aCoder.encodeInteger(self.preferenceToInt(self.paymentMethod), forKey: "paymentMethod")
        aCoder.encodeBool(self.hasCreatedFirstCard, forKey: "hasCreated")
        aCoder.encodeBool(self.isLoggedIn, forKey: "isLoggedIn")
        aCoder.encodeObject(self.jwt, forKey: "jwt")
        aCoder.encodeObject(self.orderHistory, forKey: "orderHistory")
        aCoder.encodeObject(self.hasPromptedRating, forKey: "hasPrompted")
        aCoder.encodeObject(self.loyaltySlices, forKey: "loyaltySlices")
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
        NSKeyedArchiver.archiveRootObject(self, toFile: Constants.userFilePath())
    }
    
}
