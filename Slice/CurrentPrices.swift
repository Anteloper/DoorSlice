//
//  CurrentPrices.swift
//  Slice
//
//  Created by Oliver Hill on 8/25/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

//A singleton class to retrieve current prices of slices
class CurrentPrices{
    static let sharedInstance = CurrentPrices()
    
    private var pepperoniPrice: Int //Price in cents
    private var cheesePrice: Int
    
    init(){
        pepperoniPrice = 349
        cheesePrice = 299
        Alamofire.request(.GET, Constants.getPricesURLString, parameters: nil).responseJSON{ response in
            debugPrint(response)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    let json = JSON(value)
                    self.pepperoniPrice = Int(json["Cheese"].doubleValue * 100)
                    self.cheesePrice = Int(json["Pepperoni"].doubleValue * 100)
                }
            case .Failure:
                self.pepperoniPrice = 349
                self.cheesePrice = 299
            }
        }
    }
    
    func getPepperoniCents()->Int{ return pepperoniPrice }
    
    func getCheeseCents()->Int{ return cheesePrice }
    
    func getPepperoniDollars() -> Double { return Double(Double(pepperoniPrice)/Double(100)) }
    
    func getCheeseDollars() -> Double { return Double(Double(cheesePrice)/Double(100)) }
    
}