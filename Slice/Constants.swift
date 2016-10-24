//
//  Constants.swift
//  Slice
//
//  Created by Oliver Hill on 7/7/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import UIKit

internal struct Constants{
    
    private static var pepperoniPrice = 349
    private static var cheesePrice = 299
    
    static func setPrices(cheese cheese: Int, pepperoni: Int){
        cheesePrice = cheese
        pepperoniPrice = pepperoni
    }
    
    static func getPepperoniPriceCents()->Int{
        return pepperoniPrice
    }
    static func getCheesePriceCents()->Int{
        return cheesePrice
    }
    static func getPepperoniPriceDollars()->Double{
        return Double(Double(pepperoniPrice)/Double(100))
    }
    static func getCheesePriceDollars()->Double{
        return Double(Double(cheesePrice)/Double(100))
    }
    
    static func userFilePath() -> String{
        let paths = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let filePath = paths[0].URLByAppendingPathComponent("productionPath.plist")
        return filePath!.path!
    }
    
    static func getTitleAttributedString(text: String, size: Int, kern: Double)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: CGFloat(size))!, range: (attributedString.string as NSString).rangeOfString(text))
        return attributedString
    }
    
    //The amount of the main view that is still showing when the side menu slides out. Should match amountVisibleOfSliceController
    static let sliceControllerShowing: CGFloat = 110
    
    //Colors
    static let tiltColor = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 1.0)
    static let seaFoam = UIColor(red: 40/255.0, green: 231/255.0, blue: 169/255.0, alpha: 1.0)
    static let tiltColorFade = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 0.8)
    static let darkBlue = UIColor(red: 30/255.0, green: 39/255.0, blue: 68/255.0, alpha: 1.0)
    static let lightRed = UIColor(red: 208/255.0, green: 91/255.0, blue: 91/255.0, alpha: 1.0)

    //URLS
    static let isOpenURLString = "https://prod-doorslice.herokuapp.com/api/isOpen/"
    static let getPricesURLString = "https://prod-doorslice.herokuapp.com/api/prices"
    static let saveOrderURLString = "https://prod-doorslice.herokuapp.com/api/orders/"
    static let rateLastOrderURLString = "https://prod-doorslice.herokuapp.com/api/rateorder/"
    
    static let sendPassodeURLString = "https://prod-doorslice.herokuapp.com/api/sendPassCode"
    static let resetPasswordURLString = "https://prod-doorslice.herokuapp.com/api/resetPass"
    
    static let accountCreationURLString = "https://prod-doorslice.herokuapp.com/api/users"
    static let sendCodeURLString = "https://prod-doorslice.herokuapp.com/api/sendCode"
    static let authenticateURLString = "https://prod-doorslice.herokuapp.com/api/users/authenticate"
    static let loginURLString = "https://prod-doorslice.herokuapp.com/api/users/login"
    static let addEmailURLString = "https://prod-doorslice.herokuapp.com/api/users/addEmail/"
    
    static let getAddressesURLString = "https://prod-doorslice.herokuapp.com/api/addresses/"
    static let newAddressURLString = "https://prod-doorslice.herokuapp.com/api/address/"
    static let deleteAddressURLString = "https://prod-doorslice.herokuapp.com/api/address/"
    
    static let firstCardURLString = "https://prod-doorslice.herokuapp.com/api/payments/newStripeUser/"
    static let newCardURLString = "https://prod-doorslice.herokuapp.com/api/payments/newStripeCard/"
    static let updateCardURLString = "https://prod-doorslice.herokuapp.com/api/payments/updateDefaultCard/"
    static let chargeUserURLString = "https://prod-doorslice.herokuapp.com/api/payments/charge/"
    static let deleteCardURLString = "https://prod-doorslice.herokuapp.com/api/payments/removeCard/"
    
    static let booleanChangeURLString = "https://prod-doorslice.herokuapp.com/api/users/"
    static let wantsReceipts = "wantsReceipts"
    static let wantsConfirmation = "wantsConfirmation"
    static let hasSeenTutorial = "hasSeenTutorial"
    
    static let stripePublishableKey = "pk_live_zDpdr6lg6Y5rdeJRK4Efu9AQ"

    static let dormNicknames = ["CARMAN HALL" : "CARMAN", "JOHN JAY HALL" : "JOHN JAY", "MCBAIN HALL" : "MCBAIN",  "WIEN HALL" : "WIEN", "48 CLAREMONT" : "48 CLAREMONT", "601 WEST 113TH STREET" : "601 113TH", "BROADWAY HALL" : "BROADWAY", "CARLTON ARMS" : "CARLTON ARMS", "EAST CAMPUS" : "EC", "FURNALD HALL" : "FURNALD", "HARMONY HALL" : "HARMONY", "HARTLEY HALL" : "HARTLEY", "HOGAN HALL" : "HOGAN", "RIVER HALL" : "RIVER" , "JUGGLES HALL" : "JUGGLES", "SHAPIRO HALL" : "SHAPIRO", "WALLACH HALL" : "WALLACH", "WATT HALL" : "WATT", "WOODBRIDGE HALL" : "WOODBRIDGE", "VILLAGE C EAST" : "VCE", "VILLAGE C WEST" : "VCW", "NEW SOUTH" : "NEW SOUTH", "KENNEDY HALL" : "KENNEDY", "LXR" : "LXR", "HARBIN HALL" : "HARBIN", "NORTH EAST HALL" : "NET", "COPLEY HALL" : "COPLEY", "REYNOLDS HALL" : "REYNOLDS", "MCCARTHY HALL" : "MCCARTHY", "DARNALL HALL" : "DARNALL", "HENLE VILLAGE" : "HENLE", "VILLAGE A" : "VILLAGE A", "VILLAGE B" : "VILLAGE B", "NEVILS" : "NEVILS", "FREEDOM HALL" : "FREEDOM"]
    
}
