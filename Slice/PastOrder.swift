//
//  PastOrder.swift
//  Slice
//
//  Created by Oliver Hill on 7/23/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation

class PastOrder: NSObject, NSCoding, NSCopying{
    var address: Address
    var cheeseSlices: Int
    var pepperoniSlices: Int
    var timeOrdered: NSDate
    var paymentMethod: String
    
    init(address: Address, cheeseSlices: Int = 0, pepperoniSlices: Int = 0, timeOrdered: NSDate = NSDate(), paymentMethod: String){
        self.address = address
        self.cheeseSlices = cheeseSlices
        self.pepperoniSlices = pepperoniSlices
        self.timeOrdered = timeOrdered
        self.paymentMethod = paymentMethod
    }
    
    required override init(){
        address = Address()
        cheeseSlices = 0
        pepperoniSlices = 0
        timeOrdered = NSDate()
        paymentMethod = ""
    }
    required init(_ order: PastOrder){
        self.address = order.address
        self.cheeseSlices = order.cheeseSlices
        self.pepperoniSlices = order.pepperoniSlices
        self.timeOrdered = order.timeOrdered
        self.paymentMethod = order.paymentMethod
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return self.dynamicType.init(self)
    }
    required convenience init?(coder decoder: NSCoder){
        guard let address = decoder.decodeObjectForKey("address") as? Address,
            let cheeseSlices = decoder.decodeObjectForKey("cheeseSlices") as? Int,
            let pepperoniSlices = decoder.decodeObjectForKey("pepperoniSlices") as? Int,
            let timeOrdered = decoder.decodeObjectForKey("timeOrdered") as? NSDate,
            let paymentMethod = decoder.decodeObjectForKey("paymentMethod") as? String else
        {
            return nil
        }
        self.init(address: address, cheeseSlices: cheeseSlices, pepperoniSlices: pepperoniSlices, timeOrdered: timeOrdered, paymentMethod: paymentMethod)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.address, forKey: "address")
        aCoder.encodeObject(self.cheeseSlices, forKey: "cheeseSlices")
        aCoder.encodeObject(self.pepperoniSlices, forKey: "pepperoniSlices")
        aCoder.encodeObject(self.timeOrdered, forKey: "timeOrdered")
        aCoder.encodeObject(self.paymentMethod, forKey: "paymentMethod")
    }
}

