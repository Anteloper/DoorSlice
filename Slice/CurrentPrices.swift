//
//  CurrentPrices.swift
//  Slice
//
//  Created by Oliver Hill on 8/25/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation

class CurrentPrices{
    static let sharedInstance = CurrentPrices()
    
    private var pepperoniPrice: Int //Price in cents
    private var cheesePrice: Int
    
    init(){
        pepperoniPrice = 349
        cheesePrice = 300
    }
    
    func getPepperoniCents()->Int{ return pepperoniPrice }
    
    func getCheeseCents()->Int{ return cheesePrice }
    
    func getPepperoniDollars() -> Double { return Double(Double(pepperoniPrice)/Double(100)) }
    
    func getCheeseDollars() -> Double { return Double(Double(cheesePrice)/Double(100)) }
    
}