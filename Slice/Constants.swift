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
    
    static func userFilePath() -> String{
        let paths = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let filePath = paths[0].URLByAppendingPathComponent("finalPath.plist")
        return filePath.path!
    }
    
    //The amount of the main view that is still showing when the side menu slides out. Should match amountVisibleOfSliceController
    static let sliceControllerShowing: CGFloat = 110
    static let tiltColor = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 1.0)
    static let seaFoam = UIColor(red: 40/255.0, green: 231/255.0, blue: 169/255.0, alpha: 1.0)
    static let tiltColorFade = UIColor(red: 19/255.0,green: 157/255.0, blue: 234/255.0, alpha: 0.8)
    static let darkBlue = UIColor(red: 30/255.0, green: 39/255.0, blue: 68/255.0, alpha: 1.0)
    static let lightRed = UIColor(red: 208/255.0, green: 91/255.0, blue: 91/255.0, alpha: 1.0)
    static let statusColor = UIColor(red: 30/255.0, green: 40/255.0, blue: 62/255.0, alpha: 1.0)

    
    static let stripePublishableKey = "pk_test_Lp3E4ypwmrizs2jfEenXdwpr"
    static let JWTSecretKey = "2vczz6nvmvjpcfv0nrho"

    static let saveOrderURLString = "https://doorslice.herokuapp.com/api/orders/"
    static let sendPassodeURLString = "https://doorslice.herokuapp.com/api/sendPassCode"
    static let resetPasswordURLString = "https://doorslice.herokuapp.com/api/resetPass"
    
    static let accountCreationURLString = "https://doorslice.herokuapp.com/api/users"
    static let sendCodeURLString = "https://doorslice.herokuapp.com/api/sendCode"
    static let authenticateURLString = "https://doorslice.herokuapp.com/api/users/authenticate"
    static let loginURLString = "https://doorslice.herokuapp.com/api/users/login"
    
    static let testAuthURLString = "https://doorslice.herokuapp.com/api/users/"
    
    static let getAddressesURLString = "https://doorslice.herokuapp.com/api/addresses"
    static let newAddressURLString = "https://doorslice.herokuapp.com/api/address/"
    static let deleteAddressURLString = "https://doorslice.herokuapp.com/api/address/"
    
    static let firstCardURLString = "https://doorslice.herokuapp.com/api/payments/newStripeUser/"
    static let newCardURLString = "https://doorslice.herokuapp.com/api/payments/newStripeCard/"
    static let updateCardURLString = "https://doorslice.herokuapp.com/api/payments/updateDefaultCard/"
    static let chargeUserURLString = "https://doorslice.herokuapp.com/api/payments/charge/"
    static let deleteCardURLString = "https://doorslice.herokuapp.com/api/payments/removeCard/"
    
    static func getTitleAttributedString(text: String, size: Int, kern: Double)->NSMutableAttributedString{
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSKernAttributeName, value: CGFloat(kern), range: (attributedString.string as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Myriad Pro", size: CGFloat(size))!, range: (attributedString.string as NSString).rangeOfString(text))
        return attributedString
    }

    static func getBackButton()->UIButton{
        let backButton = UIButton(frame: CGRect(x: 9, y: 20, width: 20, height: 20))
        backButton.setImage(UIImage(imageLiteral: "back"), forState: .Normal)
        return backButton
    }
    
    static let appleMerchantId = "merchant.com.dormslice"
    static let userKey = "finalUserKey"
    static let applePayCardID = "applePay"
    
    static let schools = ["GEORGETOWN UNIVERSITY",  "COLUMBIA UNIVERSITY"]
    
    static let columbiaDorms = ["CARMAN HALL", "JOHN JAY HALL", "MCBAIN HALL",  "WIEN HALL", "48 CLAREMONT", "601 WEST 113TH STREET", "BROADWAY HALL", "CARLTON ARMS", "EAST CAMPUS", "FURNALD HALL", "HARMONY HALL", "HARTLEY HALL", "HOGAN HALL", "RIVER HALL" , "JUGGLES HALL", "SHAPIRO HALL", "WALLACH HALL", "WATT HALL", "WOODBRIDGE HALL"]
    
    static let georgetownDorms = [ "VILLAGE C EAST", "VILLAGE C WEST", "NEW SOUTH", "KENNEDY HALL", "LXR", "HARBIN HALL", "NORTH EAST HALL", "COPLEY HALL", "REYNOLDS HALL", "MCCARTHY HALL", "DARNALL HALL", "HENLE VILLAGE", "VILLAGE A", "VILLAGE B", "NEVILS", "FREEDOM HALL"]
    
    static let dormNicknames = ["CARMAN HALL" : "CARMAN", "JOHN JAY HALL" : "JOHN JAY", "MCBAIN HALL" : "MCBAIN",  "WIEN HALL" : "WIEN", "48 CLAREMONT" : "48 CLAREMONT", "601 WEST 113TH STREET" : "601 113TH", "BROADWAY HALL" : "BROADWAY", "CARLTON ARMS" : "CARLTON ARMS", "EAST CAMPUS" : "EC", "FURNALD HALL" : "FURNALD", "HARMONY HALL" : "HARMONY", "HARTLEY HALL" : "HARTLEY", "HOGAN HALL" : "HOGAN", "RIVER HALL" : "RIVER" , "JUGGLES HALL" : "JUGGLES", "SHAPIRO HALL" : "SHAPIRO", "WALLACH HALL" : "WALLACH", "WATT HALL" : "WATT", "WOODBRIDGE HALL" : "WOODBRIDGE", "VILLAGE C EAST" : "VCE", "VILLAGE C WEST" : "VCW", "NEW SOUTH" : "NEW SOUTH", "KENNEDY HALL" : "KENNEDY", "LXR" : "LXR", "HARBIN HALL" : "HARBIN", "NORTH EAST HALL" : "NET", "COPLEY HALL" : "COPLEY", "REYNOLDS HALL" : "REYNOLDS", "MCCARTHY HALL" : "MCCARTHY", "DARNALL HALL" : "DARNALL", "HENLE VILLAGE" : "HENLE", "VILLAGE A" : "VILLAGE A", "VILLAGE B" : "VILLAGE B", "NEVILS" : "NEVILS", "FREEDOM HALL" : "FREEDOM"]
    
}