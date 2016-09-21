//
//  PastOrder.swift
//  Slice
//
//  Created by Oliver Hill on 7/23/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation

//An instance of this class is an object representing a single order. Conforms to NSCoding and NSCopying so it can be stored with the User
class PastOrder: NSObject, NSCoding, NSCopying{
    var address: Address
    var cheeseSlices: Int
    var pepperoniSlices: Int
    var price: Double
    var timeOrdered: Date
    var paymentMethod: String
    
    init(address: Address, cheeseSlices: Int = 0, pepperoniSlices: Int = 0, price: Double, timeOrdered: Date = Date(), paymentMethod: String){
        self.address = address
        self.cheeseSlices = cheeseSlices
        self.price = price
        self.pepperoniSlices = pepperoniSlices
        self.timeOrdered = timeOrdered
        self.paymentMethod = paymentMethod
    }
    
    required override init(){
        address = Address()
        cheeseSlices = 0
        price = 0
        pepperoniSlices = 0
        timeOrdered = Date()
        paymentMethod = ""
    }
    required init(_ order: PastOrder){
        self.address = order.address
        self.cheeseSlices = order.cheeseSlices
        self.pepperoniSlices = order.pepperoniSlices
        self.price = order.price
        self.timeOrdered = order.timeOrdered
        self.paymentMethod = order.paymentMethod
    }
    
    func copy(with zone: NSZone?) -> Any {
        return type(of: self).init(self)
    }
    required convenience init?(coder decoder: NSCoder){
        guard let address = decoder.decodeObject(forKey: "address") as? Address,
            let cheeseSlices = decoder.decodeObject(forKey: "cheeseSlices") as? Int,
            let pepperoniSlices = decoder.decodeObject(forKey: "pepperoniSlices") as? Int,
            let price = decoder.decodeObject(forKey: "price") as? Double,
            let timeOrdered = decoder.decodeObject(forKey: "timeOrdered") as? Date,
            let paymentMethod = decoder.decodeObject(forKey: "paymentMethod") as? String else{
            return nil
        }
        self.init(address: address, cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, price: price, timeOrdered: timeOrdered, paymentMethod: paymentMethod)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.address, forKey: "address")
        aCoder.encode(self.cheeseSlices, forKey: "cheeseSlices")
        aCoder.encode(self.pepperoniSlices, forKey: "pepperoniSlices")
        aCoder.encode(self.price, forKey: "price")
        aCoder.encode(self.timeOrdered, forKey: "timeOrdered")
        aCoder.encode(self.paymentMethod, forKey: "paymentMethod")
    }
}

