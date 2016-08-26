//
//  Architecture
//  Slice
//
//  Created by Oliver Hill on 6/10/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.

import Foundation

//Either Apple Pay or the index of a Card
enum PaymentPreference: Equatable{
    func value()->Int{
        switch self{
        case .ApplePay:
            return -1
        case .CardIndex(let ind):
            return ind
        }
    }
    
    case CardIndex(Int)
    case ApplePay
}

func == (lhs: PaymentPreference, rhs: PaymentPreference) -> Bool{
    switch(lhs, rhs){
    case (.ApplePay, .ApplePay): return true
    case (.ApplePay, .CardIndex(_)):return false
    case (.CardIndex(let l), .CardIndex(let r)): return r==l
    case (.CardIndex(_), .ApplePay): return false
    }
}
