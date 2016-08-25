//
//  PaymentController.swift
//  Slice
//
//  Created by Oliver Hill on 6/22/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import Foundation
import Stripe
import Alamofire
import SwiftyJSON

enum STPBackendChargeResult {
    case Success, Failure
}
typealias STPTokenSubmissionHandler = (STPBackendChargeResult?, NSError?) -> Void


//A bag of functions to do the all of the networking and charge the user. 
//Exactly one of the delegates and the headers property MUST BE SET to use this class
class NetworkingController{
    
    var containerDelegate: Payable?
    var tutorialDelegate: Configurable?
    var headers: [String : String]!
    
    //MARK: Save Order
    //Used for both Apple Pay and card payment. Price is in dollars (6.49 = $6.49)
    func saveOrder(cheese: Int, pepperoni: Int, url: String, cardID: String, price: String, completion: ()->Void){
        let parameters = ["cheese" : String(cheese), "pepperoni" : String(pepperoni), "cardUsed" : cardID, "price" : String(price)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            completion()
            switch response.result{
            case .Success:
                self.containerDelegate!.addLoyalty(cheese+pepperoni)
            case .Failure:
                self.containerDelegate!.removeLoyalty(cheese+pepperoni)
                if response.response?.statusCode == 401{ self.containerDelegate?.unauthenticated() }
            }
        }
    }
    
    
    //MARK: Card Specific Functions
    
