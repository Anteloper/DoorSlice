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
    
    var userID: String //User can't login without it
    var addresses: [Address] {didSet{saveToDefaults()}}
    var addressIDs: [String: String] {didSet{saveToDefaults()}}
    var preferredAddress: Int {didSet{saveToDefaults()}}
    var cards: [String] {didSet{saveToDefaults()}}
    var cardIDs: [String : String] {didSet{saveToDefaults()}} //key: last four digits, value: cardID provided by the database
    var preferredCard: Int {didSet{saveToDefaults()}}
    var hasCreatedFirstCard: Bool{didSet{saveToDefaults()}}//To avoid hitting the newStripeUser endpoint when not applicable
    var isLoggedIn: Bool{didSet{saveToDefaults()}}//For checking at launchtime
    var orderHistory: [PastOrder]{didSet{saveToDefaults()}}
    var jwt: String {didSet{saveToDefaults()}}//The raw string for header authentification in requests
    var hasPromptedRating: Bool? {didSet{saveToDefaults()}}//If nil or true, don't ask for slice rating
    var loyaltySlices: Int //Not currently in use
    var hasSeenTutorial: Bool{didSet{saveToDefaults()}}
    var email: String?{didSet{saveToDefaults()}}//Email address for receipts if the user provided one
    var wantsReceipts: Bool{didSet{saveToDefaults()}}
    var wantsOrderConfirmation: Bool{didSet{saveToDefaults()}}//Whether an alert should confirm an order
    var school: String //All caps, the name of the school, no "university" or "college" ex: "GEORGETOWN"
    
    init(userID: String,
         addresses: [Address] = [Address](), addressIDs: [String: String] = [String : String](),
         preferredAddress: Int = 0, cards: [String] = [String](),
         cardIDs: [String : String] = [String : String](), preferredCard: Int = 0,
         hasCreatedFirstCard: Bool = false, isLoggedIn: Bool = true, jwt: String,
         orderHistory: [PastOrder] = [PastOrder](), hasPromptedRating: Bool? = nil,
         loyaltySlices: Int = 0, hasSeenTutorial: Bool = false, email: String? = nil,
         wantsReceipts: Bool = false, wantsOrderConfirmation:Bool = true, school: String){
        
        self.userID = userID
        self.addresses = addresses
        self.addressIDs = addressIDs
        self.preferredAddress = preferredAddress
        self.cards = cards
        self.cardIDs = cardIDs
        self.preferredCard = preferredCard
        self.hasCreatedFirstCard = hasCreatedFirstCard
        self.isLoggedIn = isLoggedIn
        self.jwt = jwt
        self.orderHistory = orderHistory
        self.hasPromptedRating = hasPromptedRating
        self.loyaltySlices = loyaltySlices
        self.hasSeenTutorial = hasSeenTutorial
        self.email = email
        self.wantsReceipts = wantsReceipts
        self.wantsOrderConfirmation = wantsOrderConfirmation
        self.school = school
        super.init()
        self.saveToDefaults()
    }
    
    required convenience init?(coder decoder: NSCoder){
        guard let addresses = decoder.decodeObject(forKey: "addresses") as? [Address],
            let addressIDs = decoder.decodeObject(forKey: "addressIDs") as? [String : String],
            let cards = decoder.decodeObject(forKey: "cards") as? [String],
            let cardIDs = decoder.decodeObject(forKey: "cardIDs") as? [String : String],
            let userID = decoder.decodeObject(forKey: "userID") as? String,
            let jwt = decoder.decodeObject(forKey: "jwt") as? String,
            let orderHistory = decoder.decodeObject(forKey: "orderHistory") as? [PastOrder],
            let hasPromptedRating = decoder.decodeObject(forKey: "hasPrompted") as? Bool?,
            let loyaltySlices = decoder.decodeObject(forKey: "loyaltySlices") as? Int,
            let hasSeenTutorial = decoder.decodeObject(forKey: "hasSeenTutorial") as? Bool,
            let email = decoder.decodeObject(forKey: "email") as? String?,
            let wantsReceipt = decoder.decodeObject(forKey: "wantsReceipts") as? Bool,
            let wantsOrderConfirmation = decoder.decodeObject(forKey: "confirmation") as? Bool,
            let school = decoder.decodeObject(forKey: "school") as? String
            else{
                return nil
            }
    
        self.init(userID:  userID,
                  addresses: addresses,
                  addressIDs:  addressIDs,
                  preferredAddress: decoder.decodeInteger(forKey: "preferredAddress"),
                  cards: cards,
                  cardIDs: cardIDs,
                  preferredCard: decoder.decodeInteger(forKey: "preferredCard"),
                  hasCreatedFirstCard: decoder.decodeBool(forKey: "hasCreated"),
                  isLoggedIn: decoder.decodeBool(forKey: "isLoggedIn"),
                  jwt: jwt,
                  orderHistory: orderHistory,
                  hasPromptedRating: hasPromptedRating,
                  loyaltySlices: loyaltySlices,
                  hasSeenTutorial: hasSeenTutorial,
                  email: email,
                  wantsReceipts: wantsReceipt,
                  wantsOrderConfirmation: wantsOrderConfirmation,
                  school: school
        )
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.userID, forKey:  "userID")
        aCoder.encode(self.addresses, forKey: "addresses")
        aCoder.encode(self.addressIDs, forKey: "addressIDs")
        aCoder.encode(self.preferredAddress, forKey: "preferredAddress")
        aCoder.encode(self.cards, forKey: "cards")
        aCoder.encode(self.cardIDs, forKey: "cardIDs")
        aCoder.encode(self.preferredCard, forKey: "preferredCard")
        aCoder.encode(self.hasCreatedFirstCard, forKey: "hasCreated")
        aCoder.encode(self.isLoggedIn, forKey: "isLoggedIn")
        aCoder.encode(self.jwt, forKey: "jwt")
        aCoder.encode(self.orderHistory, forKey: "orderHistory")
        aCoder.encode(self.hasPromptedRating, forKey: "hasPrompted")
        aCoder.encode(self.loyaltySlices, forKey: "loyaltySlices")
        aCoder.encode(self.hasSeenTutorial, forKey: "hasSeenTutorial")
        aCoder.encode(self.email, forKey: "email")
        aCoder.encode(self.wantsReceipts, forKey: "wantsReceipts")
        aCoder.encode(self.wantsOrderConfirmation, forKey: "confirmation")
        aCoder.encode(self.school, forKey: "school")
    }
    
    func saveToDefaults(){
        NSKeyedArchiver.archiveRootObject(self, toFile: Constants.userFilePath())
    }
}
