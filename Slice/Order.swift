//
//  Order.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation

//A struct to hold the slice information of an order while it's being placed
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