    //Saves a new card regardless of whether it is the user's first card or not. The url passed to it has already taken this into consideration
    func saveNewCard(card: STPCardParams?, url: String, lastFour: String){
        STPAPIClient.sharedClient().createTokenWithCard(card!){ (tokenOpt, error) -> Void in
            if error != nil{
                self.containerDelegate?.cardStoreageFailed(cardDeclined: true)
                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: true)
            }
            else if let token = tokenOpt{
                let parameters = ["stripeToken" : token.tokenId, "lastFour" : lastFour]
                Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: self.headers).responseJSON { response in
                    debugPrint(response)
                    switch response.result{
                    case .Success:
                        if let value = response.result.value{
                            let cardID = JSON(value)["card"]["cardID"].stringValue
                            if cardID != ""{
                                self.containerDelegate?.storeCardID(cardID, lastFour: lastFour)
                                self.tutorialDelegate?.storeCardID(cardID, lastFour: lastFour)
                            }
                            else{
                                self.containerDelegate?.cardStoreageFailed(cardDeclined: false)
                                self.tutorialDelegate?.cardStoreageFailed(cardDeclined: false)
                            }
                        }
                    case .Failure:
                        if response.response?.statusCode == 401{
                            self.containerDelegate?.unauthenticated()
                            self.tutorialDelegate?.unauthenticated()
                        }
                        else{
                            self.containerDelegate?.cardStoreageFailed(cardDeclined: false)
                            self.tutorialDelegate?.cardStoreageFailed(cardDeclined: false)
                        }

                    }
                }
            }
        }
    }

    
    func changeCard(cardID: String, userID: String, completion: ()->Void){
        Alamofire.request(.POST, Constants.updateCardURLString+userID, parameters: ["cardID" : cardID], encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion()
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.cardPaymentFailed(cardDeclined: false)
                }
            }
        }
    }
    
    //Amount should be in cents, url should already have userID appended to it
    //Default card should already be changed in the backend
    //Amount is in cents (649 = $6.49)
    func chargeUser(url: String, amount: String, description: String){
        let parameters = ["chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            debugPrint(response)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["succesful charge"] != JSON("blank"){
                        self.containerDelegate?.cardPaymentSuccesful()
                    }
                    else{
                        self.containerDelegate?.cardPaymentFailed(cardDeclined: true)
                    }
                    
                }
            
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.cardPaymentFailed(cardDeclined: false)
                }
            }
        }
    }
    
    
    
    //MARK: Apple Pay Functions
    static func canApplePay() -> Bool{
        if let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(Constants.appleMerchantId){
            if Stripe.canSubmitPaymentRequest(paymentRequest){
                return true
            }
        }
        return false
    }
    
    
    func createPaymentRequest(cheese cheese: Double, pepperoni: Double) -> PKPaymentRequest{
        let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(Constants.appleMerchantId)!
        if cheese != 0 {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "Cheese slices",
                amount:NSDecimalNumber(double: cheese*3.00)))
        }
        if pepperoni != 0 {
            paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "Pepperoni slices",
                amount:NSDecimalNumber(double: pepperoni*3.59)))
        }
        let total = cheese*3 + pepperoni*3.59
        paymentRequest.paymentSummaryItems.append(PKPaymentSummaryItem(label: "DoorSlice Order", amount: NSDecimalNumber(double: total)))
        
        return paymentRequest
    }
    
    
    func applePayAuthorized(payment: PKPayment, userID: String, amount: Int, description: String, completion: ((PKPaymentAuthorizationStatus) -> Void)){
        
        let apiClient = STPAPIClient(publishableKey: Constants.stripePublishableKey)
        apiClient.createTokenWithPayment(payment, completion: { (token, error) -> Void in
            if error == nil {
                if let token = token {
                    self.createBackendChargeWithToken(token, userID: userID, amount: amount, description: description, completion: { (result, error) -> Void in
                        if result == STPBackendChargeResult.Success {
                            completion(PKPaymentAuthorizationStatus.Success)
                            self.containerDelegate?.applePayFailed = false
                        }
                        else {
                            completion(PKPaymentAuthorizationStatus.Failure)
                            self.containerDelegate?.applePayFailed = true
                        }
                    })
                }
            }
            else {
                completion(PKPaymentAuthorizationStatus.Failure)
                self.containerDelegate?.applePayFailed = true
            }
        })
    }
    
    
    //MARK: Charge Backend
    func createBackendChargeWithToken(token: STPToken, userID: String, amount: Int, description: String, completion: STPTokenSubmissionHandler) {
        
        let parameters = ["stripeToken" : token, "chargeAmount" : amount, "chargeDescription" : description]
        Alamofire.request(.POST, Constants.chargeUserURLString+userID, parameters: parameters, encoding: .URL, headers: headers).responseJSON {
            response in
            debugPrint(response)
            switch response.result{
            case .Success:
                completion(.Success, nil)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                completion(.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "There was an error communication with your payment backend."]))
            }
        }
    }
    
    //MARK: Addresses
    func saveAddress(add: Address, userID: String){
        let url = Constants.newAddressURLString+userID
        let parameters = ["School" : add.school, "Dorm" : add.dorm, "Room" : add.room]
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON { response in
            debugPrint(response)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    let id = JSON(value)["Data"]["_id"].stringValue
                    if id != ""{
                        self.containerDelegate?.addressSaveSucceeded(add, orderID: id)
                        self.tutorialDelegate?.addressSaveSucceeded(add, orderID: id)
                    }
                    else{
                        self.containerDelegate?.addressSaveFailed()
                        self.tutorialDelegate?.addressSaveFailed()
                    }
                }
                else{
                    self.containerDelegate?.addressSaveFailed()
                    self.tutorialDelegate?.addressSaveFailed()
                }
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                    self.tutorialDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.addressSaveFailed()
                    self.tutorialDelegate?.addressSaveFailed()
                }
            }
        }
    }
    
    func deleteAddress(url: String, completion: (Bool)->Void){
        Alamofire.request(.DELETE, url, parameters: nil, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion(true)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func deleteCard(url: String, card: String, completion: (Bool)->Void){
        let parameters = ["cardID" : card]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                completion(true)
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    completion(false)
                }
            }
        }
    }
    
    func rateLastOrder(userID: String, stars: Int, comment: String?){
        let parameters = comment != nil ? ["stars" :  String(stars), "review" : comment!] : ["stars" : String(stars)]
        Alamofire.request(.POST, Constants.rateLastOrderURLString + userID, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    func addEmail(userID: String, email: String){
        Alamofire.request(.POST, Constants.addEmailURLString + userID, parameters: ["email" : email], encoding: .URL, headers: headers).responseJSON{ response in
            switch response.result{
            case .Success:
                break
            case .Failure:
                if response.response?.statusCode == 401{
                    self.containerDelegate?.unauthenticated()
                }
                else{
                    self.containerDelegate?.emailSaveFailed()
                }
            }
        }
    }
    
    
    func booleanChange(endpoint: String, userID: String, boolean: Bool){
        let url = "\(Constants.booleanChangeURLString)\(endpoint)/\(userID)"
        let parameters = [endpoint : String(boolean)]
        Alamofire.request(.POST, url, parameters: parameters, encoding: .URL, headers: headers).responseJSON{ response in
            debugPrint(response)
            if response.response?.statusCode == 401{
                self.containerDelegate?.unauthenticated()
            }
        }
    }
    
    
    static func checkHours(userID: String)->Bool{
        var isOpen = false
        Alamofire.request(.GET, Constants.isOpenURLString + userID).responseJSON{ response in
            debugPrint(response)
            switch response.result{
            case .Success:
                if let value = response.result.value{
                    if JSON(value)["open"].boolValue{
                        isOpen = true
                    }
                    else{
                        isOpen = false
                    }
                }
            case .Failure:
                isOpen = false
            }
        }
        return isOpen
    }
}



